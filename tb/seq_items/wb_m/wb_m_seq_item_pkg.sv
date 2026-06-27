//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_m_seq_item_pkg.sv
// Author   : Wael
// Date     : 2026-06-26
//------------------------------------------------------------------------------
// Description:
//   Package contain all wishbone master transactions.
//==============================================================================

`ifndef WB_M_SEQ_ITEM_PKG_SV
`define WB_M_SEQ_ITEM_PKG_SV
package wb_m_seq_item_pkg;

    `include "uvm_macros.svh"
     import uvm_pkg::*;

    import eth_glob_pkg::*;

    `include "wb_m_seq_item_base.sv";

endpackage 

`endif // WB_M_SEQ_ITEM_PKG_SV