//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_s_seq_tx_len.sv
// Author   : Wael
// Date     : 2026-07-23
//------------------------------------------------------------------------------
// Description:
// Used for testing different packet lengths.
//==============================================================================
`ifndef WB_S_SEQ_TX_LEN
`define WB_S_SEQ_TX_LEN
class wb_s_seq_tx_len extends wb_s_basic_tx_seq;

    `uvm_object_utils(wb_s_seq_tx_len)

    function new(string name="wb_s_seq_tx_len");
        super.new(name);
    endfunction


    task body();
    //-----------------------------------------------------
    // Randomize transaction
    //-----------------------------------------------------
    assert(m_item.randomize() with {
    pkt_data dist{'hFFFF_FFFF:=5, 'h0000_0000 := 5,['h0000_0001:'hFFFF_FFFE] :/ 95};
    tx_bd_num inside{1,2};
    foreach (pkt_len[i]){
        pkt_len[i] dist {'hFFFF:=8, ['h0001:'h0004] := 2,['h0005:'hFFFE] :/ 95}; 
        if(tx_bd_num==2)
            pkt_len[i] >4;
    }
    maxfl==100;
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
    configure_tx_registers(.tx_bd_num(m_item.tx_bd_num),.maxfl(m_item.maxfl),.txen(1));


    `uvm_info(get_type_name(),
                "Packet length TX configuration completed",
                UVM_LOW)

    repeat(m_item.tx_bd_num) begin
        @(m_ev_end_pkt);
    end 

    endtask

endclass
`endif
