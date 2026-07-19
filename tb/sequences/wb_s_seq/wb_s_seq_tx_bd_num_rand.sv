//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_s_seq_tx_bd_num_rand.sv
// Author   : Nada
// Date     :2026-07-18
//------------------------------------------------------------------------------
// Description:
// Random TX_BD_NUM configuration sequence.
//
// Randomizes the number of transmit buffer descriptors and configures
// the MAC accordingly.
//==============================================================================

`ifndef WB_S_SEQ_TX_BD_NUM_RAND_SV
`define WB_S_SEQ_TX_BD_NUM_RAND_SV

class wb_s_seq_tx_bd_num_rand extends wb_s_basic_tx_seq;

  `uvm_object_utils(wb_s_seq_tx_bd_num_rand)

  rand bit [7:0] tx_bd_num;

 
  int iter_cnt= 0;

  
// Legal range: 1..128 
constraint c_tx_bd_num { tx_bd_num inside {[0:8'd128]}; }



  function new(string name="wb_s_seq_tx_bd_num");
    super.new(name);
  endfunction
  
  virtual task body();

    case (iter_cnt)

        0  : tx_bd_num = 8'd0;                          // min
        1  : tx_bd_num = 8'd128;                        // max

        2  : assert(std::randomize(tx_bd_num) with { tx_bd_num inside {[1:8]};   });
        3  : assert(std::randomize(tx_bd_num) with { tx_bd_num inside {[9:16]};  });
        4  : assert(std::randomize(tx_bd_num) with { tx_bd_num inside {[17:24]}; });
        5  : assert(std::randomize(tx_bd_num) with { tx_bd_num inside {[25:32]}; });
        6  : assert(std::randomize(tx_bd_num) with { tx_bd_num inside {[33:40]}; });
        7  : assert(std::randomize(tx_bd_num) with { tx_bd_num inside {[41:48]}; });
        8  : assert(std::randomize(tx_bd_num) with { tx_bd_num inside {[49:56]}; });
        9  : assert(std::randomize(tx_bd_num) with { tx_bd_num inside {[57:64]}; });
        10 : assert(std::randomize(tx_bd_num) with { tx_bd_num inside {[65:72]}; });
        11 : assert(std::randomize(tx_bd_num) with { tx_bd_num inside {[73:80]}; });
        12 : assert(std::randomize(tx_bd_num) with { tx_bd_num inside {[81:88]}; });
        13 : assert(std::randomize(tx_bd_num) with { tx_bd_num inside {[89:96]}; });
        14 : assert(std::randomize(tx_bd_num) with { tx_bd_num inside {[97:104]}; });
        15 : assert(std::randomize(tx_bd_num) with { tx_bd_num inside {[105:112]}; });
        16 : assert(std::randomize(tx_bd_num) with { tx_bd_num inside {[113:120]}; });
        17 : assert(std::randomize(tx_bd_num) with { tx_bd_num inside {[121:127]}; });

        default : assert(randomize(tx_bd_num));

    endcase

    iter_cnt++;
	
	`uvm_info(get_type_name(),
          $sformatf("iter_cnt=%0d tx_bd_num=%0d",
                    iter_cnt, tx_bd_num),
          UVM_LOW)

    `uvm_info(get_type_name(),
      $sformatf("Random TX_BD_NUM = %0d", tx_bd_num),
      UVM_MEDIUM)

    //---------------------------------------------------------
    // DMA memory
    //---------------------------------------------------------
    for (int i = 0; i < tx_bd_num; i++) begin
      tx_ptr[i] = 32'h1000 + i*32'h100;

      dma_mem_wr(
        tx_ptr[i],
        PKT_LEN,
        $urandom
      );
    end

    //---------------------------------------------------------
    // Configure BDs
    //---------------------------------------------------------
    for (int i = 0; i < tx_bd_num; i++) begin

      configure_tx_bd(
        .bd_index(i),
        .frame_length(PKT_LEN),
        .frame_ptr(tx_ptr[i]),
        .enable_irq(0),
        .is_wrap(i == tx_bd_num-1),
        .enable_pad(1),
        .enable_crc(1)
      );

    end

    //---------------------------------------------------------
    // Configure registers
    //---------------------------------------------------------
    configure_tx_registers(
	  .minfl (16'h006),
      .tx_bd_num(tx_bd_num),
      .mac_addr0($urandom),
      .mac_addr1($urandom),
      .fulld(1),
      .txen(1)
    );

    repeat(tx_bd_num)
      @(m_ev_end_pkt);

  endtask

endclass

`endif