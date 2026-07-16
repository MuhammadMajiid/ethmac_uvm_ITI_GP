//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_v_sequencer.sv
// Author   : Wael
// Date     : 2026-07-06
//------------------------------------------------------------------------------
// Description:
//   virtual sequencer declares handles of all sequencers 
//==============================================================================
`ifndef ETH_V_SEQUENCER_SV
`define ETH_V_SEQUENCER_SV

class eth_v_sequencer extends uvm_sequencer;
 `uvm_component_utils(eth_v_sequencer)
  wb_m_sequencer_base   m_wb_m_sqr;
  wb_s_sequencer_base   m_wb_s_sqr;
  mii_tx_sequencer_base m_mii_tx_sqr;
  mii_rx_sequencer_base m_mii_rx_sqr;
  reset_sequencer m_reset_sqr;

 function new(string name, uvm_component parent);
  super.new(name, parent);
 endfunction
endclass

`endif // ETH_V_SEQUENCER_SV