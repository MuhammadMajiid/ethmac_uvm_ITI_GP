//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_s_seq_item_pkg.sv
// Author   : Wael
// Date     : 2026-07-5
//------------------------------------------------------------------------------
// Description:
//   Package contain all wishbone slave transactions.
//==============================================================================

`ifndef WB_S_SEQ_ITEM_PKG_SV
`define WB_S_SEQ_ITEM_PKG_SV
package wb_s_seq_item_pkg;

    `include "uvm_macros.svh"
    import uvm_pkg::*;

    import eth_glob_pkg::*;

    `include "wb_s_seq_item_base.sv";
    `include "wb_s_seq_item_tx.sv";

endpackage : wb_s_seq_item_pkg

`endif // WB_S_SEQ_ITEM_PKG_SV