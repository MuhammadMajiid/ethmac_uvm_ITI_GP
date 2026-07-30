//==============================================================================
// File       : eth_test_mdio_rw.sv
// Description: Standalone read/write smoke test for the MIIM interface.
//
// FIX: this called a class named `eth_v_seq_mdio_rw`, which does not exist
// anywhere in the repository. The virtual sequence that actually covers
// write + read, with and without preamble (TC2/TC3/TC5/TC6), is
// `v_seq_tc_miim_rw_preamble` in eth_v_seq_mdio_lib.sv -- retargeted onto
// that instead of inventing a second, redundant sequence. This test class
// is otherwise a near-duplicate of `eth_test_miim_rw_preamble` in
// eth_test_mdio_lib.sv; consider deleting one of the two once you confirm
// you don't need both entry points.
//==============================================================================
`ifndef ETH_TEST_MDIO_RW_SV
`define ETH_TEST_MDIO_RW_SV

class eth_test_mdio_rw extends eth_test_mdio_base;
    `uvm_component_utils(eth_test_mdio_rw)

    function new(string name = "eth_test_mdio_rw", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        v_seq_tc_miim_rw_preamble v_seq;
        phase.raise_objection(this);

        v_seq = v_seq_tc_miim_rw_preamble::type_id::create("v_seq");
        v_seq.start(m_env.m_v_sqr);

        #1000ns;
        phase.drop_objection(this);
    endtask
endclass
`endif // ETH_TEST_MDIO_RW_SV
