//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : mii_tx_seq_collision_pre.sv
// Author   : Wael
// Date     : 2026-08-16
//------------------------------------------------------------------------------
// Description:
// This sequence injects a collision on the MII interface during frame
// transmission. Exactly during transmission of preamble field.
//==============================================================================

`ifndef MII_TX_SEQ_COLLISION_PRE_SV
`define MII_TX_SEQ_COLLISION_PRE_SV

class mii_tx_seq_collision_pre extends mii_tx_seq_collision;
  `uvm_object_utils(mii_tx_seq_collision_pre)


  function new(string name = "mii_tx_seq_collision_pre");
    super.new(name);
  endfunction

  virtual task body();
  @(p_sequencer.vif.cb_mii_tx);
  
  wait (p_sequencer.vif.cb_mii_tx.MTxEN);
 

    req = mii_tx_seq_item_base::type_id::create("req");

    start_item(req);
    assert(req.randomize() with {
    MColl_time inside {9,14};
    MColl == 1'b1;
    })  
    else
      `uvm_fatal(get_name(), "Randomization failed")
	

    finish_item(req);
	
	
    // Wait until this transmission attempt finishes
    wait (!p_sequencer.vif.cb_mii_tx.MTxEN);
	

    `uvm_info(get_type_name(),
      "Asserting collision while MTxEN is high",
      UVM_MEDIUM)
	  
	

  endtask

endclass

`endif