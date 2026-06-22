// mii_rx_agent.sv

`ifndef MII_RX_AGENT_SV
`define MII_RX_AGENT_SV

class mii_rx_agent extends uvm_agent;
  `uvm_component_utils(mii_rx_agent)

  uvm_analysis_port #(mii_rx_tx) a_port;

  mii_rx_sequencer_base m_sequencer;
  mii_rx_driver_base    m_driver;
  mii_rx_monitor_base   m_monitor;

  virtual mii_rx_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    if (get_is_active() == UVM_ACTIVE)
    begin
      m_sequencer = mii_rx_sequencer_base::type_id::create("m_sequencer", this);
      m_driver    = mii_rx_driver_base   ::type_id::create("m_driver",    this);
    end

    m_monitor = mii_rx_monitor_base::type_id::create("m_monitor", this);
    a_port    = new("a_port", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    if (vif == null)
      `uvm_fatal(get_type_name(), "mii_rx virtual interface not set")

    m_monitor.vif = vif;

    if (get_is_active() == UVM_ACTIVE)
    begin
      m_driver.vif = vif;
      m_driver.seq_item_port.connect(m_sequencer.seq_item_export);
    end

    m_monitor.a_port.connect(a_port);
  endfunction

endclass

`endif // MII_RX_AGENT_SV
