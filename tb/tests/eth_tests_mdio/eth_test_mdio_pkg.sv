`ifndef ETH_TEST_MDIO_PKG_SV
`define ETH_TEST_MDIO_PKG_SV

package eth_test_mdio_pkg;
  `include "uvm_macros.svh"
  import uvm_pkg::*;
  
  import eth_glob_pkg::*;
  
  // import config package
  import eth_config_pkg::*;



  // import virtual sequence/sequencer package
  import eth_v_seq_sqr_pkg::*;

  // import sequences package
  import wb_m_seq_pkg::*;
  import wb_s_seq_pkg::*;
  import mii_tx_seq_pkg::*;
  import reset_seq_pkg::*;
  import mdio_seq_pkg::*;

  // import tx agent package
  import mii_tx_agent_pkg::*;

  // import environment package
  import eth_env_pkg::*;

  `include "eth_test_mdio_base.sv"
  `include "eth_test_mdio_lib.sv"

endpackage

`endif // ETH_TEST_MDIO_PKG_SV