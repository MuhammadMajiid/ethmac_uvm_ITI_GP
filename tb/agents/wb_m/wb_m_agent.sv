
`ifndef WB_M_AGENT_SV
`define WB_M_AGENT_SV

class wb_m_agent extends uvm_agent;

    `uvm_component_utils(wb_m_agent)

    //--------------------------------------------------------------------------
    // Analysis port — forwarded from monitor so env can connect subscribers
    //--------------------------------------------------------------------------
    uvm_analysis_port #(wb_m_tx) ap;

    //--------------------------------------------------------------------------
    // Sub-component handles
    //--------------------------------------------------------------------------
    wb_m_sequencer_base     m_sequencer;
    wb_m_driver_base  m_driver;
    wb_m_monitor_base m_monitor;

    //--------------------------------------------------------------------------
    // Configuration object
    //--------------------------------------------------------------------------
    wb_m_config m_config;

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    //--------------------------------------------------------------------------
    // build_phase — retrieve config, create sub-components
    //--------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        if (!uvm_config_db #(wb_m_config)::get(this, "", "config", m_config))
            `uvm_fatal(get_type_name(), "wb_m_config not found in config_db")

        // Propagate same config object to children
        uvm_config_db #(wb_m_config)::set(this, "m_driver",  "config", m_config);
        uvm_config_db #(wb_m_config)::set(this, "m_monitor", "config", m_config);

        if (get_is_active() == UVM_ACTIVE) begin
            m_sequencer = wb_m_sequencer_base   ::type_id::create("m_sequencer", this);
            m_driver    = wb_m_driver_base::type_id::create("m_driver",    this);
        end

        m_monitor = wb_m_monitor_base::type_id::create("m_monitor", this);
        ap        = new("ap", this);
    endfunction

    //--------------------------------------------------------------------------
    // connect_phase — wire driver seq_item_port and forward monitor AP
    //--------------------------------------------------------------------------
    function void connect_phase(uvm_phase phase);
        if (get_is_active() == UVM_ACTIVE)
            m_driver.seq_item_port.connect(m_sequencer.seq_item_export);
        m_monitor.ap.connect(ap);
    endfunction

    //--------------------------------------------------------------------------
    // get_is_active — delegate to config object
    //--------------------------------------------------------------------------
    virtual function uvm_active_passive_enum get_is_active();
        return uvm_active_passive_enum'(m_config.is_active);
    endfunction

endclass : wb_m_agent

`endif // WB_M_AGENT_SV
