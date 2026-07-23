//==============================================================================
// File       : eth_v_seq_mdio_lib.sv
// Description: Virtual sequence library translated from tp_miim_tx.xlsx
//==============================================================================
`ifndef ETH_V_SEQ_MDIO_LIB_SV
`define ETH_V_SEQ_MDIO_LIB_SV

// -----------------------------------------------------------------------------
// TC 1: tc_miim_clkdiv (Try all even values from 1:255 for CLKDIV)
// -----------------------------------------------------------------------------
class v_seq_tc_miim_clkdiv extends eth_v_seq_base;
    `uvm_object_utils(v_seq_tc_miim_clkdiv)
    function new(string name = "v_seq_tc_miim_clkdiv"); super.new(name); endfunction

    task body();
        wb_s_write_seq host_write = wb_s_write_seq::type_id::create("host_write");
        // Loop through even values 2 to 254 (0x02 to 0xFE)
        for (int i = 2; i <= 254; i += 2) begin
            `uvm_do_on_with(host_write, p_sequencer.m_wb_s_sqr, {
                m_addr == 'h20; // MIIMODER
                m_wdata == i;
            })
        end
    endtask
endclass

// -----------------------------------------------------------------------------
// TC 2 & 5: tc_miim_write_phy & tc_miim_read_phy (Toggle MIINOPRE)
// TC 3 & 6: tc_miim_busy_assrt (Implicitly checked by scoreboard during W/R)
// -----------------------------------------------------------------------------
class v_seq_tc_miim_rw_preamble extends eth_v_seq_base;
    `uvm_object_utils(v_seq_tc_miim_rw_preamble)
    function new(string name = "v_seq_tc_miim_rw_preamble"); super.new(name); endfunction

    task body();
        wb_s_write_seq host_write = wb_s_write_seq::type_id::create("host_write");

        // Sequence 1: Preamble ENABLED (MIINOPRE = 0)
        `uvm_do_on_with(host_write, p_sequencer.m_wb_s_sqr, { m_addr == 'h20; m_wdata == 32'h00000000; })
        `uvm_do_on_with(host_write, p_sequencer.m_wb_s_sqr, { m_addr == 'h28; m_wdata == 32'h00000101; }) // FIAD=1, RGAD=1
        `uvm_do_on_with(host_write, p_sequencer.m_wb_s_sqr, { m_addr == 'h2C; m_wdata == 32'h0000ABCD; }) // TX Data
        `uvm_do_on_with(host_write, p_sequencer.m_wb_s_sqr, { m_addr == 'h24; m_wdata == 32'h00000004; }) // WCTRLDATA=1

        // Sequence 2: Preamble DISABLED (MIINOPRE = 1)
        `uvm_do_on_with(host_write, p_sequencer.m_wb_s_sqr, { m_addr == 'h20; m_wdata == 32'h00000100; })
        `uvm_do_on_with(host_write, p_sequencer.m_wb_s_sqr, { m_addr == 'h28; m_wdata == 32'h00000102; }) // FIAD=1, RGAD=2
        `uvm_do_on_with(host_write, p_sequencer.m_wb_s_sqr, { m_addr == 'h24; m_wdata == 32'h00000002; }) // RSTAT=1 (Read)
    endtask
endclass

// -----------------------------------------------------------------------------
// TC 4: tc_miim_rst_phy (Write to PHY Control Reg 0, bit 15)
// -----------------------------------------------------------------------------
class v_seq_tc_miim_rst_phy extends eth_v_seq_base;
    `uvm_object_utils(v_seq_tc_miim_rst_phy)
    function new(string name = "v_seq_tc_miim_rst_phy"); super.new(name); endfunction

    task body();
        wb_s_write_seq host_write = wb_s_write_seq::type_id::create("host_write");

        `uvm_do_on_with(host_write, p_sequencer.m_wb_s_sqr, { m_addr == 'h28; m_wdata == 32'h00000000; }) // RGAD=0
        `uvm_do_on_with(host_write, p_sequencer.m_wb_s_sqr, { m_addr == 'h2C; m_wdata == 32'h00008000; }) // Soft Reset (Bit 15=1)
        `uvm_do_on_with(host_write, p_sequencer.m_wb_s_sqr, { m_addr == 'h24; m_wdata == 32'h00000004; }) // Trigger Write
    endtask
endclass

// -----------------------------------------------------------------------------
// TC 7 & 8: tc_miim_scan & tc_miim_scan_linkfail
// -----------------------------------------------------------------------------
class v_seq_tc_miim_scan extends eth_v_seq_base;
    `uvm_object_utils(v_seq_tc_miim_scan)
    function new(string name = "v_seq_tc_miim_scan"); super.new(name); endfunction

    task body();
        wb_s_write_seq host_write = wb_s_write_seq::type_id::create("host_write");
        wb_s_read_seq  host_read  = wb_s_read_seq::type_id::create("host_read");

        // Target PHY Status Reg (RGAD=1) to verify Linkfail mirroring during scan
        `uvm_do_on_with(host_write, p_sequencer.m_wb_s_sqr, { m_addr == 'h28; m_wdata == 32'h00000101; }) // FIAD=1, RGAD=1
        `uvm_do_on_with(host_write, p_sequencer.m_wb_s_sqr, { m_addr == 'h24; m_wdata == 32'h00000001; }) // SCANSTAT=1

        // Wait to allow hardware to poll
        #1000ns;
        // Read MIISTATUS to check NVALID, BUSY, and LINKFAIL
        `uvm_do_on_with(host_read, p_sequencer.m_wb_s_sqr, { m_addr == 'h34; })
    endtask
endclass

// -----------------------------------------------------------------------------
// TC 10: tc_miim_priority (WRITE then SCAN priority validation)
// -----------------------------------------------------------------------------
class v_seq_tc_miim_priority extends eth_v_seq_base;
    `uvm_object_utils(v_seq_tc_miim_priority)
    function new(string name = "v_seq_tc_miim_priority"); super.new(name); endfunction

    task body();
        wb_s_write_seq host_write = wb_s_write_seq::type_id::create("host_write");
        // Assert WRITE(2), READ(1), and SCAN(0) simultaneously: 3'b111
        `uvm_do_on_with(host_write, p_sequencer.m_wb_s_sqr, { m_addr == 'h24; m_wdata == 32'h00000007; })
    endtask
endclass

// -----------------------------------------------------------------------------
// TC 13, 14, 15: tc_miim_walk_phy_addr, walk_reg_addr, walk_data
// -----------------------------------------------------------------------------
class v_seq_tc_miim_walking extends eth_v_seq_base;
    `uvm_object_utils(v_seq_tc_miim_walking)
    function new(string name = "v_seq_tc_miim_walking"); super.new(name); endfunction

    task body();
        wb_s_write_seq host_write = wb_s_write_seq::type_id::create("host_write");

        // 13: Walking-1 FIAD[4:0]
        for (int i = 0; i < 5; i++) begin
            `uvm_do_on_with(host_write, p_sequencer.m_wb_s_sqr, { m_addr == 'h28; m_wdata == (1<<i); })
            `uvm_do_on_with(host_write, p_sequencer.m_wb_s_sqr, { m_addr == 'h24; m_wdata == 32'h00000004; })
        end

        // 14: Walking-1 RGAD[4:0] (Bits 12:8 of MIIADDRESS)
        for (int i = 0; i < 5; i++) begin
            `uvm_do_on_with(host_write, p_sequencer.m_wb_s_sqr, { m_addr == 'h28; m_wdata == (1<<(i+8)); })
            `uvm_do_on_with(host_write, p_sequencer.m_wb_s_sqr, { m_addr == 'h24; m_wdata == 32'h00000004; })
        end

        // 15: Walking-1 DATA[15:0] (MIITX_DATA)
        for (int i = 0; i < 16; i++) begin
            `uvm_do_on_with(host_write, p_sequencer.m_wb_s_sqr, { m_addr == 'h2C; m_wdata == (1<<i); })
            `uvm_do_on_with(host_write, p_sequencer.m_wb_s_sqr, { m_addr == 'h24; m_wdata == 32'h00000004; })
        end
    endtask
endclass

`endif
