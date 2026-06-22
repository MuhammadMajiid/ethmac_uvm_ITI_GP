
`ifndef ETH_ENV_SV
`define ETH_ENV_SV

class eth_env extends uvm_env;
  `uvm_component_utils(eth_env)

  // Sub-agents
  mii_rx_agent m_mii_rx_agent;
  mii_tx_agent m_mii_tx_agent;
  mdio_agent   m_mdio_agent;

  // TODO: Instantiate scoreboard, coverage collector when implemented
  // eth_scoreboard    m_scoreboard;
  // eth_cov_collector m_cov_collector;

  eth_config m_config;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    if (!uvm_config_db #(eth_config)::get(this, "", "config", m_config))
      `uvm_error(get_type_name(), "eth_config not found in config_db")

    // Build MII Rx agent: propagate vif and is_active via config_db
    begin
      mii_rx_agent m_tmp_rx;  // just for scoping clarity
      m_mii_rx_agent = mii_rx_agent::type_id::create("m_mii_rx_agent", this);
      uvm_config_db #(uvm_active_passive_enum)::set(
        this, "m_mii_rx_agent", "is_active", m_config.mii_rx_is_active);
    end

    // Build MII Tx agent
    begin
      m_mii_tx_agent = mii_tx_agent::type_id::create("m_mii_tx_agent", this);
      uvm_config_db #(uvm_active_passive_enum)::set(
        this, "m_mii_tx_agent", "is_active", m_config.mii_tx_is_active);
    end

    // Build MDIO agent
    begin
      m_mdio_agent = mdio_agent::type_id::create("m_mdio_agent", this);
      uvm_config_db #(uvm_active_passive_enum)::set(
        this, "m_mdio_agent", "is_active", m_config.mdio_is_active);
    end

    // TODO: Create scoreboard and coverage collector
    // m_scoreboard    = eth_scoreboard   ::type_id::create("m_scoreboard",    this);
    // m_cov_collector = eth_cov_collector::type_id::create("m_cov_collector", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    // Assign virtual interfaces directly from top-level config object
    if (m_config.mii_rx_vif == null)
      `uvm_fatal(get_type_name(), "mii_rx virtual interface not set in eth_config")
    if (m_config.mii_tx_vif == null)
      `uvm_fatal(get_type_name(), "mii_tx virtual interface not set in eth_config")
    if (m_config.mdio_vif == null)
      `uvm_fatal(get_type_name(), "mdio virtual interface not set in eth_config")

    m_mii_rx_agent.vif = m_config.mii_rx_vif;
    m_mii_tx_agent.vif = m_config.mii_tx_vif;
    m_mdio_agent.vif   = m_config.mdio_vif;

    // TODO: Connect analysis ports to scoreboard / coverage collector
    // m_mii_rx_agent.a_port.connect(m_scoreboard.mii_rx_export);
    // m_mii_tx_agent.a_port.connect(m_scoreboard.mii_tx_export);
    // m_mdio_agent.a_port.connect(m_scoreboard.mdio_export);
  endfunction

  task run_phase(uvm_phase phase);
    // TODO: Start virtual sequence here when implemented
    // eth_vseq vseq;
    // vseq = eth_vseq::type_id::create("vseq");
    // if (!vseq.randomize())
    //   `uvm_error(get_type_name(), "Randomize failed")
    // vseq.m_mii_rx_sqr = m_mii_rx_agent.m_sequencer;
    // vseq.m_mii_tx_sqr = m_mii_tx_agent.m_sequencer;
    // vseq.m_mdio_sqr   = m_mdio_agent.m_sequencer;
    // phase.raise_objection(this, "eth_env run started");
    // vseq.start(null, null);
    // phase.drop_objection(this, "eth_env run finished");
  endtask

endclass

`endif // ETH_ENV_SV
