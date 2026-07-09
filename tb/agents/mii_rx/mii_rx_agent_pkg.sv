//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : mii_rx_agent_pkg.sv
// Author   : Mariam Hossam
// Date     : 2026-06-24
//------------------------------------------------------------------------------
// Description:
//   Package to include MII Rx files of agent & it's subcomponents.
//==============================================================================

`ifndef MII_RX_AGENT_PKG_SV
`define MII_RX_AGENT_PKG_SV

package mii_rx_agent_pkg;
  
  `include "uvm_macros.svh"
  import uvm_pkg::*;
  import eth_glob_pkg::*;
  import mii_rx_seq_item_pkg::*;
  
  // import config package
  import eth_config_pkg::*;

  // Agent subcomponents files
  `include "mii_rx_sequencer_base.sv"
  `include "mii_rx_driver_base.sv"
  `include "mii_rx_monitor_base.sv"
  `include "mii_rx_agent.sv"

endpackage : mii_rx_agent_pkg

`endif // MII_RX_AGENT_PKG_SV