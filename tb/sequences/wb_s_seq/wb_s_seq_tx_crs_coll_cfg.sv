//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_s_seq_tx_crs_coll_cfg.sv
// Author   : Nada
// Date     : 2026-08-01
//------------------------------------------------------------------------------
// Description:
// TX configuration sequence for crs and collision testing.
//
// Inherits the basic TX configuration sequence and overrides only the MAC
// register configuration. The transmitter is configured for half-duplex
// operation with:
//
//   - FULLD     = 0
//   - NOBCKOF   = 1
//   - MAXRET    = 3
//   - TX enabled
//   - Packet length 55-80 bytes
//
// Intended for collision ,crs , JAM and retry verification.
//==============================================================================

`ifndef WB_S_SEQ_TX_CRS_COLL_CFG_SV
`define WB_S_SEQ_TX_CRS_COLL_CFG_SV

class wb_s_seq_tx_crs_coll_cfg extends wb_s_basic_tx_seq;

    `uvm_object_utils(wb_s_seq_tx_crs_coll_cfg)

    function new(string name = "wb_s_seq_tx_crs_coll_cfg");
        super.new(name);
    endfunction

    virtual task body();
        //-----------------------------------------------------
        // Randomize transaction
        //-----------------------------------------------------
        assert(m_item.randomize() with {
        tx_bd_num inside {4};
        foreach (pkt_len[i]){
            pkt_len[i]<100;
            pkt_len[i]>4;
        }
        })   

        //-----------------------------------------------------
        // Fill DMA memory
        //-----------------------------------------------------
        for(int bd =0; bd < m_item.tx_bd_num; bd++) begin
        dma_mem_wr(m_item.tx_pnt[bd],m_item.pkt_len[bd],0,1);

        configure_tx_bd(.bd_index(bd),.frame_length(m_item.pkt_len[bd]),.frame_ptr(m_item.tx_pnt[bd]),.enable_irq(0),
        .is_wrap(bd == m_item.tx_bd_num-1),.enable_pad(m_item.bd_pad[bd]),.enable_crc(m_item.bd_crc[bd]));
        end

        //-----------------------------------------------------
        // Configure registers for collision testing
        //-----------------------------------------------------
        configure_tx_registers(
            .tx_bd_num (m_item.tx_bd_num),
            .txen      (1),
            .fulld     (0),
            .nobckof   (1),
            .maxret    (3)
        );

        `uvm_info(get_type_name(),
                  "Collision TX configuration completed",
                  UVM_LOW)

        //-----------------------------------------------------
        // Wait until all frames complete
        //-----------------------------------------------------
        repeat (m_item.tx_bd_num)
            @(m_ev_end_pkt);

    endtask

endclass

`endif