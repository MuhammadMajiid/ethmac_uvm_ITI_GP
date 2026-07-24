//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_s_seq_tx_minfl.sv
// Author   : Wael
// Date     : 2026-07-16
//------------------------------------------------------------------------------
// Description:
// transmit configuration without preamble sequence for the Ethernet MAC.
//==============================================================================
`ifndef WB_S_TX_MINFL_SV
`define WB_S_TX_MINFL_SV
class wb_s_seq_tx_minfl extends wb_s_basic_tx_seq;

    `uvm_object_utils(wb_s_seq_tx_minfl)

    //---------------------------------------------------------
    function new(string name="wb_s_seq_tx_minfl");
        super.new(name);
    endfunction


    //---------------------------------------------------------
    task body();

    uvm_resource_db#(bit)::set("*","end_seq",0,this);
    //-----------------------------------------------------
    // Randomize transaction
    //-----------------------------------------------------
    m_item.c_minfl_maxfl.constraint_mode(0);
    assert(m_item.randomize() with {
    tx_bd_num==1;
    maxfl == 'd1000;
    minfl dist { ['h0005:'h003F] :/ 35, 'h0040 :/ 20, ['h00041:'h000FF] :/ 25,'hFFFF :/ 20};
    if(minfl == 'hFFFF){
        moder_pad==0;
        }   
    foreach (bd_pad[i]){
        if(minfl == 'hFFFF){
            bd_pad[i]==0;
        }        
    }    
    foreach (pkt_len[i]){
        pkt_len[i]<128;
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
        dma_mem_wr(m_item.tx_pnt[bd],m_item.pkt_len[bd],$random);

        configure_tx_bd(.bd_index(bd),.frame_length(m_item.pkt_len[bd]),.frame_ptr(m_item.tx_pnt[bd]),.enable_irq(0),
        .is_wrap(bd == m_item.tx_bd_num-1),.enable_pad(m_item.bd_pad[bd]),.enable_crc(1));
    end

    //-----------------------------------------------------
    // Configure registers
    //-----------------------------------------------------
    configure_tx_registers(.tx_bd_num(m_item.tx_bd_num),.fulld(m_item.moder_fd),.minfl(m_item.minfl),.maxfl(m_item.maxfl),.pad(m_item.moder_pad),.txen(1));


    `uvm_info(get_type_name(),
                "TX MINFL configuration completed",
                UVM_LOW)

    repeat(m_item.tx_bd_num) begin
        @(m_ev_end_pkt);
    end 

    endtask

 

endclass

`endif
