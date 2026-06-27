`ifndef ETH_ENV_CONFIG_SV
`define ETH_ENV_CONFIG_SV
class eth_env_config_obj extends uvm_object;

  uvm_active_passive_enum wb_s_is_active = UVM_ACTIVE;
 // uvm_active_passive_enum wb_m_is_active = UVM_ACTIVE;
  //uvm_active_passive_enum mii_is_active  = UVM_ACTIVE;

  // Per-agent configs, each carrying its own vif 
  wb_s_config_obj  m_wb_s_config;
  //wb_m_config  m_wb_m_config;
  //mii_config   m_mii_config;

  function new(string name = "");
    super.new(name);
  endfunction

endclass
`endif // ETH_ENV_CONFIG_SV
