//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : mdio_pkg.sv
// Author   : Muhammad Majid
// Date     : 2026-06-26
//------------------------------------------------------------------------------
// Description:
//   Package for MDIO agent components. Includes sequencer, driver, and monitor base classes.
//==============================================================================

`ifndef MDIO_PKG_SV
`define MDIO_PKG_SV

package mdio_pkg;
  `include "uvm_macros.svh"
  import uvm_pkg::*;

  // The transaction item must be compiled first because everything else uses it.
  `include "../../seq_items/mdio/mdio_seq_item_base.sv"

  // The components that use the transaction item
  `include "mdio_sequencer_base.sv"
  `include "mdio_driver_base.sv"
  `include "mdio_monitor_base.sv"

  // The agent is compiled last because it instantiates all the components above.
  `include "mdio_agent.sv"
endpackage

`endif // MDIO_PKG_SV
