//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_m_agent.sv
// Author   : Wael
// Date     : 2026-06-24
//------------------------------------------------------------------------------
// Description:
//   Agent for wishbone master interface.it acts as a wishbone slave to the DUT.
//   It's reactive agent that doesn't respond to DUT until it receives request.
//==============================================================================
`ifndef WB_M_AGENT_SV
`define WB_M_AGENT_SV

class wb_m_agent extends uvm_agent;

    `uvm_component_utils(wb_m_agent)

    uvm_analysis_port #(wb_m_seq_item_base) a_port;     // Analysis Port

    //--------------------------------------------------------------------------
    // Sub-component handles
    //--------------------------------------------------------------------------
    wb_m_sequencer_base     m_sequencer;
    wb_m_driver_base        m_driver;
    wb_m_monitor_base       m_monitor;


    wb_m_config_obj         m_config;               // Configuration object

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
        super.build_phase(phase);
        
        // Get config object from database
        if (!uvm_config_db #(wb_m_config_obj)::get(this, "", "config", m_config))
            `uvm_fatal(get_type_name(), "wb_m_config_obj not found in config_db")

        // Instantiate driver & monitor if the agent is active
        if (m_config.is_active == UVM_ACTIVE) begin
            m_sequencer = wb_m_sequencer_base::type_id::create("m_sequencer", this);
            m_driver    = wb_m_driver_base::type_id::create("m_driver",    this);
        end

        // Instantiate monitor
        m_monitor      = wb_m_monitor_base::type_id::create("m_monitor", this);     
        // Instantiate analysis port of agent
        a_port         = new("a_port", this);                                       
    endfunction

    //--------------------------------------------------------------------------
    // Connect Phase 
    //--------------------------------------------------------------------------
    function void connect_phase(uvm_phase phase);
        if (m_config.is_active== UVM_ACTIVE) begin
            // Connect driver port to sequencer Export
            m_driver.seq_item_port.connect(m_sequencer.seq_item_export);            
            // Connect request analysis port in monitor to analysis export in sequencer
            m_monitor.request_a_port.connect(m_sequencer.request_export);           
            // Assign driver vif handle to that in config object
           m_driver.vif= m_config.vif;
        end
        // Connect transaction analysis port of monitor to analysis port of agent
        m_monitor.transaction_a_port.connect(a_port);
        // Assign monitor vif handle to that in config object
        m_monitor.vif= m_config.vif;
    endfunction


endclass : wb_m_agent

`endif // WB_M_AGENT_SV
