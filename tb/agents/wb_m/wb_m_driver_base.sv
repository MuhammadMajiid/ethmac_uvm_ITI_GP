//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_m_driver_base.sv
// Author   : Wael
// Date     : 2026-06-24
//------------------------------------------------------------------------------
// Description:
//   Base driver for wishbone master interface. Drives wishbone slave pins based
//   on wb_m_seq_item sequences via virtual interface.
//==============================================================================
`ifndef WB_M_DRIVER_BASE_SV
`define WB_M_DRIVER_BASE_SV

class wb_m_driver_base extends uvm_driver #(wb_m_seq_item_base);

    `uvm_component_utils(wb_m_driver_base)


    virtual wb_m_if          vif;           
    wb_m_seq_item_base       m_item;    
    int                      m_item_cnt;    // for counting no. of driven transactions


    extern function new (string name, uvm_component parent);
    extern task run_phase(uvm_phase phase);
    // -------------------------------------------------------------------------
    //  task : reset_items
    // -------------------------------------------------------------------------
    // Description:
    //   At 0 runtime drive all pin level inputs eith 0 to prevent x/z
    //   propagation.
    //
    // Arguments: None
    //
    // -------------------------------------------------------------------------
    extern task reset_items();
    // -------------------------------------------------------------------------
    //  task : drive_items
    // -------------------------------------------------------------------------
    // Description:
    //   Get transactions from sequencer and drive pin level inputs with fields
    //   in transactions. Has to be virtual because the driver may be replaced
    //   with factory override with child has new implementation.
    //
    // Arguments: None
    //
    // -------------------------------------------------------------------------
    extern virtual task drive_items();
    // -------------------------------------------------------------------------
    //  Report Phase
    // -------------------------------------------------------------------------
    extern function void report_phase(uvm_phase phase);

endclass : wb_m_driver_base


// =============================================================================
//  IMPLEMENTATION
// =============================================================================

// Function : new (Constructor)
function wb_m_driver_base::new (string name, uvm_component parent);
    super.new(name, parent);
endfunction

// Task: run_phase
task wb_m_driver_base::run_phase(uvm_phase phase);
    super.run_phase(phase);
    reset_items();
    forever begin
        // Get the next item from the sequencer
        seq_item_port.get_next_item(m_item);
        `uvm_info(get_type_name(), $sformatf("time: %0t , Got a request item",$time), UVM_DEBUG)

        drive_items();

        `uvm_info(get_type_name(), $sformatf("time %0t, Item no. %0d driven successfully",$time,m_item_cnt), UVM_DEBUG)
        // Increment number of driven transactions
        m_item_cnt++;    
        seq_item_port.item_done();
    end    

endtask

// Task: reset_items
task wb_m_driver_base::reset_items();
    vif.cb.m_ack_i<=0;
    vif.cb.m_err_i<=0;
    vif.cb.m_data_i<=0;
    @(posedge vif.clk_i);
endtask

// Task: drive_items
task wb_m_driver_base::drive_items();


    @(posedge vif.clk_i);

    // Drive pin level DUT signals
    vif.cb.m_ack_i<=m_item.m_ack_i;
    vif.cb.m_err_i<=m_item.m_err_i;
    vif.cb.m_data_i<=m_item.m_data_i;

    `uvm_info(get_type_name(),m_item.convert2string(), UVM_DEBUG)

endtask

// Function: report_phase
function void wb_m_driver_base::report_phase(uvm_phase phase);
  super.report_phase(phase);
  `uvm_info(get_type_name(), $sformatf("Drived %0d active transactions", m_item_cnt), UVM_LOW)
endfunction : report_phase

`endif // WB_M_DRIVER_BASE_SV
