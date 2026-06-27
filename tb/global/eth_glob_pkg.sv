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

    // Macros for width
    parameter WB_DATA_WIDTH       = 32;
    parameter WB_S_ADDR_WIDTH     = 10;
    parameter WB_M_ADDR_WIDTH     = 32; 
    parameter WB_SEL_WIDTH        = 4;
    parameter PHY_NIBBLE_WIDTH    = 4;

endpackage : eth_glob_pkg

`endif // ETH_GLOB_PKG_SV
