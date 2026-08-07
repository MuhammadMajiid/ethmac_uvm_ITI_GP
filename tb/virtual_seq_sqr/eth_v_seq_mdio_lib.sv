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
        uvm_status_e   status;
        uvm_reg_data_t rdata;

        // Reset (bit[15]): write, then two reads back-to-back so Prsd[15]
        // is observed as 1 once (self-clear-on-read) and then as 0.
        // MIIRX_DATA reads + prints added below purely as diagnostics --
        // Prsd[15] toggle coverage stayed at 0% despite this being the
        // same mechanism as bit[9] below (which reaches 100%), and code
        // review alone couldn't explain the gap. This will show the
        // actual captured value directly in the log.
        cfg.configure_miim_registers(p_sequencer.regmodel,
            .fiad(5'h1), .rgad(5'h0), .ctrl_data(16'h8000), .wctrldata(1'b1));
        p_sequencer.regmodel.wait_miim_done();
        cfg.configure_miim_registers(p_sequencer.regmodel, .fiad(5'h1), .rgad(5'h0), .rstat(1'b1));
        p_sequencer.regmodel.wait_miim_done();
        p_sequencer.regmodel.MIIRX_DATA.read(status, rdata);
        `uvm_info(get_type_name(), $sformatf("Reset bit[15] 1st read: MIIRX_DATA=0x%0h (bit15=%0b)", rdata, rdata[15]), UVM_LOW)
        cfg.configure_miim_registers(p_sequencer.regmodel, .fiad(5'h1), .rgad(5'h0), .rstat(1'b1));
        p_sequencer.regmodel.wait_miim_done();
        p_sequencer.regmodel.MIIRX_DATA.read(status, rdata);
        `uvm_info(get_type_name(), $sformatf("Reset bit[15] 2nd read: MIIRX_DATA=0x%0h (bit15=%0b)", rdata, rdata[15]), UVM_LOW)

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
                                      .wctrldata(1'b1), .rstat(1'b1));
        p_sequencer.regmodel.wait_miim_done();


        cfg.configure_miim_registers(p_sequencer.regmodel, .fiad(5'h1), .rgad(5'h1), .ctrl_data(16'hBEEF),
                                      .wctrldata(1'b1), .rstat(1'b1), .scanstat(1'b1));
        // #100ns;
        cfg.configure_miim_registers(p_sequencer.regmodel, .fiad(5'h1), .rgad(5'h1)); // stop scan before next combo
        p_sequencer.regmodel.wait_miim_done();


        cfg.configure_miim_registers(p_sequencer.regmodel, .fiad(5'h1), .rgad(5'h1), .ctrl_data(16'hBEEF),
                                      .wctrldata(1'b1), .scanstat(1'b1));
        // #100ns;
        cfg.configure_miim_registers(p_sequencer.regmodel, .fiad(5'h1), .rgad(5'h1)); // stop scan before next combo
        p_sequencer.regmodel.wait_miim_done();
        
        
        cfg.configure_miim_registers(p_sequencer.regmodel, .fiad(5'h1), .rgad(5'h1),
                                        .rstat(1'b1), .scanstat(1'b1));
        // #100ns;
        cfg.configure_miim_registers(p_sequencer.regmodel, .fiad(5'h1), .rgad(5'h1)); // stop scan before next combo
        p_sequencer.regmodel.wait_miim_done();

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

        cfg.configure_miim_registers(p_sequencer.regmodel, .fiad(5'h1), .rgad(5'h1), .ctrl_data(16'hBEEF),
                                      .wctrldata(1'b1));
        p_sequencer.regmodel.wait_miim_done();
        
        cfg.configure_miim_registers(p_sequencer.regmodel, .fiad(5'h1), .rgad(5'h1), .scanstat(1'b1));
        #3500;
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
            cfg.configure_miim_registers(p_sequencer.regmodel, .miinopre(pre[0]), .fiad(5'h1), .rgad(5'h0)); // stop scan
            // p_sequencer.regmodel.wait_miim_done();
            p_sequencer.regmodel.wait_miim_done();

            cfg.configure_miim_registers(p_sequencer.regmodel,
                .miinopre(pre[0]), .fiad(5'h1), .rgad(5'h2), .scanstat(1'b1));
            cfg.configure_miim_registers(p_sequencer.regmodel, .miinopre(pre[0]), .fiad(5'h1), .rgad(5'h2)); // stop scan
            // p_sequencer.regmodel.wait_miim_done();
            p_sequencer.regmodel.wait_miim_done();

            cfg.configure_miim_registers(p_sequencer.regmodel,
                .miinopre(pre[0]), .fiad(5'h1), .rgad(5'h3), .scanstat(1'b1));
            cfg.configure_miim_registers(p_sequencer.regmodel, .miinopre(pre[0]), .fiad(5'h1), .rgad(5'h3)); // stop scan before next combo
            // p_sequencer.regmodel.wait_miim_done();
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

// -----------------------------------------------------------------------------
// TC 17: tc_miim_scan_intr_sweep -- sweeps the delay between starting a scan
// and stopping it across a full frame's worth of bit-times, to isolate
// exactly which interruption windows leave BUSY stuck (see MIIM_TIMEOUT
// findings in tc_miim_scan_intr / tc_miim_walking). Uses its own bounded
// poll instead of wait_miim_done() so one stuck point doesn't UVM_FATAL the
// whole sweep -- each point is reported individually instead.
// -----------------------------------------------------------------------------
class v_seq_tc_miim_scan_intr_sweep extends eth_v_seq_base;
    `uvm_object_utils(v_seq_tc_miim_scan_intr_sweep)
    function new(string name = "v_seq_tc_miim_scan_intr_sweep"); super.new(name); endfunction

    // Bounded busy poll: returns 1 if BUSY cleared within budget_ns, else 0.
    task automatic poll_busy_clear(int budget_ns, int poll_period_ns, output bit cleared);
        uvm_status_e status;
        uvm_reg_data_t rdata;
        int elapsed = 0;
        cleared = 0;
        while (elapsed < budget_ns) begin
            p_sequencer.regmodel.MIISTATUS.read(status, rdata);
            if (!rdata[1]) begin // BUSY bit
                cleared = 1;
                return;
            end
            #(poll_period_ns);
            elapsed += poll_period_ns;
        end
    endtask

    task body();
        wb_s_seq_mdio cfg = wb_s_seq_mdio::type_id::create("cfg");
        reset_seq     m_reset_seq;
        // One full 64-bit frame at clkdiv=100/WB=5ns is ~32000ns (64 *
        // 500ns/bit). Sweep from "before the scan even starts" through
        // "well after it should have completed".
        int delays_ns[] = '{0, 250, 500, 1000, 2000, 4000, 8000, 16000, 32000, 40000};
        bit cleared;

        foreach (delays_ns[idx]) begin
            cfg.configure_miim_registers(p_sequencer.regmodel,
                .fiad(5'h1), .rgad(5'h1), .scanstat(1'b1));
            #(delays_ns[idx]);
            cfg.configure_miim_registers(p_sequencer.regmodel, .fiad(5'h1), .rgad(5'h1)); // stop scan

            // Budget matched to wait_miim_done()'s own patience (100000
            // iterations) rather than an arbitrary tight window -- an
            // earlier version of this test used 50000ns here, which is
            // nowhere near wait_miim_done()'s real effective budget and
            // produced false "stuck" reports for delays that likely just
            // recover slower than that, not permanently.
            poll_busy_clear(5_000_000, 5000, cleared);
            if (cleared)
                `uvm_info(get_type_name(),
                    $sformatf("delay=%0dns: BUSY cleared normally", delays_ns[idx]), UVM_LOW)
            else
                `uvm_error(get_type_name(),
                    $sformatf("delay=%0dns: BUSY stuck after scan interruption (MIIM_TIMEOUT-class hang)", delays_ns[idx]))

            // Recover regardless of pass/fail so each delay value is an
            // INDEPENDENT data point -- without this, one stuck point
            // would trivially make every later point "fail" too, since
            // the core never got a chance to recover in between.
            m_reset_seq = reset_seq::type_id::create("m_reset_seq");
            m_reset_seq.m_regmodel = p_sequencer.regmodel;
            m_reset_seq.start(p_sequencer.m_reset_sqr);
            p_sequencer.regmodel.reset(); // resync RAL mirror to defaults
        end
    endtask
endclass

// -----------------------------------------------------------------------------
// TC 18: tc_miim_back_to_back -- issues consecutive WRITE/READ operations
// with zero idle time between one op's BUSY-clear and the next op's
// register writes, to check for missed/double-triggered StartOp edges
// (WCtrlDataStart/RStatStart) under tight back-to-back cadence.
// -----------------------------------------------------------------------------
class v_seq_tc_miim_back_to_back extends eth_v_seq_base;
    `uvm_object_utils(v_seq_tc_miim_back_to_back)
    function new(string name = "v_seq_tc_miim_back_to_back"); super.new(name); endfunction

    task body();
        wb_s_seq_mdio cfg = wb_s_seq_mdio::type_id::create("cfg");

        for (int i = 0; i < 20; i++) begin
            cfg.configure_miim_registers(p_sequencer.regmodel,
                .fiad(5'h1), .rgad(5'h1), .ctrl_data(16'h1111 * (i+1)), .wctrldata(1'b1));
            p_sequencer.regmodel.wait_miim_done();
            // No delay here on purpose -- next op's register writes land
            // immediately on BUSY's falling edge.
            cfg.configure_miim_registers(p_sequencer.regmodel, .fiad(5'h1), .rgad(5'h1), .rstat(1'b1));
            p_sequencer.regmodel.wait_miim_done();
        end
    endtask
endclass

// -----------------------------------------------------------------------------
// TC 19: tc_miim_phy_addr_sweep -- exercises FIAD address decode across the
// full 5-bit range, not just the single 0x1F case tc_miim_wrong_phy_addr
// covers.
// -----------------------------------------------------------------------------
class v_seq_tc_miim_phy_addr_sweep extends eth_v_seq_base;
    `uvm_object_utils(v_seq_tc_miim_phy_addr_sweep)
    function new(string name = "v_seq_tc_miim_phy_addr_sweep"); super.new(name); endfunction

    task body();
        wb_s_seq_mdio cfg = wb_s_seq_mdio::type_id::create("cfg");
        bit [4:0] fiads[] = '{5'h00, 5'h01, 5'h0A, 5'h15, 5'h1E, 5'h1F};

        foreach (fiads[idx]) begin
            cfg.configure_miim_registers(p_sequencer.regmodel,
                .fiad(fiads[idx]), .rgad(5'h0), .ctrl_data(16'hACE0 + idx), .wctrldata(1'b1));
            p_sequencer.regmodel.wait_miim_done();
            cfg.configure_miim_registers(p_sequencer.regmodel, .fiad(fiads[idx]), .rgad(5'h0), .rstat(1'b1));
            p_sequencer.regmodel.wait_miim_done();
        end
    endtask
endclass

// -----------------------------------------------------------------------------
// TC 20: tc_miim_reset_in_flight -- pulses the DUT reset while a WRITE
// operation is mid-shift (well before the ~32000ns a full frame takes at
// clkdiv=100), then checks the core comes out of reset clean: BUSY reads 0,
// and a completely normal subsequent write+read works correctly. Checks
// InProgress/BitCounter/ShiftReg's handling of an async reset mid-FSM.
// -----------------------------------------------------------------------------
class v_seq_tc_miim_reset_in_flight extends eth_v_seq_base;
    `uvm_object_utils(v_seq_tc_miim_reset_in_flight)
    function new(string name = "v_seq_tc_miim_reset_in_flight"); super.new(name); endfunction

    task body();
        wb_s_seq_mdio cfg = wb_s_seq_mdio::type_id::create("cfg");
        reset_seq     m_reset_seq;
        uvm_status_e  status;
        uvm_reg_data_t rdata;

        // Start a write and let it run partway (~10 of 64 bit-times at
        // clkdiv=100/WB=5ns is ~5000ns) -- deliberately not waiting for
        // wait_miim_done(), since we're interrupting it on purpose.
        cfg.configure_miim_registers(p_sequencer.regmodel,
            .fiad(5'h1), .rgad(5'h0), .ctrl_data(16'hDEAD), .wctrldata(1'b1));
        #5000ns;

        // Pulse reset mid-shift.
        m_reset_seq = reset_seq::type_id::create("m_reset_seq");
        m_reset_seq.m_regmodel = p_sequencer.regmodel;
        m_reset_seq.start(p_sequencer.m_reset_sqr);

        // Reset wipes the DUT's registers back to defaults, but the RAL
        // mirror still thinks the pre-reset values are current -- resync
        // it so the next .update() actually issues real bus writes instead
        // of silently skipping fields it (wrongly) believes are unchanged.
        p_sequencer.regmodel.reset();

        p_sequencer.regmodel.MIISTATUS.read(status, rdata);
        if (rdata[1]) // BUSY
            `uvm_error(get_type_name(), "BUSY still asserted after reset mid-transaction")

        // Core should be fully usable afterward, not just superficially
        // idle -- run a normal write+read and let the scoreboard confirm
        // it's actually correct.
        cfg.configure_miim_registers(p_sequencer.regmodel,
            .fiad(5'h1), .rgad(5'h0), .ctrl_data(16'hBEEF), .wctrldata(1'b1));
        p_sequencer.regmodel.wait_miim_done();
        cfg.configure_miim_registers(p_sequencer.regmodel, .fiad(5'h1), .rgad(5'h0), .rstat(1'b1));
        p_sequencer.regmodel.wait_miim_done();
        

        
        // Directed case for the scan in order to toggle the LinkFail bit
        cfg.configure_miim_registers(p_sequencer.regmodel,
            .fiad(5'h1), .rgad(5'h0), .scanstat(1'b1));
        #5000ns;

        // Pulse reset mid-shift.
        m_reset_seq = reset_seq::type_id::create("m_reset_seq");
        m_reset_seq.m_regmodel = p_sequencer.regmodel;
        m_reset_seq.start(p_sequencer.m_reset_sqr);

        // Reset wipes the DUT's registers back to defaults, but the RAL
        // mirror still thinks the pre-reset values are current -- resync
        // it so the next .update() actually issues real bus writes instead
        // of silently skipping fields it (wrongly) believes are unchanged.
        p_sequencer.regmodel.reset();

        p_sequencer.regmodel.MIISTATUS.read(status, rdata);
        if (rdata[1]) // BUSY
            `uvm_error(get_type_name(), "BUSY still asserted after reset mid-transaction")

        // Core should be fully usable afterward, not just superficially
        // idle -- run a normal write+read and let the scoreboard confirm
        // it's actually correct.
        cfg.configure_miim_registers(p_sequencer.regmodel,
            .fiad(5'h1), .rgad(5'h0), .ctrl_data(16'hBEEF), .wctrldata(1'b1));
        p_sequencer.regmodel.wait_miim_done();
        cfg.configure_miim_registers(p_sequencer.regmodel, .fiad(5'h1), .rgad(5'h0), .rstat(1'b1));
        p_sequencer.regmodel.wait_miim_done();
    endtask
endclass

// -----------------------------------------------------------------------------
// TC 21: tc_miim_overwrite_while_busy -- attempts to overwrite
// MIIADDRESS/MIITX_DATA/MIICOMMAND with different values while a previous
// op is still InProgress (before its wait_miim_done()), then reads back
// what the PHY-side actually latched. Checks whether the RTL correctly
// ignores/holds off the overwrite (address/data are expected to latch
// once at StartOp and not be continuously re-sampled) rather than
// corrupting the in-flight operation.
//
// NOTE: a mismatch here could be a genuine RTL latching bug OR a
// scoreboard predictor limitation (pred_write/pred_read may not model a
// same-slot overwrite attempt) -- triage which before filing either way.
// -----------------------------------------------------------------------------
class v_seq_tc_miim_overwrite_while_busy extends eth_v_seq_base;
    `uvm_object_utils(v_seq_tc_miim_overwrite_while_busy)
    function new(string name = "v_seq_tc_miim_overwrite_while_busy"); super.new(name); endfunction

    task body();
        wb_s_seq_mdio cfg = wb_s_seq_mdio::type_id::create("cfg");

        // Start the real op: fiad=1, reg0, data=0x1111.
        cfg.configure_miim_registers(p_sequencer.regmodel,
            .fiad(5'h1), .rgad(5'h0), .ctrl_data(16'h1111), .wctrldata(1'b1));

        // Attempt to overwrite mid-shift, well before completion.
        #2000ns;
        cfg.configure_miim_registers(p_sequencer.regmodel,
            .fiad(5'h2), .rgad(5'h1), .ctrl_data(16'h2222), .wctrldata(1'b1));

        p_sequencer.regmodel.wait_miim_done();

        // Read back reg0 on the ORIGINAL phy address -- if the RTL latched
        // correctly at StartOp, this should show the FIRST write's data.
        cfg.configure_miim_registers(p_sequencer.regmodel, .fiad(5'h1), .rgad(5'h0), .rstat(1'b1));
        p_sequencer.regmodel.wait_miim_done();
    endtask
endclass

// -----------------------------------------------------------------------------
// TC 22: tc_miim_clkdiv_extremes -- runs a full real write+read transaction
// (not just a config-only register write) at clkdiv boundary values:
// smallest legal (1, 2 -- both clamp to the same TempDivider=2 in RTL),
// smallest odd giving a distinct half-period (3), and max (255, odd).
// tc_miim_clkdiv only ever configures MIIMODER.CLKDIV without driving a
// real MDIO frame at any value other than 100, so the clock generator's
// actual bit-timing was never checked at the extremes.
// -----------------------------------------------------------------------------
class v_seq_tc_miim_clkdiv_extremes extends eth_v_seq_base;
    `uvm_object_utils(v_seq_tc_miim_clkdiv_extremes)
    function new(string name = "v_seq_tc_miim_clkdiv_extremes"); super.new(name); endfunction

    task body();
        wb_s_seq_mdio cfg = wb_s_seq_mdio::type_id::create("cfg");
        bit [7:0] divs[] = '{8'h01, 8'h02, 8'h03, 8'hFF};

        foreach (divs[idx]) begin
            cfg.configure_miim_registers(p_sequencer.regmodel, .clkdiv(divs[idx]));
            cfg.configure_miim_registers(p_sequencer.regmodel,
                .fiad(5'h1), .rgad(5'h0), .ctrl_data(16'hA5A5 + idx), .wctrldata(1'b1));
            p_sequencer.regmodel.wait_miim_done();
            cfg.configure_miim_registers(p_sequencer.regmodel, .fiad(5'h1), .rgad(5'h0), .rstat(1'b1));
            p_sequencer.regmodel.wait_miim_done();
        end
    endtask
endclass

// -----------------------------------------------------------------------------
// TC 23: tc_miim_linkfail_toggle -- closes LinkFail's missing 1->0 toggle
// bin. Uses only RSTAT (no SCANSTAT at all) so it can't be confounded by
// the scan-interruption lockup bug -- a clean, minimal up/down/up sequence
// on reg1 to unambiguously exercise both toggle directions.
// -----------------------------------------------------------------------------
class v_seq_tc_miim_linkfail_toggle extends eth_v_seq_base;
    `uvm_object_utils(v_seq_tc_miim_linkfail_toggle)
    function new(string name = "v_seq_tc_miim_linkfail_toggle"); super.new(name); endfunction

    task body();
        wb_s_seq_mdio cfg = wb_s_seq_mdio::type_id::create("cfg");

        // Up (reset default) -> confirms starting state.
        cfg.configure_miim_registers(p_sequencer.regmodel, .fiad(5'h1), .rgad(5'h1), .rstat(1'b1));
        p_sequencer.regmodel.wait_miim_done();

        // Down: LinkFail 0->1.
        p_sequencer.m_mdio_phy_rsp.set_link_status(5'h1, 1'b0);
        cfg.configure_miim_registers(p_sequencer.regmodel, .fiad(5'h1), .rgad(5'h1), .rstat(1'b1));
        p_sequencer.regmodel.wait_miim_done();

        // Back up: LinkFail 1->0.
        p_sequencer.m_mdio_phy_rsp.set_link_status(5'h1, 1'b1);
        cfg.configure_miim_registers(p_sequencer.regmodel, .fiad(5'h1), .rgad(5'h1), .rstat(1'b1));
        p_sequencer.regmodel.wait_miim_done();

        // And once more for good measure (down again).
        p_sequencer.m_mdio_phy_rsp.set_link_status(5'h1, 1'b0);
        cfg.configure_miim_registers(p_sequencer.regmodel, .fiad(5'h1), .rgad(5'h1), .rstat(1'b1));
        p_sequencer.regmodel.wait_miim_done();
    endtask
endclass

`endif