//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : mii_tx_seq_item_pkg.sv
// Author   : Wael
// Date     : 2026-07-5
//------------------------------------------------------------------------------
// Description:
//   Package contain all mii tx master transactions.
//==============================================================================

`ifndef MII_TX_SEQ_ITEM_PKG_SV
`define MII_TX_SEQ_ITEM_PKG_SV

package mii_tx_seq_item_pkg;

    `include "uvm_macros.svh"
     import uvm_pkg::*;

    import eth_glob_pkg::*;

    `include "mii_tx_seq_item_base.sv";

endpackage : mii_tx_seq_item_pkg
`endif // MII_TX_SEQ_ITEM_PKG_SV