`ifndef ETH_TEST_MDIO_RW_SV
`define ETH_TEST_MDIO_RW_SV

class eth_test_mdio_rw extends eth_test_mdio_base;
    `uvm_component_utils(eth_test_mdio_rw)

    function new(string name = "eth_test_mdio_rw", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        eth_v_seq_mdio_rw v_seq;
        phase.raise_objection(this);

        v_seq = eth_v_seq_mdio_rw::type_id::create("v_seq");
        // Start the virtual sequence on the virtual sequencer
        v_seq.start(m_env.m_v_sqr);

        #1000ns;
        phase.drop_objection(this);
    endtask
endclass
`endif
