//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_v_sequencer_base .sv
// Author   : Wael
// Date     : 2026-07-06
//------------------------------------------------------------------------------
// Description:
//   Base virtual sequencer declares handles of wishbone master & slave agents
//   All other virtual sequencer extend from it 
//==============================================================================
`ifndef ETH_V_SEQUENCER_BASE_SV
`define ETH_V_SEQUENCER_BASE_SV

class eth_v_sequencer_base extends uvm_sequencer;
 `uvm_component_utils(eth_v_sequencer_base)
 wb_m_agent m_wb_m_agent;
 wb_s_agent m_wb_s_agent;

 function new(string name, uvm_component parent);
 super.new(name, parent);
 endfunction
endclass

`endif // ETH_V_SEQUENCER_SV