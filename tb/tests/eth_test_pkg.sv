
`ifndef ETH_TEST_PKG_SV
`define ETH_TEST_PKG_SV

package eth_test_pkg;
  `include "uvm_macros.svh"
  import uvm_pkg::*;

  import mii_rx_pkg::*;
  import mii_tx_pkg::*;
  import mdio_pkg::*;
  import eth_env_pkg::*;

  `include "eth_test.sv"
endpackage

`endif // ETH_TEST_PKG_SV
