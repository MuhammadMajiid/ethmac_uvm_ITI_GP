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

    //------------------------------------------------------------
    // apply_reset
    //------------------------------------------------------------
    // Drives the DUT hardware reset through the reset agent before any
    // MDIO/MIIM traffic starts. Every derived MDIO test must call this
    // as the first thing in its run_phase, right after raise_objection()
    // and before starting its virtual sequence.
    //
    // Without this, wb_rst_i sits at its uninitialized value for the
    // whole test and the DUT's wishbone slave logic never leaves reset --
    // this was the root cause of the 781 errors / 11-13% coverage runs.
    //------------------------------------------------------------
    task apply_reset();
        reset_seq m_reset_seq;
        m_reset_seq = reset_seq::type_id::create("m_reset_seq");
        m_reset_seq.m_regmodel = m_env.m_v_sqr.regmodel;
        m_reset_seq.start(m_env.m_v_sqr.m_reset_sqr);
    endtask

endclass
`endif
