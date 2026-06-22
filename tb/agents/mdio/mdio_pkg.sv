
`ifndef MDIO_PKG_SV
`define MDIO_PKG_SV

package mdio_pkg;
  `include "uvm_macros.svh"
  import uvm_pkg::*;

  `include "mdio_tx.sv"
  `include "mdio_sequencer_base.sv"
  `include "mdio_driver_base.sv"
  `include "mdio_monitor_base.sv"
  `include "mdio_agent.sv"
endpackage

`endif // MDIO_PKG_SV
