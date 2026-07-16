//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : reset_sequencer.sv
// Author   : Nada
// Date     : 2026-07-16
//------------------------------------------------------------------------------
// Description:
// Sequencer for the reset agent.
// Arbitrates and forwards reset sequence items from reset sequences
// to the reset driver.
//------------------------------------------------------------------------------
class reset_sequencer extends uvm_sequencer #(reset_seq_item);

  `uvm_component_utils(reset_sequencer)

  function new(string name, uvm_component parent);
    super.new(name,parent);
  endfunction

endclass