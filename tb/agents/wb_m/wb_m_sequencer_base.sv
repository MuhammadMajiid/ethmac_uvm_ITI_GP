//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_m_sequencer_base.sv
// Author   : Wael
// Date     : 2026-06-24
//------------------------------------------------------------------------------
// Description:
//   Sequencer for wishbone master agent. In addition to sending transactons to
//   driver, it receives requests from monitor on separate analysis port.
//==============================================================================
`ifndef WB_M_SEQUENCER_BASE_SV
`define WB_M_SEQUENCER_BASE_SV

class wb_m_sequencer_base extends uvm_sequencer #(wb_m_seq_item_base);

    `uvm_component_utils(wb_m_sequencer_base)

    uvm_analysis_export     #(wb_m_seq_item_base) request_export;   // Export connected to monitor request port
    uvm_tlm_analysis_fifo   #(wb_m_seq_item_base) request_fifo;     // FIFO storing upcoming requests from monitor

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    //--------------------------------------------------------------------------
    // Build phase
    //--------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build(phase);
        request_fifo   = new("request_fifo", this);
        request_export = new("request_export", this);
    endfunction    

    //--------------------------------------------------------------------------
    // Connect Phase 
    //--------------------------------------------------------------------------
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        request_export.connect(request_fifo.analysis_export);
    endfunction

endclass : wb_m_sequencer_base

`endif // WB_M_SEQUENCER_BASE_SV
