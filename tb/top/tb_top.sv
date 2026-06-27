
`ifndef TB_TOP_SV
`define TB_TOP_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
import eth_test_pkg::*;

module tb_top;

  // -------------------------------------------------------------------------
  // Clock and reset generation (always in the module, never in UVM classes)
  // -------------------------------------------------------------------------
  logic clk_i;
  logic rst_i;

  initial clk_i = 0;
  always #5 clk_i = ~clk_i; // 100 MHz

  initial
  begin
    rst_i = 1;
    repeat (10) @(negedge clk_i);
    rst_i = 0;
  end

  // -------------------------------------------------------------------------
  // Interface instances
  // -------------------------------------------------------------------------
  wb_m_if m_wb_m_if(.clk_i(clk_i), .rst_i(rst_i));
  initial begin
    m_wb_m_if.m_addr_o=$random;
    m_wb_m_if.m_data_o=$random;
    m_wb_m_if.m_sel_o=1;
    m_wb_m_if.m_we_o=0;
    m_wb_m_if.m_stb_o=1;
    m_wb_m_if.m_cyc_o=1;
  end

  // -------------------------------------------------------------------------
  // DUT instantiation
  // -------------------------------------------------------------------------


  // -------------------------------------------------------------------------
  // UVM configuration and test launch
  // -------------------------------------------------------------------------
  initial
  begin

    // Place interface in database for the test to retrieve
    uvm_config_db #(virtual wb_m_if)::set(null, "uvm_test_top", "wb_m_vif", m_wb_m_if);

    // Select test via +UVM_TESTNAME command-line argument
    run_test("eth_test");
  end

endmodule

`endif // TB_TOP_SV
