//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : mii_tx_sequencer_base.sv
// Author   : Mounir
// Date     : 2026-06-24
//------------------------------------------------------------------------------
// Description:
// Base UVM sequencer for the MII Transmit Agent.
// Sits between the Virtual Sequencer and the MII Tx driver,
// arbitrating mii_tx_seq_item transactions from one or more concurrent sequences.
//==============================================================================

`ifndef MII_TX_SEQUENCER_BASE_SV
`define MII_TX_SEQUENCER_BASE_SV

class mii_tx_sequencer_base extends uvm_sequencer #(mii_tx_seq_item_base);

    `uvm_component_utils(mii_tx_sequencer_base)
	    virtual mii_tx_if vif;


    function new(string name = "mii_tx_sequencer_base", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass : mii_tx_sequencer_base

`endif 