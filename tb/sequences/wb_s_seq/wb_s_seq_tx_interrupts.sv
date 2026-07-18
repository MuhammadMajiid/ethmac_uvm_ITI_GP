//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_s_seq_tx_interrupts.sv
// Author   : Nada
// Date     : 2026-07-17
//------------------------------------------------------------------------------
// Description:
// Random transmit configuration sequence for the Ethernet MAC.
//
// Extends wb_s_basic_tx_seq to generate randomized transmit scenarios
// through the Wishbone slave interface using the Register Abstraction
// Layer (RAL).
//
// The sequence performs the following:
//
//  - Randomly enables or masks the transmit-related interrupt sources
//    (TXB, TXE, BUSY and TXC) by programming the INT_MASK register.
//    Receive-related interrupt bits remain disabled.
//  - Randomly generates either normal Ethernet data frames or
//    IEEE 802.3x pause (control) frames.
//  - Programs the transmit Buffer Descriptors (BDs) and DMA memory.
//  - Configures the required MAC registers (MODER, CTRLMODER,
//    TXCTRL, IPG registers, PACKETLEN, MAC address, etc.).
//  - Enables the transmitter and starts randomized transmit traffic.
//
// This sequence is intended for constrained-random verification of
// transmit functionality and interrupt generation while reusing the
// common configuration infrastructure provided by wb_s_basic_tx_seq.
//==============================================================================
`ifndef WB_S_SEQ_TX_INTERRUPTS_SV
`define WB_S_SEQ_TX_INTERRUPTS_SV

class wb_s_seq_tx_interrupts extends wb_s_basic_tx_seq;

  `uvm_object_utils(wb_s_seq_tx_interrupts)

  typedef enum bit {DATA_FRAME, CONTROL_FRAME} frame_type_e;

  rand frame_type_e frame_type[NUM_TX_BD];

  rand bit txb_irq_en;
  rand bit txe_irq_en;
  rand bit txc_irq_en;
  rand bit enable_irq;
  
  constraint c_enable_irq {
    enable_irq dist {
        1 := 90,
        0 := 10
    };
  }

  // Mostly data frames
  constraint c_frame_type {
    foreach(frame_type[i])
      frame_type[i] dist {
        DATA_FRAME    := 80,
        CONTROL_FRAME := 20
      };
  }

  function new(string name="wb_s_random_tx_seq");
    super.new(name);
  endfunction

task configure_random_int_mask();

    uvm_status_e status;
    uvm_reg_data_t int_mask;

    if (!randomize(txb_irq_en, txe_irq_en, txc_irq_en))
        `uvm_fatal(get_type_name(),"Interrupt randomization failed")

    int_mask = '0;

    int_mask[0] = txb_irq_en;   // TXB
    int_mask[1] = txe_irq_en;   // TXE
    int_mask[5] = txc_irq_en;   // TXC

    regmodel.INT_MASK.write(status, int_mask);

    `uvm_info(get_type_name(),
        $sformatf("INT_MASK = 0x%02h (TXB=%0d TXE=%0d  TXC=%0d)",
            int_mask,
            txb_irq_en,
            txe_irq_en,
            txc_irq_en),
        UVM_MEDIUM)

endtask

  virtual task body();
  uvm_status_e   status;
  uvm_reg_data_t int_source;

    if (!randomize())
        `uvm_fatal(get_type_name(),"Randomization failed")

    //---------------------------------------------------------
    // Random interrupt configuration
    //---------------------------------------------------------
    configure_random_int_mask();


    //---------------------------------------------------------
    // DMA addresses
    //---------------------------------------------------------
    tx_ptr[0] = 32'h0000_1000;
    tx_ptr[1] = 32'h0000_2000;
    tx_ptr[2] = 32'h0000_3000;
    tx_ptr[3] = 32'h0000_4000;

    //---------------------------------------------------------
    // Write packet data
    //---------------------------------------------------------
    foreach(tx_ptr[i])
      dma_mem_wr(tx_ptr[i], PKT_LEN, $urandom);

    //---------------------------------------------------------
    // Configure BDs
    //---------------------------------------------------------
    for(int bd=0; bd<NUM_TX_BD; bd++) begin

      configure_tx_bd(
        .bd_index     (bd),
        .frame_length (PKT_LEN),
        .frame_ptr    (tx_ptr[bd]),
        .enable_irq   (enable_irq),
        .is_wrap      (bd==NUM_TX_BD-1),
        .enable_pad   (1),
        .enable_crc   (1)
      );

    end

  
    //---------------------------------------------------------
    // Print generated traffic
    //---------------------------------------------------------
    foreach(frame_type[i]) begin

      if(frame_type[i] == DATA_FRAME)
        `uvm_info(get_type_name(),
          $sformatf("BD[%0d] : DATA FRAME",i),UVM_LOW)

      else
        `uvm_info(get_type_name(),
          $sformatf("BD[%0d] : CONTROL FRAME",i),UVM_LOW)

    end

    //---------------------------------------------------------
    // Transmit frames
    //---------------------------------------------------------
    foreach(frame_type[i]) begin

      if(frame_type[i] == DATA_FRAME) begin

        //-----------------------------------------------------
        // Normal Ethernet frame
        //-----------------------------------------------------

    configure_tx_registers(
      .tx_bd_num(NUM_TX_BD),
      .mac_addr0($urandom),
      .mac_addr1($urandom),
      .txen(1),
      .fulld(1),
	  .pause_req(0),
	  .tx_flow(0)
	  
    );

      end
      else begin

        //-----------------------------------------------------
        // Pause control frame
        //-----------------------------------------------------
         configure_tx_registers(
      .tx_bd_num(NUM_TX_BD),
      .mac_addr0($urandom),
      .mac_addr1($urandom),
      .txen(1),
      .fulld(1),
	  .pause_req(1),
	  .tx_flow(1)
	  
    );

      end

      `uvm_info(get_type_name(),
        $sformatf("Sending frame [%0d] as %s",
                  i,
                  (frame_type[i]==DATA_FRAME) ?
                  "DATA" : "CONTROL"),
        UVM_MEDIUM)

    

    end
	
	
	for (int i = 0; i < NUM_TX_BD; i++) begin

    @(m_ev_end_pkt);

    regmodel.INT_SOURCE.read(status, int_source, UVM_FRONTDOOR);

    `uvm_info(get_type_name(),
        $sformatf(
          "INT_SOURCE: TXB=%0d TXE=%0d RXB=%0d RXE=%0d BUSY=%0d TXC=%0d RXC=%0d",
          int_source[0],
          int_source[1],
          int_source[2],
          int_source[3],
          int_source[4],
          int_source[5],
          int_source[6]),
        UVM_MEDIUM)

    end

  endtask
  
  

endclass

`endif