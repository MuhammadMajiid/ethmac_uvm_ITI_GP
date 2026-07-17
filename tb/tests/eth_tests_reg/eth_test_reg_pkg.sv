
`ifndef ETH_TEST_REG_PKG_SV
`define ETH_TEST_TX_PKG_SV

package eth_test_reg_pkg;
  `include "uvm_macros.svh"
  import uvm_pkg::*;
  
  import eth_glob_pkg::*;
  
  // import config package
  import eth_config_pkg::*;

  // import virtual sequence/sequencer package
  import eth_v_seq_sqr_pkg::*;

  // import environment package
  import eth_env_pkg::*;
  
  import wb_s_seq_pkg::*; 

  `include "eth_base_test.sv"
  
  `include "eth_test_reg_access.sv"
  
  `include "eth_test_bd_access.sv"
endpackage

`endif // ETH_TEST_TX_PKG_SV
