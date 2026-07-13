`ifndef ETH_ENV_RX_SV
`define ETH_ENV_RX_SV

class eth_env_rx extends eth_env_base;
  `uvm_component_utils(eth_env_rx)

  // Declare RX agent handle
  mii_rx_agent        m_mii_rx_agent;

  // Declare RX scoreboard handle
  eth_rx_scoreboard   m_rx_sb;

  //--------------------------------------------------------------------------
  // Constructor
  //--------------------------------------------------------------------------
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  //--------------------------------------------------------------------------
  // Build Phase
  //--------------------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Distribute RX config down to its agent
    uvm_config_db #(mii_rx_config_obj)::set(this, "m_mii_rx_agent", "config", m_config.m_mii_rx_config);

    // Pass RAL Model directly to the RX Scoreboard
    // (This matches the uvm_config_db::get inside your eth_rx_scoreboard exactly!)
    uvm_config_db #(eth_reg_block)::set(this, "m_rx_sb", "m_regmodel", m_regmodel);

    // 3. Build Components
    m_mii_rx_agent = mii_rx_agent::type_id::create("m_mii_rx_agent", this);
    m_rx_sb        = eth_rx_scoreboard::type_id::create("m_rx_sb", this);
  endfunction

  //--------------------------------------------------------------------------
  // Connnect Phase
  //--------------------------------------------------------------------------
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // -------------------------------------------------------------------------
    // Virtual Sequencer Connections
    // -------------------------------------------------------------------------
    m_v_sqr.m_mii_rx_sqr = m_mii_rx_agent.m_sequencer;
    m_v_sqr.m_wb_m_sqr   = m_wb_m_agent.m_sequencer;
    m_v_sqr.m_wb_s_sqr   = m_wb_s_agent.m_sequencer;

    // -------------------------------------------------------------------------
    // RX Scoreboard Connections
    // -------------------------------------------------------------------------
    // MII RX Monitor to Scoreboard
    m_mii_rx_agent.m_monitor.a_port.connect(m_rx_sb.mii_rx_export);  

    // Wishbone Master Monitor to Scoreboard
    m_wb_m_agent.m_monitor.transaction_a_port.connect(m_rx_sb.wb_master_imp);  

    // Wishbone Slave Monitor to Scoreboard (Connects to BOTH ports for RXEN and BD status)
    m_wb_s_agent.m_monitor.a_port.connect(m_rx_sb.wb_slave_imp); 
    m_wb_s_agent.m_monitor.bd_status_ap.connect(m_rx_sb.bd_status_export); 
  endfunction

endclass
`endif // ETH_ENV_RX_SV