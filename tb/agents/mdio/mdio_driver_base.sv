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

  // 1. Wait for Start of Frame (ST = 01)
  forever begin
    @(posedge vif.mdc);
    shift_reg = {shift_reg[0], vif.mdio_out};
    if (shift_reg == 2'b01) break;
  end

  // 2. Decode Opcode
  @(posedge vif.mdc); op[1] = vif.mdio_out;
  @(posedge vif.mdc); op[0] = vif.mdio_out;

  // 3. Decode Addresses (We just consume these clocks to stay synchronized)
  for(int i=4; i>=0; i--) begin @(posedge vif.mdc); phy_ad[i] = vif.mdio_out; end
  for(int i=4; i>=0; i--) begin @(posedge vif.mdc); reg_ad[i] = vif.mdio_out; end

  // 4. React based on Opcode
  if (op == 2'b10) begin // READ OPERATION requested by MAC

    // Get the status data we want to send back from the sequencer
    seq_item_port.get_next_item(req);

    // Turn Around (TA) time: MAC releases bus, PHY takes over driving a '0'
    @(negedge vif.mdc);
    vif.mdio_in <= 1'b0;
    @(posedge vif.mdc);

    // Drive 16-bit Data back to the MAC
    for(int i=15; i>=0; i--) begin
      @(negedge vif.mdc);
      vif.mdio_in <= req.data[i];
      @(posedge vif.mdc);
    end

    // Release bus and tell sequencer we are done
    @(negedge vif.mdc);
    vif.mdio_in <= 1'bz;
    seq_item_port.item_done();

  end else begin
    // WRITE OPERATION: The MAC is writing to the PHY.
    // The driver doesn't need to do anything, it just waits out the rest of the frame.
    repeat(18) @(posedge vif.mdc);
  end
endtask

`endif // MDIO_DRIVER_BASE_SV
