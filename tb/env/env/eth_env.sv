`ifndef ETH_ENV_SV
`define ETH_ENV_SV
class eth_env extends uvm_env;
  `uvm_component_utils(eth_env)

  eth_env_config_obj m_config;

  wb_s_agent  m_wb_s_agent;
  //wb_m_agent  m_wb_m_agent;
  //mii_agent   m_mii_agent;

  eth_reg_block     regmodel;   
  eth_wb_adapter    m_reg2wb;
  uvm_reg_predictor #(wb_s_seq_item_base) m_predictor;

 // eth_scoreboard m_sb;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    if (!uvm_config_db #(eth_env_config_obj)::get(this, "", "config", m_config))
      `uvm_error(get_type_name(), "eth_env_config not found in config_db")

    // Distribute agent-specific configs down to each agent
    uvm_config_db #(wb_s_config_obj)::set(this, "m_wb_s_agent", "config", m_config.m_wb_s_config);
    //uvm_config_db #(wb_m_config)::set(this, "m_wb_m_agent", "config", m_config.m_wb_m_config);
    //uvm_config_db #(mii_config) ::set(this, "m_mii_agent",  "config", m_config.m_mii_config);

    m_wb_s_agent = wb_s_agent::type_id::create("m_wb_s_agent", this);
    //m_wb_m_agent = wb_m_agent::type_id::create("m_wb_m_agent", this);
    //m_mii_agent  = mii_agent ::type_id::create("m_mii_agent",  this);

    // Register layer - only build if this env is the top-level owner
    // (regmodel == null means no parent env has already set it)
    if (regmodel == null)
    begin
      regmodel = eth_reg_block::type_id::create("regmodel");
      regmodel.build();
      regmodel.lock_model();
           
    end

    m_reg2wb   = eth_wb_adapter::type_id::create("m_reg2wb");
    m_predictor = uvm_reg_predictor #(wb_s_seq_item_base)::type_id::create("m_predictor", this);

    //m_sb = eth_scoreboard::type_id::create("m_sb", this);
  endfunction

  function void connect_phase(uvm_phase phase);
 
   //Connect the wb_s_sequencer  to the address map in order
      //to use the API of the registers to start wb_s transactions
    regmodel.default_map.set_sequencer(m_wb_s_agent.m_sequencer, m_reg2wb);
      
    //Configure the predictor with an address map and an adapter
    m_predictor.map     = regmodel.default_map;
    m_predictor.adapter = m_reg2wb;
    regmodel.default_map.set_auto_predict(0);
    //Connect the wb_s_monitor with the predictor
   //m_wb_s_agent.m_monitor.a_port.connect(m_predictor.bus_in);

    // Scoreboard hookups
    /*m_mii_agent.m_monitor.tx_ap.connect(m_sb.mii_tx_export);  // captured TX-side frames
    m_mii_agent.m_monitor.rx_ap.connect(m_sb.mii_rx_export);  // injected RX-side frames
    m_wb_m_agent.m_monitor.a_port.connect(m_sb.dma_export);   // DMA read/write activity
    m_wb_s_agent.m_monitor.inta_port.connect(m_sb.inta_export); // continuous INTA_O samples*/
  endfunction

endclass
`endif // ETH_ENV_SV