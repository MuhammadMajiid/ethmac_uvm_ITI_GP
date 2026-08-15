//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_m_monitor_base.sv
// Author   : Wael
// Date     : 2026-06-24
//------------------------------------------------------------------------------
// Description:
//   Monitor for wishbone master agent. It converts pin level signals into 
//   transactions and sends it to coverage collector & scoreboard through 
//   analysis port.
//==============================================================================
`ifndef WB_M_MONITOR_BASE_SV
`define WB_M_MONITOR_BASE_SV

class wb_m_monitor_base extends uvm_monitor;

    `uvm_component_utils(wb_m_monitor_base)


    uvm_analysis_port #(wb_m_seq_item_base) a_port;     // For Scoreboard & Coverage

    int m_item_cnt;                                     // for counting no. of monitored transactions

    virtual wb_m_if     vif;
    

    extern function new(string name, uvm_component parent);    
    extern function void build_phase(uvm_phase phase);
    extern task run_phase(uvm_phase phase);
    // -------------------------------------------------------------------------
    //  task : mon_reset
    // -------------------------------------------------------------------------
    // Description:
    //   Wait until deassertion of reset.
    //
    // Arguments: None
    //
    // -------------------------------------------------------------------------
    extern task mon_reset();
    // -------------------------------------------------------------------------
    //  task : mon_items
    // -------------------------------------------------------------------------
    // Description:
    //   Convert pin level signals into transaction fields then broadcast it 
    //   to sequencer analysis port and agent analysis port.
    //
    // Arguments: None
    //
    // -------------------------------------------------------------------------
    extern task mon_items(wb_m_seq_item_base m_item);
    extern function void report_phase(uvm_phase phase);

endclass : wb_m_monitor_base

// =============================================================================
//  IMPLEMENTATION
// =============================================================================


// Function : new (Constructor)
function wb_m_monitor_base::new (string name, uvm_component parent);
    super.new(name, parent);
endfunction

// Function: build_phase
function void wb_m_monitor_base::build_phase(uvm_phase phase);
    super.build_phase(phase);
    a_port = new("a_port", this);
endfunction    

// Task : run_phase
task wb_m_monitor_base::run_phase(uvm_phase phase);
    wb_m_seq_item_base m_item;
    
    mon_reset();

    forever begin

        m_item = wb_m_seq_item_base::type_id::create("m_item");
        mon_items(m_item);

        // Check if it's valid transaction       
        // Send transaction to agent analysis port
        a_port.write(m_item);
        `uvm_info(get_type_name(), $sformatf("Item no. %0d monitored successfully",m_item_cnt), UVM_DEBUG)
        // Increment number of monitored transactions
        m_item_cnt++;
    end    
endtask

// Task: mon_reset
task wb_m_monitor_base::mon_reset();
    // Reset deassertion 
    @(negedge vif.rst_i);
     `uvm_info(get_type_name(),"Begin monitoring after reset deassertion", UVM_LOW)
endtask    

// Task: mon_items
task wb_m_monitor_base::mon_items(wb_m_seq_item_base m_item);

    // Wait until clocking block triggers at positive edge
    @(negedge vif.clk_i);
    
    // DUT input signals -> output from testbench
    m_item.m_err_i=vif.m_err_i;
    m_item.m_ack_i=vif.m_ack_i;
    m_item.m_data_i=vif.m_data_i;
    
    // DUT output signals -> input to testbench
    m_item.m_addr_o=vif.m_addr_o;
    m_item.m_cyc_o=vif.m_cyc_o;
    m_item.m_sel_o=vif.m_sel_o;
    m_item.m_stb_o=vif.m_stb_o;
    m_item.m_data_o=vif.m_data_o;
    m_item.m_dir=wb_dir_t'(vif.m_we_o);

    `uvm_info(get_type_name(),m_item.convert2string(), UVM_DEBUG)

endtask

// report_phase
function void wb_m_monitor_base::report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), $sformatf("Monitored %0d TRANSACTIONS", m_item_cnt), UVM_LOW)
endfunction
`endif // WB_M_MONITOR_BASE_SV
