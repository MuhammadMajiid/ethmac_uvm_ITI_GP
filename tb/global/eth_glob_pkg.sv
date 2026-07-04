//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_glob_pkg.sv
// Author   : Wael
// Date     : 2026-06-24
//------------------------------------------------------------------------------
// Description:
//   Package for including user dedfined data types, oarameters and macros used
//   across the project.
//==============================================================================

`ifndef ETH_GLOB_PKG_SV
`define ETH_GLOB_PKG_SV

package eth_glob_pkg;
    
    // Enum represents write/read in wishbone
    typedef enum logic { WB_READ = 1'b0, WB_WRITE = 1'b1 , UNKNOWN= 1'bx, HIGH_IMP= 1'bz} wb_dir_t;    
    
    // Enum represent states of interpacket gap time during transmission
    typedef enum bit [1:0] {WAIT_FIRST_FRAME,WAIT_END_FRAME,COUNT_IPGT} ipgt_state_e;
    
    // Queue for storing packet in bytes
    typedef byte bytes_q[$];

    // parameters
    parameter WB_DATA_WIDTH          = 32;
    parameter WB_S_ADDR_WIDTH        = 10;
    parameter WB_M_ADDR_WIDTH        = 32; 
    parameter WB_SEL_WIDTH           = 4;
    parameter WB_TX_BD_RD_POS        = 15;
    parameter WB_TX_BD_WR_POS        = 13;
    parameter WB_TX_BD_UR_POS        = 8;
    parameter WB_BD_MEM_DEPTH        = 256;
    parameter ETH_NIBBLE_WIDTH       = 4;
    parameter ETH_PAUSE_FRAME_ADDR   = 48'h0180C2000001;                    
    parameter ETH_PAUSE_LEN_TYPE     = 16'h8808;
    parameter ETH_PAUSE_OPCODE       = 16'h0001;    
    parameter ETH_PAD                = 8'h00;
    parameter ETH_PREAMBLE           = 8'h55;
    parameter ETH_SFD                = 8'h5D;
    parameter ETH_CRC_POLY           = 32'hc704dd7b;   
    parameter real IFG_MIN_NS        = 960.0; 
    parameter ETH_PREAMBLE_LEN       = 7;
    parameter ETH_SFD_LEN            = 1;
    parameter ETH_CRC_LEN            = 4;
    parameter ETH_ADDR_LEN           = 6;
    parameter ETH_TYPE_LEN           = 2;
    parameter ETH_PAUSE_OPCODE_LEN   = 2;
    parameter ETH_PAUSE_TIMER_LEN    = 2;
    parameter ETH_PAUSE_RESERVED_LEN = 42;
    // Clocks
    parameter ETH_PHY_TX_CLK_PERIOD_NS    = 40; // 25 MHz
    parameter ETH_PHY_RX_CLK_PERIOD_NS    = 40; // 25MHz
    parameter WB_CLK_PERIOD_NS            = 5;  // 200 MHz

    `include "dma_mem.sv"
    `include "crc_func.sv"
 
endpackage : eth_glob_pkg

`endif // ETH_GLOB_PKG_SV
