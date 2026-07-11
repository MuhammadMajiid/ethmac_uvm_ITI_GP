//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : mdio_tx.sv
// Author   : Muhammad Majid
// Date     : 2026-06-26
//------------------------------------------------------------------------------
// Description:
//   Transaction contains mdio interface ports.
//==============================================================================

`ifndef MDIO_SEQ_ITEM_BASE
`define MDIO_SEQ_ITEM_BASE

    `include "uvm_macros.svh"
    import uvm_pkg::*;

class mdio_seq_item_base extends uvm_sequence_item;

    `uvm_object_utils(mdio_seq_item_base)

    // Randomizable transaction fields
    op_code_e  op;
    bit [1:0]  st;
    bit [31:0] preamble;
    bit [4:0]  phy_addr;
    bit [4:0]  reg_addr;
    bit [15:0] data;
    bit [1:0]  turn_around;
    real       clk_period_ns;
    function new(string name = "mdio_seq_item_base");
    super.new(name);
    endfunction

endclass

`endif // MDIO_SEQ_ITEM_BASE
