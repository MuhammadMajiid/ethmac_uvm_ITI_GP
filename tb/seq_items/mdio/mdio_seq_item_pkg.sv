//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : mdio_seq_item_pkg.sv
// Author   : Majid
// Date     : 2026-07-5
//------------------------------------------------------------------------------
// Description:
//   Package contain all MDIO transactions.
//==============================================================================

`ifndef MDIO_SEQ_ITEM_PKG_SV
`define MDIO_SEQ_ITEM_PKG_SV
package mdio_seq_item_pkg;

    `include "uvm_macros.svh"
    import uvm_pkg::*;

    import eth_glob_pkg::*;

    `include "mdio_seq_item_base.sv";

endpackage : mdio_seq_item_pkg

`endif // MDIO_SEQ_ITEM_PKG_SV
