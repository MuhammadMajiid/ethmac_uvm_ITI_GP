//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_m_seq_smoke.sv
// Author   : Wael
// Date     : 2026-07-05
//------------------------------------------------------------------------------
// Description:
//   Sequence sends dummy randomized data.
//==============================================================================
`ifndef WB_M_SEQ_SMOKE_SV
`define WB_M_SEQ_SMOKE_SV

class wb_m_seq_smoke extends wb_m_seq_base;

    `uvm_object_utils(wb_m_seq_smoke)

    function new(string name = "");
        super.new(name);
    endfunction


    task body;
        repeat(10) begin
        p_sequencer.request_fifo.get(m_req_item);    
        m_tr_item  = wb_m_seq_item_base::type_id::create("m_tr_item");
        m_tr_item.randomize();
        start_item(m_tr_item);
        finish_item(m_tr_item);
        end
    endtask


endclass : wb_m_seq_smoke

`endif // WB_M_SEQ_SMOKE_SV
