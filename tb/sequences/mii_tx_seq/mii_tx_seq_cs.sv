//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : mii_tx_seq_cs.sv
// Author   : Wael
// Date     : 2026-07-23
//------------------------------------------------------------------------------
// Description:
// Extended from tx sequence base, used to assert MCrs during TX transmission.
//
//==============================================================================
`ifndef MII_TX_SEQ_CS_SV
`define MII_TX_SEQ_CS_SV

class mii_tx_seq_cs extends mii_tx_seq_base;

    `uvm_object_utils(mii_tx_seq_cs)

    function new(string name="mii_tx_seq_cs");
        super.new(name);
    endfunction

    virtual task body();
        forever
        begin
        start_item(m_tr_item);
        assert(m_tr_item.randomize() with {
            MCrS dist{1 := 95, 0 := 5};
        })   
        else begin
        `uvm_fatal(get_name(), "Failed randomization")
        end
        finish_item(m_tr_item);
        end
    endtask


endclass
`endif // MII_TX_SEQ_CS_SV