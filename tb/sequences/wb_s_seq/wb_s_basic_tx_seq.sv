//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_s_basic_tx_seq.sv
// Author   : Nada
// Date     : 2026-07-06
//------------------------------------------------------------------------------
// Description:
// Basic transmit configuration sequence for the Ethernet MAC.
// full duplex , padding and crc are enabled , no control frames are transmiited
//
// Programs the MAC through the Wishbone slave interface using the
// Register Abstraction Layer (RAL). The sequence performs the initial
// transmitter configuration by:
//
//  - Configuring Ethernet MAC control and timing registers
//    (IPGT, IPGR1, IPGR2, PACKETLEN, COLLCONF, etc.).
//  - Programming the transmit Buffer Descriptors (BDs) with packet
//    length, control bits, and DMA memory pointers.
//  - Configuring the MAC address.
//  - Enabling the transmitter by setting the TXEN bit in the MODER
//    register as the final configuration step.
//
// This sequence assumes that the packet data has already been written
// into DMA memory by the Wishbone Master environment or testbench.
//==============================================================================
`ifndef WB_S_BASIC_TX_SEQ_SV
`define WB_S_BASIC_TX_SEQ_SV
class wb_s_basic_tx_seq extends wb_s_seq_base;

    `uvm_object_utils(wb_s_basic_tx_seq)
    wb_s_seq_item_tx m_item;
	
	parameter int NUM_TX_BD = 1;
    parameter int unsigned        PKT_LEN    = 56;
	bit [31:0] tx_ptr[NUM_TX_BD];

    //---------------------------------------------------------
    function new(string name="wb_s_basic_tx_seq");
        super.new(name);
        m_item = wb_s_seq_item_tx#(
        WB_S_ADDR_WIDTH,
        WB_DATA_WIDTH,
        WB_SEL_WIDTH
      )::type_id::create("m_item");
    endfunction

    extern task configure_tx_registers(
    bit [7:0]  ipgt = 8'h12,
    bit [7:0]  ipgr1 = 8'h0C,
    bit [7:0]  ipgr2 = 8'h12,
    bit [15:0] minfl = 16'h0040,
    bit [15:0] maxfl = 16'h0600,
    bit [7:0]  tx_bd_num = 8'h00,
    bit [15:0] mac_addr1 = 16'h0000,
    bit [31:0] mac_addr0 = 32'h00000000,
    bit [15:0]  pause_timer = 16'h0000,
    bit fulld = 1'b0,
    bit txen = 1'b0,
    bit nopre = 1'b0,
    bit crcen = 1'b1,
    bit dcrc = 1'b0,
    bit pad = 1'b1,
    bit hugen = 1'b0,
    bit nobckof = 1'b0,
    bit exdf = 1'b0,
    bit txb_m =1'b0,
    bit txc_m =1'b0,
    bit txe_m =1'b0,
    bit pause_req = 1'b0,
    bit tx_flow  = 1'b0
    );

    extern task configure_tx_bd(
    int bd_index,
    bit [15:0] frame_length,
    bit [31:0] frame_ptr,
    bit enable_irq,
    bit is_wrap,
    bit enable_pad,
    bit enable_crc
    );
    extern function void dma_mem_wr(bit [31:0] tx_ptr,bit [15:0] len,bit [31:0] data);
    //---------------------------------------------------------
    task body();

  

    //-----------------------------------------------------
    // DMA packet addresses for the basic test
    //-----------------------------------------------------
        tx_ptr[0] = 32'h0000_1000;
        tx_ptr[1] = 32'h0000_003C;
        tx_ptr[2] = 32'h0000_0078;
        tx_ptr[3] = 32'h0000_00B4;

        //-----------------------------------------------------
        // Write dma memory
        //----------------------------------------------------- 

        foreach (tx_ptr[i]) begin
            dma_mem_wr(tx_ptr[i],PKT_LEN,$random);
        end

        //-----------------------------------------------------
        // Program Buffer Descriptors
        //-----------------------------------------------------

        for(int bd=0; bd<NUM_TX_BD; bd++) begin
            configure_tx_bd(.bd_index(bd),.frame_length(PKT_LEN),.frame_ptr(tx_ptr[bd]),.enable_irq(0),
            .is_wrap(bd == NUM_TX_BD-1),.enable_pad(1),.enable_crc(1));
        end

        //-----------------------------------------------------
        // Configure registers
        //-----------------------------------------------------
        configure_tx_registers(.tx_bd_num(NUM_TX_BD),.txen(1),.fulld(1),.minfl(55),.maxfl(55));


        `uvm_info(get_type_name(),
                  "Basic TX configuration completed",
                  UVM_LOW)


        repeat(NUM_TX_BD) begin
            @(m_ev_end_pkt);
        end

    endtask 

endclass

task wb_s_basic_tx_seq::configure_tx_registers(
    bit [7:0]  ipgt = 8'h12,
    bit [7:0]  ipgr1 = 8'h0C,
    bit [7:0]  ipgr2 = 8'h12,
    bit [15:0] minfl = 16'h0040,
    bit [15:0] maxfl = 16'h0600,
    bit [7:0]  tx_bd_num = 8'h00,
    bit [15:0] mac_addr1 = 16'h0000,
    bit [31:0] mac_addr0 = 32'h00000000,
    bit [15:0]  pause_timer = 16'h0000,
    bit fulld = 1'b0,
    bit txen = 1'b0,
    bit nopre = 1'b0,
    bit crcen = 1'b1,
    bit dcrc = 1'b0,
    bit pad = 1'b1,
    bit hugen = 1'b0,
    bit nobckof = 1'b0,
    bit exdf = 1'b0,
    bit txb_m =1'b0,
    bit txc_m =1'b0,
    bit txe_m =1'b0,
    bit pause_req = 1'b0,
    bit tx_flow  = 1'b0
    );
    uvm_status_e status;

    `uvm_info("TX_CONFIG", "Configuring TX registers", UVM_MEDIUM)

    // ── INT_MASK Register ────────────────────────────────────
    regmodel.INT_MASK.TXB_M.set(txb_m);
    regmodel.INT_MASK.TXC_M.set(txc_m);
    regmodel.INT_MASK.TXE_M.set(txe_m);
    regmodel.INT_MASK.update(status);

    // ── IPGT Register ────────────────────────────────────
    regmodel.IPGT.write(status, ipgt);

    // ── IPGR1 Register ───────────────────────────────────
    regmodel.IPGR1.write(status, ipgr1);

    // ── IPGR2 Register ───────────────────────────────────
    regmodel.IPGR2.write(status, ipgr2);

    // ── PACKETLEN Register ────────────────────────────────
    regmodel.PACKETLEN.MINFL.set(minfl);
    regmodel.PACKETLEN.MAXFL.set(maxfl);
    regmodel.PACKETLEN.update(status);

    // ── TX_BD_NUM Register ────────────────────────────────
    regmodel.TX_BD_NUM.write(status, tx_bd_num);


    // ── MAC_ADDR Registers ────────────────────────────────
    regmodel.MAC_ADDR1.BYTE0.set(mac_addr1[7:0]);
    regmodel.MAC_ADDR1.BYTE1.set(mac_addr1[15:8]);
    regmodel.MAC_ADDR1.update(status);


    regmodel.MAC_ADDR0.BYTE2.set(mac_addr0[7:0]);
    regmodel.MAC_ADDR0.BYTE3.set(mac_addr0[15:8]);
    regmodel.MAC_ADDR0.BYTE4.set(mac_addr0[23:16]);
    regmodel.MAC_ADDR0.BYTE5.set(mac_addr0[31:24]);
    regmodel.MAC_ADDR0.update(status);

    // CTRLMODER
    regmodel.CTRLMODER.TXFLOW.set(tx_flow);
    regmodel.CTRLMODER.update(status);
    
    // TXCTRL
    regmodel.TXCTRL.TXPAUSERQ.set(pause_req);
    regmodel.TXCTRL.TXPAUSETV.set(pause_timer);
    regmodel.TXCTRL.update(status);

    // ── MODER Register: Control Flags ─────────────────────
    regmodel.MODER.FULLD.set(fulld);
    regmodel.MODER.TXEN.set(txen);
    regmodel.MODER.NOPRE.set(nopre);
    regmodel.MODER.CRCEN.set(crcen);
    regmodel.MODER.DLYCRCEN.set(dcrc);
    regmodel.MODER.PAD.set(pad);
    regmodel.MODER.HUGEN.set(hugen);
    regmodel.MODER.NOBCKOF.set(nobckof);
    regmodel.MODER.EXDFREN.set(exdf);
    regmodel.MODER.update(status);
    `uvm_info("TX_CONFIG", 
        $sformatf("MODER: FULLD=%0d, TXEN=%0d, BDNUM = %0d, NOPRE=%0d, CRCEN=%0d, DCRC=%0d, PAD=%0d, HUGEN=%0d, NOBCKOF=%0d, EXDF=%0d, IPGT = %0d, TXB_M = %0d, TXC_M = %0d, TXE_M = %0d, MAXFL = %0d, MINFL = %0d",
                  fulld, txen, tx_bd_num, nopre, crcen, dcrc,pad, hugen, nobckof,exdf,ipgt,txb_m,txc_m,txe_m,maxfl,minfl),
        UVM_MEDIUM)

endtask 

function void wb_s_basic_tx_seq::dma_mem_wr(bit [31:0] tx_ptr,bit [15:0] len,bit [31:0] data);
            for(int j=0; j<$ceil(len/4.0);j++)
                dma_mem::write(tx_ptr+j*4,data);
endfunction



task wb_s_basic_tx_seq::configure_tx_bd(
    int bd_index,
    bit [15:0] frame_length,
    bit [31:0] frame_ptr,
    bit enable_irq,
    bit is_wrap,
    bit enable_pad,
    bit enable_crc
);
    bit [31:0] bd_status_word;
    bit [31:0] bd_pointer_word;
    bit [31:0] bd_addr;
    uvm_status_e status;

    // Calculate BD address in BD RAM
    bd_addr = bd_index * 2;


    bd_status_word[31:16] = frame_length;
    bd_status_word[15]    = 1'b1;                          // RD always 1
    bd_status_word[14]    = enable_irq;
    bd_status_word[13]    = is_wrap;
    bd_status_word[12]    = enable_pad;
    bd_status_word[11]    = enable_crc;
    bd_status_word[10:0]  = 11'h0;                         // Status bits cleared


    bd_pointer_word = frame_ptr;


    regmodel.eth_bd_mem.write(status, bd_addr, bd_status_word);
    regmodel.eth_bd_mem.write(status, bd_addr+1, bd_pointer_word);

    `uvm_info("TX_CONFIG", 
        $sformatf(" Configuring TX BD[%0d] - LEN=%0d, PTR=0x%08h, IRQ=%0d, WR=%0d, PAD=%0d, CRC=%0d", 
                  bd_index, frame_length, frame_ptr, enable_irq, is_wrap, enable_pad, enable_crc), 
        UVM_MEDIUM)

endtask

`endif
