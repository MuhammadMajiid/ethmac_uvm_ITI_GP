//==============================================================================
// File       : eth_test_mdio_lib.sv
// Description: UVM tests translated from tp_miim_tx.xlsx (Section 1: MIIM)
//==============================================================================
`ifndef ETH_TEST_MDIO_LIB_SV
`define ETH_TEST_MDIO_LIB_SV

// Test 1: Clock Divider
class eth_test_miim_clkdiv extends eth_test_mdio_base;
    `uvm_component_utils(eth_test_miim_clkdiv)

    function new(string name = "eth_test_miim_clkdiv", uvm_component parent = null);
     super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        v_seq_tc_miim_clkdiv v_seq;
        v_seq = v_seq_tc_miim_clkdiv::type_id::create("v_seq");
        phase.raise_objection(this);
        apply_reset();
        v_seq.start(m_env.m_v_sqr);
        #100ns;
        phase.drop_objection(this);
    endtask
endclass

// Test 2: Preamble toggling (Write/Read)
class eth_test_miim_rw_preamble extends eth_test_mdio_base;
    `uvm_component_utils(eth_test_miim_rw_preamble)

    function new(string name = "eth_test_miim_rw_preamble", uvm_component parent = null);
     super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        v_seq_tc_miim_rw_preamble v_seq;
        v_seq = v_seq_tc_miim_rw_preamble::type_id::create("v_seq");
        phase.raise_objection(this);
        apply_reset();
        v_seq.start(m_env.m_v_sqr);
        #1000ns;
        phase.drop_objection(this);
    endtask
endclass

// Test 3: PHY Reset Command
class eth_test_miim_rst_phy extends eth_test_mdio_base;
    `uvm_component_utils(eth_test_miim_rst_phy)
    function new(string name = "eth_test_miim_rst_phy", uvm_component parent = null);
     super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        v_seq_tc_miim_rst_phy v_seq;
        v_seq = v_seq_tc_miim_rst_phy::type_id::create("v_seq");
        phase.raise_objection(this);
        apply_reset();
        v_seq.start(m_env.m_v_sqr);
        #500ns;
        apply_reset();
        phase.drop_objection(this);
    endtask
endclass

// Test 4: Scan Mode and Linkfail Tracking
class eth_test_miim_scan extends eth_test_mdio_base;
    `uvm_component_utils(eth_test_miim_scan)
    function new(string name = "eth_test_miim_scan", uvm_component parent = null);
     super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        v_seq_tc_miim_scan v_seq;
        v_seq = v_seq_tc_miim_scan::type_id::create("v_seq");
        phase.raise_objection(this);
        apply_reset();
        v_seq.start(m_env.m_v_sqr);
        #2000ns; // Extended delay for scanning cycles
        phase.drop_objection(this);
    endtask
endclass

// Test 5: Dedicated MDIO coverage-cross stimulus
class eth_test_miim_cov_cross extends eth_test_mdio_base;
    `uvm_component_utils(eth_test_miim_cov_cross)

    function new(string name = "eth_test_miim_cov_cross", uvm_component parent = null);
     super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        v_seq_tc_miim_cov_cross v_seq;
        v_seq = v_seq_tc_miim_cov_cross::type_id::create("v_seq");
        phase.raise_objection(this);
        apply_reset();
        v_seq.start(m_env.m_v_sqr);
        #10000ns;
        phase.drop_objection(this);
    endtask
endclass

// Test 6: Walking 1s (Address and Data buses)
class eth_test_miim_walking extends eth_test_mdio_base;
    `uvm_component_utils(eth_test_miim_walking)
    function new(string name = "eth_test_miim_walking", uvm_component parent = null);
     super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        v_seq_tc_miim_walking v_seq;
        v_seq = v_seq_tc_miim_walking::type_id::create("v_seq");
        phase.raise_objection(this);
        apply_reset();
        v_seq.start(m_env.m_v_sqr);
        #1500ns;
        phase.drop_objection(this);
    endtask
endclass

// Test 6: Write to read-only PHY registers (TC9)
class eth_test_miim_write_readonly_regs extends eth_test_mdio_base;
    `uvm_component_utils(eth_test_miim_write_readonly_regs)
    function new(string name = "eth_test_miim_write_readonly_regs", uvm_component parent = null);
     super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        v_seq_tc_miim_write_readonly_regs v_seq;
        v_seq = v_seq_tc_miim_write_readonly_regs::type_id::create("v_seq");
        phase.raise_objection(this);
        apply_reset();
        v_seq.start(m_env.m_v_sqr);
        #1000ns;
        phase.drop_objection(this);
    endtask
endclass

// Test 7: WRITE/READ/SCAN command priority resolution (TC10)
class eth_test_miim_priority extends eth_test_mdio_base;
    `uvm_component_utils(eth_test_miim_priority)
    function new(string name = "eth_test_miim_priority", uvm_component parent = null);
     super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        v_seq_tc_miim_priority v_seq;
        v_seq = v_seq_tc_miim_priority::type_id::create("v_seq");
        phase.raise_objection(this);
        apply_reset();
        v_seq.start(m_env.m_v_sqr);
        #1500ns;
        phase.drop_objection(this);
    endtask
endclass

// Test 8: Access to a non-responding / reserved PHY address (TC11)
class eth_test_miim_wrong_phy_addr extends eth_test_mdio_base;
    `uvm_component_utils(eth_test_miim_wrong_phy_addr)
    function new(string name = "eth_test_miim_wrong_phy_addr", uvm_component parent = null);
     super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        v_seq_tc_miim_wrong_phy_addr v_seq;
        v_seq = v_seq_tc_miim_wrong_phy_addr::type_id::create("v_seq");
        phase.raise_objection(this);
        apply_reset();
        v_seq.start(m_env.m_v_sqr);
        #500ns;
        phase.drop_objection(this);
    endtask
endclass

// Test 9: Sliding stop of an in-progress scan (TC12)
class eth_test_miim_scan_intr extends eth_test_mdio_base;
    `uvm_component_utils(eth_test_miim_scan_intr)
    function new(string name = "eth_test_miim_scan_intr", uvm_component parent = null);
     super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        v_seq_tc_miim_scan_intr v_seq;
        v_seq = v_seq_tc_miim_scan_intr::type_id::create("v_seq");
        phase.raise_objection(this);
        apply_reset();
        v_seq.start(m_env.m_v_sqr);
        #500ns;
        phase.drop_objection(this);
    endtask
endclass

class eth_test_miim_reg_bits extends eth_test_mdio_base;
    `uvm_component_utils(eth_test_miim_reg_bits)
    function new(string name = "eth_test_miim_reg_bits", uvm_component parent = null);
    super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        v_seq_tc_miim_reg_bits v_seq;
        v_seq = v_seq_tc_miim_reg_bits::type_id::create("v_seq");
        phase.raise_objection(this);
        apply_reset();
        v_seq.start(m_env.m_v_sqr);
        #500ns;
        phase.drop_objection(this);
    endtask
endclass

// Test 12: Scan interruption timing sweep (isolates the BUSY-lockup window)
class eth_test_miim_scan_intr_sweep extends eth_test_mdio_base;
    `uvm_component_utils(eth_test_miim_scan_intr_sweep)
    function new(string name = "eth_test_miim_scan_intr_sweep", uvm_component parent = null);
     super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        v_seq_tc_miim_scan_intr_sweep v_seq;
        v_seq = v_seq_tc_miim_scan_intr_sweep::type_id::create("v_seq");
        phase.raise_objection(this);
        apply_reset();
        v_seq.start(m_env.m_v_sqr);
        #500ns;
        phase.drop_objection(this);
    endtask
endclass

// Test 13: Back-to-back ops with zero idle gap
class eth_test_miim_back_to_back extends eth_test_mdio_base;
    `uvm_component_utils(eth_test_miim_back_to_back)
    function new(string name = "eth_test_miim_back_to_back", uvm_component parent = null);
     super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        v_seq_tc_miim_back_to_back v_seq;
        v_seq = v_seq_tc_miim_back_to_back::type_id::create("v_seq");
        phase.raise_objection(this);
        apply_reset();
        v_seq.start(m_env.m_v_sqr);
        #500ns;
        phase.drop_objection(this);
    endtask
endclass

// Test 14: Wider PHY address decode sweep
class eth_test_miim_phy_addr_sweep extends eth_test_mdio_base;
    `uvm_component_utils(eth_test_miim_phy_addr_sweep)
    function new(string name = "eth_test_miim_phy_addr_sweep", uvm_component parent = null);
     super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        v_seq_tc_miim_phy_addr_sweep v_seq;
        v_seq = v_seq_tc_miim_phy_addr_sweep::type_id::create("v_seq");
        phase.raise_objection(this);
        apply_reset();
        v_seq.start(m_env.m_v_sqr);
        #500ns;
        phase.drop_objection(this);
    endtask
endclass

// Test 15: Reset while a transaction is in flight
class eth_test_miim_reset_in_flight extends eth_test_mdio_base;
    `uvm_component_utils(eth_test_miim_reset_in_flight)
    function new(string name = "eth_test_miim_reset_in_flight", uvm_component parent = null);
     super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        v_seq_tc_miim_reset_in_flight v_seq;
        v_seq = v_seq_tc_miim_reset_in_flight::type_id::create("v_seq");
        phase.raise_objection(this);
        apply_reset();
        v_seq.start(m_env.m_v_sqr);
        #500ns;
        phase.drop_objection(this);
    endtask
endclass

// Test 16: Live register overwrite attempt while BUSY=1
class eth_test_miim_overwrite_while_busy extends eth_test_mdio_base;
    `uvm_component_utils(eth_test_miim_overwrite_while_busy)
    function new(string name = "eth_test_miim_overwrite_while_busy", uvm_component parent = null);
     super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        v_seq_tc_miim_overwrite_while_busy v_seq;
        v_seq = v_seq_tc_miim_overwrite_while_busy::type_id::create("v_seq");
        phase.raise_objection(this);
        apply_reset();
        v_seq.start(m_env.m_v_sqr);
        #500ns;
        phase.drop_objection(this);
    endtask
endclass

// Test 17: CLKDIV boundary values with a real transaction
class eth_test_miim_clkdiv_extremes extends eth_test_mdio_base;
    `uvm_component_utils(eth_test_miim_clkdiv_extremes)
    function new(string name = "eth_test_miim_clkdiv_extremes", uvm_component parent = null);
     super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        v_seq_tc_miim_clkdiv_extremes v_seq;
        v_seq = v_seq_tc_miim_clkdiv_extremes::type_id::create("v_seq");
        phase.raise_objection(this);
        apply_reset();
        v_seq.start(m_env.m_v_sqr);
        #500ns;
        phase.drop_objection(this);
    endtask
endclass

// Test 18: LinkFail toggle coverage closure (RSTAT-only, avoids scan lockup)
class eth_test_miim_linkfail_toggle extends eth_test_mdio_base;
    `uvm_component_utils(eth_test_miim_linkfail_toggle)
    function new(string name = "eth_test_miim_linkfail_toggle", uvm_component parent = null);
     super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        v_seq_tc_miim_linkfail_toggle v_seq;
        v_seq = v_seq_tc_miim_linkfail_toggle::type_id::create("v_seq");
        phase.raise_objection(this);
        apply_reset();
        v_seq.start(m_env.m_v_sqr);
        #500ns;
        phase.drop_objection(this);
    endtask
endclass

// Test 19: Continuous uninterrupted scan (closes restart-adjacency bins)
class eth_test_miim_scan_continuous extends eth_test_mdio_base;
    `uvm_component_utils(eth_test_miim_scan_continuous)
    function new(string name = "eth_test_miim_scan_continuous", uvm_component parent = null);
     super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        v_seq_tc_miim_scan_continuous v_seq;
        v_seq = v_seq_tc_miim_scan_continuous::type_id::create("v_seq");
        phase.raise_objection(this);
        apply_reset();
        v_seq.start(m_env.m_v_sqr);
        #500ns;
        phase.drop_objection(this);
    endtask
endclass

// Test 20: Clear command bit while an op is in flight
class eth_test_miim_clear_cmd_while_busy extends eth_test_mdio_base;
    `uvm_component_utils(eth_test_miim_clear_cmd_while_busy)
    function new(string name = "eth_test_miim_clear_cmd_while_busy", uvm_component parent = null);
     super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        v_seq_tc_miim_clear_cmd_while_busy v_seq;
        v_seq = v_seq_tc_miim_clear_cmd_while_busy::type_id::create("v_seq");
        phase.raise_objection(this);
        apply_reset();
        v_seq.start(m_env.m_v_sqr);
        #500ns;
        phase.drop_objection(this);
    endtask
endclass

// Test 21: Precisely-timed BitCounter abort sweep
class eth_test_miim_bitcounter_abort_sweep extends eth_test_mdio_base;
    `uvm_component_utils(eth_test_miim_bitcounter_abort_sweep)
    function new(string name = "eth_test_miim_bitcounter_abort_sweep", uvm_component parent = null);
     super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        v_seq_tc_miim_bitcounter_abort_sweep v_seq;
        v_seq = v_seq_tc_miim_bitcounter_abort_sweep::type_id::create("v_seq");
        phase.raise_objection(this);
        apply_reset();
        v_seq.start(m_env.m_v_sqr);
        #500ns;
        phase.drop_objection(this);
    endtask
endclass

`endif