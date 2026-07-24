//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_s_seq_tx_underrun.sv
// Author   : Wael
// Date     : 2026-07-18
//------------------------------------------------------------------------------
// Description:
// transmit configuration without preamble sequence for the Ethernet MAC.
//==============================================================================
`ifndef WB_S_TX_UNDERRUN_SV
`define WB_S_TX_UNDERRUN_SV
class wb_s_seq_tx_underrun extends wb_s_basic_tx_seq;

    `uvm_object_utils(wb_s_seq_tx_underrun)
    uvm_reg_data_t rd_data;

    //---------------------------------------------------------
    function new(string name="wb_s_seq_tx_underrun");
        super.new(name);
    endfunction


    //---------------------------------------------------------
    task body();
    
    //-----------------------------------------------------
    // Randomize transaction
    //-----------------------------------------------------
    assert(m_item.randomize() with {
    tx_bd_num inside {[2:4]};
    foreach (pkt_len[i]){
        pkt_len[i]<120;
        pkt_len[i]>64;
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

        configure_tx_bd(.bd_index(bd),.frame_length(m_item.pkt_len[bd]),.frame_ptr(m_item.tx_pnt[bd]),.enable_irq(1),
        .is_wrap(bd == m_item.tx_bd_num-1),.enable_pad(m_item.bd_pad[bd]),.enable_crc(m_item.bd_crc[bd]));
    end

    //-----------------------------------------------------
    // Configure registers
    //-----------------------------------------------------
    configure_tx_registers(.tx_bd_num(m_item.tx_bd_num),.fulld(1),.pad(m_item.moder_pad),.txe_m(1),.txen(1));


    `uvm_info(get_type_name(),
                "TX underrun configuration completed",
                UVM_LOW)

    // Read interrupt and underrun for coverage
    for(int i=0; i<m_item.tx_bd_num; i++) begin
        @(m_ev_end_pkt);
        # (2*WB_CLK_PERIOD_NS);
        `uvm_info(get_name(), "Reading underrun", UVM_MEDIUM)
        
        // Read interuupt
        regmodel.INT_SOURCE.read(status,rd_data, UVM_FRONTDOOR);
        // if TXE is asserted  read underrun bit in bd
        if(rd_data[1]) begin
        regmodel.eth_bd_mem.read(status,i*2,rd_data, UVM_FRONTDOOR);
        `uvm_info(get_name(),$sformatf("Underrun bit = %0b",rd_data[8]), UVM_MEDIUM)
        // Clear underrun bit
        rd_data=rd_data ^ (1'b1<<8);
        regmodel.eth_bd_mem.write(status,i*2,rd_data, UVM_BACKDOOR);
        
    end
        // Clear interrupt source register
        regmodel.INT_SOURCE.write(status,7'b111_1111, UVM_BACKDOOR);
    end 

    endtask

 

endclass

`endif
