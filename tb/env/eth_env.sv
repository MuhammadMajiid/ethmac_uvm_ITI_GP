//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_env.sv
// Author   : Wael
// Date     : 2026-06-26
//------------------------------------------------------------------------------
// Description:
//   Ethernet Environmet encabsulates 5 agents, Scoreboard & coverage model.
//==============================================================================
`ifndef ETH_ENV_SV
`define ETH_ENV_SV

class eth_env extends uvm_env;
  `uvm_component_utils(eth_env)

  // Sub-agents
  wb_m_agent m_wb_m_agent;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // Build Wishbone master agent
      m_wb_m_agent = wb_m_agent::type_id::create("m_wb_m_agent", this);
  endfunction

  


endclass

`endif // ETH_ENV_SV
