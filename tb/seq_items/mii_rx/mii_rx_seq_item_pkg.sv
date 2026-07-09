//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : mii_rx_seq_item_pkg.sv
// Author   : Mariam
// Date     : 2026-07-9
//------------------------------------------------------------------------------
// Description:
//   Package contain all mii tx master transactions.
//==============================================================================

`ifndef MII_RX_SEQ_ITEM_PKG_SV
`define MII_RX_SEQ_ITEM_PKG_SV

package mii_rx_seq_item_pkg;

    `include "uvm_macros.svh"
     import uvm_pkg::*;

    import eth_glob_pkg::*;

    `include "mii_rx_seq_item.sv";

endpackage : mii_rx_seq_item_pkg
`endif // MII_RX_SEQ_ITEM_PKG_SV