//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_s_seq_tx_maxfl.sv
// Author   : Wael
// Date     : 2026-07-17
//------------------------------------------------------------------------------
// Description:
// transmit configuration without preamble sequence for the Ethernet MAC.
//==============================================================================
`ifndef WB_S_TX_MAXFL_SV
`define WB_S_TX_MAXFL_SV
class wb_s_seq_tx_maxfl extends wb_s_basic_tx_seq;

    `uvm_object_utils(wb_s_seq_tx_maxfl)

    //---------------------------------------------------------
    function new(string name="wb_s_seq_tx_maxfl");
        super.new(name);
    endfunction


    //---------------------------------------------------------
    task body();

    uvm_resource_db#(bit)::set("*","end_seq",0,this);
    //-----------------------------------------------------
    // Randomize transaction
    //-----------------------------------------------------
    assert(m_item.randomize() with {
    tx_bd_num==1;
    rand_tx_bd_idx inside {0,1};
    minfl inside {30,64,256};
    maxfl dist { ['h0000:'h0004] :/ 20 ,['h0005:'h003F] :/ 20, 'h0040 :/ 20, ['h00041:'hFFFE] :/20 ,'hFFFF :/ 20, 'h05EE :/20 };
    foreach (pkt_len[i]){
        pkt_len[i] <= 'd128;
        pkt_len[i]>4;
        if(rand_tx_bd_idx && moder_hugen)
            pkt_len[i]>maxfl;
        else if(moder_hugen)
            pkt_len[i]<maxfl;   
    }
    })   
    else begin
    `uvm_fatal(get_name(), "Failed randomization")
    end

    //-----------------------------------------------------
    // Write dma memory & program buffer descriptors
    //-----------------------------------------------------
    for(int bd=0; bd<m_item.tx_bd_num; bd++) begin
        dma_mem_wr(m_item.tx_pnt[bd],m_item.pkt_len[bd],$random);

        configure_tx_bd(.bd_index(bd),.frame_length(m_item.pkt_len[bd]),.frame_ptr(m_item.tx_pnt[bd]),.enable_irq(0),
        .is_wrap(bd == m_item.tx_bd_num-1),.enable_pad(m_item.bd_pad[bd]),.enable_crc(1));
    end

    //-----------------------------------------------------
    // Configure registers
    //-----------------------------------------------------
    configure_tx_registers(.tx_bd_num(m_item.tx_bd_num),.fulld(m_item.moder_fd),.minfl(m_item.minfl),.maxfl(m_item.maxfl),
                            .pad(0),.hugen(m_item.moder_hugen),.txen(1));


    `uvm_info(get_type_name(),
                "TX MAXFL configuration completed",
                UVM_LOW)

    repeat(m_item.tx_bd_num) begin
        @(m_ev_end_pkt);
    end 

    endtask

 

endclass

`endif
