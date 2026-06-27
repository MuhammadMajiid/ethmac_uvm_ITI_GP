
`ifndef ETH_ENV_PKG_SV
`define ETH_ENV_PKG_SV

package eth_env_pkg;
  `include "uvm_macros.svh"
  import uvm_pkg::*;

  import eth_glob_pkg::*;
  import wb_m_agent_pkg::*;
  `include "eth_env.sv"
endpackage

`endif // ETH_ENV_PKG_SV
