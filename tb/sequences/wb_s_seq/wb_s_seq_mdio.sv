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

    extern task configure_miim_registers(
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
    bit [7:0]  clkdiv    = 8'h64,
    bit        miinopre  = 1'b0,
    bit [4:0]  fiad      = 5'h0,
    bit [4:0]  rgad      = 5'h0,
    bit [15:0] ctrl_data = 16'h0000,
    bit        wctrldata = 1'b0,
    bit        rstat     = 1'b0,
    bit        scanstat  = 1'b0
);
    if (!$onehot0({wctrldata, rstat, scanstat}))
        `uvm_fatal("MIIM_CONFIG",
                   "Only one of WCTRLDATA, RSTAT, and SCANSTAT may be set")

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
