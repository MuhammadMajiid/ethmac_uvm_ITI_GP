//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_s_agent.sv
// Author   : Nada
// Date     : 2026-06-23
//------------------------------------------------------------------------------
// Description:
// Wishbone slave UVM agent.
// Creates and connects the sequencer, driver, and monitor. 
// In ACTIVE mode,the agent drives slave responses through the driver. 
// In PASSIVE mode,only the monitor is created.
// Monitored transactions are broadcast through the analysis port.   
//==============================================================================

`ifndef WB_S_AGENT_SV
`define WB_S_AGENT_SV
class wb_s_agent extends uvm_agent;
  `uvm_component_utils(wb_s_agent)

  uvm_analysis_port #(wb_s_seq_item_base) a_port;

  wb_s_config_obj             m_config;
  wb_s_sequencer_base   m_sequencer;
  wb_s_driver_base       m_driver;
  wb_s_monitor_base      m_monitor;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    if (!uvm_config_db #(wb_s_config_obj    )::get(this, "", "config", m_config))
      `uvm_fatal(get_type_name(), "wb_s_config_obj     not found in config_db")

    if (m_config.vif == null)
      `uvm_fatal(get_type_name(), "wb_s virtual interface not set")

    // Pass the same config object down to monitor ,(the driver and sequencer if active) so they can each get their own copy
    uvm_config_db #(wb_s_config_obj    )::set(this, "m_monitor", "config", m_config);
    if (get_is_active() == UVM_ACTIVE)
    begin     
      uvm_config_db #(wb_s_config_obj    )::set(this, "m_sequencer", "config", m_config);
      uvm_config_db #(wb_s_config_obj    )::set(this, "m_driver",  "config", m_config);
   // Creates the sequencer and driver if the agent is active
      m_sequencer = wb_s_sequencer_base::type_id::create("m_sequencer", this);
      m_driver    = wb_s_driver_base   ::type_id::create("m_driver", this);
    end
   
    m_monitor = wb_s_monitor_base::type_id::create("m_monitor", this);
    a_port    = new("a_port", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    if (get_is_active() == UVM_ACTIVE)
      m_driver.seq_item_port.connect(m_sequencer.seq_item_export);

    m_monitor.a_port.connect(a_port);
  endfunction


  virtual function uvm_active_passive_enum get_is_active();
// Returns the agent operating mode (ACTIVE or PASSIVE) from the configuration object.
    return m_config.is_active;
  endfunction

endclass
`endif // WB_S_AGENT_SV