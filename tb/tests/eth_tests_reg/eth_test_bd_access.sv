//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_test_bd_access.sv
// Author   : Nada
// Date     : 2026-07-15
//------------------------------------------------------------------------------
// Description: buffer descriptor access test. Targets WISHBONE slave accesses to
//              the buffer descriptor of the Ethernet MAC, exercising the RAL-only
//              sequences from Section 1.2 of the testplan.
///////////////////////////////////////////////////////////////////////////////

class eth_test_bd_access extends eth_base_test;

  `uvm_component_utils(eth_test_bd_access)

  function new(string name = "eth_test_bd_access", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  task run_phase(uvm_phase phase);

  eth_v_seq_bd vseq;

  phase.raise_objection(this);

  vseq = eth_v_seq_bd::type_id::create("vseq");
  vseq.start(m_env.m_v_sqr);

  phase.drop_objection(this);

endtask

 

endclass