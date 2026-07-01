//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : mii_rx_agent.sv
// Author   : Mariam
// Date     : 2026-06-24
//------------------------------------------------------------------------------
// Description:
//   Agent for MII Rx interface.
//==============================================================================

`ifndef MII_RX_AGENT_SV
`define MII_RX_AGENT_SV

  `include "uvm_macros.svh"
  import uvm_pkg::*;

class mii_rx_agent extends uvm_agent;
  `uvm_component_utils(mii_rx_agent)

  uvm_analysis_port #(mii_rx_seq_item) a_port;

  // Configuration Object Handle
  mii_rx_agent_config m_cfg;

  mii_rx_sequencer_base       m_sequencer;
  mii_rx_driver_base          m_driver;
  mii_rx_monitor_base         m_monitor;

  virtual mii_rx_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Retrieve the configuration object from the config_db
    if (!uvm_config_db #(mii_rx_agent_config)::get(this, "", "mii_rx_agent_config", m_cfg)) begin
      `uvm_fatal(get_type_name(), "Failed to get mii_rx_agent_config from uvm_config_db")
    end

    // Build Sequencer and Driver ONLY if the agent is ACTIVE
    if (m_cfg.is_active == UVM_ACTIVE) begin
      m_sequencer = mii_rx_sequencer_base::type_id::create("m_sequencer", this);
      m_driver    = mii_rx_driver_base   ::type_id::create("m_driver",    this);
    end

    // Always build the Monitor and Analysis Port
    m_monitor = mii_rx_monitor_base::type_id::create("m_monitor", this);
    a_port    = new("a_port", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // Ensure the virtual interface is valid inside the config object
    if (m_cfg.vif == null)
      `uvm_fatal(get_type_name(), "mii_rx virtual interface not set")

    // Connect the Monitor's VIF and Analysis Port
    m_monitor.vif = m_cfg.vif;
    m_monitor.a_port.connect(this.a_port);

    // Connect Driver's VIF and link it to the Sequencer (If ACTIVE)
    if (m_cfg.is_active == UVM_ACTIVE) begin
      m_driver.vif = m_cfg.vif;
      m_driver.seq_item_port.connect(m_sequencer.seq_item_export);
    end
  endfunction

endclass

`endif // MII_RX_AGENT_SV
