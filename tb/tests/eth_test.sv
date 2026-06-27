
`ifndef ETH_TEST_SV
`define ETH_TEST_SV


class eth_test extends uvm_test;
  `uvm_component_utils(eth_test)

  eth_env                 m_env;
  wb_m_config_obj         m_wb_m_config_obj;               // Wishbone master configuration object
  wb_m_sequence_base m_sequence; 
  
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    m_wb_m_config_obj = wb_m_config_obj::type_id::create("m_wb_m_config_obj");

    // Retrieve the top-level config that tb_top placed in the database
    if (!uvm_config_db #(virtual wb_m_if)::get(this, "", "wb_m_vif", m_wb_m_config_obj.vif))
      `uvm_fatal(get_type_name(), "wb_m_vif is not found in config_db")

    // set agent to active
    m_wb_m_config_obj.is_active=UVM_ACTIVE;

    // Propagate Wishbone configuration object to env and it's subcomponents
    uvm_config_db #(wb_m_config_obj)::set(this, "m_env.m_wb_m*", "config", m_wb_m_config_obj);

    m_env = eth_env::type_id::create("m_env", this);
  endfunction

  function void start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
      `uvm_info(get_type_name(),"start of sim phase", UVM_LOW)
  endfunction

  task run_phase(uvm_phase phase);
 
          super.run_phase(phase);

      m_sequence=wb_m_sequence_base::type_id::create("m_sequence");
      phase.raise_objection(this);
      m_sequence.start(m_env.m_wb_m_agent.m_sequencer);
      phase.drop_objection(this);
  endtask

endclass

`endif // ETH_TEST_SV
