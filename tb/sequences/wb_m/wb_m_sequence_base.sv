`ifndef WB_M_SEQUENCE_BASE_SV
`define WB_M_SEQUENCE_BASE_SV

class wb_m_sequence_base extends uvm_sequence #(wb_m_seq_item_base);

    `uvm_object_utils(wb_m_sequence_base)
    `uvm_declare_p_sequencer (wb_m_sequencer_base)
    
    wb_m_seq_item_base m_tr_item;
    wb_m_seq_item_base m_req_item;

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


endclass : wb_m_sequence_base

`endif // WB_M_SEQUENCE_BASE_SV
