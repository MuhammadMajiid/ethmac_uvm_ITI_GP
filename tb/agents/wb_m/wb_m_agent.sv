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
        super.build_phase(phase)
        if (!uvm_config_db #(wb_m_config_obj)::get(this, "", "config", m_config))
            `uvm_fatal(get_type_name(), "wb_m_config_obj not found in config_db")

        // Propagate same config object to children
        uvm_config_db #(wb_m_config_obj)::set(this, "m_driver",  "config", m_config);
        uvm_config_db #(wb_m_config_obj)::set(this, "m_monitor", "config", m_config);

        if (get_is_active() == UVM_ACTIVE) begin
            m_sequencer = wb_m_sequencer_base   ::type_id::create("m_sequencer", this);
            m_driver    = wb_m_driver_base::type_id::create("m_driver",    this);
        end

        m_monitor      = wb_m_monitor_base::type_id::create("m_monitor", this);
        a_port         = new("a_port", this);
    endfunction

    //--------------------------------------------------------------------------
    // Connect Phase 
    //--------------------------------------------------------------------------
    function void connect_phase(uvm_phase phase);
        if (get_is_active() == UVM_ACTIVE) begin
            m_driver.seq_item_port.connect(m_sequencer.seq_item_export);
            m_monitor.request_a_port.connect(m_sequencer.request_export);
        end
            m_monitor.transaction_a_port.connect(a_port);
    endfunction

    // -------------------------------------------------------------------------
    //  function : get_is_active
    // -------------------------------------------------------------------------
    // Description:
    //   Get the configured state of the agent if it's active or passive.
    //
    // Arguments: None
    //
    // Returns :
    // uvm_active_passive_enum: Enum holds 2 values UVM_ACTIVE or UVM_PASSIVE
    // -------------------------------------------------------------------------
    virtual function uvm_active_passive_enum get_is_active();
        return uvm_active_passive_enum'(m_config.is_active);
    endfunction

endclass : wb_m_agent

`endif // WB_M_AGENT_SV
