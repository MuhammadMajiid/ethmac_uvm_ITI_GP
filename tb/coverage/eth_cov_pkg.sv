//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_cov_pkg.sv
// Author   : Wael
// Date     : 2026-07-12
//------------------------------------------------------------------------------
// Description:
//   Package for including coverage files.
//==============================================================================

`ifndef ETH_COV_PKG
`define ETH_COV_PKG
package eth_cov_pkg;

import uvm_pkg::*;
`include "uvm_macros.svh"
import eth_glob_pkg::*;

// import RAL package
import eth_ral_pkg::*;

// import transactions packages
import wb_m_seq_item_pkg::*;
import wb_s_seq_item_pkg::*;
import mii_tx_seq_item_pkg::*;
import mii_rx_seq_item_pkg::*;


// include coverage files
`include "eth_cov_tx.sv"
//`include "eth_cov_rx.sv"

endpackage

`endif // ETH_COV_PKG