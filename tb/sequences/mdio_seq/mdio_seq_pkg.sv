//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : mdio_seq_pkg.sv
//------------------------------------------------------------------------------
// Description:
//   Package for including MDIO agent sequences. Mirrors the structure of
//   wb_s_seq_pkg.sv / mii_tx_seq_pkg.sv.
//
//   NOTE: mdio_seq_base.sv existed in the repo before this package did, but
//   was never `included by anything -- it was an orphan file not part of
//   any compiled package. This file fixes that in addition to adding the
//   new PHY responder sequence (mdio_seq_phy_responder.sv).
//==============================================================================
`timescale 1ns/1ps

`ifndef MDIO_SEQ_PKG_SV
`define MDIO_SEQ_PKG_SV

package mdio_seq_pkg;
    `include "uvm_macros.svh"
    import uvm_pkg::*;

    // Global package (op_code_e, ETH_CTRL_* parameters)
    import eth_glob_pkg::*;

    // Transaction item + sequencer package
    import mdio_agent_pkg::mdio_seq_item_base;
    import mdio_agent_pkg::mdio_sequencer_base;

    // wb_s_seq_mdio.sv extends wb_s_seq_base and drives regmodel updates
    // through the wb_s bus, so both need to be visible here. wb_s_seq_pkg
    // is guaranteed to already be compiled at this point (compile.tcl
    // orders it before mdio_seq_pkg).
    import wb_s_seq_pkg::wb_s_seq_base;
    import eth_ral_pkg::eth_reg_block;

    // Sequences
    `include "mdio_seq_base.sv"
    `include "mdio_seq_phy_responder.sv"
    // `include "wb_s_seq_mdio.sv"
    // `include "../wb_s_seq/wb_s_seq_mdio.sv"

endpackage : mdio_seq_pkg

`endif // MDIO_SEQ_PKG_SV
