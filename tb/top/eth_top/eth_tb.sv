`timescale 1ns/1ps

module eth_tb;

  import uvm_pkg::*;
  import wb_s_pkg::*;
  import eth_ral_pkg::*;
  import eth_env_pkg::*;
  import eth_glob_pkg::*;

  //--------------------------------------------------------------------------
  // Clock / Reset
  //--------------------------------------------------------------------------
  bit clk;
  bit rst;

  //--------------------------------------------------------------------------
  // Interface
  //--------------------------------------------------------------------------
  wb_s_if #(
    .WB_S_ADDR_WIDTH (WB_S_ADDR_WIDTH),
    .WB_DATA_WIDTH (WB_DATA_WIDTH),
    .WB_SEL_WIDTH(WB_SEL_WIDTH)
  ) wb_s_if (
    .clk(clk),
    .rst(rst)
  );

  //--------------------------------------------------------------------------
  // Environment Configuration
  //--------------------------------------------------------------------------
  eth_env_config_obj env_cfg;

  //--------------------------------------------------------------------------
  // Clock Generation (100 MHz)
  //--------------------------------------------------------------------------
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  //--------------------------------------------------------------------------
  // Reset Generation
  //--------------------------------------------------------------------------
  initial begin
    rst = 1'b1;
    #2;
    rst = 1'b0;
  end

  //--------------------------------------------------------------------------
  // DUT
  //--------------------------------------------------------------------------
  eth_top dut
  (
      .wb_clk_i (wb_s_if.clk),
      .wb_rst_i (wb_s_if.rst),

      .wb_adr_i (wb_s_if.addr_i),
      .wb_dat_i (wb_s_if.wdata_i),
      .wb_sel_i (wb_s_if.sel_i),
      .wb_we_i  (wb_s_if.we_i),
      .wb_stb_i (wb_s_if.stb_i),
      .wb_cyc_i (wb_s_if.cyc_i),

      .wb_dat_o (wb_s_if.rdata_o),
      .wb_ack_o (wb_s_if.ack_o),
      .wb_err_o (wb_s_if.err_o),

      .int_o    (wb_s_if.inta_o)
  );

  //--------------------------------------------------------------------------
  // UVM Configuration
  //--------------------------------------------------------------------------
  initial begin

    env_cfg = new("env_cfg");

    env_cfg.m_wb_s_config = new("wb_s_cfg");

    env_cfg.m_wb_s_config.vif       = wb_s_if;
    env_cfg.m_wb_s_config.is_active = UVM_ACTIVE;

    uvm_config_db#(eth_env_config_obj)::set(
      null,
      "*",
      "config",
      env_cfg
    );

    run_test("eth_test_reg_access");

  end

endmodule
