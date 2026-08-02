//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_s_seq_tx_ptr.sv
// Author   : Wael
// Date     : 2026-08-01
//------------------------------------------------------------------------------
// Description:
// Used for testing non-aligned pointers.
//==============================================================================
`ifndef WB_S_SEQ_TX_PTR
`define WB_S_SEQ_TX_PTR
class wb_s_seq_tx_ptr extends wb_s_basic_tx_seq;

    `uvm_object_utils(wb_s_seq_tx_ptr)
    uvm_reg_data_t rd_data;

    function new(string name="wb_s_seq_tx_ptr");
        super.new(name);
    endfunction


    task body();
    //-----------------------------------------------------
    // Randomize transaction
    //-----------------------------------------------------
    assert(m_item.randomize() with {
    tx_bd_num==1;
    foreach (tx_pnt[i]){
        tx_pnt[i]%4!=0;
    }
    foreach (pkt_len[i]){
        pkt_len[i]<100;
        pkt_len[i]>4;
    }
    })   
    else begin
    `uvm_fatal(get_name(), "Failed randomization")
    end

    //-----------------------------------------------------
    // Write dma memory & program buffer descriptors
    //-----------------------------------------------------
    for(int bd=0; bd<m_item.tx_bd_num; bd++) begin
        dma_mem_wr(m_item.tx_pnt[bd],m_item.pkt_len[bd],0,1);

        configure_tx_bd(.bd_index(bd),.frame_length(m_item.pkt_len[bd]),.frame_ptr(m_item.tx_pnt[bd]),.enable_irq(0),
        .is_wrap(bd == m_item.tx_bd_num-1),.enable_pad(m_item.bd_pad[bd]),.enable_crc(m_item.bd_crc[bd]));
    end

    //-----------------------------------------------------
    // Configure registers
    //-----------------------------------------------------
    configure_tx_registers(.tx_bd_num(m_item.tx_bd_num),.txen(1));


    `uvm_info(get_type_name(),
                "Non-aligned pointers TX configuration completed",
                UVM_LOW)

    //-----------------------------------------------------
    // Wait until all frames complete
    //-----------------------------------------------------
    repeat (m_item.tx_bd_num)
        @(m_ev_end_pkt);


    endtask

endclass
`endif
