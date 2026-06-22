
`ifndef WB_S_PKG_SV
`define WB_S_PKG_SV

package wb_s_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Dependencies (assumed to exist)
  import wb_common_pkg::*;

  `include "wb_s_sequencer.sv"
  `include "wb_s_driver.sv"
  `include "wb_s_monitor.sv"
  `include "wb_s_agent.sv"

endpackage : wb_s_pkg

`endif // WB_S_PKG_SV