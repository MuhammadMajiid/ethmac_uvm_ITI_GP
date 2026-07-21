//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_s_seq_tx_collision_cfg.sv
// Author   : Nada
// Date     : 2026-07-21
//------------------------------------------------------------------------------
// Description:
// TX configuration sequence for collision testing.
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
// Intended for collision, JAM and retry verification.
//==============================================================================

`ifndef WB_S_SEQ_TX_COLLISION_CFG_SV
`define WB_S_SEQ_TX_COLLISION_CFG_SV

class wb_s_seq_tx_collision_cfg extends wb_s_basic_tx_seq;

    `uvm_object_utils(wb_s_seq_tx_collision_cfg)

    function new(string name = "wb_s_seq_tx_collision_cfg");
        super.new(name);
    endfunction

    virtual task body();

        //-----------------------------------------------------
        // DMA packet addresses
        //-----------------------------------------------------
        tx_ptr[0] = 32'h0000_1000;
        tx_ptr[1] = 32'h0000_003C;
        tx_ptr[2] = 32'h0000_0078;
        tx_ptr[3] = 32'h0000_00B4;

        //-----------------------------------------------------
        // Fill DMA memory
        //-----------------------------------------------------
        foreach (tx_ptr[i])
            dma_mem_wr(tx_ptr[i], PKT_LEN, $random);

        //-----------------------------------------------------
        // Program Buffer Descriptors
        //-----------------------------------------------------
        for (int bd = 0; bd < NUM_TX_BD; bd++) begin
            configure_tx_bd(
                .bd_index   (bd),
                .frame_length(PKT_LEN),
                .frame_ptr  (tx_ptr[bd]),
                .enable_irq (0),
                .is_wrap    (bd == NUM_TX_BD-1),
                .enable_pad (1),
                .enable_crc (1)
            );
        end

        //-----------------------------------------------------
        // Configure registers for collision testing
        //-----------------------------------------------------
        configure_tx_registers(
            .tx_bd_num (NUM_TX_BD),
            .txen      (1),
            .fulld     (0),
            .minfl     (55),
            .maxfl     (80),
            .nobckof   (1),
            .maxret    (3)
        );

        `uvm_info(get_type_name(),
                  "Collision TX configuration completed",
                  UVM_LOW)

        //-----------------------------------------------------
        // Wait until all frames complete
        //-----------------------------------------------------
        repeat (NUM_TX_BD)
            @(m_ev_end_pkt);

    endtask

endclass

`endif