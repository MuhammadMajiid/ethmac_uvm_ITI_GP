
`ifndef ETH_TEST_TX_BASE_SV
`define ETH_TEST_TX_BASE_SV


class eth_test_tx_base extends uvm_test;
  `uvm_component_utils(eth_test_tx_base)

  eth_env_tx                 m_env;
  eth_env_config_obj         m_config;       
  // declare virtual sequence
  eth_v_seq_tx  m_v_seq_tx;

  // declare end sequences event
  event         m_ev_end_seqs;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
           `uvm_info(get_type_name(),"start of build_phase", UVM_LOW)
    super.build_phase(phase);

    m_config = eth_env_config_obj::type_id::create("m_eth_env_config_obj");

    // Retrieve wishbone master interface
    if (!uvm_config_db #(virtual wb_m_if)::get(this, "", "wb_m_vif", m_config.m_wb_m_config.vif))
      `uvm_fatal(get_type_name(), "wb_m_vif is not found in config_db")

    // Retrieve wishbone slave interface
    if (!uvm_config_db #(virtual wb_s_if)::get(this, "", "wb_s_vif", m_config.m_wb_s_config.vif))
      `uvm_fatal(get_type_name(), "wb_s_vif is not found in config_db")

    // Retrieve mii tx interface
    if (!uvm_config_db #(virtual mii_tx_if)::get(this, "", "mii_tx_vif", m_config.m_mii_tx_config.vif))
      `uvm_fatal(get_type_name(), "mii_tx_interface is not found in config_db")
	  
	  
	 // Retrieve mii tx interface
    if (!uvm_config_db #(virtual reset_if)::get(this, "", "reset_if", m_config.m_rst_config.vif))
      `uvm_fatal(get_type_name(), "reset_interface is not found in config_db")


    // Propagate Environmrnt configuration object to env and it's subcomponents
    uvm_config_db #(eth_env_config_obj)::set(this, "m_env", "config", m_config);

    // Build environment
    m_env = eth_env_tx::type_id::create("m_env", this);
    
    // Assign end sequence event to event in config object
    m_config.m_tx_sb_config.m_ev_end_seqs=m_ev_end_seqs;
endfunction

  function void start_of_simulation_phase(uvm_phase phase);
    longint seed;
    int fd;
    super.start_of_simulation_phase(phase);
    seed = $get_initial_random_seed();

    fd = $fopen("repo/results/tx/seeds.txt", "a");
    $fdisplay(fd, "Test = %s Seed = %0d", get_type_name(), seed);
    $fclose(fd);
    `uvm_info(get_type_name(),"start of sim phase", UVM_LOW)
    this.print();
    factory.print();
  endfunction

  task run_phase(uvm_phase phase);
      super.run_phase(phase);

      m_env.m_cov_tx.m_reserved_bit_cov.stop();
      m_env.m_cov_tx.m_rw_bit_cov.stop();
      
      // create virtual sequence
      m_v_seq_tx = eth_v_seq_tx::type_id::create("m_v_seq_tx");

      // assign regmodel in wishbone slave sequence to the one in config object
      m_v_seq_tx.m_wb_s_seq_base.regmodel=m_config.m_regmodel;

      // assign regmodel in wishbone slave sequence to the one in config object
      m_v_seq_tx.m_wb_s_seq_base.m_ev_end_pkt=m_config.m_tx_sb_config.m_ev_end_pkt;
      
      phase.raise_objection(this);
      // Start virtual sequence;      
      m_v_seq_tx.start(m_env.m_v_sqr);
      //trigger end seqs event
      -> m_ev_end_seqs;
      phase.drop_objection(this);
  endtask

endclass

`endif // ETH_TEST_TX_BASE_SV

