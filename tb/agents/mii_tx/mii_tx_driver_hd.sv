//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : mii_tx_driver_hd.sv
// Author   : Wael
// Date     : 2026-07-14
//------------------------------------------------------------------------------
// Description:
// UVM driver for half duplex mode.
//==============================================================================

`ifndef MII_TX_DRIVER_HD_SV
`define MII_TX_DRIVER_HD_SV
 
class mii_tx_driver_hd extends mii_tx_driver_base;

    `uvm_component_utils(mii_tx_driver_hd)
    
    function new(string name = "mii_tx_driver_hd", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        bit prev_txen;
        reset_items();
        forever begin
            m_seq_item = mii_tx_seq_item_base::type_id::create("m_seq_item");
            seq_item_port.get_next_item(m_seq_item);
            m_seq_item.MCrS=vif.MTxEN | prev_txen;
            m_seq_item.MColl=0;
            prev_txen=vif.MTxEN;
            drive_items(m_seq_item);
        end
    endtask 

endclass : mii_tx_driver_hd

`endif