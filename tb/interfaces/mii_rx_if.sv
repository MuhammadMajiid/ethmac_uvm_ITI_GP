//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : mii_rx_if.sv
// Author   : Mariam
// Date     : 2026-06-26
//------------------------------------------------------------------------------
// Description: MII Receive Interface
//==============================================================================

`ifndef MII_RX_IF_SV
`define MII_RX_IF_SV
`timescale 1ns/1ps

interface mii_rx_if #(parameter PHY_NIBBLE_WIDTH = 4)(
    input logic MRxClk,  // The Receive Clock
    input logic rst
    );

    // MII Receive Signals
    logic                        MRxDV;   // Receive Data Valid
    logic [PHY_NIBBLE_WIDTH-1:0] MRxD;    // Receive Data Nibbles
    logic                        MRxErr;  // Receive Error

    // Clocking block synchronizes the testbench to the Receive Clock
    clocking cb_mii_rx @(posedge MRxClk);
        // Inputs arrive 1 time unit before the clock edge
        // Outputs driven 1 time unit after the clock edge
        default input #1 output #1;

        // DUT inputs -> Driven by the testbench (PHY model)
        output MRxDV;
        output MRxD;
        output MRxErr;
        
        // (No DUT outputs exist on the MII RX interface)
  
    endclocking

endinterface : mii_rx_if

`endif // MII_RX_IF_SV 
