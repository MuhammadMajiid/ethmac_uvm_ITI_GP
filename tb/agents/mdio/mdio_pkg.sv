
`ifndef MDIO_PKG_SV
`define MDIO_PKG_SV

package mdio_pkg;
  `include "uvm_macros.svh"
  import uvm_pkg::*;

  `include "mdio_tx.sv"
  `include "mdio_sequencer.sv"
  `include "mdio_driver.sv"
  `include "mdio_monitor.sv"
  `include "mdio_agent.sv"
endpackage

`endif // MDIO_PKG_SV
