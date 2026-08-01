//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_s_seq_mdio.sv
// Description:
// Wishbone slave sequence helper for configuring the writable MIIM registers.
//==============================================================================
`ifndef WB_S_SEQ_MDIO_SV
`define WB_S_SEQ_MDIO_SV

class wb_s_seq_mdio extends wb_s_seq_base;

    `uvm_object_utils(wb_s_seq_mdio)

    function new(string name = "wb_s_seq_mdio");
        super.new(name);
    endfunction

    // NOTE: this task is called as a plain helper method on a freshly
    // `type_id::create()`d object -- it is never `.start()`ed on a
    // sequencer. That means any `regmodel` field inherited from
    // wb_s_seq_base (which only gets populated inside body(), i.e. only
    // once a sequence actually runs) would still be null here. regmodel is
    // therefore passed in explicitly by the caller (typically
    // p_sequencer.regmodel from a virtual sequence) instead.
    extern task configure_miim_registers(
        eth_reg_block regmodel,
        bit [7:0]  clkdiv    = 8'h64,
        bit        miinopre  = 1'b0,
        bit [4:0]  fiad      = 5'h0,
        bit [4:0]  rgad      = 5'h0,
        bit [15:0] ctrl_data = 16'h0000,
        bit        wctrldata = 1'b0,
        bit        rstat     = 1'b0,
        bit        scanstat  = 1'b0
    );

endclass : wb_s_seq_mdio

task wb_s_seq_mdio::configure_miim_registers(
    eth_reg_block regmodel,
    bit [7:0]  clkdiv    = 8'h64,
    bit        miinopre  = 1'b0,
    bit [4:0]  fiad      = 5'h0,
    bit [4:0]  rgad      = 5'h0,
    bit [15:0] ctrl_data = 16'h0000,
    bit        wctrldata = 1'b0,
    bit        rstat     = 1'b0,
    bit        scanstat  = 1'b0
);
    uvm_status_e status; // was missing -- update() calls below need it
    // if (!$onehot0({wctrldata, rstat, scanstat}))
    //     `uvm_fatal("MIIM_CONFIG",
    //                "Only one of WCTRLDATA, RSTAT, and SCANSTAT may be set")

    // Downgraded from `uvm_fatal -- v_seq_tc_miim_priority (TC10) deliberately
    // sets more than one of these bits at once, on purpose, to observe how
    // the DUT's hardware arbitrates between simultaneous MIIM commands. A
    // fatal here was blocking that test before it ever reached the bus write.
    if (!$onehot0({wctrldata, rstat, scanstat}))
        `uvm_warning("MIIM_CONFIG",
                   "More than one of WCTRLDATA/RSTAT/SCANSTAT set -- intentional for priority/arbitration testing")

    `uvm_info("MIIM_CONFIG", "Configuring MIIM registers", UVM_MEDIUM)

    regmodel.MIIMODER.CLKDIV.set(clkdiv);
    regmodel.MIIMODER.MIINOPRE.set(miinopre);
    regmodel.MIIMODER.update(status);

    regmodel.MIIADDRESS.FIAD.set(fiad);
    regmodel.MIIADDRESS.RGAD.set(rgad);
    regmodel.MIIADDRESS.update(status);

    regmodel.MIITX_DATA.CTRLDATA.set(ctrl_data);
    regmodel.MIITX_DATA.update(status);

    // Command bits trigger the MIIM transaction, so update them last.
    regmodel.MIICOMMAND.WCTRLDATA.set(wctrldata);
    regmodel.MIICOMMAND.RSTAT.set(rstat);
    regmodel.MIICOMMAND.SCANSTAT.set(scanstat);
    regmodel.MIICOMMAND.update(status);

    regmodel.MIICOMMAND.WCTRLDATA.set(wctrldata);
regmodel.MIICOMMAND.RSTAT.set(rstat);
regmodel.MIICOMMAND.SCANSTAT.set(scanstat);
regmodel.MIICOMMAND.update(status);

// WCTRLDATA/RSTAT self-clear in real hardware once the operation
// completes, but nothing else in the TB ever re-reads MIICOMMAND to tell
// the RAL mirror that happened -- so update() silently skips the *next*
// identical command (desired == stale mirror => "no change needed").
// predict() corrects the mirror's bookkeeping with no bus transaction, so
// the next call's update() detects a real change again. SCANSTAT is left
// out on purpose: it's level-held for a continuous scan, not self-
// clearing, and TC12's explicit all-zero "clear" call already produces a
// genuine write that keeps its mirror accurate.
regmodel.MIICOMMAND.WCTRLDATA.predict(1'b0);
regmodel.MIICOMMAND.RSTAT.predict(1'b0);
// regmodel.MIICOMMAND.SCANSTAT.predict(1'b0);

    `uvm_info(
        "MIIM_CONFIG",
        $sformatf(
            "CLKDIV=%0d, MIINOPRE=%0d, FIAD=%0d, RGAD=%0d, CTRLDATA=0x%04h, WCTRLDATA=%0d, RSTAT=%0d, SCANSTAT=%0d",
            clkdiv, miinopre, fiad, rgad, ctrl_data,
            wctrldata, rstat, scanstat
        ),
        UVM_MEDIUM
    )
endtask

`endif // WB_S_SEQ_MDIO_SV
