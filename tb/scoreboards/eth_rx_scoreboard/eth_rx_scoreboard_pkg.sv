//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_rx_scoreboard_pkg.sv
// Author   : Mariam
// Date     : 2026-07-09
//------------------------------------------------------------------------------
// Description:
//   Package for including scoreboard files.
//==============================================================================
`timescale 1ns/1ps
`ifndef ETH_RX_SCOREBOARD_PKG_SV
`define ETH_RX_SCOREBOARD_PKG_SV

package eth_rx_scoreboard_pkg;
    
    `include "uvm_macros.svh"
    import uvm_pkg::*;

    // Global package
    import eth_glob_pkg::*;

    // RAL package
    import eth_ral_pkg::*;

    // Transactions packages
    import wb_m_seq_item_pkg::*;
    import wb_s_seq_item_pkg::*;
    import mii_rx_seq_item_pkg::*;

    // import config package
    import eth_config_pkg::*;

    `include "eth_rx_scoreboard.sv"
 
endpackage : eth_rx_scoreboard_pkg

`endif // ETH_RX_SCOREBOARD_PKG_SV
