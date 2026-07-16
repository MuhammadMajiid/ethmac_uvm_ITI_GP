
`ifndef ETH_TEST_TX_DCRC_SV
`define ETH_TEST_TX_DCRC_SV


class eth_test_tx_dcrc extends eth_test_tx_base;
  `uvm_component_utils(eth_test_tx_dcrc)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    
    // Factory override
    factory.set_type_override_by_type(
      wb_m_seq_base::get_type(),
      wb_m_seq_wr_rd::get_type()
  );
      factory.set_type_override_by_type(
      wb_s_seq_base::get_type(),
      wb_s_seq_tx_dcrc::get_type()
  );
    super.build_phase(phase);

    // set wishnbone master & slave agents to active
    m_config.m_wb_m_config.is_active=UVM_ACTIVE;
    m_config.m_wb_s_config.is_active=UVM_ACTIVE;

    // set mii tx agent to passive
    m_config.m_mii_tx_config.is_active=UVM_PASSIVE;

  endfunction


endclass

`endif // ETH_TEST_TX_DCRC_SV
