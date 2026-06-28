//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : mdio_agent.sv
// Author   : Muhammad Majid
// Date     : 2026-06-26
//------------------------------------------------------------------------------
// Description:
//   Base MDIO agent for Ethernet MAC management interface. Integrates driver,
//   sequencer, and monitor components.
//==============================================================================

`ifndef MDIO_AGENT_SV
`define MDIO_AGENT_SV

class mdio_agent extends uvm_agent;
  `uvm_component_utils(mdio_agent)

  uvm_analysis_port #(mdio_seq_item_base) a_port;

  mdio_config_obj     m_config;
  mdio_sequencer_base m_sequencer;
  mdio_driver_base    m_driver;
  mdio_monitor_base   m_monitor;

  virtual mdio_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase); // Crucial: Always call super in build_phase


    if (!uvm_config_db #(mdio_config_obj)::get(this, "", "config", m_config))
      `uvm_fatal(get_type_name(), "mdio_config_obj not found in config_db")

    if (m_config.vif == null)
      `uvm_fatal(get_type_name(), "mdio virtual interface not set")

    // Pass the same config object down to monitor ,(the driver and sequencer if active) so they can each get their own copy
    uvm_config_db #(mdio_config_obj    )::set(this, "m_monitor", "config", m_config);

    if (get_is_active() == UVM_ACTIVE) begin
      uvm_config_db #(mdio_config_obj    )::set(this, "m_sequencer", "config", m_config);
      uvm_config_db #(mdio_config_obj    )::set(this, "m_driver",  "config", m_config);
   // Creates the sequencer and driver if the agent is active
      m_sequencer = mdio_sequencer_base::type_id::create("m_sequencer", this);
      m_driver    = mdio_driver_base   ::type_id::create("m_driver", this);
    end

    m_monitor = mdio_monitor_base::type_id::create("m_monitor", this);
    a_port    = new("a_port", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase); // Crucial: Always call super in connect_phase

    if (vif == null)
      `uvm_fatal(get_type_name(), "mdio virtual interface not set")

    m_monitor.vif = vif;

    if (get_is_active() == UVM_ACTIVE) begin
      m_driver.vif = vif;
      // Connect the driver's port to the sequencer's export so they can talk
      m_driver.seq_item_port.connect(m_sequencer.seq_item_export);
    end

    // Pass the monitor's analysis port up to the agent's boundary
    m_monitor.a_port.connect(a_port);
  endfunction

  virtual function uvm_active_passive_enum get_is_active();
    // Returns the agent operating mode (ACTIVE or PASSIVE) from the configuration object.
    return m_config.is_active;
  endfunction

endclass

`endif // MDIO_AGENT_SV
