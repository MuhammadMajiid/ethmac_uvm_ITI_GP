//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : mii_tx_seq_collision.sv
// Author   : Nada
// Date     : 2026-07-21
//------------------------------------------------------------------------------
// Description:
// This sequence injects a collision on the MII interface during frame
// transmission. It waits until the DUT asserts MTxEN, indicating the start
// of transmission, then asserts the MColl signal (and MCrS if required) to
// emulate a collision on the Ethernet medium. The sequence is intended to
// verify the MAC's collision detection, retransmission, backoff, and error
// handling mechanisms in half-duplex mode.
//==============================================================================

`ifndef MII_TX_SEQ_COLLISION_SV
`define MII_TX_SEQ_COLLISION_SV

class mii_tx_seq_collision extends mii_tx_seq_base;
  `uvm_object_utils(mii_tx_seq_collision)
   `uvm_declare_p_sequencer(mii_tx_sequencer_base)

  mii_tx_seq_item_base req;

  function new(string name = "mii_tx_seq_collision");
    super.new(name);
  endfunction

  virtual task body();
  @(p_sequencer.vif.cb_mii_tx);
  
  wait (p_sequencer.vif.cb_mii_tx.MTxEN);
 

    req = mii_tx_seq_item_base::type_id::create("req");

    start_item(req);
    assert(req.randomize())
    else
      `uvm_fatal(get_name(), "Randomization failed")
    req.MColl = 1'b1;
	

    finish_item(req);
	
	
    // Wait until this transmission attempt finishes
    wait (!p_sequencer.vif.cb_mii_tx.MTxEN);
	

    `uvm_info(get_type_name(),
      "Asserting collision while MTxEN is high",
      UVM_MEDIUM)
	  
	

  endtask

endclass

`endif