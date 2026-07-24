//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_v_seq_reg.sv
// Author   : Nada
// Date     : 2026-07-17
//------------------------------------------------------------------------------
// Description:
// Virtual sequence for register-access verification.
// Applies a hardware reset, then starts the Wishbone master reactive sequence
// and the Wishbone slave register-access sequence. Used by register access
// tests to verify Ethernet MAC register functionality through the RAL model.
//==============================================================================

`ifndef ETH_V_SEQ_REG_SV
`define ETH_V_SEQ_REG_SV

class eth_v_seq_reg extends eth_v_seq_base;

  `uvm_object_utils(eth_v_seq_reg)

  reset_seq               rst_seq;
  eth_max_value_seq       max_seq;
  eth_rw_pattern_seq      pattern_seq;
  uvm_reg_hw_reset_seq    hw_reset_seq;
  //uvm_reg_bit_bash_seq    bit_bash_seq;
  //eth_tx_bd_num_bit_bash_seq tx_bd_seq;

  function new(string name="eth_v_seq_reg");
    super.new(name);
  endfunction

  virtual task body();

    super.body();

    `uvm_info(get_type_name(),
              "Starting Register Access Virtual Sequence",
              UVM_LOW)

    //-----------------------------------
    // Reset DUT
    //-----------------------------------
    rst_seq = reset_seq::type_id::create("rst_seq");
    rst_seq.m_regmodel = p_sequencer.regmodel;
    rst_seq.start(m_reset_sqr);

    //-----------------------------------
    // Verify reset values
    //-----------------------------------
    hw_reset_seq = uvm_reg_hw_reset_seq::type_id::create("hw_reset_seq");
    hw_reset_seq.model = p_sequencer.regmodel;
    hw_reset_seq.start(null);

    //-----------------------------------
    // Max-value test
    //-----------------------------------
    max_seq = eth_max_value_seq::type_id::create("max_seq");
    max_seq.rgm = p_sequencer.regmodel;
    max_seq.start(null);

    //-----------------------------------
    // Reset again
    //-----------------------------------
    rst_seq = reset_seq::type_id::create("rst_seq_after_max");
    rst_seq.m_regmodel = p_sequencer.regmodel;
    rst_seq.start(m_reset_sqr);

    //-----------------------------------
    // Verify reset values again
    //-----------------------------------
    hw_reset_seq = uvm_reg_hw_reset_seq::type_id::create("hw_reset_seq2");
    hw_reset_seq.model = p_sequencer.regmodel;
    hw_reset_seq.start(null);

    //-----------------------------------
    // Alternating-pattern test
    //-----------------------------------
    pattern_seq = eth_rw_pattern_seq::type_id::create("pattern_seq");
    pattern_seq.model = p_sequencer.regmodel;
    pattern_seq.start(null);

   /*//----------------------------
    // Walk-1 / Walk-0 test
    //----------------------------

   // Disable bit bash for TX_BD_NUM
    uvm_resource_db#(bit)::set(
    {"REG::", p_sequencer.regmodel.TX_BD_NUM.get_full_name()},
    "NO_REG_BIT_BASH_TEST",
    1,
    this
     );

    bit_bash_seq = uvm_reg_bit_bash_seq::type_id::create("bit_bash_seq");
    bit_bash_seq.model = p_sequencer.regmodel;
    bit_bash_seq.start(null);



    tx_bd_seq = eth_tx_bd_num_bit_bash_seq::type_id::create("tx_bd_seq");

    tx_bd_seq.model = p_sequencer.regmodel;

    tx_bd_seq.start(null);*/

    `uvm_info(get_type_name(),
              "Register Access Virtual Sequence Completed",
              UVM_LOW)

  endtask

endclass

`endif