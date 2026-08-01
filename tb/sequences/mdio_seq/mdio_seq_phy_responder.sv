//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : mdio_seq_phy_responder.sv
// Description:
//   Background "PHY model" sequence for the MDIO agent.
//
//   Models per-(FIAD,RGAD) PHY register content instead of one flat value.
//   Only reg0 (Control) and reg1 (Status) get real semantics, per the
//   standard MII register map:
//     Reg0 Control : [15]=Reset(self-clear)   [14]=Loopback
//                     [13]=Speed Selection     [12]=AutoNeg Enable
//                     [11]=Power Down          [10]=Isolate
//                     [9]=Restart AutoNeg(self-clear) [8]=Duplex Mode
//                     [7]=Collision Test       [6:0]=Reserved (RO, 0)
//     Reg1 Status  : entirely RO. [2]=Link Status is the bit
//                     eth_mdio_scoreboard::comp_linkfail() checks.
//   Any other (FIAD,RGAD) stays a plain read/write slot defaulting to 0 --
//   enough for the framing-only test cases that don't care about PHY
//   register content.
//
//   mdio_driver_base talks to THIS OBJECT DIRECTLY (via a config_db handle,
//   see mdio_driver_base.sv) for the actual data value on both reads and
//   writes. get_next_item()/item_done() are still used, but purely as the
//   synchronization mechanism that originally prevented RSTAT/SCANSTAT
//   from hanging forever with no sequence running -- the sequence has no
//   way to know which (FIAD,RGAD) is being asked for until well after
//   start_item()/finish_item() would already have committed a response,
//   so the response VALUE can no longer travel through the item itself.
//
//   Usage (from a virtual sequence, started once and left running for the
//   rest of the test):
//     mdio_seq_phy_responder phy_rsp = mdio_seq_phy_responder::type_id::create("phy_rsp");
//     fork phy_rsp.start(p_sequencer.m_mdio_sqr); join_none
//     ...
//     phy_rsp.set_link_status(5'h1, 1'b0); // simulate link-down on PHY 1
//==============================================================================
`ifndef MDIO_SEQ_PHY_RESPONDER_SV
`define MDIO_SEQ_PHY_RESPONDER_SV

class mdio_seq_phy_responder extends mdio_seq_base;
    `uvm_object_utils(mdio_seq_phy_responder)

    // Per-PHY, per-register storage. Key = {FIAD[4:0], RGAD[4:0]}.
    // Lazily initialized to the reset defaults below the first time a
    // given (FIAD,RGAD) is touched.
    protected bit [15:0] phy_regs[bit [9:0]];

    localparam bit [15:0] REG0_RESET_VAL = 16'h1000; // AutoNeg Enable=1, rest 0
    localparam bit [15:0] REG1_RESET_VAL = 16'h0004; // Link Status=1 (up), rest 0

    function new(string name = "mdio_seq_phy_responder");
        super.new(name);
    endfunction

    // ------------------------------------------------------------------
    // get_reg / put_reg -- the actual register model. All reg0/reg1
    // semantics live here so the driver and any virtual sequence share
    // one consistent view of "what the PHY currently holds."
    // ------------------------------------------------------------------
    function bit [15:0] get_reg(bit [4:0] fiad, bit [4:0] rgad);
        bit [9:0] key = {fiad, rgad};
        if (!phy_regs.exists(key)) begin
            case (rgad)
                5'h00:   phy_regs[key] = REG0_RESET_VAL;
                5'h01:   phy_regs[key] = REG1_RESET_VAL;
                default: phy_regs[key] = 16'h0000;
            endcase
        end
        return phy_regs[key];
    endfunction

    function void put_reg(bit [4:0] fiad, bit [4:0] rgad, bit [15:0] wr_data);
        bit [9:0] key = {fiad, rgad};
        void'(get_reg(fiad, rgad)); // seed the default before touching it

        if (rgad == 5'h00) begin
            // Latch the 8 real RW bits [14:7] (Loopback, Speed, AutoNeg
            // Enable, Power Down, Isolate, Restart AutoNeg, Duplex,
            // Collision Test) as written.
            phy_regs[key][14:7] = wr_data[14:7];
            phy_regs[key][6:0]  = 7'h0;   // reserved, always reads 0
            // Bit[15] Reset and bit[9] Restart AutoNeg are self-clearing
            // on real hardware -- modeled as "already done" by the next
            // read rather than tracking a multi-cycle process.
            phy_regs[key][15] = 1'b0;
            phy_regs[key][9]  = 1'b0;
        end
        else if (rgad == 5'h01) begin
            // Reg1 is entirely RO -- a host write is a protocol-level
            // no-op on real hardware; nothing on the wire flags it as an
            // error, so just log it and drop the data.
            `uvm_info(get_type_name(), $sformatf(
                "Write to read-only PHY Status reg ignored (FIAD=%0d, data=0x%0h)",
                fiad, wr_data), UVM_MEDIUM)
        end
        else begin
            phy_regs[key] = wr_data; // unmodeled register: plain rd/wr slot
        end
    endfunction

    // ------------------------------------------------------------------
    // set_link_status -- convenience wrapper for the common "simulate
    // link up/down" case. Replaces the old direct `phy_data[2] = ...`
    // usage now that content is tracked per-register instead of flat.
    // ------------------------------------------------------------------
    function void set_link_status(bit [4:0] fiad, bit up);
        bit [15:0] reg1 = get_reg(fiad, 5'h01);
        reg1[2] = up;
        phy_regs[{fiad, 5'h01}] = reg1;
    endfunction

    // ------------------------------------------------------------------
    // body -- still runs forever pulling generic items so a sequence is
    // always present on m_mdio_sqr (see FIX HISTORY above). The driver no
    // longer reads req.data for the answer -- see mdio_driver_base.sv.
    // ------------------------------------------------------------------
    virtual task body();
        mdio_seq_item_base req;
        forever begin
            req = mdio_seq_item_base::type_id::create("req");
            start_item(req);
            finish_item(req);
        end
    endtask

endclass

`endif // MDIO_SEQ_PHY_RESPONDER_SV