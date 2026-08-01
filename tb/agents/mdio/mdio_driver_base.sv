//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : mdio_driver_base.sv
// Author   : Muhammad Majid
// Date     : 2026-06-26
//------------------------------------------------------------------------------
// Description:
//   Base MDIO driver for Ethernet MAC management interface. Drives MDIO/MDC
//   pins based on mdio_seq_item_base sequences via virtual interface.
//==============================================================================

`ifndef MDIO_DRIVER_BASE_SV
`define MDIO_DRIVER_BASE_SV

class mdio_driver_base extends uvm_driver #(mdio_seq_item_base);
  `uvm_component_utils(mdio_driver_base)

  virtual mdio_if vif;
  mdio_config_obj   m_config;
  mdio_seq_phy_responder m_phy_model;

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  extern function new(string name, uvm_component parent);

  // -------------------------------------------------------------------------
  //  Build Phase
  // -------------------------------------------------------------------------
  extern function void build_phase(uvm_phase phase);

  // -------------------------------------------------------------------------
  //  Run Phase
  // -------------------------------------------------------------------------
  extern task run_phase(uvm_phase phase);

  // -------------------------------------------------------------------------
  //  Task : drive_items
  // -------------------------------------------------------------------------
  // Description:
  //   Drive pin level interface with stimulus from mdio_seq_item_base.
  //
  // Arguments: None
  //
  // Returns : void
  // -------------------------------------------------------------------------
  extern task drive_items();

endclass

// =============================================================================
//  IMPLEMENTATION
// =============================================================================

// Function : new (Constructor)
function mdio_driver_base::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction

// Build Phase
function void mdio_driver_base::build_phase(uvm_phase phase);
  super.build_phase(phase);

  if (!uvm_config_db #(mdio_config_obj)::get(this, "", "config", m_config))
    `uvm_fatal(get_type_name(), "mdio_config_obj not found in config_db")

  vif = m_config.vif;
  if (vif == null)
    `uvm_fatal(get_type_name(), "mdio driver virtual interface not set")

  // The PHY register model (reg0/reg1 content) lives on the always-on
  // responder sequence built by eth_env_mdio -- fetched directly here
  // rather than through a mdio_config_obj field, to avoid adding a
  // mdio_seq_pkg dependency to the config package.
  if (!uvm_config_db #(mdio_seq_phy_responder)::get(this, "", "phy_model", m_phy_model))
    `uvm_fatal(get_type_name(), "PHY register model not found in config_db -- check eth_env_mdio.sv")

endfunction


// Task : run_phase
task mdio_driver_base::run_phase(uvm_phase phase);
  vif.mdio_in <= 1'bz; // PHY starts by not driving the bus
  forever begin
    drive_items();
  end
endtask


// Task : drive_items
task mdio_driver_base::drive_items();
  bit [1:0] op;
  bit [4:0] phy_ad, reg_ad;
  bit [1:0] shift_reg = 2'b11;
  bit [15:0] wr_data;

  forever begin
    @(posedge vif.mdc);
    shift_reg = {shift_reg[0], vif.mdio_out};
    if (shift_reg == 2'b01) break;
  end

  @(posedge vif.mdc); op[1] = vif.mdio_out;
  @(posedge vif.mdc); op[0] = vif.mdio_out;

  for(int i=4; i>=0; i--) begin @(posedge vif.mdc); phy_ad[i] = vif.mdio_out; end
  for(int i=4; i>=0; i--) begin @(posedge vif.mdc); reg_ad[i] = vif.mdio_out; end

  if (op == 2'b10) begin // READ
    seq_item_port.get_next_item(req); // sync token only, see phy_responder header

    @(negedge vif.mdc);
    vif.mdio_in <= 1'b0;
    @(posedge vif.mdc);

    begin
      bit [15:0] rd_data = m_phy_model.get_reg(phy_ad, reg_ad);
      for(int i=15; i>=0; i--) begin
        @(negedge vif.mdc);
        vif.mdio_in <= rd_data[i];
        @(posedge vif.mdc);
      end
    end

    @(negedge vif.mdc);
    vif.mdio_in <= 1'bz;
    seq_item_port.item_done();

  end else begin
    // WRITE: capture the payload so reg0's RW bits actually take effect.
    seq_item_port.get_next_item(req);

    repeat(2) @(posedge vif.mdc); // consume Turn-Around bits ('1','0')
    for(int i=15; i>=0; i--) begin
      @(posedge vif.mdc);
      wr_data[i] = vif.mdio_out;
    end

    m_phy_model.put_reg(phy_ad, reg_ad, wr_data);
    seq_item_port.item_done();
  end
endtask

`endif // MDIO_DRIVER_BASE_SV
