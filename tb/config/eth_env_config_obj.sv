`ifndef ETH_ENV_CONFIG_SV
`define ETH_ENV_CONFIG_SV
class eth_env_config_obj extends uvm_object;
  `uvm_object_utils(eth_env_config_obj)
  //uvm_active_passive_enum wb_s_is_active = UVM_ACTIVE;
  // uvm_active_passive_enum wb_m_is_active = UVM_ACTIVE;
  //uvm_active_passive_enum mii_is_active  = UVM_ACTIVE;

  // RAL 
  eth_reg_block m_regmodel; 

  // Per-agent configs, each carrying its own vif 
  wb_s_config_obj     m_wb_s_config;
  wb_m_config_obj     m_wb_m_config;
  mii_tx_config_obj   m_mii_tx_config;
  mii_rx_config_obj   m_mii_rx_config;

  // config of tx scoreboard
  eth_tx_scoreboard_config_obj m_tx_sb_config;
  
  function new(string name = "env_config");
    super.new(name);
    // Build config objs
    m_wb_s_config   = wb_s_config_obj::type_id::create("m_wb_s_config");
    m_wb_m_config   = wb_m_config_obj::type_id::create("m_wb_m_config");
    m_mii_tx_config = mii_tx_config_obj::type_id::create("m_mii_tx_config");
    m_mii_rx_config = mii_rx_config_obj::type_id::create("m_mii_rx_config");
    m_tx_sb_config  = eth_tx_scoreboard_config_obj::type_id::create("m_tx_sb_config");
  endfunction

endclass
`endif // ETH_ENV_CONFIG_SV
