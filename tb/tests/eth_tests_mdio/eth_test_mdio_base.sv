`ifndef ETH_TEST_MDIO_BASE_SV
`define ETH_TEST_MDIO_BASE_SV

class eth_test_mdio_base extends uvm_test;
    `uvm_component_utils(eth_test_mdio_base)

    eth_env_mdio             m_env;
    eth_env_config_obj       m_config;

    function new(string name = "eth_test_mdio_base", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // eth_env_config_obj's constructor builds all per-agent config
        // objects, including m_mdio_config -- eth_env_base::build_phase
        // (and eth_env_mdio::build_phase on top of it) is what actually
        // reads this back out of config_db under key "config" and
        // distributes m_mdio_config down to the MDIO agent/scoreboard.
        m_config = eth_env_config_obj::type_id::create("m_config");
        uvm_config_db#(eth_env_config_obj)::set(this, "*", "config", m_config);

        m_env = eth_env_mdio::type_id::create("m_env", this);
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        uvm_top.print_topology();
    endfunction

endclass
`endif
