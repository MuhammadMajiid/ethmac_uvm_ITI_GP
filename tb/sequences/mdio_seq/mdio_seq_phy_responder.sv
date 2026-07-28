//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : mdio_seq_phy_responder.sv
// Description:
//   Background "PHY model" sequence for the MDIO agent.
//
//   mdio_driver_base (tb/agents/mdio/mdio_driver_base.sv) already emulates
//   a PHY on the wire: when it decodes a READ frame (ST=01, OP=10) it calls
//   seq_item_port.get_next_item(req) and drives req.data back onto mdio_in.
//   That call blocks until *some* sequence is running on m_mdio_sqr and
//   reaches finish_item(). Previously nothing ever started a sequence on
//   the MDIO sequencer, so any test that issues MIISTATUS.RSTAT or
//   MIISTATUS.SCANSTAT would hang the simulation indefinitely with the
//   driver parked in get_next_item().
//
//   This sequence plugs that gap: it runs forever, and on every request
//   from the driver it hands back the current value of `phy_data`.
//   phy_data is a plain (non-rand) public field, not re-randomized every
//   iteration, so a virtual sequence can hold a handle to a running
//   instance and update phy_data live -- the change is picked up on the
//   very next PHY response, no extra synchronization required.
//
//   Bit[2] of phy_data is the standard MII "Link Status" bit (1 = link
//   up). eth_mdio_scoreboard::comp_linkfail() checks MIISTATUS.LINKFAIL
//   against the inverse of this bit whenever RGAD == 5'h01, so a linkfail
//   test case flips it to 0 to model a down link.
//
//   Usage (from a virtual sequence, started once and left running for the
//   rest of the test):
//     mdio_seq_phy_responder phy_rsp = mdio_seq_phy_responder::type_id::create("phy_rsp");
//     fork
//       phy_rsp.start(p_sequencer.m_mdio_sqr);
//     join_none
//     ...
//     phy_rsp.phy_data[2] = 1'b0; // simulate link-down for a linkfail test
//==============================================================================
`ifndef MDIO_SEQ_PHY_RESPONDER_SV
`define MDIO_SEQ_PHY_RESPONDER_SV

class mdio_seq_phy_responder extends mdio_seq_base;
    `uvm_object_utils(mdio_seq_phy_responder)

    // Value returned on the next READ frame. Default = link-up (bit[2]=1),
    // all other bits 0. Not `rand` on purpose: this is meant to be driven
    // deterministically by whichever virtual sequence owns the test's
    // intent, not randomized underneath it.
    bit [15:0] phy_data = 16'h0004;

    function new(string name = "mdio_seq_phy_responder");
        super.new(name);
    endfunction

    virtual task body();
        mdio_seq_item_base req;

        forever begin
            req = mdio_seq_item_base::type_id::create("req");
            start_item(req);
            req.data = phy_data;
            finish_item(req);
        end
    endtask

endclass

`endif // MDIO_SEQ_PHY_RESPONDER_SV
