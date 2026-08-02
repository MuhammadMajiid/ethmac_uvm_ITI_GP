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
    bit prev_txen;
    bit frame_no;
    
    function new(string name = "mii_tx_driver_df", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        reset_items();
        forever begin
            seq_item_port.get_next_item(m_seq_item);
            m_seq_item.randomize();
            // If next bd is the first, assert carrier sense time for less excessive defer
            if (frame_no) begin
                m_seq_item.MCrS_time=ETH_MAX_IPG_VAL;
            end
            if(vif.rst) begin
                m_seq_item.MCrS_time=ETH_MAX_IPG_VAL;
                frame_no=0;
            end
            m_seq_item.MCrS=prev_txen | vif.MTxEN;
            prev_txen = vif.MTxEN;
            drive_items(m_seq_item);
            seq_item_port.item_done();
        end
    endtask 

    task drive_items(mii_tx_seq_item_base m_seq_item);
        vif.cb_mii_tx.MColl<=m_seq_item.MColl;
        vif.cb_mii_tx.MCrS<=m_seq_item.MCrS;
        @(vif.cb_mii_tx);

        if(prev_txen && !vif.MTxEN) begin
            prev_txen=0;
            frame_no++;
            // Deassert MCrs for one cycle  
            vif.cb_mii_tx.MCrS<=0;
            @(vif.cb_mii_tx);
            vif.cb_mii_tx.MCrS<=1;
            // Assert carrier sense for  MAXIMUM DEFER limit + 50  MII clocks 
            repeat (m_seq_item.MCrS_time) begin
                @(vif.cb_mii_tx);
                if(vif.rst)
                break;
            end
        end
    endtask

endclass : mii_tx_driver_df

`endif