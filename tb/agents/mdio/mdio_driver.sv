//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : mdio_driver_base.sv
// Author   : Mohammad
// Date     : 2026-06-22
//------------------------------------------------------------------------------
// Description:
//   Base MDIO driver for Ethernet MAC management interface. Drives MDIO/MDC
//   pins based on mdio_seq_item sequences via virtual interface.
//==============================================================================

`ifndef MDIO_DRIVER_BASE_SV
`define MDIO_DRIVER_BASE_SV

class mdio_driver_base extends uvm_driver #(mdio_seq_item);
  `uvm_component_utils(mdio_driver_base)

  virtual mdio_if vif;

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  extern function new(string name, uvm_component parent);

  // -------------------------------------------------------------------------
  //  Run Phase
  // -------------------------------------------------------------------------
  extern task run_phase(uvm_phase phase);

  // -------------------------------------------------------------------------
  //  Task : drive_items
  // -------------------------------------------------------------------------
  // Description:
  //   Drive pin level interface with stimulus from mdio_seq_item.
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


// Task : run_phase

task mdio_driver_base::run_phase(uvm_phase phase);
  forever
    begin
      seq_item_port.get_next_item(req);
      drive_items();
      seq_item_port.item_done();
    end
endtask


// Task : drive_items

task mdio_driver_base::drive_items();
endtask

`endif // MDIO_DRIVER_BASE_SV