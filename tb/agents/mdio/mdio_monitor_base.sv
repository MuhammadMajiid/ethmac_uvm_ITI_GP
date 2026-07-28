//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : mdio_monitor_base.sv
// Author   : Muhammad Majid
// Date     : 2026-06-26
//------------------------------------------------------------------------------
// Description:
//   Base MDIO monitor for Ethernet MAC management interface. Observes MDIO/MDC
//   pins and generates transactions.
//==============================================================================

`ifndef MDIO_MONITOR_BASE_SV
`define MDIO_MONITOR_BASE_SV

class mdio_monitor_base extends uvm_monitor;
  `uvm_component_utils(mdio_monitor_base)

  uvm_analysis_port #(mdio_seq_item_base) a_port;
  mdio_config_obj   m_config;
  virtual mdio_if vif;

  mdio_seq_item_base m_mdio_seq_item;
  bit [1:0] op_bits;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase); // Always call super
    if (!uvm_config_db #(mdio_config_obj)::get(this, "", "config", m_config))
      `uvm_fatal(get_type_name(), "mdio_config not found in config_db")
    vif = m_config.vif;
    if (vif == null)
      `uvm_fatal(get_type_name(), "mdio_monitor virtual interface not set")
    a_port = new("a_port", this);
  endfunction

  task run_phase(uvm_phase phase);

    forever begin
      m_mdio_seq_item = mdio_seq_item_base::type_id::create("m_mdio_seq_item");

      @(posedge vif.mdio_en);
      fork
      pack_preamble();
      pack_data();
      calc_freq();
      join;

      // 7. Broadcast the fully constructed transaction to the testbench
      a_port.write(m_mdio_seq_item);
    end
  endtask

task pack_preamble();

  for (int i=ETH_CTRL_PREAMBLE_LEN-1; i>=0; i--) begin
    m_mdio_seq_item.preamble[i]=vif.mdio_out;
    @(posedge vif.mdc);
  end

endtask

task pack_data();
        m_mdio_seq_item.st = 2'b11;
        // 1. Wait for Start of Frame (01)
      forever begin
        @(posedge vif.mdc); // Sample AFTER the clock edge, not before
        m_mdio_seq_item.st = {m_mdio_seq_item.st[0], vif.mdio_out};
        if (m_mdio_seq_item.st == 2'b01) break;
      end

      // 2. Sample Opcode
      @(posedge vif.mdc); op_bits[1] = vif.mdio_out;
      @(posedge vif.mdc); op_bits[0] = vif.mdio_out;
      // $cast(m_mdio_seq_item.op, op_bits);
      if (!$cast(m_mdio_seq_item.op, op_bits)) begin
          `uvm_error("MON", $sformatf("Invalid opcode observed: %b", op_bits))
      end

      // 3. Sample PHY Address
      for(int i=4; i>=0; i--) begin @(posedge vif.mdc); m_mdio_seq_item.phy_addr[i] = vif.mdio_out; end

      // 4. Sample REG Address
      for(int i=4; i>=0; i--) begin @(posedge vif.mdc); m_mdio_seq_item.reg_addr[i] = vif.mdio_out; end

      // 5. sample Turn Around bits (2 cycles)
      @(posedge vif.mdc);
      m_mdio_seq_item.turn_around[1] = (vif.mdio_en) ? vif.mdio_out : vif.mdio_in;
      @(posedge vif.mdc);
      m_mdio_seq_item.turn_around[0] = (vif.mdio_en) ? vif.mdio_out : vif.mdio_in;

      // 6. Sample Data
      for(int i=15; i>=0; i--) begin
        @(posedge vif.mdc);
        m_mdio_seq_item.data[i] = (vif.mdio_en) ? vif.mdio_out : vif.mdio_in;
      end
  endtask

task calc_freq();
    realtime st, fin;
    @(posedge vif.mdc);
    st=$time;
    @(posedge vif.mdc);
    fin=$time;
    m_mdio_seq_item.clk_period_ns=(fin-st); // Removed /1000.0 to keep it in ns
  endtask

endclass

`endif // MDIO_MONITOR_BASE_SV
