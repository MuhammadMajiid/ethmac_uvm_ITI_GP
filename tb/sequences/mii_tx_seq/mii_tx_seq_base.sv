//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : mii_tx_seq_base.sv
// Author   : Wael
// Date     : 2026-07-14
//------------------------------------------------------------------------------
// Description:
// Base UVM sequence for the MII tx Agent.
//
//==============================================================================
`ifndef MII_TX_SEQ_BASE_SV
`define MII_TX_SEQ_BASE_SV

class mii_tx_seq_base extends uvm_sequence;

    `uvm_object_utils(mii_tx_seq_base)

    function new(string name="mii_tx_seq_base");
        super.new(name);
    endfunction

    virtual task body();
        mii_tx_seq_item_base m_tr_item  = mii_tx_seq_item_base::type_id::create("m_tr_item");
        forever
        begin
        start_item(m_tr_item);
        finish_item(m_tr_item);
        end
    endtask


endclass
`endif // MII_TX_SEQ_BASE_SV