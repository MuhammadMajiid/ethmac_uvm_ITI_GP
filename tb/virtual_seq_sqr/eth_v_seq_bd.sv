//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_v_seq_bd.sv
// Author   : Nada
// Date     : 2026-07-17
//------------------------------------------------------------------------------
// Description:
// Virtual sequence for buffer descriptor (BD) memory verification.
// Applies a hardware reset, then starts the Wishbone master reactive sequence
// and the Wishbone slave BD access sequence. Used to execute Buffer Descriptor
// memory tests through the RAL memory model.
//==============================================================================
`ifndef ETH_V_SEQ_BD_SV
`define ETH_V_SEQ_BD_SV

class eth_v_seq_bd extends eth_v_seq_base;

  `uvm_object_utils(eth_v_seq_bd)

  reset_seq     rst_seq;
  eth_bd_wr_seq bd_wr_seq;

  // Optional
  //eth_bd_mem_walk_seq walk_seq;
  //eth_bd_mem_alternating_seq alt_seq;

  function new(string name="eth_v_seq_bd");
    super.new(name);
  endfunction

  virtual task body();

    super.body();

    `uvm_info(get_type_name(),
              "Starting Buffer Descriptor Virtual Sequence",
              UVM_LOW)

    //-----------------------------------
    // Reset DUT
    //-----------------------------------
    rst_seq = reset_seq::type_id::create("rst_seq");
    rst_seq.start(m_reset_sqr);

    //-----------------------------------
    // Buffer Descriptor Test
    //-----------------------------------
    bd_wr_seq = eth_bd_wr_seq::type_id::create("bd_wr_seq");
    bd_wr_seq.model = p_sequencer.regmodel;
    bd_wr_seq.start(null);

    // Optional tests
    /*
    walk_seq = eth_bd_mem_walk_seq::type_id::create("walk_seq");
    walk_seq.regmodel = p_sequencer.regmodel;
    walk_seq.start(m_wb_s_sqr);

    alt_seq = eth_bd_mem_alternating_seq::type_id::create("alt_seq");
    alt_seq.regmodel = p_sequencer.regmodel;
    alt_seq.start(null);
    */

    `uvm_info(get_type_name(),
              "Buffer Descriptor Virtual Sequence Completed",
              UVM_LOW)

  endtask

endclass

`endif