
`ifndef ETH_TEST_SV
`define ETH_TEST_SV

class eth_test extends uvm_test;
  `uvm_component_utils(eth_test)

  eth_env    m_env;
  eth_config m_config;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    m_config = new("m_config");

    // Virtual interfaces are set into eth_config by tb_top before run_test()
    // Retrieve the top-level config that tb_top placed in the database
    if (!uvm_config_db #(eth_config)::get(this, "", "config", m_config))
      `uvm_info(get_type_name(),
        "eth_config not found in config_db at test level; using default", UVM_MEDIUM)

    // Propagate config to env
    uvm_config_db #(eth_config)::set(this, "m_env", "config", m_config);

    m_env = eth_env::type_id::create("m_env", this);
  endfunction

  function void start_of_simulation_phase(uvm_phase phase);
    // TODO: Apply factory overrides for specific test variants here
  endfunction

  task run_phase(uvm_phase phase);
    // Default test: env drives stimulus via virtual sequence (see eth_env::run_phase)
    // Extended tests can override this to launch directed sequences
  endtask

endclass

`endif // ETH_TEST_SV
