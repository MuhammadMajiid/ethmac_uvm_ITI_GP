//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_s_seq_tx_df.sv
// Author   : Wael
// Date     : 2026-07-28
//------------------------------------------------------------------------------
// Description:
// Used for testing deferral.
//==============================================================================
`ifndef WB_S_SEQ_TX_DF
`define WB_S_SEQ_TX_DF
class wb_s_seq_tx_df extends wb_s_basic_tx_seq;

    `uvm_object_utils(wb_s_seq_tx_df)
    uvm_reg_data_t rd_data;

    function new(string name="wb_s_seq_tx_df");
        super.new(name);
    endfunction


    task body();
    //-----------------------------------------------------
    // Randomize transaction
    //-----------------------------------------------------
    assert(m_item.randomize() with {
    tx_bd_num ==2;
    moder_fd ==0;
    foreach (pkt_len[i]){
        pkt_len[i]<100;
        pkt_len[i]>4;
    }
    ipgr1 inside {'h0000_0000,'h0000_0020,'h0000_007F};
    ipgr2 inside {'h0000_0000,'h0000_0020,'h0000_007F};
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
    configure_tx_registers(.tx_bd_num(m_item.tx_bd_num),.fulld(m_item.moder_fd),.ipgr1(m_item.ipgr1),
                           .ipgr2(m_item.ipgr2),.exdf(m_item.moder_exdf),.txen(1));


    `uvm_info(get_type_name(),
                "DF TX configuration completed",
                UVM_LOW)

    // Read carrier sense lost for coverage
    for(int i=0; i<m_item.tx_bd_num; i++) begin
        @(m_ev_end_pkt);
        `uvm_info(get_name(), "Reading carrier sense lost", UVM_MEDIUM)
        // Read bd
        regmodel.eth_bd_mem.read(status,i*2,rd_data, UVM_FRONTDOOR);
        // if carrier sense is asserted clear it
        `uvm_info(get_name(),$sformatf("Deferral bit = %0b",rd_data[1]),UVM_MEDIUM)
        if(rd_data[1]) begin
        rd_data = rd_data ^ (1'b1<<1);
        // clear deferral bit
        regmodel.eth_bd_mem.write(status,i*2,rd_data, UVM_BACKDOOR);
    end
    #(4*ETH_PHY_TX_CLK_PERIOD_NS);
    end 

    endtask

endclass
`endif
