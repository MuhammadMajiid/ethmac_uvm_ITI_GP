//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : mii_tx_driver_df.sv
// Author   : Wael
// Date     : 2026-07-28
//------------------------------------------------------------------------------
// Description:
// TX driver triggerring deferral condition.
//==============================================================================

`ifndef MII_TX_DRIVER_DF_SV
`define MII_TX_DRIVER_DF_SV
 
class mii_tx_driver_df extends mii_tx_driver_base;

    `uvm_component_utils(mii_tx_driver_df)
    
    function new(string name = "mii_tx_driver_df", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        bit prev_txen;
        reset_items();
        forever begin
            m_seq_item = mii_tx_seq_item_base::type_id::create("m_seq_item");
            seq_item_port.get_next_item(m_seq_item);
            m_seq_item.MCrS=vif.MTxEN | prev_txen;
            prev_txen=vif.MTxEN;
            drive_items(m_seq_item);
        end
    endtask 

    task drive_items(mii_tx_seq_item_base m_seq_item);

    if (vif.MTxEN) begin

        // Wait  30  MII clocks 
        repeat (30) begin
            @(vif.cb_mii_tx);
        end

        // Assert collision until defer occurs
        repeat(ETH_EXCESS_DEFER_LIMIT+10) begin
            @(vif.cb_mii_tx);
            vif.cb_mii_tx.MColl <= 1'b1;
        end
    end

    endtask

endclass : mii_tx_driver_df

`endif