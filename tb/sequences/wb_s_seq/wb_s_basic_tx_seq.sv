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
   
     eth_reg_block regmodel;
     uvm_status_e status;
     uvm_reg_data_t rd_data;

    //---------------------------------------------------------
    // Parameters
    //---------------------------------------------------------
    localparam int NUM_TX_BD = 4;
    localparam int unsigned        PKT_LEN    = 81;
    bit [31:0] tx_ptr[NUM_TX_BD];


    //---------------------------------------------------------
    function new(string name="wb_s_basic_tx_seq");
        super.new(name);
    endfunction

    //---------------------------------------------------------
    task body();

        bit [31:0] bd_status;
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
            for(int j=0; j<$ceil(PKT_LEN/4.0);j++)
            dma_mem::write(tx_ptr[i]+j*4,$random);
        end
		
		 //regmodel.PACKETLEN.MAXFL.set(16'd76);
        //regmodel.PACKETLEN.update(status);
        
        //-----------------------------------------------------
        // Configure registers
        //-----------------------------------------------------

        regmodel.IPGT.write(status,8'h15);


        //-----------------------------------------------------
        // Number of TX BDs
        //-----------------------------------------------------

        regmodel.TX_BD_NUM.write(status,NUM_TX_BD);

        //-----------------------------------------------------
        // MAC Address
        //-----------------------------------------------------

        regmodel.MAC_ADDR1.BYTE0.set(8'h11);
        regmodel.MAC_ADDR1.BYTE1.set(8'h22);
        regmodel.MAC_ADDR1.update(status);

        regmodel.MAC_ADDR0.BYTE2.set(8'h33);
        regmodel.MAC_ADDR0.BYTE3.set(8'h44);
        regmodel.MAC_ADDR0.BYTE4.set(8'h55);
        regmodel.MAC_ADDR0.BYTE5.set(8'h66);
        regmodel.MAC_ADDR0.update(status);

        //-----------------------------------------------------
        // Program Buffer Descriptors
        //-----------------------------------------------------

        for(int bd=0; bd<NUM_TX_BD; bd++) begin

            bd_status = 0;

            //------------------------------
            // Packet length
            //------------------------------
            bd_status[31:16] = PKT_LEN;

            //------------------------------
            // Ready
            //------------------------------
            bd_status[15] = 1'b1;

            //------------------------------
            // IRQ disabled
            //------------------------------
            bd_status[14] = 1'b0;

            //------------------------------
            // Wrap on last BD
            //------------------------------
            bd_status[13] = (bd == NUM_TX_BD-1);

            //------------------------------
            // Padding enabled
            //------------------------------
            bd_status[12] = 1'b1;

            //------------------------------
            // CRC enabled
            //------------------------------
            bd_status[11] = 1'b1;

            //------------------------------
            // Status word
            //------------------------------
            regmodel.eth_bd_mem.write(status, bd*2, bd_status);


            //------------------------------
            // Pointer word
            //------------------------------
           regmodel.eth_bd_mem.write(status, bd*2+1, tx_ptr[bd]);
           
        end
		

        //-----------------------------------------------------
        // Enable transmitter LAST
        //-----------------------------------------------------
           //regmodel.MODER.HUGEN.set(1);
           regmodel.MODER.TXEN.set(1);
           regmodel.MODER.FULLD.set(1);
           regmodel.MODER.update(status);
       


        `uvm_info(get_type_name(),
                  "Basic TX configuration completed",
                  UVM_LOW)

    endtask

endclass
`endif
