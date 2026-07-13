//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_env_base.sv
// Author   : Nada
// Date     : 2026-07-06
//------------------------------------------------------------------------------
// Description:
//   extended from base environment, used for creating tx agent & tx scorebpard.
//==============================================================================

`ifndef ETH_ENV_TX_SV
`define ETH_ENV_TX_SV
class eth_env_tx extends eth_env_base;
  `uvm_component_utils(eth_env_tx)

  // declare TX agent handle
  mii_tx_agent                 m_mii_tx_agent;

  // declare TX scoreboard handle
  eth_tx_scoreboard            m_tx_sb;

  // declare coverage handle
  eth_cov_tx                    m_cov_tx;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Distribute TX config down to it's agent
    uvm_config_db #(mii_tx_config_obj) ::set(this, "m_mii_tx_agent","config", m_config.m_mii_tx_config);

    // Distribute tx scoreboard config down to scoreboard
    uvm_config_db #(eth_tx_scoreboard_config_obj) ::set(this, "m_tx_sb","config", m_config.m_tx_sb_config);

    // build TX agent
    m_mii_tx_agent  = mii_tx_agent::type_id::create("m_mii_tx_agent",this);

    // build TX scoreboard
    m_tx_sb = eth_tx_scoreboard::type_id::create("m_tx_sb", this);

    // build TX coverage
    m_cov_tx = eth_cov_tx::type_id::create("m_cov_tx", this);
  endfunction

  function void connect_phase(uvm_phase phase);

    super.connect_phase(phase);
    // Assign ral handle in scoreboard config obj to local
    m_config.m_tx_sb_config.m_regmodel=m_regmodel;

    // Connect each sequencer in virtual sequencer to it's real sequencer
    m_v_sqr.m_mii_tx_sqr=m_mii_tx_agent.m_sequencer;
    m_v_sqr.m_wb_m_sqr=m_wb_m_agent.m_sequencer;
    m_v_sqr.m_wb_s_sqr=m_wb_s_agent.m_sequencer;

    // Connect TX Scoreboard analysis export with TX agent analysis export
    m_mii_tx_agent.agent_a_port.connect(m_tx_sb.mii_tx_a_export);  
    // Connect TX Scoreboard analysis export with wishbone master agent analysis export
    m_wb_m_agent.a_port.connect(m_tx_sb.wb_m_a_export);  
    // Connect TX Scoreboard analysis implementation with wishbone slave agent analysis export
    m_wb_s_agent.a_port.connect(m_tx_sb.wb_s_imp); 

    // Assign regmodel in scoreboard config to regmodel in tx scoreboard
    m_tx_sb.m_regmodel=m_config.m_tx_sb_config.m_regmodel;

    // Connect TX Coverage analysis implementation with wishbone slave agent analysis export
    m_wb_s_agent.a_port.connect(m_cov_tx.wb_s_a_export); 
  
    // Connect TX Coverage analysis implementation with wishbone master agent analysis export
    m_wb_m_agent.a_port.connect(m_cov_tx.wb_m_a_export); 

    // Connect TX Coverage analysis implementation with mii tx agent analysis export
    m_mii_tx_agent.agent_a_port.connect(m_cov_tx.mii_tx_a_export); 

  endfunction

endclass
`endif // ETH_ENV_TX_SV