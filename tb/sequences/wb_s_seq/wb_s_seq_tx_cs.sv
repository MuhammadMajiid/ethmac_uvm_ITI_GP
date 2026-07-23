//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_s_seq_tx_cs.sv
// Author   : Wael
// Date     : 2026-07-23
//------------------------------------------------------------------------------
// Description:
// Used for testing carrier sense lost during transmission.
//==============================================================================
`ifndef WB_S_SEQ_TX_CTRL_FRAME
`define WB_S_SEQ_TX_CTRL_FRAME
class wb_s_seq_tx_cs extends wb_s_basic_tx_seq;

    `uvm_object_utils(wb_s_seq_tx_cs)
    uvm_reg_data_t rd_data;

    function new(string name="wb_s_seq_tx_cs");
        super.new(name);
    endfunction


    task body();
    //-----------------------------------------------------
    // Randomize transaction
    //-----------------------------------------------------
    assert(m_item.randomize() with {
    tx_bd_num inside{1,2};
    moder_fd dist {1 := 30, 0:= 70};
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
    configure_tx_registers(.tx_bd_num(m_item.tx_bd_num),.fulld(m_item.moder_fd),.txen(1));


    `uvm_info(get_type_name(),
                "CS TX configuration completed",
                UVM_LOW)

    // Read carrier sense lost for coverage
    for(int i=0; i<m_item.tx_bd_num; i++) begin
        @(m_ev_end_pkt);
        `uvm_info(get_name(), "Reading carrier sense lost", UVM_MEDIUM)
        // Read bd
        regmodel.eth_bd_mem.read(status,i*2,rd_data, UVM_FRONTDOOR);
        // if carrier sense is asserted clear it
        if(rd_data[0]) begin
        `uvm_info(get_name(),$sformatf("Carrier sense lost bit = %0b",rd_data[0]),UVM_MEDIUM)
        regmodel.eth_bd_mem.write(status,i*2,rd_data ^ (1'b1), UVM_FRONTDOOR);
        end
    end 

    endtask

endclass
`endif
