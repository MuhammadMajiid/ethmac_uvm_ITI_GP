//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : reset_driver.sv
// Author   : Nada
// Date     : 2026-07-16
//------------------------------------------------------------------------------
// Description:
// Reset driver that receives reset transactions from the sequencer
// and drives the reset interface accordingly.
// Responsible for asserting and deasserting the DUT reset for the
// requested number of clock cycles.
//------------------------------------------------------------------------------

class reset_driver extends uvm_driver #(reset_seq_item);

  `uvm_component_utils(reset_driver)

  virtual reset_if vif;

  function new(string name, uvm_component parent);
    super.new(name,parent);
  endfunction

  task run_phase(uvm_phase phase);

    forever begin

      seq_item_port.get_next_item(req);

      vif.rst <= req.active_level;

      repeat(req.cycles)
        @(posedge vif.clk);

      vif.rst <= ~req.active_level;

      seq_item_port.item_done();

    end

  endtask

endclass