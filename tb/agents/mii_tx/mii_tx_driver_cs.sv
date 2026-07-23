//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : mii_tx_driver_cs.sv
// Author   : Wael
// Date     : 2026-07-23
//------------------------------------------------------------------------------
// Description:
// UVM driver for half duplex mode.
//==============================================================================

`ifndef MII_TX_DRIVER_CS_SV
`define MII_TX_DRIVER_CS_SV
 
class mii_tx_driver_cs extends mii_tx_driver_base;

    `uvm_component_utils(mii_tx_driver_cs)
    
    function new(string name = "mii_tx_driver_cs", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        reset_items();
        forever begin
            m_seq_item = mii_tx_seq_item_base::type_id::create("m_seq_item");
            seq_item_port.get_next_item(m_seq_item);
            m_seq_item.MCrS=m_seq_item.MCrS & vif.MTxEN;
            m_seq_item.MColl=0;
            drive_items(m_seq_item);
        end
    endtask 

endclass : mii_tx_driver_cs

`endif