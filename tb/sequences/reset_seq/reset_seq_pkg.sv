//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : reset_seq_pkg.sv
// Author   : Nada
// Date     : 2026-07-16
//------------------------------------------------------------------------------
// Description:
//   Package for including reset sequence.
//==============================================================================

`ifndef RESET_SEQ_PKG_SV
`define RESET_SEQ_PKG_SV

package reset_seq_pkg;

    `include "uvm_macros.svh"
    import uvm_pkg::*;

    // Global package
    import eth_glob_pkg::*;
    // Transaction object package
    import reset_seq_item_pkg::*;
    

    // Sequences
    `include "reset_seq.sv"

endpackage : reset_seq_pkg

`endif // RESET_SEQ_PKG_SV
