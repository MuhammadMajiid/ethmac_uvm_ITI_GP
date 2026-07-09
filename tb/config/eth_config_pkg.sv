//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_config_pkg.sv
// Author   : Wael
// Date     : 2026-07-06
//------------------------------------------------------------------------------
// Description:
// SystemVerilog package includes all configuration objects.
//==============================================================================


`ifndef ETH_CONFIG_PKG_SV
`define ETH_CONFIG_PKG_SV

package eth_config_pkg;
    import uvm_pkg::*;
    import eth_glob_pkg::*;
    `include "uvm_macros.svh"

    // import RAL package
    import eth_ral_pkg::*;

    // Config abject files
    `include "eth_tx_scoreboard_config_obj.sv"
    `include "mdio_config_obj.sv"
    `include "mii_tx_config_obj.sv"
    `include "mii_rx_config_obj.sv"
    `include "wb_m_config_obj.sv"
    `include "wb_s_config_obj.sv"
    `include "eth_env_config_obj.sv"

endpackage : eth_config_pkg

`endif // ETH_CONFIG_PKG_SV