//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_env_pkg.sv
// Author   : Wael
// Date     : 2026-07-06
//------------------------------------------------------------------------------
// Description:
//   Package for including environment files.
//==============================================================================

`ifndef ETH_ENV_SCOREBOARD_PKG
`define ETH_ENV_SCOREBOARD_PKG
package eth_env_pkg;

import uvm_pkg::*;
`include "uvm_macros.svh"
import eth_glob_pkg::*;

// import config package
import eth_config_pkg::*;

// import RAL package
import eth_ral_pkg::*;

// import transactions packages
import wb_m_seq_item_pkg::*;
import wb_s_seq_item_pkg::*;
import mii_tx_seq_item_pkg::*;
import mii_rx_seq_item_pkg::*;


// import agent packages
import wb_s_agent_pkg::wb_s_agent;
import wb_m_agent_pkg::wb_m_agent;
import mii_tx_agent_pkg::mii_tx_agent;
import mii_rx_agent_pkg::mii_rx_agent;

// import virtual sequence/sequencer package
import eth_v_seq_sqr_pkg::eth_v_sequencer;

// import scoerboard packages
import eth_tx_scoreboard_pkg::*;
import eth_rx_scoreboard_pkg::*;

// include env files
`include "eth_env_base.sv"
`include "eth_env_tx.sv"
`include "eth_env_rx.sv"

/*
`include "eth_env_config_obj.sv"
`include "eth_env.sv"
`include "eth_base_test.sv"
`include "eth_test_reg_access.sv"
*/

endpackage

`endif // ETH_ENV_SCOREBOARD_PKG