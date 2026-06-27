// =============================================================================
// Project  : ethmac_uvm_ITI_GP
// File      : eth_ral_pkg.sv
// Author   : Nada
// Date     : 2026-06-25
//------------------------------------------------------------------------------
// Description:
//Package that includes all RAL files in the correct compilation order.
// =============================================================================

`ifndef ETH_RAL_PKG_SV
`define ETH_RAL_PKG_SV
package eth_ral_pkg;

    // Import UVM base package 
  `include "uvm_macros.svh"
    import uvm_pkg::*;

    import wb_s_pkg::*;

    // -------------------------------------------------------------------------
    // Step 1: Individual register class files
    //         Each file defines one register class (extends uvm_reg)
    // -------------------------------------------------------------------------

    // Core operation mode register
    `include "eth_moder_reg.sv"

    // Interrupt registers (source W1C, mask RW)
    `include "eth_int_regs.sv"

    // Inter-packet gap and packet length registers
    `include "eth_ipg_pkt_regs.sv"

    // TX BD number and control mode register
    `include "eth_tx_bd_ctrl_regs.sv"

    // All six MIIM registers
    `include "eth_miim_regs.sv"

    // MAC address, hash table, and TX control
    `include "eth_mac_hash_txctrl_regs.sv"

    // -------------------------------------------------------------------------
    // Step 2: Register block
    //         Instantiates all register objects, creates the memory,
    //         and builds the WISHBONE address map
    // -------------------------------------------------------------------------
    `include "eth_reg_block.sv"

    // -------------------------------------------------------------------------
    // Step 3: WISHBONE adapter, driver, monitor, and agent
    //         These bridge the RAL to the physical bus
    // -------------------------------------------------------------------------
    `include "eth_wb_adapter.sv"

    // -------------------------------------------------------------------------
    // Step 4: Environment and test classes
    //         Wires everything together and provides test entry points
    // -------------------------------------------------------------------------


endpackage : eth_ral_pkg
`endif //  ETH_RAL_PKG_SV
