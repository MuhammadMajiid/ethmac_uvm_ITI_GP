//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : mii_tx_agent_pkg.sv
// Author   : Mounir
// Date     : 2026-06-24
//------------------------------------------------------------------------------
// Description:
// SystemVerilog package for the MII Transmit Agent.
// Imports UVM base library and bundles all MII Tx agent source files into one package
//==============================================================================


`ifndef MII_TX_AGENT_PKG_SV
`define MII_TX_AGENT_PKG_SV

package mii_tx_agent_pkg;
    import uvm_pkg::*;
    import eth_glob_pkg::*;
    `include "uvm_macros.svh"

    import mii_tx_seq_item_pkg::*;
    // import config package
   import eth_config_pkg::*;
    
    `include "mii_tx_sequencer_base.sv"
    `include "mii_tx_driver_base.sv"
    `include "mii_tx_monitor_base.sv"
    `include "mii_tx_agent.sv"

endpackage : mii_tx_agent_pkg

`endif