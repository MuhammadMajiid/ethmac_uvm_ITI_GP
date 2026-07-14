//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_v_seq_sqr_pkg.sv
// Author   : Wael
// Date     : 2026-07-06
//------------------------------------------------------------------------------
// Description:
//   Package for including environment files.
//==============================================================================

`ifndef ETH_ENV_SCOREBOARD_PKG
`define ETH_ENV_SCOREBOARD_PKG

package  eth_v_seq_sqr_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"


  // import agent packages
  import wb_s_agent_pkg::wb_s_sequencer_base;
  import wb_m_agent_pkg::wb_m_sequencer_base;
  import mii_tx_agent_pkg::mii_tx_sequencer_base;
  import mii_rx_agent_pkg::mii_rx_sequencer_base;

  // import sequences package
  import wb_m_seq_pkg::*;
  import wb_s_seq_pkg::*;
  import mii_tx_seq_pkg::*;
  
  // include virtual sequencer files
  `include "eth_v_sequencer.sv"
  `include "eth_v_seq_base.sv"
  `include "eth_v_seq_tx.sv"

endpackage

`endif // ETH_ENV_SCOREBOARD_PKG