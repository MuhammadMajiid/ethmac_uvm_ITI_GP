//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : mii_tx_if.sv
// Author   : Mounir
// Date     : 2026-06-24
//------------------------------------------------------------------------------
// Description:
// interface for the MII Transmit path.
// Bundles all signals between the Ethernet MAC DUT and the PHY on the transmit side
//       - MTxCLK  : transmit clock driven by PHY (input to DUT)
//       - MTxD    : 4-bit transmit data nibble (output from DUT)
//       - MTxEN   : transmit enable (output from DUT)
//       - MTxERR  : transmit error (output from DUT)
//       - MColl   : collision detected signal (input to DUT)
//       - MCrS    : carrier sense signal (input to DUT)
// Used by the MII Tx Agent driver to inject MColl/MCrS
// stimulus and by the monitor to observe MTxD/MTxEN output.
//==============================================================================

`ifndef MII_TX_IF_SV
`define MII_TX_IF_SV

// Import UVM base package 
`include "uvm_macros.svh"
import uvm_pkg::*;

`timescale 1ns/1ps
interface mii_tx_if #(parameter PHY_NIBBLE_WIDTH = 4)(
    input logic MTxCLK,
    input logic rst
    );

    // MII TX Signals

    logic [PHY_NIBBLE_WIDTH-1:0] MTxD;
    logic MTxEN;
    logic MTxERR;
    logic MColl;
    logic MCrS;

    // Variable for measuring clock frequency
    real start_time=0.0;
    real meas_duty=0.0;
    real meas_per=0.0;

    
    // Clocking Block

    clocking cb_mii_tx @(posedge MTxCLK);

        // Inputs arrive before 1 time step positive edge of clk
        // Outputs driven after 1 time step positive edge of clk
        default input #1 output #1;

        //DUT outputs
        input MTxD;
        input MTxEN;
        input MTxERR;

        //DUT inputs
        output MColl;
        output MCrS;
  
    endclocking

    modport DUT (

        input MTxCLK,
        input rst,

        input MColl,
        input MCrS, 
        
        output MTxD,
        output MTxEN,
        output MTxERR

    );

  //--------------------------------------------------------------------------
  // Assertions
  //--------------------------------------------------------------------------

  // TX_RST_TXEN_DEASSERTED: MTxEN must be deasserted during reset. 
  a_rst_txen: assert property(@(posedge MTxCLK) disable iff(!rst) (rst |-> !MTxEN))
    else `uvm_error("A_MII_TX",$sformatf("Assertion failed, MTxEN = %0d",MTxEN));
  // TX_RST_TXERR_DEASSERTED: MTxERR must be deasserted during reset. 
  a_rst_txerr: assert property(@(posedge MTxCLK) disable iff(!rst) (rst |-> !MTxERR))
    else `uvm_error("A_MII_TX",$sformatf("Assertion failed, MTxERR = %0d",MTxERR));
  // TX_RST_DATA_NO_X_Z_PROPAGATION To ensure data doesn’t take x or z values after reset. 
  a_rst_x_z_txdata: assert property(@(posedge MTxCLK) disable iff(!rst) (rst |-> not $isunknown(MTxD) ))
    else `uvm_error("A_MII_TX",$sformatf("Assertion failed, MTxD = %0d",MTxD));
 
  // TX_DATA_CHANGED_TXEN Data should only change during TXEN is asserted or rise or fall.
  property p_en_data;
    @(posedge MTxCLK)  disable iff(rst) ($changed(MTxD) |-> MTxEN || $rose(MTxEN) || $fell(MTxEN));
  endproperty
  a_en_data: assert property (p_en_data);
  c_en_data: cover property (p_en_data);
  
  // TX_ERR_REQUIRES_TXEN MTxERR must only assert when MTxEN is also asserted. 
  property p_en_err;
    @(posedge MTxCLK)  disable iff(rst) (MTxERR |-> MTxEN);
  endproperty
  a_en_err: assert property (p_en_err);
  c_en_err: cover property (p_en_err);

  // TX_CLK_FREQ: Check that  MTxClk frequency is 25 MHz or 2.5 MHz with half duty cycle.
  always @(posedge MTxCLK) begin
    if(start_time==0) begin
        start_time=$realtime;
    end    
    else begin
        meas_per=$realtime-start_time;
        a_tx_freq: assert (meas_per==40 || meas_per==400)
            else `uvm_error("A_MII_TX", $sformatf("Assertion failed, Measured period = %0f ns",meas_per));
        start_time=$realtime;    
    end    
  end
  
  always @(negedge MTxCLK) begin
     if(start_time!=0) begin
        meas_duty=$realtime-start_time;
        a_tx_duty: assert (meas_duty==20 || meas_duty==200)
            else `uvm_error("A_MII_TX", $sformatf("Assertion failed, Measured duty isn't 50%%, duty = %0f ns",meas_duty));
     end   
  end
 
endinterface : mii_tx_if

`endif 