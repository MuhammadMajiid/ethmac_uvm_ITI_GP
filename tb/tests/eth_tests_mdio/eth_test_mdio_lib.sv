//==============================================================================
// File       : eth_test_mdio_lib.sv
// Description: UVM tests translated from tp_miim_tx.xlsx (Section 1: MIIM)
//==============================================================================
`ifndef ETH_TEST_MDIO_LIB_SV
`define ETH_TEST_MDIO_LIB_SV

// Test 1: Clock Divider
class eth_test_miim_clkdiv extends eth_test_mdio_base;
    `uvm_component_utils(eth_test_miim_clkdiv)
    function new(string name = "eth_test_miim_clkdiv", uvm_component parent = null); super.new(name, parent); endfunction

    task run_phase(uvm_phase phase);
        v_seq_tc_miim_clkdiv v_seq = v_seq_tc_miim_clkdiv::type_id::create("v_seq");
        phase.raise_objection(this);
        v_seq.start(m_env.m_v_sqr);
        #100ns;
        phase.drop_objection(this);
    endtask
endclass

// Test 2: Preamble toggling (Write/Read)
class eth_test_miim_rw_preamble extends eth_test_mdio_base;
    `uvm_component_utils(eth_test_miim_rw_preamble)
    function new(string name = "eth_test_miim_rw_preamble", uvm_component parent = null); super.new(name, parent); endfunction

    task run_phase(uvm_phase phase);
        v_seq_tc_miim_rw_preamble v_seq = v_seq_tc_miim_rw_preamble::type_id::create("v_seq");
        phase.raise_objection(this);
        v_seq.start(m_env.m_v_sqr);
        #1000ns;
        phase.drop_objection(this);
    endtask
endclass

// Test 3: PHY Reset Command
class eth_test_miim_rst_phy extends eth_test_mdio_base;
    `uvm_component_utils(eth_test_miim_rst_phy)
    function new(string name = "eth_test_miim_rst_phy", uvm_component parent = null); super.new(name, parent); endfunction

    task run_phase(uvm_phase phase);
        v_seq_tc_miim_rst_phy v_seq = v_seq_tc_miim_rst_phy::type_id::create("v_seq");
        phase.raise_objection(this);
        v_seq.start(m_env.m_v_sqr);
        #500ns;
        phase.drop_objection(this);
    endtask
endclass

// Test 4: Scan Mode and Linkfail Tracking
class eth_test_miim_scan extends eth_test_mdio_base;
    `uvm_component_utils(eth_test_miim_scan)
    function new(string name = "eth_test_miim_scan", uvm_component parent = null); super.new(name, parent); endfunction

    task run_phase(uvm_phase phase);
        v_seq_tc_miim_scan v_seq = v_seq_tc_miim_scan::type_id::create("v_seq");
        phase.raise_objection(this);
        v_seq.start(m_env.m_v_sqr);
        #2000ns; // Extended delay for scanning cycles
        phase.drop_objection(this);
    endtask
endclass

// Test 5: Walking 1s (Address and Data buses)
class eth_test_miim_walking extends eth_test_mdio_base;
    `uvm_component_utils(eth_test_miim_walking)
    function new(string name = "eth_test_miim_walking", uvm_component parent = null); super.new(name, parent); endfunction

    task run_phase(uvm_phase phase);
        v_seq_tc_miim_walking v_seq = v_seq_tc_miim_walking::type_id::create("v_seq");
        phase.raise_objection(this);
        v_seq.start(m_env.m_v_sqr);
        #1500ns;
        phase.drop_objection(this);
    endtask
endclass

`endif
