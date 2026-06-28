//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_s_pkg.sv
// Author   : Nada
// Date     : 2026-06-23
//------------------------------------------------------------------------------
// Description:
// Wishbone slave agent package.
// Imports UVM libraries and includes all components required to build the
// Wishbone slave agent, including the configuration object, sequencer,
// driver, monitor, and agent classes.
//------------------------------------------------------------------------------
`ifndef WB_S_PKG_SV
`define WB_S_PKG_SV

package wb_s_pkg;
  `include "uvm_macros.svh"
  import uvm_pkg::*;
  import eth_glob_pkg::*;

  
  `include "wb_s_config_obj.sv"
  `include "wb_s_seq_item_base.sv"
  `include "wb_s_seq_base.sv"
  `include "wb_s_sequencer_base.sv"
  `include "wb_s_driver_base.sv"
  `include "wb_s_monitor_base.sv"
  `include "wb_s_agent.sv"
  
  
  

endpackage : wb_s_pkg

`endif // WB_S_PKG_SV