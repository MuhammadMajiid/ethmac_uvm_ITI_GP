//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_s_seq_tx_collision_pre.sv
// Author   : Wael
// Date     : 2026-08-16
//------------------------------------------------------------------------------
// Description:
// TX configuration sequence for collision testing during preamble.
//==============================================================================

`ifndef WB_S_SEQ_TX_COLLISION_PRE_SV
`define WB_S_SEQ_TX_COLLISION_PRE_SV

class wb_s_seq_tx_collision_pre extends wb_s_seq_tx_collision_cfg;

    `uvm_object_utils(wb_s_seq_tx_collision_pre)

    function new(string name = "wb_s_seq_tx_collision_pre");
        super.new(name);
    endfunction

    virtual task body();
        //-----------------------------------------------------
        // Randomize transaction
        //-----------------------------------------------------
        assert(m_item.randomize() with {
        tx_bd_num ==1;
        foreach (pkt_len[i]){
            pkt_len[i]==78;
        }
        })   

        //-----------------------------------------------------
        // Fill DMA memory
        //-----------------------------------------------------
        foreach (m_item.tx_pnt[i])
            dma_mem_wr(m_item.tx_pnt[i],m_item.pkt_len[i], $random,1);

        //-----------------------------------------------------
        // Program Buffer Descriptors
        //-----------------------------------------------------
        for (int bd = 0; bd <m_item.tx_bd_num; bd++) begin
            configure_tx_bd(
                .bd_index   (bd),
                .frame_length(m_item.pkt_len[bd]),
                .frame_ptr  (m_item.tx_pnt[bd]),
                .enable_irq (0),
                .is_wrap    (bd == m_item.tx_bd_num-1),
                .enable_pad (1),
                .enable_crc (1)
            );
        end

        //-----------------------------------------------------
        // Configure registers for collision testing
        //-----------------------------------------------------
        configure_tx_registers(
            .tx_bd_num (m_item.tx_bd_num),
            .txen      (1),
            .fulld     (0),
            .maxret    (5)
        );

        `uvm_info(get_type_name(),
                  "Collision preamble TX configuration completed",
                  UVM_LOW)

        //-----------------------------------------------------
        // Wait until all frames complete
        //-----------------------------------------------------
        for (int bd = 0; bd < m_item.tx_bd_num; bd++) begin
            @(m_ev_end_pkt);
        end	
		
   
    endtask

endclass

`endif