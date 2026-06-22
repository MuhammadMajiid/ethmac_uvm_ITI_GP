
`ifndef TB_TOP_SV
`define TB_TOP_SV

`include "uvm_macros.svh"

import uvm_pkg::*;
import mii_rx_pkg::*;
import mii_tx_pkg::*;
import mdio_pkg::*;
import eth_env_pkg::*;
import eth_test_pkg::*;

module tb_top;

  // -------------------------------------------------------------------------
  // Clock and reset generation (always in the module, never in UVM classes)
  // -------------------------------------------------------------------------
  logic clk;
  logic rst_n;

  initial clk = 0;
  always #5 clk = ~clk; // 100 MHz

  initial
  begin
    rst_n = 0;
    repeat (10) @(posedge clk);
    rst_n = 1;
  end

  // -------------------------------------------------------------------------
  // Interface instances
  // -------------------------------------------------------------------------
  mii_rx_if mii_rx_if_inst (.clk(clk), .rst_n(rst_n));
  mii_tx_if mii_tx_if_inst (.clk(clk), .rst_n(rst_n));
  mdio_if   mdio_if_inst   (.clk(clk), .rst_n(rst_n));

  // Wishbone interfaces (used by Wishbone Master/Slave agents - not implemented here)
  // wb_slave_if  wb_slave_if_inst  (...);
  // wb_master_if wb_master_if_inst (...);

  // -------------------------------------------------------------------------
  // DUT instantiation
  // -------------------------------------------------------------------------
  // eth_top dut (
  //   .clk      (clk),
  //   .rst_n    (rst_n),
  //   .mii_rxd  (mii_rx_if_inst.rxd),
  //   .mii_rx_dv(mii_rx_if_inst.rx_dv),
  //   .mii_txd  (mii_tx_if_inst.txd),
  //   .mii_tx_en(mii_tx_if_inst.tx_en),
  //   .mdio     (mdio_if_inst.mdio),
  //   .mdc      (mdio_if_inst.mdc)
  // );

  // -------------------------------------------------------------------------
  // UVM configuration and test launch
  // -------------------------------------------------------------------------
  initial
  begin
    automatic eth_config cfg = new("cfg");

    // Bind virtual interfaces into the config object
    cfg.mii_rx_vif = mii_rx_if_inst;
    cfg.mii_tx_vif = mii_tx_if_inst;
    cfg.mdio_vif   = mdio_if_inst;

    // All agents active by default; override here if passive monitoring needed
    cfg.mii_rx_is_active = UVM_ACTIVE;
    cfg.mii_tx_is_active = UVM_ACTIVE;
    cfg.mdio_is_active   = UVM_ACTIVE;

    // Place config in database for the test to retrieve
    uvm_config_db #(eth_config)::set(null, "uvm_test_top", "config", cfg);

    // Select test via +UVM_TESTNAME command-line argument
    run_test();
  end

endmodule

`endif // TB_TOP_SV
