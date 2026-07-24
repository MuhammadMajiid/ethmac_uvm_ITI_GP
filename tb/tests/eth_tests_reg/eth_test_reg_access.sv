//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_test_reg_access.sv
// Author   : Nada
// Date     : 2026-06-24
//------------------------------------------------------------------------------
// Description: Register access test. Targets WISHBONE slave accesses to
//              the registers of the Ethernet MAC, exercising the RAL-only
//              sequences from Section 1.1 of the testplan.
///////////////////////////////////////////////////////////////////////////////
`ifndef ETH_TEST_REG_ACCESS_SV
`define ETH_TEST_REG_ACCESS_SV

class eth_test_reg_access extends eth_base_test;

  `uvm_component_utils(eth_test_reg_access)

  function new(string name="", uvm_component parent);
    super.new(name,parent);
  endfunction
  
  task run_phase(uvm_phase phase);

  eth_v_seq_reg vseq;
  super.run_phase(phase);
  phase.raise_objection(this);

  vseq = eth_v_seq_reg::type_id::create("vseq");
  vseq.start(m_env.m_v_sqr);

  phase.drop_objection(this);

endtask

 

endclass

`endif
