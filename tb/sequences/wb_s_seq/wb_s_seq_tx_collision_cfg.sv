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
	
	rand  bit [3:0] maxret_cfg;
    rand bit [5:0] collvalid_cfg;
	rand bit nobackoff;

    uvm_status_e   status;
	uvm_reg_data_t bd_status_word;
	  
constraint c_maxret {
    maxret_cfg inside {[0:15]};
}	  

constraint c_solve {
    solve maxret_cfg before nobackoff;
}

constraint c_nobackoff {
    nobackoff dist {1:=80, 0:=20};
    if(maxret_cfg>4)
        nobackoff==1;
}	 

constraint c_collvalid {
    collvalid_cfg dist {
        6'd0  := 5,
        6'd63 := 10,
        [1:62] := 1
    };
}

    function new(string name = "wb_s_seq_tx_collision_cfg");
        super.new(name);
    endfunction

    virtual task body();
    //-----------------------------------------------------
    // Randomize collision configuration
    //-----------------------------------------------------
    assert(randomize(maxret_cfg, collvalid_cfg,nobackoff))
        else `uvm_fatal(get_type_name(),
                    "Failed to randomize collision configuration")

    `uvm_info(get_type_name(),
        $sformatf("Randomized COLLCONF: MAXRET=%0d COLLVALID=%0d",
                maxret_cfg, collvalid_cfg),
        UVM_LOW)
        //-----------------------------------------------------
        // Randomize transaction
        //-----------------------------------------------------
        assert(m_item.randomize() with {
        tx_bd_num dist {1:=90,2:=10};
        foreach (pkt_len[i]){
            pkt_len[i]<100;
            pkt_len[i]>4;
        }
        })   
        tx_ptr=new[m_item.tx_bd_num];
        
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
            dma_mem_wr(tx_ptr[i],m_item.pkt_len[i], $random,1);

        //-----------------------------------------------------
        // Program Buffer Descriptors
        //-----------------------------------------------------
        for (int bd = 0; bd <m_item.tx_bd_num; bd++) begin
            configure_tx_bd(
                .bd_index   (bd),
                .frame_length(m_item.pkt_len[bd]),
                .frame_ptr  (tx_ptr[bd]),
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
            .minfl     (55),
            .maxfl     (80),
            .nobckof   (nobackoff),
            .maxret    (maxret_cfg),
			.collvalid (collvalid_cfg)
        );

        `uvm_info(get_type_name(),
                  "Collision TX configuration completed",
                  UVM_LOW)

        //-----------------------------------------------------
        // Wait until all frames complete
        //-----------------------------------------------------
        repeat (m_item.tx_bd_num)
            @(m_ev_end_pkt);
			


for (int bd = 0; bd < m_item.tx_bd_num; bd++) begin

   regmodel.eth_bd_mem.read(status, bd*2, bd_status_word);


    `uvm_info(get_type_name(),
        $sformatf("BD[%0d] Status = 0x%08h", bd, bd_status_word),
        UVM_LOW)
end	
		
   
    endtask

endclass

`endif