//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : mii_tx_seq_pkg.sv
// Author   : Wael
// Date     : 2026-07-14
//------------------------------------------------------------------------------
// Description:
//   Package for including wisbone master sequences.
//==============================================================================

`ifndef MII_TX_SEQ_PKG_SV
`define MII_TX_SEQ_PKG_SV

package mii_tx_seq_pkg;

    `include "uvm_macros.svh"
    import uvm_pkg::*;

    // Global package
    import eth_glob_pkg::*;
    // Transaction object package
    import mii_tx_seq_item_pkg::*;

    // Sequences
    `include "mii_tx_seq_base.sv"

endpackage : mii_tx_seq_pkg

`endif // MII_TX_SEQ_PKG_SV
