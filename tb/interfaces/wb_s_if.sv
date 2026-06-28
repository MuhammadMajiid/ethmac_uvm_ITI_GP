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
interface wb_s_if (input logic clk , rst);
  //--------------------------------------------------------------------------
  // Inputs to DUT
  //--------------------------------------------------------------------------
  logic [9:0]   addr ;
  logic [31:0]  wdata ;
  logic [3:0]   sel ;
  logic         we ;   
  logic         stb ;  
  logic         cyc ;  
  //--------------------------------------------------------------------------
  // Outputs from DUT 
  //--------------------------------------------------------------------------
  logic [31:0]  rdata;
  logic         ack ;
  logic         err ;
  logic         inta ;  


  //--------------------------------------------------------------------------
  // Clocking block - isolates the testbench from gate-level timing and
  // scheduler ordering. Inputs (DUT outputs) sampled with a negative skew
  // so the testbench always sees the value as it was AFTER the clock edge
  // has fully settled, never racing the DUT's own synchronous update.
  // Outputs (DUT inputs) driven with a small positive skew, the standard
  // pattern for avoiding setup-time races on the driven side.
  //--------------------------------------------------------------------------
clocking cb @(posedge clk);
    default input #1 output #1;

  //--------------------------------------------------------------------------
  // Outputs from DUT
  //--------------------------------------------------------------------------
  input         rdata;
  input         ack;
  input         err;
  input         inta;

  //--------------------------------------------------------------------------
  // Inputs to DUT
  //--------------------------------------------------------------------------
  output         addr;
  output         wdata;
  output         sel;
  output         we;
  output         stb;
  output         cyc;
    
  endclocking



endinterface
`endif // WB_S_IF_SV
