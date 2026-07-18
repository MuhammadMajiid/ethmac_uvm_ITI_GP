//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_s_seq_tx_hugen.sv
// Author   : Wael
// Date     : 2026-07-14
//------------------------------------------------------------------------------
// Description:
// transmit configuration without preamble sequence for the Ethernet MAC.
//==============================================================================
`ifndef WB_S_TX_HUGEN_SV
`define WB_S_TX_HUGEN_SV
class wb_s_seq_tx_hugen extends wb_s_basic_tx_seq;

    `uvm_object_utils(wb_s_seq_tx_hugen)

    //---------------------------------------------------------
    function new(string name="wb_s_seq_tx_hugen");
        super.new(name);
    endfunction


    //---------------------------------------------------------
    task body();

    uvm_resource_db#(bit)::set("*","end_seq",0,this);
    //-----------------------------------------------------
    // Randomize transaction
    //-----------------------------------------------------
    assert(m_item.randomize() with {
    tx_bd_num<5;
    foreach (pkt_len[i]){
        pkt_len[i]<100;
        pkt_len[i]>4;
        pkt_len[i] >maxfl;
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
        .is_wrap(bd == m_item.tx_bd_num-1),.enable_pad(m_item.bd_pad[bd]),.enable_crc(m_item.bd_crc[bd]));
    end

    //-----------------------------------------------------
    // Configure registers
    //-----------------------------------------------------
    configure_tx_registers(.tx_bd_num(m_item.tx_bd_num),.fulld(0),.txen(1),.nopre(0),.hugen(0),.maxfl(m_item.maxfl));


    `uvm_info(get_type_name(),
                "Hugen TX configuration completed",
                UVM_LOW)

    repeat(m_item.tx_bd_num) begin
        @(m_ev_end_pkt);
    end 

    endtask 

endclass

`endif
