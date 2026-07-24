//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_tx_scoreboard_config_obj.sv
// Author   : Wael
// Date     : 2026-07-05
//------------------------------------------------------------------------------
// Description:
//   Configuration object for the Tx scoreboard agent. Holds register model and
//   event triggered when running sequence ends.
//==============================================================================

`ifndef ETH_TX_SCOREBOARD_CONFIG_OBJ_SV
`define ETH_TX_SCOREBOARD_CONFIG_OBJ_SV

class eth_tx_scoreboard_config_obj extends uvm_object;
  `uvm_object_utils(eth_tx_scoreboard_config_obj)

 
  uvm_active_passive_enum is_active = UVM_ACTIVE;

  eth_reg_block         m_regmodel;       // RAL model
  event                 m_ev_end_seqs;    // triggerd when sequences finish
  event                 m_ev_end_pkt;
  function new(string name = "eth_tx_scoreboard_config_obj");
    super.new(name);
  endfunction

endclass

`endif // ETH_TX_SCOREBOARD_CONFIG_OBJ_SV