
`ifndef ETH_TEST_SV
`define ETH_TEST_SV


class eth_test_tx_base extends uvm_test;
  `uvm_component_utils(eth_test_tx_base)

  eth_env_tx                 m_env;
  eth_env_config_obj         m_config;       
  
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    m_eth_env_config_obj = eth_env_config_obj::type_id::create("m_eth_env_config_obj");

    // Retrieve wishbone master interface
    if (!uvm_config_db #(virtual wb_m_if)::get(this, "", "wb_m_vif", m_config.m_wb_m_config.vif))
      `uvm_fatal(get_type_name(), "wb_m_vif is not found in config_db")

    // Retrieve wishbone slave interface
    if (!uvm_config_db #(virtual wb_s_interface)::get(this, "", "wb_s_vif", m_config.m_wb_s_config.vif))
      `uvm_fatal(get_type_name(), "wb_s_vif is not found in config_db")

    // Retrieve mii tx interface
    if (!uvm_config_db #(virtual mii_tx_interface)::get(this, "", "mii_tx_interface", m_config.m_mii_tx_config.vif))
      `uvm_fatal(get_type_name(), "mii_tx_interface is not found in config_db")


    // Propagate Environmrnt configuration object to env and it's subcomponents
    uvm_config_db #(eth_env_config_obj)::set(this, "m_env", "config", m_config);

    // Build environment
    m_env = eth_env::type_id::create("m_env", this);

    // set agent to active
    //m_wb_m_config_obj.is_active=UVM_ACTIVE;
endfunction

  function void start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    `uvm_info(get_type_name(),"start of sim phase", UVM_LOW)
    this.print();
    factory.print();
  endfunction

endclass

`endif // ETH_TEST_SV

