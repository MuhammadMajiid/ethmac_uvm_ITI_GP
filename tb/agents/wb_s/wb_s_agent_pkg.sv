//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_agent_s_pkg.sv
// Author   : Nada
// Date     : 2026-06-23
//------------------------------------------------------------------------------
// Description:
// Wishbone slave agent package.
// Imports UVM libraries and includes all components required to build the
// Wishbone slave agent, including the configuration object, sequencer,
// driver, monitor, and agent classes.
//------------------------------------------------------------------------------
`ifndef WB_S_AGENT_PKG_SV
`define WB_S_AGENT_PKG_SV

package wb_s_agent_pkg;
  `include "uvm_macros.svh"
  import uvm_pkg::*;
  import eth_glob_pkg::*;

  
  // import config package
  import eth_config_pkg::*;
   import wb_s_seq_item_pkg::*;
  `include "wb_s_sequencer_base.sv"
  `include "wb_s_driver_base.sv"
  `include "wb_s_monitor_base.sv"
  `include "wb_s_agent.sv"
  
  
  

endpackage : wb_s_agent_pkg

`endif // WB_S_AGENT_PKG_SV