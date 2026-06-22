
`ifndef WB_S_PKG_SV
`define WB_S_PKG_SV

package wb_s_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "wb_s_sequencer_base.sv"
  `include "wb_s_driver_base.sv"
  `include "wb_s_monitor_base.sv"
  `include "wb_s_agent.sv"

endpackage : wb_s_pkg

`endif // WB_S_PKG_SV