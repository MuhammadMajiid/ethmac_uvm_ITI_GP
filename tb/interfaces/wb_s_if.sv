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

endinterface

`endif // WB_S_IF_SV
