//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_m_seq_pkg.sv
// Author   : Wael
// Date     : 2026-06-26
//------------------------------------------------------------------------------
// Description:
//   Package for including wisbone master sequences.
//==============================================================================

`ifndef WB_M_SEQ_PKG_SV
`define WB_M_SEQ_PKG_SV

package wb_m_seq_pkg;

    `include "uvm_macros.svh"
    import uvm_pkg::*;

    // Global package
    import eth_glob_pkg::*;
    // Transaction object package
    import wb_m_seq_item_pkg::*;
    // Agent package (include only sequencer)
    import wb_m_agent_pkg::wb_m_sequencer_base;
    // Sequences
    `include "wb_m_seq_base.sv"
    `include "wb_m_seq_smoke.sv"
    `include "wb_m_seq_wr_rd.sv"
    `include "wb_m_seq_wait.sv"

endpackage : wb_m_seq_pkg

`endif // WB_M_SEQ_PKG_SV
