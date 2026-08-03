//==============================================================================
// File       : eth_v_seq_mdio_lib.sv
// Description: Virtual sequence library for the MIIM section of
//              tp_miim_tx.xlsx (test cases 1-15).
//
// FIX HISTORY:
//   v1 (Claude): used a nonexistent `wb_s_write_seq` class.
//   v2 (manual patch, to unblock vlog): swapped in `wb_s_seq_base` with
//       `uvm_do_on_with(..., {m_addr==...; m_wdata==...;})`. This let vlog
//       pass, but wb_s_seq_base has no fields called m_addr/m_wdata --
//       vlog doesn't fully resolve symbols inside randomize-with
//       constraint blocks at compile time, so this only surfaced at vsim
//       elaboration: "(vsim-3043) Unresolved reference to 'm_addr'" /
//       'm_wdata', one per call site, in every TC class.
//   v3 (this version): every register access goes through
//       wb_s_seq_mdio::configure_miim_registers(), which sets individual
//       RAL fields (regmodel.MIIMODER.CLKDIV.set(...), etc.) and calls
//       .update() -- the same mechanism wb_s_seq_base itself uses
//       internally, so there's no reliance on any field that doesn't
//       actually exist. regmodel is passed in explicitly as
//       p_sequencer.regmodel (see wb_s_seq_mdio.sv header comment for why:
//       this helper object is never .start()ed as a sequence, so any
//       inherited regmodel field would never get populated).
//
//   Register bit layouts (from eth_miim_regs.sv), for reference:
//     MIIMODER   [8]=MIINOPRE          [7:0]=CLKDIV
//     MIICOMMAND [2]=WCTRLDATA [1]=RSTAT [0]=SCANSTAT
//     MIIADDRESS [12:8]=RGAD            [4:0]=FIAD
//     MIITX_DATA [15:0]=CTRLDATA
//     MIISTATUS  [2]=NVALID [1]=BUSY [0]=LINKFAIL          (read-only)
//
//   PHY-side read responses come from the always-running background
//   sequence started by eth_env_mdio::run_phase (mdio_seq_phy_responder).
//   Sequences below reach it through p_sequencer.m_mdio_phy_rsp.phy_data
//   to control what the "PHY" reports back -- most importantly bit[2],
//   the standard MII Link Status bit, for the linkfail test case.
//==============================================================================
`ifndef ETH_V_SEQ_MDIO_LIB_SV
`define ETH_V_SEQ_MDIO_LIB_SV

// -----------------------------------------------------------------------------
// TC 1: tc_miim_clkdiv
// -----------------------------------------------------------------------------
class v_seq_tc_miim_clkdiv extends eth_v_seq_base;
    `uvm_object_utils(v_seq_tc_miim_clkdiv)
    function new(string name = "v_seq_tc_miim_clkdiv"); super.new(name); endfunction

    task body();
        wb_s_seq_mdio cfg = wb_s_seq_mdio::type_id::create("cfg");

        for (int i = 2; i <= 254; i += 2) begin
            cfg.configure_miim_registers(p_sequencer.regmodel, .clkdiv(i[7:0]));
        end
        // Directed for corner cases
        // clkdiv = odd number
        cfg.configure_miim_registers(p_sequencer.regmodel, .clkdiv(8'h65));
        // clkdiv = 0
        cfg.configure_miim_registers(p_sequencer.regmodel, .clkdiv(8'h00));
    endtask
endclass

// -----------------------------------------------------------------------------
// TC 2, 3, 5, 6: tc_miim_write_phy / tc_miim_busy_assrt(write) /
//                tc_miim_read_phy / tc_miim_busy_assrt(read)
// -----------------------------------------------------------------------------
class v_seq_tc_miim_rw_preamble extends eth_v_seq_base;
    `uvm_object_utils(v_seq_tc_miim_rw_preamble)
    function new(string name = "v_seq_tc_miim_rw_preamble"); super.new(name); endfunction

    task body();
        wb_s_seq_mdio cfg = wb_s_seq_mdio::type_id::create("cfg");
        uvm_status_e status;
        uvm_reg_data_t rdata;
        bit busy;

        // ---- Preamble ENABLED (MIINOPRE=0): expect the full 64-bit frame ----
        cfg.configure_miim_registers(p_sequencer.regmodel,
            .miinopre(1'b0), .fiad(5'h1), .rgad(5'h1), .ctrl_data(16'hABCD), .wctrldata(1'b1));
        p_sequencer.regmodel.is_miim_busy(busy);
        if (!busy)
            `uvm_error(get_type_name(), "BUSY did not assert immediately after WCTRLDATA write")
        p_sequencer.regmodel.wait_miim_done(); // TC3

        // ---- Preamble DISABLED (MIINOPRE=1): expect the 32-bit short frame ----
        cfg.configure_miim_registers(p_sequencer.regmodel,
            .miinopre(1'b1), .fiad(5'h1), .rgad(5'h2), .rstat(1'b1));
        p_sequencer.regmodel.is_miim_busy(busy);
        if (!busy)
            `uvm_error(get_type_name(), "BUSY did not assert immediately after RSTAT write")
        p_sequencer.regmodel.wait_miim_done(); // TC6

        // ---- Preamble ENABLED (MIINOPRE=0): expect the full 64-bit frame ----
        cfg.configure_miim_registers(p_sequencer.regmodel,
            .miinopre(1'b0), .fiad(5'h1), .rgad(5'h1), .ctrl_data(16'hABCD), .wctrldata(1'b1));
        p_sequencer.regmodel.is_miim_busy(busy);
        if (!busy)
            `uvm_error(get_type_name(), "BUSY did not assert immediately after WCTRLDATA write")
        p_sequencer.regmodel.wait_miim_done(); // TC3 again but to toggle the preamble bit back to 0

        p_sequencer.regmodel.MIIRX_DATA.read(status, rdata);
        `uvm_info(get_type_name(), $sformatf("MIIRX_DATA read back = 0x%0h", rdata), UVM_MEDIUM)

        p_sequencer.regmodel.MIIMODER.MIINOPRE.write(status, 1'b1); // force real bus write, both directions
        p_sequencer.regmodel.MIIMODER.MIINOPRE.write(status, 1'b0);
    endtask
endclass

// -----------------------------------------------------------------------------
// TC 4: tc_miim_rst_phy
// -----------------------------------------------------------------------------
class v_seq_tc_miim_rst_phy extends eth_v_seq_base;
    `uvm_object_utils(v_seq_tc_miim_rst_phy)
    function new(string name = "v_seq_tc_miim_rst_phy"); super.new(name); endfunction

    task body();
        wb_s_seq_mdio cfg = wb_s_seq_mdio::type_id::create("cfg");

        // Reset (bit[15]): write, then two reads back-to-back so Prsd[15]
        // is observed as 1 once (self-clear-on-read) and then as 0.
        cfg.configure_miim_registers(p_sequencer.regmodel,
            .fiad(5'h1), .rgad(5'h0), .ctrl_data(16'h8000), .wctrldata(1'b1));
        p_sequencer.regmodel.wait_miim_done();
        cfg.configure_miim_registers(p_sequencer.regmodel, .fiad(5'h1), .rgad(5'h0), .rstat(1'b1));
        p_sequencer.regmodel.wait_miim_done();
        cfg.configure_miim_registers(p_sequencer.regmodel, .fiad(5'h1), .rgad(5'h0), .rstat(1'b1));
        p_sequencer.regmodel.wait_miim_done();

        // Restart AutoNeg (bit[9]): same pattern.
        cfg.configure_miim_registers(p_sequencer.regmodel,
            .fiad(5'h1), .rgad(5'h0), .ctrl_data(16'h0200), .wctrldata(1'b1));
        p_sequencer.regmodel.wait_miim_done();
        cfg.configure_miim_registers(p_sequencer.regmodel, .fiad(5'h1), .rgad(5'h0), .rstat(1'b1));
        p_sequencer.regmodel.wait_miim_done();
        cfg.configure_miim_registers(p_sequencer.regmodel, .fiad(5'h1), .rgad(5'h0), .rstat(1'b1));
        p_sequencer.regmodel.wait_miim_done();
    endtask
endclass

// -----------------------------------------------------------------------------
// TC 7, 8: tc_miim_scan / tc_miim_scan_linkfail
// -----------------------------------------------------------------------------
class v_seq_tc_miim_scan extends eth_v_seq_base;
    `uvm_object_utils(v_seq_tc_miim_scan)
    function new(string name = "v_seq_tc_miim_scan"); super.new(name); endfunction

    task body();
        wb_s_seq_mdio cfg = wb_s_seq_mdio::type_id::create("cfg");
        uvm_status_e status;
        uvm_reg_data_t rdata;

        // Block 1: rgad 5'h1
        cfg.configure_miim_registers(p_sequencer.regmodel,
            .fiad(5'h1), .rgad(5'h1), .scanstat(1'b1));
        #1000ns;
        p_sequencer.regmodel.MIISTATUS.read(status, rdata);
        `uvm_info(get_type_name(), $sformatf("MIISTATUS after 1st scan window = 0x%0h", rdata), UVM_MEDIUM)
        
        p_sequencer.m_mdio_phy_rsp.set_link_status(5'h1, 1'b0); // link status = down
        cfg.configure_miim_registers(p_sequencer.regmodel, .fiad(5'h1), .rgad(5'h1)); // stop scan
        p_sequencer.regmodel.wait_miim_done();
        cfg.configure_miim_registers(p_sequencer.regmodel, .fiad(5'h1), .rgad(5'h1), .rstat(1'b1)); // guaranteed-complete read while down
        p_sequencer.regmodel.wait_miim_done();
        p_sequencer.m_mdio_phy_rsp.set_link_status(5'h1, 1'b1); // link status = back up

        cfg.configure_miim_registers(p_sequencer.regmodel, .fiad(5'h1), .rgad(5'h1), .rstat(1'b1)); // capture link back up
        p_sequencer.regmodel.wait_miim_done();

        // Block 2: rgad 5'h2
        cfg.configure_miim_registers(p_sequencer.regmodel,
            .fiad(5'h1), .rgad(5'h2), .scanstat(1'b1));
        #1000ns;
        p_sequencer.regmodel.MIISTATUS.read(status, rdata);
        `uvm_info(get_type_name(), $sformatf("MIISTATUS after 1st scan window = 0x%0h", rdata), UVM_MEDIUM)

        p_sequencer.m_mdio_phy_rsp.set_link_status(5'h1, 1'b0); // link status = down
        cfg.configure_miim_registers(p_sequencer.regmodel, .fiad(5'h1), .rgad(5'h2)); // stop scan
        p_sequencer.regmodel.wait_miim_done();
        cfg.configure_miim_registers(p_sequencer.regmodel, .fiad(5'h1), .rgad(5'h2), .rstat(1'b1)); // guaranteed-complete read while down
        p_sequencer.regmodel.wait_miim_done();
        p_sequencer.m_mdio_phy_rsp.set_link_status(5'h1, 1'b1); // link status = back up
        
        // Block 3: rgad 5'h5
        cfg.configure_miim_registers(p_sequencer.regmodel,
            .fiad(5'h1), .rgad(5'h5), .scanstat(1'b1));
        #1000ns;
        p_sequencer.regmodel.MIISTATUS.read(status, rdata);
        `uvm_info(get_type_name(), $sformatf("MIISTATUS after 1st scan window = 0x%0h", rdata), UVM_MEDIUM)

        p_sequencer.m_mdio_phy_rsp.set_link_status(5'h1, 1'b0); // link status = down
        cfg.configure_miim_registers(p_sequencer.regmodel, .fiad(5'h1), .rgad(5'h5)); // stop scan
        p_sequencer.regmodel.wait_miim_done();
        cfg.configure_miim_registers(p_sequencer.regmodel, .fiad(5'h1), .rgad(5'h5), .rstat(1'b1)); // guaranteed-complete read while down
        p_sequencer.regmodel.wait_miim_done();
        p_sequencer.m_mdio_phy_rsp.set_link_status(5'h1, 1'b1); // link status = back up
    endtask
endclass

// -----------------------------------------------------------------------------
// TC 9: tc_miim_write_readonly_regs
// NOTE: mdio_seq_phy_responder has no per-register PHY memory yet, so the
// "value unchanged after write" half of this check is a known limitation
// -- see the class body for detail.
// -----------------------------------------------------------------------------
class v_seq_tc_miim_write_readonly_regs extends eth_v_seq_base;
    `uvm_object_utils(v_seq_tc_miim_write_readonly_regs)
    function new(string name = "v_seq_tc_miim_write_readonly_regs"); super.new(name); endfunction

    task body();
        wb_s_seq_mdio cfg = wb_s_seq_mdio::type_id::create("cfg");
        uvm_status_e status;
        uvm_reg_data_t rdata_before, rdata;

        cfg.configure_miim_registers(p_sequencer.regmodel, .fiad(5'h1), .rgad(5'h1), .rstat(1'b1));
        p_sequencer.regmodel.wait_miim_done();
        p_sequencer.regmodel.MIIRX_DATA.read(status, rdata_before);

        cfg.configure_miim_registers(p_sequencer.regmodel,
            .fiad(5'h1), .rgad(5'h1), .ctrl_data(16'hDEAD), .wctrldata(1'b1));
        p_sequencer.regmodel.wait_miim_done();

        cfg.configure_miim_registers(p_sequencer.regmodel, .fiad(5'h1), .rgad(5'h1), .rstat(1'b1));
        p_sequencer.regmodel.wait_miim_done();
        p_sequencer.regmodel.MIIRX_DATA.read(status, rdata);

        if (rdata !== rdata_before)
            `uvm_error(get_type_name(),
                $sformatf("Read-only PHY reg value changed after write: before=0x%0h after=0x%0h",
                          rdata_before, rdata))
    endtask
endclass

// -----------------------------------------------------------------------------
// TC 10: tc_miim_priority
// -----------------------------------------------------------------------------
class v_seq_tc_miim_priority extends eth_v_seq_base;
    `uvm_object_utils(v_seq_tc_miim_priority)
    function new(string name = "v_seq_tc_miim_priority"); super.new(name); endfunction

    task body();
        wb_s_seq_mdio cfg = wb_s_seq_mdio::type_id::create("cfg");

        cfg.configure_miim_registers(p_sequencer.regmodel, .fiad(5'h1), .rgad(5'h1), .ctrl_data(16'hBEEF),
                                      .wctrldata(1'b1), .rstat(1'b1), .scanstat(1'b1));
        p_sequencer.regmodel.wait_miim_done();
        cfg.configure_miim_registers(p_sequencer.regmodel, .fiad(5'h1), .rgad(5'h1)); // stop scan before next combo
        p_sequencer.regmodel.wait_miim_done();

        cfg.configure_miim_registers(p_sequencer.regmodel, .fiad(5'h1), .rgad(5'h1), .ctrl_data(16'hBEEF),
                                      .wctrldata(1'b1), .rstat(1'b1));
        p_sequencer.regmodel.wait_miim_done();

        cfg.configure_miim_registers(p_sequencer.regmodel, .fiad(5'h1), .rgad(5'h1), .ctrl_data(16'hBEEF),
                                      .wctrldata(1'b1), .scanstat(1'b1));
        p_sequencer.regmodel.wait_miim_done();
        cfg.configure_miim_registers(p_sequencer.regmodel, .fiad(5'h1), .rgad(5'h1)); // stop scan before next combo
        p_sequencer.regmodel.wait_miim_done();

        cfg.configure_miim_registers(p_sequencer.regmodel, .fiad(5'h1), .rgad(5'h1),
                                      .rstat(1'b1), .scanstat(1'b1));
        p_sequencer.regmodel.wait_miim_done();
        cfg.configure_miim_registers(p_sequencer.regmodel, .fiad(5'h1), .rgad(5'h1)); // stop scan before next combo
        p_sequencer.regmodel.wait_miim_done();

        cfg.configure_miim_registers(p_sequencer.regmodel, .fiad(5'h1), .rgad(5'h1));
    endtask
endclass

// -----------------------------------------------------------------------------
// TC 11: tc_miim_wrong_phy_addr
// -----------------------------------------------------------------------------
class v_seq_tc_miim_wrong_phy_addr extends eth_v_seq_base;
    `uvm_object_utils(v_seq_tc_miim_wrong_phy_addr)
    function new(string name = "v_seq_tc_miim_wrong_phy_addr"); super.new(name); endfunction

    task body();
        wb_s_seq_mdio cfg = wb_s_seq_mdio::type_id::create("cfg");

        cfg.configure_miim_registers(p_sequencer.regmodel,
            .fiad(5'h1F), .rgad(5'h0), .ctrl_data(16'h1234), .wctrldata(1'b1));
        p_sequencer.regmodel.wait_miim_done();

        cfg.configure_miim_registers(p_sequencer.regmodel, .fiad(5'h1F), .rgad(5'h0), .rstat(1'b1));
        p_sequencer.regmodel.wait_miim_done();
    endtask
endclass

// -----------------------------------------------------------------------------
// TC 12: tc_miim_scan_intr
// -----------------------------------------------------------------------------
class v_seq_tc_miim_scan_intr extends eth_v_seq_base;
    `uvm_object_utils(v_seq_tc_miim_scan_intr)
    function new(string name = "v_seq_tc_miim_scan_intr"); super.new(name); endfunction

    task body();
        wb_s_seq_mdio cfg = wb_s_seq_mdio::type_id::create("cfg");
        uvm_status_e status;
        uvm_reg_data_t rdata;
        bit busy;

        cfg.configure_miim_registers(p_sequencer.regmodel, .fiad(5'h1), .rgad(5'h1), .scanstat(1'b1));
        cfg.configure_miim_registers(p_sequencer.regmodel, .fiad(5'h1), .rgad(5'h1)); // immediate clear

        p_sequencer.regmodel.wait_miim_done();
        p_sequencer.regmodel.is_miim_busy(busy);
        if (busy)
            `uvm_error(get_type_name(), "BUSY still asserted after a sliding scan stop")

        p_sequencer.regmodel.MIISTATUS.read(status, rdata);
        `uvm_info(get_type_name(), $sformatf("MIISTATUS after sliding scan stop = 0x%0h", rdata), UVM_MEDIUM)
    endtask
endclass

// -----------------------------------------------------------------------------
// Dedicated coverage-cross sequence: directly target the scan/read + reg-address bins.
// -----------------------------------------------------------------------------
class v_seq_tc_miim_cov_cross extends eth_v_seq_base;
    `uvm_object_utils(v_seq_tc_miim_cov_cross)
    function new(string name = "v_seq_tc_miim_cov_cross"); super.new(name); endfunction

    task body();
        wb_s_seq_mdio cfg = wb_s_seq_mdio::type_id::create("cfg");

        // Explicitly hit the max-divider bin as well.
        cfg.configure_miim_registers(p_sequencer.regmodel,
            .clkdiv(8'hFF), .miinopre(1'b0), .fiad(5'h1), .rgad(5'h0), .ctrl_data(16'h0000));
        #200ns;

        // scan_op + ctrl_reg
        cfg.configure_miim_registers(p_sequencer.regmodel,
            .fiad(5'h1), .rgad(5'h0), .scanstat(1'b1));
        #200ns;

        // scan_op + id1_reg
        cfg.configure_miim_registers(p_sequencer.regmodel,
            .fiad(5'h1), .rgad(5'h2), .scanstat(1'b1));
        #200ns;
        cfg.configure_miim_registers(p_sequencer.regmodel,
            .fiad(5'h1), .rgad(5'h2), .scanstat(1'b1));
        #200ns;

        // scan_op + others
        cfg.configure_miim_registers(p_sequencer.regmodel,
            .fiad(5'h1), .rgad(5'h3), .scanstat(1'b1));
        #200ns;
        cfg.configure_miim_registers(p_sequencer.regmodel,
            .fiad(5'h1), .rgad(5'h3), .scanstat(1'b1));
        #200ns;

        // read_op + others
        cfg.configure_miim_registers(p_sequencer.regmodel,
            .fiad(5'h1), .rgad(5'h3), .rstat(1'b1));
        #200ns;
        cfg.configure_miim_registers(p_sequencer.regmodel,
            .fiad(5'h1), .rgad(5'h3), .rstat(1'b1));
        #200ns;
    endtask
endclass

// -----------------------------------------------------------------------------
// TC 13, 14, 15: tc_miim_walk_phy_addr / tc_miim_walk_reg_addr / tc_miim_walk_data
// -----------------------------------------------------------------------------
class v_seq_tc_miim_walking extends eth_v_seq_base;
    `uvm_object_utils(v_seq_tc_miim_walking)
    function new(string name = "v_seq_tc_miim_walking"); super.new(name); endfunction

    task body();
        wb_s_seq_mdio cfg = wb_s_seq_mdio::type_id::create("cfg");

        for (int pre = 0; pre < 2; pre++) begin
            for (int i = 0; i < 5; i++) begin // TC13: walking-1 FIAD
                cfg.configure_miim_registers(p_sequencer.regmodel,
                    .miinopre(pre[0]), .fiad(5'h1 << i), .rgad(5'h0), .wctrldata(1'b1));
                p_sequencer.regmodel.wait_miim_done();
            end

            for (int i = 0; i < 5; i++) begin // TC14: walking-1 RGAD
                cfg.configure_miim_registers(p_sequencer.regmodel,
                    .miinopre(pre[0]), .fiad(5'h1), .rgad(5'h1 << i), .wctrldata(1'b1));
                p_sequencer.regmodel.wait_miim_done();
            end

            for (int i = 0; i < 16; i++) begin // TC15: walking-1 write data
                cfg.configure_miim_registers(p_sequencer.regmodel,
                    .miinopre(pre[0]), .fiad(5'h1), .rgad(5'h1), .ctrl_data(16'h1 << i), .wctrldata(1'b1));
                p_sequencer.regmodel.wait_miim_done();
            end

            // Explicitly hit the all-ones control-data coverpoint.
            cfg.configure_miim_registers(p_sequencer.regmodel,
                .miinopre(pre[0]), .fiad(5'h1), .rgad(5'h1), .ctrl_data(16'hFFFF), .wctrldata(1'b1));
            p_sequencer.regmodel.wait_miim_done();

            // Explicitly hit the missing cross bins in m_mdio_cfg_cov:
            // scan_op + ctrl_reg, scan_op + id1_reg, scan_op + others, read_op + others.
            cfg.configure_miim_registers(p_sequencer.regmodel,
                .miinopre(pre[0]), .fiad(5'h1), .rgad(5'h0), .scanstat(1'b1));
            p_sequencer.regmodel.wait_miim_done();
            cfg.configure_miim_registers(p_sequencer.regmodel, .miinopre(pre[0]), .fiad(5'h1), .rgad(5'h0)); // stop scan
            p_sequencer.regmodel.wait_miim_done();

            cfg.configure_miim_registers(p_sequencer.regmodel,
                .miinopre(pre[0]), .fiad(5'h1), .rgad(5'h2), .scanstat(1'b1));
            p_sequencer.regmodel.wait_miim_done();
            cfg.configure_miim_registers(p_sequencer.regmodel, .miinopre(pre[0]), .fiad(5'h1), .rgad(5'h2)); // stop scan
            p_sequencer.regmodel.wait_miim_done();

            cfg.configure_miim_registers(p_sequencer.regmodel,
                .miinopre(pre[0]), .fiad(5'h1), .rgad(5'h3), .scanstat(1'b1));
            p_sequencer.regmodel.wait_miim_done();
            cfg.configure_miim_registers(p_sequencer.regmodel, .miinopre(pre[0]), .fiad(5'h1), .rgad(5'h3)); // stop scan before next combo
            p_sequencer.regmodel.wait_miim_done();

            cfg.configure_miim_registers(p_sequencer.regmodel,
                .miinopre(pre[0]), .fiad(5'h1), .rgad(5'h3), .rstat(1'b1));
            p_sequencer.regmodel.wait_miim_done();
        end
    endtask
endclass

// -----------------------------------------------------------------------------
// TC 16: tc_miim_reg_bits -- exercises reg0's RW bits and reg1's RO status
// bits that no other test touches (closes Prsd[0-1,3-11,13-15] toggle gaps).
// -----------------------------------------------------------------------------
class v_seq_tc_miim_reg_bits extends eth_v_seq_base;
    `uvm_object_utils(v_seq_tc_miim_reg_bits)
    function new(string name = "v_seq_tc_miim_reg_bits"); super.new(name); endfunction

    task body();
        wb_s_seq_mdio cfg = wb_s_seq_mdio::type_id::create("cfg");

        // reg0: set every RW bit (Loopback,Speed,PowerDown,Isolate,Duplex,
        // CollisionTest -- excludes AutoNegEnable, already covered, and the
        // self-clearing Reset/RestartAutoNeg bits, which structurally never
        // read back as 1).
        cfg.configure_miim_registers(p_sequencer.regmodel,
            .fiad(5'h1), .rgad(5'h0), .ctrl_data(16'h7F80), .wctrldata(1'b1)); // bits[14:7] all 1
        p_sequencer.regmodel.wait_miim_done();
        cfg.configure_miim_registers(p_sequencer.regmodel, .fiad(5'h1), .rgad(5'h0), .rstat(1'b1));
        p_sequencer.regmodel.wait_miim_done();

        // reg0: clear those same bits back to 0 (Prsd[12]'s missing ->0 direction).
        cfg.configure_miim_registers(p_sequencer.regmodel,
            .fiad(5'h1), .rgad(5'h0), .ctrl_data(16'h0000), .wctrldata(1'b1));
        p_sequencer.regmodel.wait_miim_done();
        cfg.configure_miim_registers(p_sequencer.regmodel, .fiad(5'h1), .rgad(5'h0), .rstat(1'b1));
        p_sequencer.regmodel.wait_miim_done();

        // reg1: force every RO status bit high, then read it.
        p_sequencer.m_mdio_phy_rsp.set_status_bits(5'h1, 7'b111_1111);
        cfg.configure_miim_registers(p_sequencer.regmodel, .fiad(5'h1), .rgad(5'h1), .rstat(1'b1));
        p_sequencer.regmodel.wait_miim_done();

        // reg1: back to 0.
        p_sequencer.m_mdio_phy_rsp.set_status_bits(5'h1, 7'b000_0000);
        cfg.configure_miim_registers(p_sequencer.regmodel, .fiad(5'h1), .rgad(5'h1), .rstat(1'b1));
        p_sequencer.regmodel.wait_miim_done();
    endtask
endclass

`endif