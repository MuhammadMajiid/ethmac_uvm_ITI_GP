//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_if.sv
// Author   : Nada
// Date     : 2026-06-25
//------------------------------------------------------------------------------
// Description:
// Wishbone slave interface used between the UVM testbench and the ETHMAC DUT.
//
// Inputs to DUT (driven by testbench):
//   clk    - Clock
//   rst    - Reset
//   addr   - Address
//   wdata  - Write data
//   sel    - Byte enables
//   we     - Write enable
//   stb    - Strobe
//   cyc    - Bus cycle indicator
//
// Outputs from DUT:
//   rdata  - Read data
//   ack    - Transfer acknowledge
//   err    - Transfer error
//   inta   - Interrupt request
//==============================================================================
`timescale 1ns/1ps
`ifndef WB_S_IF_SV
`define WB_S_IF_SV
    `include "uvm_macros.svh"
    import uvm_pkg::*;

interface wb_s_if #(
    parameter int WB_S_ADDR_WIDTH = 10,
    parameter int WB_DATA_WIDTH  = 32,
    parameter int WB_SEL_WIDTH    = 4
)(
    input logic clk,
    input logic rst
);

  //--------------------------------------------------------------------------
  // Inputs to DUT
  //--------------------------------------------------------------------------
  logic [WB_S_ADDR_WIDTH-1:0] addr_i;
  logic [WB_DATA_WIDTH-1:0]   wdata_i;
  logic [WB_SEL_WIDTH-1:0]    sel_i;
  logic                       we_i;
  logic                       stb_i;
  logic                       cyc_i;

  //--------------------------------------------------------------------------
  // Outputs from DUT
  //--------------------------------------------------------------------------
  logic [WB_DATA_WIDTH-1:0] rdata_o;
  logic                     ack_o;
  logic                     err_o;
  logic                     inta_o;

  //--------------------------------------------------------------------------
  // Clocking block
  //--------------------------------------------------------------------------
  clocking cb @(posedge clk);
    default input #1 output #1;

    // Outputs from DUT
    input  rdata_o;
    input  ack_o;
    input  err_o;
    input  inta_o;

    // Inputs to DUT
    output addr_i;
    output wdata_i;
    output sel_i;
    output we_i;
    output stb_i;
    output cyc_i;

  endclocking

  //--------------------------------------------------------------------------
  // Assertions
  //--------------------------------------------------------------------------

  // WBS_RESET_NO_X_Z_PROPAGATION: Ensures no x z propagation for all ports
  a_rst_x_z_rdata: assert property(@(posedge clk) disable iff(!rst) (rst |-> |rdata_o!==1'bz && |rdata_o!==1'bx))
    else `uvm_error("A_WB_S",$sformatf("Assertion failed, read data = %0d",rdata_o));
  a_rst_x_z_ack: assert property(@(posedge clk) disable iff(!rst)   (rst |-> ack_o!==1'bz && ack_o!==1'bx))
    else `uvm_error("A_WB_S",$sformatf("Assertion failed, ack = %0d",ack_o));
  a_rst_x_z_err: assert property(@(posedge clk) disable iff(!rst)   (rst |-> err_o!==1'bz && err_o!==1'bx))
    else `uvm_error("A_WB_S",$sformatf("Assertion failed, err = %0d",err_o));
  a_rst_x_z_inta: assert property(@(posedge clk) disable iff(!rst)   (rst |-> inta_o!==1'bz && inta_o!==1'bx))
    else `uvm_error("A_WB_S",$sformatf("Assertion failed, inta = %0d",inta_o));
  
  // WBS_RST_ACK_DEASSERTED : Ensures ack is 0 during rst
  a_rst_ack: assert property(@(posedge clk) disable iff(!rst)   (rst |-> ack_o==1'b0 ))
    else `uvm_error("A_WB_S",$sformatf("Assertion failed, ack = %0d",ack_o));
  // WBS_ACK_ACK_DEASSERTED : Ensures ack is 0 during rst
  a_rst_err: assert property(@(posedge clk) disable iff(!rst)   (rst |-> err_o==1'b0))
    else `uvm_error("A_WB_S",$sformatf("Assertion failed, err = %0d",err_o));

  // WBS_STB_REQUIRES_CYC: STB_I must never be asserted without CYC_I also being asserted in the same cycle.   
  property p_stb_cyc;
    @(posedge clk)  disable iff(rst) (stb_i |-> cyc_i);
  endproperty
  a_stb_cyc: assert property (p_stb_cyc)
    else `uvm_error("A_WB_S", "a_stb_cyc");
  c_stb_cyc: cover property (p_stb_cyc);

  // WBS_ACK_REQUIRES_STB_CYC: ACK_O may only assert when both CYC_I and STB_I are simultaneously high.  
  property p_ack_stb_cyc;
     @(posedge clk) disable iff(rst) (ack_o |-> stb_i && cyc_i);
  endproperty
  a_ack_stb_cyc: assert property (p_ack_stb_cyc)
    else `uvm_warning("A_WB_S", "a_ack_stb_cyc");
  c_ack_stb_cyc: cover property (p_ack_stb_cyc);

  // WBS_ERR_REQUIRES_STB_CYC: ERR_O may only assert when both CYC_I and STB_I are simultaneously high.  
  property p_err_stb_cyc;
     @(posedge clk) disable iff(rst) (err_o |-> stb_i && cyc_i);
  endproperty
  a_err_stb_cyc: assert property (p_err_stb_cyc)
    else `uvm_error("A_WB_S", "a_err_stb_cyc");
  c_err_stb_cyc: cover property (p_err_stb_cyc);

  // WBS_ACK_ERR_MUTEX: ACK_O and ERR_O must never be asserted simultaneously.
  property p_ack_err_cyc;
     @(posedge clk) disable iff(rst) ($onehot({ack_o,err_o}) || (!ack_o && !err_o));
  endproperty
  a_ack_err_cyc: assert property (p_ack_err_cyc)
    else `uvm_error("A_WB_S", "a_ack_err_cyc");
  c_ack_err_cyc: cover property (p_ack_err_cyc);

  // WBS_ACK_ERR_ON_PARTIAL_SEL: When SEL_I is not 4'hF during a valid bus cycle ERR_O must assert AND ACK_O must not assert. 
  property p_ack_err_sel;
     @(posedge clk) disable iff(rst) (stb_i && cyc_i && !(&sel_i)) |=> (err_o && !ack_o) ;
  endproperty
  a_ack_err_sel: assert property (p_ack_err_sel)
    else `uvm_error("A_WB_S", "a_ack_err_sel");
  c_ack_err_sel: cover property (p_ack_err_sel);

  // WBS_ADDR_STABLE: ADDR_I must not change before ACK_O arrives during a write or read cycle wait state.
  property p_addr_ack;
     @(posedge clk) disable iff(rst) ($rose(stb_i) && $rose(cyc_i)) |=> ( $stable(addr_i) until_with (ack_o || err_o));
  endproperty
  a_addr_ack: assert property (p_addr_ack)
    else `uvm_error("A_WB_S", "a_addr_ack");
  c_addr_ack: cover property (p_addr_ack);

  // WBS_WE_STABLE_DURING_TRANSFER: WE_I must not change during a DMA bus phase while waiting for ACK_O. 
  property p_we_ack;
     @(posedge clk) disable iff(rst) ($rose(stb_i) && $rose(cyc_i)) |=> ( $stable(we_i) until_with (ack_o || err_o));
  endproperty
  a_we_ack: assert property (p_we_ack)
    else `uvm_error("A_WB_S", "a_we_ack");
  c_we_ack: cover property (p_we_ack);

  // WBS_WRITE_SEL_STABLE SEL_I must not change during any wait state before ACK_O. 
  property p_sel_ack;
     @(posedge clk) disable iff(rst) ($rose(stb_i) && $rose(cyc_i)) |=> ( $stable(sel_i) until_with (ack_o || err_o));
  endproperty
  a_sel_ack: assert property (p_sel_ack)
    else `uvm_error("A_WB_S", "a_sel_ack");
  c_sel_ack: cover property (p_sel_ack);

  // WBS_WRITE_DATA_STABLE During a write cycle wait state DATA_I must remain stable until ACK_O arrives.  
  property p_wdata_ack;
     @(posedge clk) disable iff(rst) ($rose(stb_i) && $rose(cyc_i) && we_i) |=> ( $stable(wdata_i) until_with (ack_o || err_o));
  endproperty
  a_wdata_ack: assert property (p_wdata_ack)
    else `uvm_error("A_WB_S", "a_wdata_ack");
  c_wdata_ack: cover property (p_wdata_ack);

endinterface
`endif // WB_S_IF_SV
