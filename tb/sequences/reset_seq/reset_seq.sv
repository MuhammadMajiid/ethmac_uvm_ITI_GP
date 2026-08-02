//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : reset_seq.sv
// Author   : Nada
// Date     : 2026-07-16
//------------------------------------------------------------------------------
// Description:
// Sequence that generates a hardware reset transaction.
// Requests the reset driver to assert the DUT reset for a specified
// number of clock cycles before releasing it.
//------------------------------------------------------------------------------
class reset_seq extends uvm_sequence #(reset_seq_item);

  `uvm_object_utils(reset_seq)

  eth_reg_block m_regmodel;
  function new(string name="reset_seq");
    super.new(name);
  endfunction

  task body();

    m_regmodel.reset();
    req = reset_seq_item::type_id::create("req");

    start_item(req);

    req.cycles = 9;
    req.active_level = 1;

    finish_item(req);

  endtask

endclass