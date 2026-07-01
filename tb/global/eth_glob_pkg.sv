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
    
    // Enum represents write/read
    typedef enum logic { WB_READ = 1'b0, WB_WRITE = 1'b1 , UNKNOWN= 1'bx, HIGH_IMP= 1'bz} wb_dir_t;    

    // Queue for storing packet in bytes
    typedef byte bytes_q[$];

    // parameters
    parameter WB_DATA_WIDTH          = 32;
    parameter WB_S_ADDR_WIDTH        = 10;
    parameter WB_M_ADDR_WIDTH        = 32; 
    parameter WB_SEL_WIDTH           = 4;
    parameter PHY_NIBBLE_WIDTH       = 4;
    parameter ETH_PAUSE_FRAME_ADDR   = 48'h0180C2000001;                       // source address of PAUSE frame is hardcoded
    parameter ETH_PAUSE_LEN_TYPE     = 16'h8808;
    parameter ETH_PAUSE_OPCODE       = 16'h0001;    
    parameter ETH_PAUSE_PAD          = 8'h00;
    parameter ETH_PREAMBLE           = 8'h55;
    parameter ETH_SFD                = 8'h5D;
    parameter ETH_CRC_POLY           = 32'hc704dd7b;

    parameter PHY_TX_CLK_FREQ_MHZ    = 25;
    parameter PHY_RX_CLK_FREQ_MHZ    = 25;
    parameter WB_CLK_FREQ_MHZ        = 200;

    `include "dma_mem.sv"
    `include "crc_func.sv"
 
endpackage : eth_glob_pkg

`endif // ETH_GLOB_PKG_SV
