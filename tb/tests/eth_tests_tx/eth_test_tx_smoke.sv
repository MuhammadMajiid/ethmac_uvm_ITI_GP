
`ifndef ETH_TEST_TX_SMOKE_SV
`define ETH_TEST_TX_SMOKE_SV


class eth_test_tx_smoke extends eth_test_tx_base;
  `uvm_component_utils(eth_test_tx_smoke)

  // declare virtual sequence
  eth_v_seq_tx  m_v_seq_tx;

  // declare end sequences event
  event         m_ev_end_seqs;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // set wishnbone master & slave agents to active
    m_config.m_wb_m_config.is_active=UVM_ACTIVE;
    m_config.m_wb_s_config.is_active=UVM_ACTIVE;

    // set mii tx agent to passive
    m_config.m_mii_tx_config.is_active=UVM_PASSIVE;

    // Assign end sequence event to event in config object
    m_config.m_tx_sb_config.m_ev_end_seqs=m_ev_end_seqs;

  endfunction


  task run_phase(uvm_phase phase);
 
      super.run_phase(phase);

      // create virtual sequence
      m_v_seq_tx = eth_v_seq_tx::type_id::create("m_v_seq_tx");

      // assign regmodel in wishbone slave sequence to the one in config object
      m_v_seq_tx.m_wb_s_control_frame_tx_seq.regmodel=m_config.m_regmodel;

      phase.raise_objection(this);
      // Start virtual sequence;      
      m_v_seq_tx.start(m_env.m_v_sqr);
      //trigger end seqs event
      -> m_ev_end_seqs;
      phase.drop_objection(this);
  endtask

endclass

`endif // ETH_TEST_TX_SMOKE_SV
