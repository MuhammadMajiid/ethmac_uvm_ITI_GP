`timescale 1ns/1ps

module eth_tb;

  import uvm_pkg::*;
  import eth_glob_pkg::*;
  import eth_test_tx_pkg::*;
  
  //--------------------------------------------------------------------------
  // Clock / Reset
  //--------------------------------------------------------------------------
  bit wb_clk,tx_clk;
  bit rst;

  //--------------------------------------------------------------------------
  // Wishbone slave Interface
  //--------------------------------------------------------------------------
  wb_s_if #(
    .WB_S_ADDR_WIDTH (WB_S_ADDR_WIDTH),
    .WB_DATA_WIDTH (WB_DATA_WIDTH),
    .WB_SEL_WIDTH(WB_SEL_WIDTH)
  ) m_wb_s_if (
    .clk(wb_clk),
    .rst(rst)
  );

  //--------------------------------------------------------------------------
  // Wishbone master Interface
  //--------------------------------------------------------------------------
   wb_m_if #(
    .ADDR_WIDTH (WB_M_ADDR_WIDTH),
    .DATA_WIDTH (WB_DATA_WIDTH),
    .SEL_WIDTH(WB_SEL_WIDTH)
    ) m_wb_m_if(.clk_i(wb_clk), .rst_i(rst));

  //--------------------------------------------------------------------------
  // MII TX Interface
  //--------------------------------------------------------------------------
    mii_tx_if #(.PHY_NIBBLE_WIDTH(ETH_NIBBLE_WIDTH)) m_mii_tx_if(
        .MTxCLK(tx_clk),
        .rst(rst)
        );

  //--------------------------------------------------------------------------
  // wishbone Clock Generation 
  //--------------------------------------------------------------------------
  initial begin
    wb_clk = 0;
    forever #(WB_CLK_PERIOD_NS/2.0) wb_clk = ~wb_clk;
  end

  //--------------------------------------------------------------------------
  // TX Clock Generation 
  //--------------------------------------------------------------------------
  initial begin
    tx_clk = 0;
    forever #(ETH_PHY_TX_CLK_PERIOD_NS/2.0) tx_clk = ~tx_clk;
  end

  //--------------------------------------------------------------------------
  // Reset Generation
  //--------------------------------------------------------------------------
  initial begin
    rst = 1'b1;
    #50;
    rst = 1'b0;
  end

  //--------------------------------------------------------------------------
  // DUT
  //--------------------------------------------------------------------------
  eth_top dut
  (
      // Wishbone Slave 
      .wb_clk_i (wb_clk),
      .wb_rst_i (rst),

      .wb_adr_i (m_wb_s_if.addr_i),
      .wb_dat_i (m_wb_s_if.wdata_i),
      .wb_sel_i (m_wb_s_if.sel_i),
      .wb_we_i  (m_wb_s_if.we_i),
      .wb_stb_i (m_wb_s_if.stb_i),
      .wb_cyc_i (m_wb_s_if.cyc_i),

      .wb_dat_o (m_wb_s_if.rdata_o),
      .wb_ack_o (m_wb_s_if.ack_o),
      .wb_err_o (m_wb_s_if.err_o),

      .int_o    (m_wb_s_if.inta_o),

      // Wishbone Master 
      .m_wb_adr_o       (m_wb_m_if.m_addr_o),
      .m_wb_cyc_o       (m_wb_m_if.m_cyc_o),
      .m_wb_stb_o       (m_wb_m_if.m_stb_o),
      .m_wb_we_o        (m_wb_m_if.m_we_o),
      .m_wb_sel_o       (m_wb_m_if.m_sel_o),
      .m_wb_dat_o       (m_wb_m_if.m_data_o),
      .m_wb_dat_i       (m_wb_m_if.m_data_i),
      .m_wb_ack_i       (m_wb_m_if.m_ack_i),
      .m_wb_err_i       (m_wb_m_if.m_err_i),
      
      // MII TX 
      .mtx_clk_pad_i    (tx_clk),
      .mtxd_pad_o       (m_mii_tx_if.MTxD),
      .mtxen_pad_o     (m_mii_tx_if.MTxEN),
      .mtxerr_pad_o    (m_mii_tx_if.MTxERR),
      .mcoll_pad_i      (1'b0),
      .mcrs_pad_i       (1'b0)

  );

  //--------------------------------------------------------------------------
  // UVM Configuration
  //--------------------------------------------------------------------------
  initial begin

    uvm_config_db#(virtual wb_m_if)::set(null,"*","wb_m_vif",m_wb_m_if);
    uvm_config_db#(virtual wb_s_if)::set(null,"*","wb_s_vif", m_wb_s_if);
    uvm_config_db#(virtual mii_tx_if)::set(null,"*","mii_tx_vif",m_mii_tx_if);

    
    run_test();

  end

endmodule
