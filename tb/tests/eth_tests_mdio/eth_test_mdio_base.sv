`ifndef ETH_TEST_MDIO_BASE_SV
`define ETH_TEST_MDIO_BASE_SV

class eth_test_mdio_base extends uvm_test;
    `uvm_component_utils(eth_test_mdio_base)

    eth_env                 m_env;
    eth_mdio_config_obj     m_mdio_cfg;

    function new(string name = "eth_test_mdio_base", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        m_env = eth_env::type_id::create("m_env", this);
        m_mdio_cfg = eth_mdio_config_obj::type_id::create("m_mdio_cfg");

        // Push config to db for lower components
        uvm_config_db#(eth_mdio_config_obj)::set(this, "*", "mdio_config", m_mdio_cfg);
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        uvm_top.print_topology();
    endfunction

endclass
`endif
