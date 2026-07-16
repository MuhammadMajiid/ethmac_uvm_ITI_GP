//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : reset_seq_item.sv
// Author   : Nada
// Date     : 2026-07-16
//------------------------------------------------------------------------------
// Description:
// Reset sequence item representing a reset transaction.
// Contains the reset duration and active level information used by the
// reset driver to apply hardware reset to the DUT.
//==============================================================================

class reset_seq_item extends uvm_sequence_item;

  rand int unsigned cycles;
  rand bit active_level;

  `uvm_object_utils(reset_seq_item)

  function new(string name="reset_seq_item");
    super.new(name);
  endfunction

endclass