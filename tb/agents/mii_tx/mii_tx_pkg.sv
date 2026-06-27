//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : mii_tx_pkg.sv
// Author   : Mounir
// Date     : 2026-06-24
//------------------------------------------------------------------------------
// Description:
// SystemVerilog package for the MII Transmit Agent.
// Imports UVM base library and bundles all MII Tx agent source files into one package
//==============================================================================


`ifndef MII_TX_PKG_SV
`define MII_TX_PKG_SV

package mii_tx_pkg;
    import uvm_pkg::*;
    import eth_glob_pkg::*;
    `include "uvm_macros.svh"

    `include "mii_tx_seq_item_base.sv"
    `include "mii_tx_config_obj_base.sv"
    `include "mii_tx_sequencer_base.sv"
    `include "mii_tx_driver_base.sv"
    `include "mii_tx_monitor_base.sv"
    `include "mii_tx_agent.sv"

endpackage : mii_tx_pkg

`endif