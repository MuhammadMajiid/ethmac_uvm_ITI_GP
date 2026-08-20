//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_m_seq_base.sv
// Author   : Wael
// Date     : 2026-07-06
//------------------------------------------------------------------------------
// Description:
//   This is the basic sequence that all other sequences extend from it, it
//   declare trnsaction handles and p_sequencer handle whivh is the sequencer
//   the sequence runs on.
//==============================================================================

`ifndef WB_M_SEQ_BASE_SV
`define WB_M_SEQ_BASE_SV

class wb_m_seq_base extends uvm_sequence #(wb_m_seq_item_base);

    `uvm_object_utils(wb_m_seq_base)
    `uvm_declare_p_sequencer (wb_m_sequencer_base)


    wb_m_seq_item_base m_req_item;  // contains the slave response to master.
    wb_m_seq_item_base m_rsp_item;  // captures the Wishbone request made by the DUT.

    function new(string name = "");
        super.new(name);
    endfunction

endclass : wb_m_seq_base

`endif // WB_M_SEQ_BASE_SV
