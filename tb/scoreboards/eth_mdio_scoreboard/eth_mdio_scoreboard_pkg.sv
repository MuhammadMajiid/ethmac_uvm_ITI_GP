//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_mdio_scoreboard_pkg.sv
// Author   : Majid
// Date     : 2026-07-01
//------------------------------------------------------------------------------
// Description:
//   Package for including scoreboard files.
//==============================================================================
`timescale 1ns/1ps
`ifndef ETH_MDIO_SCOREBOARD_PKG
`define ETH_MDIO_SCOREBOARD_PKG

package eth_mdio_scoreboard_pkg;
    
    `include "uvm_macros.svh"
    import uvm_pkg::*;

    // Global package
    import eth_glob_pkg::*;

    // RAL package
    import eth_ral_pkg::*;

    // Transactions packages
    import wb_m_seq_item_pkg::*;
    import wb_s_seq_item_pkg::*;
    import mii_tx_seq_item_pkg::*;
    import mdio_seq_item_pkg::*;

    // import config package
    import eth_config_pkg::*;

    `include "eth_mdio_scoreboard.sv"

endpackage : eth_mdio_scoreboard_pkg

`endif // ETH_MDIO_SCOREBOARD_PKG
