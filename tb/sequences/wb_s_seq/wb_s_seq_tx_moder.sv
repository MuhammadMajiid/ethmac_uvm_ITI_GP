//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_s_seq_tx_moder.sv
// Author   : Wael
// Date     : 2026-07-14
//------------------------------------------------------------------------------
// Description:
// transmit configuration without preamble sequence for the Ethernet MAC.
//==============================================================================
`ifndef WB_S_TX_MODER_SV
`define WB_S_TX_MODER_SV
class wb_s_seq_tx_moder extends wb_s_basic_tx_seq;

    `uvm_object_utils(wb_s_seq_tx_moder)
    
    //---------------------------------------------------------
    function new(string name="wb_s_seq_tx_moder");
        super.new(name);
    endfunction


    //---------------------------------------------------------
    task body();

    bit err_end_flag;

    //-----------------------------------------------------
    // Randomize transaction
    //-----------------------------------------------------
    assert(m_item.randomize() with {
    tx_bd_num<3;
    tx_bd_num>0;
    maxfl==90;
    minfl == 64;
    if(!moder_fd) 
    {
       moder_exdf ==0;
       moder_nobackoff ==0; 
    }

    foreach (pkt_len[i]){
        pkt_len[i]<100;
        pkt_len[i]>4;
        if(moder_hugen && i>rand_tx_bd_idx) 
            pkt_len[i]>maxfl;
        else
            pkt_len[i]<maxfl;
    
        if(moder_pad && i>rand_tx_bd_idx)
            pkt_len[i] > minfl;
        else if(moder_pad)
            pkt_len[i] < minfl;
    }
    })   
    else begin
    `uvm_fatal(get_name(), "Failed randomization")
    end

    //if it's RTL_002 bug close simulation
    for (int i=0; i<m_item.tx_bd_num; i++) begin
        if((!m_item.bd_crc[i] && !m_item.moder_crc) && (m_item.bd_pad[i]||m_item.moder_pad) && (m_item.pkt_len[i]<m_item.minfl)) begin
            `uvm_warning(get_name(),$sformatf("Not running this sequece due to RTL_002 bug, bd index = %0d, bd crc = %0d, moder crc = %0d, bd pad = %0d moder pad = %0d pkt len = %0d, min pkt len = %0d",
            i,m_item.bd_crc[i],m_item.moder_crc,m_item.bd_pad[i],m_item.moder_pad,m_item.pkt_len[i],m_item.minfl))
            err_end_flag=1;
            break;
        end    
    end

    if (!err_end_flag) begin
        //-----------------------------------------------------
        // Write dma memory & program buffer descriptors
        //-----------------------------------------------------
        for(int bd=0; bd<m_item.tx_bd_num; bd++) begin
            dma_mem_wr(m_item.tx_pnt[bd],m_item.pkt_len[bd],$random);

            configure_tx_bd(.bd_index(bd),.frame_length(m_item.pkt_len[bd]),.frame_ptr(m_item.tx_pnt[bd]),.enable_irq(0),
            .is_wrap(bd == m_item.tx_bd_num-1),.enable_pad(m_item.bd_pad[bd]),.enable_crc(m_item.bd_crc[bd]));
        end

        //-----------------------------------------------------
        // Configure registers
        //-----------------------------------------------------
        configure_tx_registers(.tx_bd_num(m_item.tx_bd_num),.fulld(m_item.moder_fd),.txen(1),.nopre(m_item.moder_nopre),.crcen(m_item.moder_crc),
                                .dcrc(m_item.moder_dcrc),.pad(m_item.moder_pad),.hugen(m_item.moder_hugen),.nobckof(m_item.moder_nobackoff),
                                .exdf(m_item.moder_exdf),.maxfl(m_item.maxfl),.minfl(m_item.minfl));


                                
        `uvm_info(get_type_name(),
                    "MODER TX configuration completed",
                    UVM_LOW)
    
        repeat(m_item.tx_bd_num) begin
            @(m_ev_end_pkt);
        end 

    end


endtask

 

endclass

`endif
