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

  rand frame_type_e frame_type;

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
      frame_type dist {
        DATA_FRAME    := 60,
        CONTROL_FRAME := 40
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

    //-----------------------------------------------------
    // Randomize irq
    //-----------------------------------------------------
    if (!randomize())
        `uvm_fatal(get_type_name(),"Randomization failed")

    //-----------------------------------------------------
    // Randomize transaction
    //-----------------------------------------------------
    assert(m_item.randomize() with {
    tx_bd_num inside{[1:3]};
    foreach (pkt_len[i]){
        pkt_len[i]<100;
        pkt_len[i]>4;
    }
    })   
    else begin
    `uvm_fatal(get_name(), "Failed randomization")
    end



    //---------------------------------------------------------
    // Configure BDs
    //---------------------------------------------------------
    for(int bd=0; bd<m_item.tx_bd_num; bd++) begin
      dma_mem_wr(m_item.tx_pnt[bd],m_item.pkt_len[bd], $urandom);

      configure_tx_bd(
        .bd_index     (bd),
        .frame_length (m_item.pkt_len[bd]),
        .frame_ptr    (m_item.tx_pnt[bd]),
        .enable_irq   (enable_irq),
        .is_wrap      (bd==m_item.tx_bd_num-1),
        .enable_pad   (m_item.bd_pad[bd]),
        .enable_crc   (m_item.bd_crc[bd])
      );

    end

  
    //---------------------------------------------------------
    // Print generated traffic
    //---------------------------------------------------------

      if(frame_type == DATA_FRAME)
        `uvm_info(get_type_name(),"DATA FRAME",UVM_LOW)

      else
        `uvm_info(get_type_name(),"CONTROL FRAME",UVM_LOW)



    //---------------------------------------------------------
    // Transmit frames
    //---------------------------------------------------------

      if(frame_type == DATA_FRAME) begin

        //-----------------------------------------------------
        // Normal Ethernet frame
        //-----------------------------------------------------

    configure_tx_registers(
      .tx_bd_num(m_item.tx_bd_num),
      .txb_m(m_item.mask_txb),
      .txc_m(m_item.mask_txc),
      .txe_m(m_item.mask_txe),
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
      .tx_bd_num(m_item.tx_bd_num),
      .txb_m(m_item.mask_txb),
      .txc_m(m_item.mask_txc),
      .txe_m(m_item.mask_txe),
      .mac_addr0($urandom),
      .mac_addr1($urandom),
      .txen(1),
      .fulld(1),
	    .pause_req(1),
	    .tx_flow(1)
	  
    );

      end

      `uvm_info(get_type_name(),
        $sformatf("Sending frame as %s",
                  (frame_type==DATA_FRAME) ?
                  "DATA" : "CONTROL"),
        UVM_MEDIUM)


	
	
	for (int i = 0; i < m_item.tx_bd_num; i++) begin

    @(m_ev_end_pkt);
    #WB_CLK_PERIOD_NS;
    // Read interrupt source register
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
    // Clear interrupt source register
    regmodel.INT_SOURCE.write(status,7'b111_1111, UVM_FRONTDOOR);
    if(frame_type==CONTROL_FRAME)
      break;
    end

  endtask
  
  

endclass

`endif