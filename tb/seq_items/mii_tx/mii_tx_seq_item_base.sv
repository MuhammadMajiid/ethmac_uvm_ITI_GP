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


    rand bit MColl;                // Collision signal:  The PHY asynchronously asserts it 
    rand bit MCrS;                 // Carrier Sense: The PHY asynchronously asserts it. MCrS=1 (busy medium)

    logic [3:0] MTxD;               // Transmit Data Nibble. They are synchronized to the rising edge of MTxClk.
    logic MTxEN;                    // Transmit Enable. indicates to the PHY that the data MTxD is valid and the transmission can start.
    logic MTxERR;                   // Transmit Coding Error
    rand int  MCrS_time;            // Time which carrier sense is asserted after frame transmission
    rand int MColl_time;            // Time which collision is asserted during frame transmission
    
    function new(string name = "mii_tx_seq_item_base");
        super.new(name);
    endfunction

    constraint c_default_idle { soft MColl == 1'b0;
                                soft MCrS  == 1'b0;}
                                
    constraint c_mcrs_time{
        MCrS_time inside{ETH_MAX_IPG_VAL,ETH_EXCESS_DEFER_LIMIT+ETH_MAX_IPG_VAL};
    }

    function string convert2string();
        return $sformatf("MColl=%0b, MCrS=%0b, MTxD=%0h, MTxEN=%0b, MTxERR=%0b", 
            MColl, MCrS, MTxD, MTxEN, MTxERR);
    endfunction

    function string convert2string_stimulus();
        return $sformatf("MColl=%0b, MCrS=%0b", MColl, MCrS);   
    endfunction

endclass : mii_tx_seq_item_base


`endif