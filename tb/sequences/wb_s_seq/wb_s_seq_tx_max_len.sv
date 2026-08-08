//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_s_seq_tx_max_len.sv
// Author   : Wael
// Date     : 2026-08-06
//------------------------------------------------------------------------------
// Description:
// Used for maximum packet lengths.
//==============================================================================
`ifndef WB_S_SEQ_TX_MAX_LEN
`define WB_S_SEQ_TX_MAX_LEN
class wb_s_seq_tx_max_len extends wb_s_basic_tx_seq;

    `uvm_object_utils(wb_s_seq_tx_max_len)

    function new(string name="wb_s_seq_tx_max_len");
        super.new(name);
    endfunction


    task body();
    //-----------------------------------------------------
    // Randomize transaction
    //-----------------------------------------------------
    assert(m_item.randomize() with {
    tx_bd_num ==1;
    moder_fd==1;
    foreach (pkt_len[i]){
        pkt_len[i] == 'hFFFF; 
    }
        maxfl=='hFFFF;
    })   
    else begin
    `uvm_fatal(get_name(), "Failed randomization")
    end

    //-----------------------------------------------------
    // Write dma memory & program buffer descriptors
    //-----------------------------------------------------
    for(int bd=0; bd<m_item.tx_bd_num; bd++) begin
        dma_mem_wr(m_item.tx_pnt[bd],m_item.pkt_len[bd],m_item.pkt_data);

        configure_tx_bd(.bd_index(bd),.frame_length(m_item.pkt_len[bd]),.frame_ptr(m_item.tx_pnt[bd]),.enable_irq(0),
        .is_wrap(bd == m_item.tx_bd_num-1),.enable_pad(m_item.bd_pad[bd]),.enable_crc(m_item.bd_crc[bd]));
    end

    //-----------------------------------------------------
    // Configure registers
    //-----------------------------------------------------
    configure_tx_registers(.tx_bd_num(m_item.tx_bd_num),.maxfl(m_item.maxfl),.fulld(m_item.moder_fd)
                           ,.txen(1));


    `uvm_info(get_type_name(),
                "Maximum Packet length TX configuration completed",
                UVM_LOW)

    repeat(m_item.tx_bd_num) begin
        @(m_ev_end_pkt);
    end 

    endtask

endclass
`endif
