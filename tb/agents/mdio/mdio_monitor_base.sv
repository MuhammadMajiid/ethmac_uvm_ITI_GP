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
  virtual mdio_if vif;

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
    mdio_seq_item_base tx;
    bit [1:0] shift_reg;
    bit [1:0] op_bits;

    forever begin
      tx = mdio_seq_item_base::type_id::create("tx");
      shift_reg = 2'b11;

      // 1. Wait for Start of Frame (01)
      forever begin
        @(posedge vif.mdc);
        shift_reg = {shift_reg[0], vif.mdio};
        if (shift_reg == 2'b01) break;
      end

      // 2. Sample Opcode
      @(posedge vif.mdc); op_bits[1] = vif.mdio;
      @(posedge vif.mdc); op_bits[0] = vif.mdio;
      $cast(tx.op, op_bits);

      // 3. Sample PHY Address
      for(int i=4; i>=0; i--) begin @(posedge vif.mdc); tx.phy_addr[i] = vif.mdio; end

      // 4. Sample REG Address
      for(int i=4; i>=0; i--) begin @(posedge vif.mdc); tx.reg_addr[i] = vif.mdio; end

      // 5. Turn Around Phase (2 cycles)
      @(posedge vif.mdc);
      @(posedge vif.mdc);

      // 6. Sample Data
      for(int i=15; i>=0; i--) begin
        @(posedge vif.mdc);
        tx.data[i] = vif.mdio;
      end

      // 7. Broadcast the fully constructed transaction to the testbench
      a_port.write(tx);
    end
  endtask

endclass

`endif // MDIO_MONITOR_BASE_SV
