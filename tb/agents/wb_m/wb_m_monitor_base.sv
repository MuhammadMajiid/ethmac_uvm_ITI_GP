//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_m_monitor_base.sv
// Author   : Wael
// Date     : 2026-06-24
//------------------------------------------------------------------------------
// Description:
//   Monitor for wishbone master agent. It converts pin level signals into 
//   transactions and sends through 2 analysis ports, the first for coverage and
//   the second for sequencer (if it's request, sequence will send stimulus).
//==============================================================================
`ifndef WB_M_MONITOR_BASE_SV
`define WB_M_MONITOR_BASE_SV

class wb_m_monitor_base extends uvm_monitor;

    `uvm_component_utils(wb_m_monitor_base)


    uvm_analysis_port #(wb_m_seq_item_base) transaction_a_port;     // For Scoreboard & Coverage
    uvm_analysis_port #(wb_m_seq_item_base) request_a_port;         // For Sequencer


    virtual wb_master_if     vif;
    wb_master_config_obj     m_config;

    
    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    extern function new(string name, uvm_component parent);    

    // -------------------------------------------------------------------------
    //  Build Phase
    // -------------------------------------------------------------------------
    extern function build_phase(uvm_phase phase);

    // -------------------------------------------------------------------------
    //  Run Phase
    // -------------------------------------------------------------------------
    extern task run_phase(uvm_phase phase);


endclass : wb_m_monitor_base


// =============================================================================
//  IMPLEMENTATION
// =============================================================================


// Function : new (Constructor)
function wb_m_monitor_base::new (string name, uvm_component parent);
    super.new(name, parent);
endfunction

// Function: build_phase
function void build_phase(uvm_phase phase);
    super.build(phase);
    transaction_a_port = new("transaction_a_port", this);
    request_a_port     = new("request_a_port", this);
endfunction    

// Task : run_phase
task wb_m_monitor_base::run_phase(uvm_phase phase);

endtask


`endif // WB_M_MONITOR_BASE_SV
