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
    bit frame_complete;

    forever begin
      m_mdio_seq_item = mdio_seq_item_base::type_id::create("m_mdio_seq_item");
      frame_complete = 0;

      @(posedge vif.mdio_en);
      fork : sample_fork
        begin
          pack_preamble();
          pack_data();
          frame_complete = 1;
        end
        calc_freq();
        // Watchdog: mdio_en dropping before the block above finishes on
        // its own means the transaction was aborted mid-flight (e.g. a
        // DUT reset asserted while shifting). Kill the stale sampling
        // threads instead of leaving them blocked on an Mdc edge that may
        // never come -- otherwise they resume mid-frame on the NEXT
        // transaction and eat its bits from the wrong position (seen as
        // "Invalid opcode observed: 11").
        begin
          @(negedge vif.mdio_en);
          disable sample_fork;
        end
      join_any
      disable sample_fork;

      if (frame_complete)
        a_port.write(m_mdio_seq_item);
      else
        `uvm_info(get_type_name(),
            "MDIO transaction aborted mid-frame (mdio_en dropped early) -- discarding partial sample",
            UVM_LOW)
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
    m_mdio_seq_item.clk_period_ns=(fin-st)/1000.0; // raw $time delta here resolves in ps
                                                    // (1ns/1ps global timescale) -- /1000.0
                                                    // converts it to ns. Do not remove.
  endtask

endclass

`endif // MDIO_MONITOR_BASE_SV