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

interface mii_tx_if (
    input logic MTxCLK,
    input logic rst_n
    );

    // MII TX Signals

    logic [3:0] MTxD;
    logic MTxEN;
    logic MTxERR;
    logic MColl;
    logic MCrS;

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
        input rst_n,

        input MColl,
        input MCrS, 
        
        output MTxD,
        output MTxEN,
        output MTxERR

    );
    
endinterface : mii_tx_if

`endif 