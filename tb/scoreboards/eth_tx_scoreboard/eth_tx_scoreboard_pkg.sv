//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_tx_scoreboard_pkg.sv
// Author   : Wael
// Date     : 2026-07-1
//------------------------------------------------------------------------------
// Description:
//   Package for including scoreboard files.
//==============================================================================

`ifndef ETH_ETH_TX_SCOREBOARD_PKG
`define ETH_ETH_TX_SCOREBOARD_PKG

package eth_tx_scoreboard_pkg;
    
    `include "uvm_macros.svh"
    import uvm_pkg::*;

    // Global package
    import eth_glob_pkg::*;

    `include "eth_tx_scoreboard.sv"
    `include "eth_tx_scoreboard_struct.sv"
 
endpackage : eth_tx_scoreboard_pkg

`endif // ETH_ETH_TX_SCOREBOARD_PKG
