
`ifndef ETH_ENV_PKG_SV
`define ETH_ENV_PKG_SV

package eth_env_pkg;
  `include "uvm_macros.svh"
  import uvm_pkg::*;

  import mii_rx_pkg::*;
  import mii_tx_pkg::*;
  import mdio_pkg::*;

  `include "eth_config.sv"
  `include "eth_env.sv"
endpackage

`endif // ETH_ENV_PKG_SV
