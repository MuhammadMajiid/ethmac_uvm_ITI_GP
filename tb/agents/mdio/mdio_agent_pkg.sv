//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : mdio_agent_pkg.sv
// Author   : Muhammad Majid
// Date     : 2026-06-26
//------------------------------------------------------------------------------
// Description:
//   Package for MDIO agent components. Includes sequencer, driver, and monitor base classes.
//==============================================================================

`ifndef MDIO_AGENT_PKG_SV
`define MDIO_AGENT_PKG_SV

package mdio_agent_pkg;
  `include "uvm_macros.svh"
  import uvm_pkg::*;

  // Global package (op_code_e used by mdio_seq_item_base.sv, ETH_CTRL_*
  // parameters used by mdio_monitor_base.sv). Imported directly because
  // wildcard imports are not transitively re-exported through
  // eth_config_pkg::* even though eth_config_pkg itself imports it.
  import eth_glob_pkg::*;

  // import config package
  // import eth_config_pkg::*;
  
  // The transaction item must be compiled first because everything else uses it.
  `include "../../seq_items/mdio/mdio_seq_item_base.sv"

  // The components that use the transaction item
  `include "mdio_sequencer_base.sv"
  `include "mdio_driver_base.sv"
  `include "mdio_monitor_base.sv"

  // The agent is compiled last because it instantiates all the components above.
  `include "mdio_agent.sv"
endpackage

`endif // MDIO_AGENT_PKG_SV
