class eth_base_test extends uvm_test;
  `uvm_component_utils(eth_base_test)

  eth_env_tx          m_env;
  eth_env_config_obj  m_config;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    m_config = eth_env_config_obj::type_id::create("m_eth_env_config_obj");

    // Wishbone master interface
    if (!uvm_config_db#(virtual wb_m_if)::get(
            this, "", "wb_m_vif", m_config.m_wb_m_config.vif))
      `uvm_fatal(get_type_name(),"wb_m_vif not found")

    // Wishbone slave interface
    if (!uvm_config_db#(virtual wb_s_if)::get(
            this, "", "wb_s_vif", m_config.m_wb_s_config.vif))
      `uvm_fatal(get_type_name(),"wb_s_vif not found")

    // MII TX interface
    if (!uvm_config_db#(virtual mii_tx_if)::get(
            this, "", "mii_tx_vif", m_config.m_mii_tx_config.vif))
      `uvm_fatal(get_type_name(),"mii_tx_vif not found")

    // Reset interface
    if (!uvm_config_db#(virtual reset_if)::get(
            this, "", "reset_if", m_config.m_rst_config.vif))
      `uvm_fatal(get_type_name(),"reset_if not found")

    // Pass configuration to environment
    uvm_config_db#(eth_env_config_obj)::set(
        this,
        "m_env",
        "config",
        m_config);

    // Create environment
    m_env = eth_env_tx::type_id::create("m_env", this);

  endfunction

 

endclass