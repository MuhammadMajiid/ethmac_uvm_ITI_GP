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

  uvm_analysis_port #(mdio_tx) a_port;

  mdio_sequencer_base m_sequencer;
  mdio_driver_base    m_driver;
  mdio_monitor_base   m_monitor;

  virtual mdio_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase); // Crucial: Always call super in build_phase

    if (get_is_active() == UVM_ACTIVE) begin
      m_sequencer = mdio_sequencer_base::type_id::create("m_sequencer", this);
      m_driver    = mdio_driver_base::type_id::create("m_driver", this);
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

endclass

`endif // MDIO_AGENT_SV
