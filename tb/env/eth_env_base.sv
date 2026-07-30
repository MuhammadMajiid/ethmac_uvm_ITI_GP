//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_env_base.sv
// Author   : Nada
// Date     : 2026-07-06
//------------------------------------------------------------------------------
// Description:
//   Base environment for creating register model, wishbone master & slave
//   agents. Other environments extend from this environment.
//==============================================================================
`ifndef ETH_ENV_BASE_SV
`define ETH_ENV_BASE_SV
class eth_env_base extends uvm_env;
  `uvm_component_utils(eth_env_base)

  eth_env_config_obj m_config;

  wb_s_agent  m_wb_s_agent;
  wb_m_agent  m_wb_m_agent;
  
  reset_agent           m_reset_agent;
  
  eth_reg_block     m_regmodel;   
  eth_wb_adapter    m_reg2wb;
  uvm_reg_predictor #(wb_s_seq_item_base) m_predictor;

  // Declare virtual sequencer
  eth_v_sequencer     m_v_sqr;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db #(eth_env_config_obj)::get(this, "", "config", m_config))
      `uvm_error(get_type_name(), "eth_env_config not found in config_db")

    // wb_s_agent, wb_m_agent, and reset_agent all expect their vif
    // pre-populated on the config object rather than fetching it
    // themselves -- pull each one out of config_db before distributing.
    if (!uvm_config_db#(virtual wb_s_if)::get(this, "", "wb_s_vif", m_config.m_wb_s_config.vif))
        `uvm_fatal(get_type_name(), "virtual wb_s_if not found in uvm_config_db under key \"wb_s_vif\" -- check eth_tb.sv")
    if (!uvm_config_db#(virtual wb_m_if)::get(this, "", "wb_m_vif", m_config.m_wb_m_config.vif))
        `uvm_fatal(get_type_name(), "virtual wb_m_if not found in uvm_config_db under key \"wb_m_vif\" -- check eth_tb.sv")
    if (!uvm_config_db#(virtual reset_if)::get(this, "", "reset_if", m_config.m_rst_config.vif))
        `uvm_fatal(get_type_name(), "virtual reset_if not found in uvm_config_db under key \"reset_if\" -- check eth_tb.sv")

    // Distribute agent-specific configs down to each agent
    uvm_config_db #(wb_s_config_obj)::set(this, "m_wb_s_agent", "config", m_config.m_wb_s_config);
    uvm_config_db #(wb_m_config_obj)::set(this, "m_wb_m_agent", "config", m_config.m_wb_m_config);
	uvm_config_db #(reset_config_obj)::set(this, "m_reset_agent", "config", m_config.m_rst_config);
	
    
    // Build virtual sequencer
    m_v_sqr        = eth_v_sequencer::type_id::create("m_v_sqr", this);
    // Build wishbone slave agent
    m_wb_s_agent = wb_s_agent::type_id::create("m_wb_s_agent", this);
    // Build wishbone master agent
    m_wb_m_agent = wb_m_agent::type_id::create("m_wb_m_agent", this);
	
	 //reset agent
     m_reset_agent  =  reset_agent::type_id::create("m_reset_agent",this);

    
    // Register layer - only build if this env is the top-level owner
    // (m_regmodel == null means no parent env has already set it)
    if (m_regmodel == null)
    begin
      m_regmodel = eth_reg_block::type_id::create("m_regmodel");
      m_regmodel.build();
      m_regmodel.lock_model();
  // Initialize desired and mirrored values to reset values
      m_regmodel.reset();     
    end

    m_reg2wb   = eth_wb_adapter::type_id::create("m_reg2wb");
    m_predictor = uvm_reg_predictor #(wb_s_seq_item_base)::type_id::create("m_predictor", this);
  endfunction

  function void connect_phase(uvm_phase phase);
 
    super.connect_phase(phase);
    // Assign ral handle in scoreboard config obj to local
    m_config.m_regmodel=m_regmodel;
	
	m_v_sqr.m_reset_sqr = m_reset_agent.m_sequencer;
	m_v_sqr.regmodel = m_regmodel;

    
   //Connect the wb_s_sequencer  to the address map in order
      //to use the API of the registers to start wb_s transactions
    m_regmodel.default_map.set_sequencer(m_wb_s_agent.m_sequencer, m_reg2wb);
      
    //Configure the predictor with an address map and an adapter
    m_predictor.map     = m_regmodel.default_map;
    m_predictor.adapter = m_reg2wb;
    m_regmodel.default_map.set_auto_predict(1);
    
  endfunction

endclass
`endif // ETH_ENV_BASE_SV