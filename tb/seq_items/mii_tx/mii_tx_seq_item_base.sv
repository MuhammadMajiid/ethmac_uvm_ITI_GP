//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : mii_tx_seq_item_base.sv
// Author   : Mounir
// Date     : 2026-06-24
//------------------------------------------------------------------------------
// Description:
// Base UVM sequence item for the MII Transmit Agent.
// Represents one complete transaction on the MII Tx interface.
// Contains randomizable fields for:
//  - Collision injection control 
//    (MColl assert timing,byte offset from preamble start, duration)
//  - Carrier sense control (MCrS assert/deassert timing)
// Also holds captured output fields
// (MTxD nibble stream, MTxEN, MTxERR) filled in by the monitor after observing
//  the DUT response.
//==============================================================================

`ifndef MII_TX_SEQ_ITEM_BASE_SV
`define MII_TX_SEQ_ITEM_BASE_SV

class mii_tx_seq_item_base extends uvm_sequence_item;
    `uvm_object_utils(mii_tx_seq_item_base)


    rand logic MColl;                // Collision signal:  The PHY asynchronously asserts it 
    rand logic MCrS;                 // Carrier Sense: The PHY asynchronously asserts it. MCrS=1 (busy medium)

    logic [3:0] MTxD;               // Transmit Data Nibble. They are synchronized to the rising edge of MTxClk.
    logic MTxEN;                    // Transmit Enable. indicates to the PHY that the data MTxD is valid and the transmission can start.
    logic MTxERR;                   // Transmit Coding Error

 
    
    function new(string name = "mii_tx_seq_item_base");
        super.new(name);
    endfunction

    constraint c_default_idle { MColl == 1'b0;
                                MCrS  == 1'b0;}
                                
    //constraint c_MCoLL {MCoLL dist{};}
    //constraint c_MCrS {MCrS dist{};}

    function string convert2string();
        return $sformatf("MColl=%0b, MCrS=%0b, MTxD=%0h, MTxEN=%0b, MTxERR=%0b", 
            MColl, MCrS, MTxD, MTxEN, MTxERR);
    endfunction

    function string convert2string_stimulus();
        return $sformatf("MColl=%0b, MCrS=%0b", MColl, MCrS);   
    endfunction

endclass : mii_tx_seq_item_base


`endif