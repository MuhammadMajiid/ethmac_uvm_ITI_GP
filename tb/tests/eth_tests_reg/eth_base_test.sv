class eth_base_test extends uvm_test;
  `uvm_component_utils(eth_base_test)

  eth_env m_env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
   super.build_phase(phase);
    m_env = eth_env::type_id::create("m_env", this);
  endfunction



endclass
