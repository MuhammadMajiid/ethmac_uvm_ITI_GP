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
    
    `include "uvm_macros.svh"
    import uvm_pkg::*;
    
    // Enum represents write/read in wishbone
    typedef enum logic { WB_READ = 1'b0, WB_WRITE = 1'b1 , UNKNOWN= 1'bx, HIGH_IMP= 1'bz} wb_dir_t;    
    
    // Enum represent states of interpacket gap time during transmission
    typedef enum bit [2:0] {
        WAIT_FIRST_FRAME,
        WAIT_END_FRAME,
        COUNT_IPGT,
        DEFER,
        WAIT_COLLISION_END,
        COUNT_IPGR1,
        COUNT_IPGR2
    } ipg_state_e;

    // Enum for mdio opcode
    typedef enum bit [1:0] {MDIO_WRITE = 2'b01, MDIO_READ = 2'b10} op_code_e;

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
    parameter WB_TX_RC_LSB_POS       = 4;
    parameter WB_TX_RC_MSB_POS       = 7;
    parameter WB_TX_RL_POS           = 3;
    parameter WB_TX_LC_POS           = 2;
    parameter WB_TX_DF_POS           = 1;
    parameter WB_TX_CS_POS           = 0;
    parameter WB_BD_MEM_DEPTH        = 256;
    parameter WB_BD_MEM_BASE_ADDR    = 'h100;
    parameter WB_BD_MEM_OFFSET_ADDR  = 'h1FF;
    parameter ETH_REG_BASE_ADDR      = 'h0;
    parameter ETH_REG_OFFSET_ADDR    = 'h14;
    parameter ETH_NIBBLE_WIDTH       = 4;
    parameter ETH_PAUSE_FRAME_ADDR   = 48'h0180C2000001;                    
    parameter ETH_PAUSE_LEN_TYPE     = 16'h8808;
    parameter ETH_PAUSE_OPCODE       = 16'h0001;    
    parameter ETH_PAD                = 8'h00;
    parameter ETH_PREAMBLE           = 8'h55;
    parameter ETH_SFD                = 8'hD5;
    parameter ETH_CRC_POLY           = 32'hEDB88320;
    parameter ETH_EXCESS_DEFER_LIMIT = 16'h17b7;   
    parameter ETH_CTRL_PREAMBLE      = 32'hFFFF_FFFF;
    parameter ETH_CTRL_PREAMBLE_LEN  = 32;
    parameter ETH_CTRL_ADDR_LEN      = 5;
    parameter ETH_CTRL_DATA_LEN      = 16;
    parameter ETH_CTRL_ST_LEN        = 2;
    parameter ETH_CTRL_OPCODE_LEN    = 2;
    parameter ETH_CTRL_TA_LEN        = 2;
    parameter ETH_CTRL_CLK_DIV_LEN   = 8;
    parameter real IFG_MIN_NS        = 960.0; 
    parameter ETH_PREAMBLE_LEN       = 7;
    parameter ETH_SFD_LEN            = 1;
    parameter ETH_CRC_LEN            = 4;
    parameter ETH_ADDR_LEN           = 6;
    parameter ETH_TYPE_LEN           = 2;
    parameter ETH_PAUSE_OPCODE_LEN   = 2;
    parameter ETH_PAUSE_TIMER_LEN    = 2;
    parameter ETH_PAUSE_RESERVED_LEN = 42;
    parameter ETH_JAM_NIBBLES        = 8;
    parameter ETH_JAM_PATTERN        = 4'h9;
    
    // Clocks
    parameter real ETH_PHY_TX_CLK_PERIOD_NS    = 40.0; // 25 MHz
    parameter real ETH_PHY_RX_CLK_PERIOD_NS    = 40.0; // 25MHz
    parameter real WB_CLK_PERIOD_NS            = 5.0;  // 200 MHz
    
    `include "mem_model.sv"
    `include "crc_func.sv"
 
endpackage : eth_glob_pkg

`endif // ETH_GLOB_PKG_SV
