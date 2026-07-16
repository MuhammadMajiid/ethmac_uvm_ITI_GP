//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : reset_agent_pkg.sv
// Author   : Nada
// Date     : 2026-07-16
//------------------------------------------------------------------------------
// Description:
// reset agent package.
// Imports UVM libraries and includes all components required to build the
// reset agent, including the configuration object, sequencer,
// driver, and agent classes.
//------------------------------------------------------------------------------
`ifndef RESET_AGENT_PKG_SV
`define RESET_AGENT_PKG_SV

package reset_agent_pkg;
  `include "uvm_macros.svh"
  import uvm_pkg::*;
  import eth_glob_pkg::*;

  
  // import config package
  import eth_config_pkg::*;
   import reset_seq_item_pkg::*;
  `include "reset_sequencer.sv"
  `include "reset_driver.sv"
  `include "reset_agent.sv"
  
  
  

endpackage : reset_agent_pkg

`endif // RESET_AGENT_PKG_SV