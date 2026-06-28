//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_s_driver_base.sv
// Author   : Nada
// Date     : 2026-06-24
//------------------------------------------------------------------------------
// Description: Register access test. Targets WISHBONE slave accesses to
//              the registers of the Ethernet MAC, exercising the RAL-only
//              sequences from Section 1 of the testplan.
///////////////////////////////////////////////////////////////////////////////
`ifndef ETH_TEST_REG_ACCESS_SV
`define ETH_TEST_REG_ACCESS_SV

class eth_test_reg_access extends eth_base_test;

  `uvm_component_utils(eth_test_reg_access)

  function new(string name="", uvm_component parent);
    super.new(name,parent);
  endfunction

  task run_phase(uvm_phase phase);

    uvm_reg_hw_reset_seq hw_reset_seq;
    uvm_reg_bit_bash_seq bit_bash_seq;

    phase.raise_objection(this);

    //----------------------------
    // Verify hardware reset values
    //----------------------------
    hw_reset_seq = uvm_reg_hw_reset_seq::type_id::create("hw_reset_seq");
    hw_reset_seq.model = m_env.regmodel;
    hw_reset_seq.start(null);


    //----------------------------
    // Walk-1 / Walk-0 test
    //----------------------------
    bit_bash_seq = uvm_reg_bit_bash_seq::type_id::create("bit_bash_seq");
    bit_bash_seq.model = m_env.regmodel;
    bit_bash_seq.start(null);

    phase.drop_objection(this);

  endtask

endclass

`endif
