//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_s_control_frame_tx_seq.sv
// Author   : Nada
// Date     : 2026-07-08
//------------------------------------------------------------------------------
// Description:
// Basic transmit configuration sequence for the Ethernet MAC.
// full duplex , padding and crc are enabled , control frames are transmiited
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
`ifndef WB_S_CONTROL_FRAME_TX_SEQ
`define WB_S_CONTROL_FRAME_TX_SEQ
class wb_s_control_frame_tx_seq extends wb_s_basic_tx_seq;

    `uvm_object_utils(wb_s_control_frame_tx_seq)
   

    //---------------------------------------------------------
    // Parameters
    //---------------------------------------------------------
    localparam int NUM_TX_BD = 4;
    localparam int unsigned        PKT_LEN    = 60;
    bit [31:0] tx_ptr[NUM_TX_BD];


    //---------------------------------------------------------
    function new(string name="wb_s_control_frame_tx_seq");
        super.new(name);
    endfunction

    //---------------------------------------------------------
    task body();
        configure_tx_registers(.tx_bd_num(1),.mac_addr0($random),.mac_addr1($random),.txen(1),.fulld(1),
        .pause_req(1),.pause_timer($random),.tx_flow(1));
    endtask

endclass
`endif
