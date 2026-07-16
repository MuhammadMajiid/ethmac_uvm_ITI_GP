//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : reset_seq_item_pkg.sv
// Author   : Nada
// Date     : 2026-07-16
//------------------------------------------------------------------------------
// Description:
//   Package contain the reset sequence item.
//==============================================================================

`ifndef RESET_SEQ_ITEM_PKG_SV
`define RESET_SEQ_ITEM_PKG_SV
package reset_seq_item_pkg;

    `include "uvm_macros.svh"
    import uvm_pkg::*;

    import eth_glob_pkg::*;

    `include "reset_seq_item.sv";

endpackage : reset_seq_item_pkg

`endif // RESET_SEQ_ITEM_PKG_SV