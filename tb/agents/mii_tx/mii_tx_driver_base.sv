//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : mii_tx_driver_base.sv
// Author   : Mounir
// Date     : 2026-06-24
//------------------------------------------------------------------------------
// Description:
// Base UVM driver for the MII Transmit Agent.
// Pulls mii_tx_seq_item transactions from the sequencer and
// drives them cycle-accurately onto the mii_tx_if interface.
// Core responsibilities:
//   - Driving MCrS (carrier sense) to create medium-busy
//     conditions for deferral tests (HD-CS-01 to HD-CS-06)
//   - Injecting MColl pulses at the exact byte offset
//     specified in the sequence item for collision tests
//     (HD-COL-01 to HD-COL-06)
//   - Timing all stimulus relative to MTxCLK edges and
//     byte/nibble counts from preamble start
//   - Respecting duplex_mode from config_obj — suppressing
//     MColl/MCrS injection in FULL_DUPLEX mode (CMB-01)
//==============================================================================

`ifndef MII_TX_DRIVER_BASE_SV
`define MII_TX_DRIVER_BASE_SV
 
class mii_tx_driver_base extends uvm_driver #(mii_tx_seq_item_base);

    `uvm_component_utils(mii_tx_driver_base)

    mii_tx_seq_item_base m_seq_item;

    virtual mii_tx_if vif;
    
    function new(string name = "mii_tx_driver_base", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        reset_items();
        forever begin
            m_seq_item = mii_tx_seq_item_base::type_id::create("m_seq_item");
            drive_items(m_seq_item);
        end
    endtask 

    // Task: reset_items
    task reset_items();
        vif.cb_mii_tx.MColl<=0;
        vif.cb_mii_tx.MCrS <=0;
        @(negedge vif.rst_n);   // wait for reset assertion
        @(posedge vif.rst_n);   // wait for reset deassertion
        @(posedge vif.MTxCLK);  
        `uvm_info("DRIVER", "Reset deasserted — starting stimulus", UVM_LOW)
    endtask

    // Task: drive_items
    task drive_items(mii_tx_seq_item_base m_seq_item);
        // Get the next item from the sequencer
        seq_item_port.get_next_item(m_seq_item);

        // Drive pin level DUT signals
        vif.cb_mii_tx.MColl <= m_seq_item.MColl ;
        vif.cb_mii_tx.MCrS <= m_seq_item.MCrS ;

        @(negedge vif.MTxCLK);

        seq_item_port.item_done();
            `uvm_info("run_phase", m_seq_item.convert2string_stimulus(), UVM_MEDIUM)
    endtask 
    
endclass : mii_tx_driver_base

`endif