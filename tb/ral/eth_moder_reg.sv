//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_moder_reg.sv
// Author   : Nada
// Date     : 2026-06-25
// =============================================================================
// Description:
// Register : MODER (Mode Register)
// Address  : 0x00
// Width    : 32 bits
// Access   : RW
// Reset    : 0x0000_A000
//
// Bit map:
//   [31:17] Reserved
//   [16]    RECSMALL  - Receive Small Packets
//   [15]    PAD       - Padding Enabled
//   [14]    HUGEN     - Huge Packets Enable
//   [13]    CRCEN     - CRC Enable              (reset=1)
//   [12]    DLYCRCEN  - Delayed CRC Enabled
//   [11]    Reserved
//   [10]    FULLD     - Full Duplex
//   [9]     EXDFREN   - Excess Defer Enabled
//   [8]     NOBCKOF   - No Backoff              (reset=1)
//   [7]     LOOPBCK   - Loop Back
//   [6]     IFG       - Interframe Gap
//   [5]     PRO       - Promiscuous
//   [4]     IAM       - Individual Address Mode
//   [3]     BRO       - Broadcast Address
//   [2]     NOPRE     - No Preamble
//   [1]     TXEN      - Transmit Enable
//   [0]     RXEN      - Receive Enable
// =============================================================================

`ifndef  ETH_MODER_REG_SV
`define  ETH_MODER_REG_SV

class eth_moder_reg extends uvm_reg;

    `uvm_object_utils(eth_moder_reg)

    // -------------------------------------------------------------------------
    // Field declarations
    // -------------------------------------------------------------------------
    rand uvm_reg_field RECSMALL;
    rand uvm_reg_field PAD;
    rand uvm_reg_field HUGEN;
    rand uvm_reg_field CRCEN;
    rand uvm_reg_field DLYCRCEN;
    rand uvm_reg_field FULLD;
    rand uvm_reg_field EXDFREN;
    rand uvm_reg_field NOBCKOF;
    rand uvm_reg_field LOOPBCK;
    rand uvm_reg_field IFG;
    rand uvm_reg_field PRO;
    rand uvm_reg_field IAM;
    rand uvm_reg_field BRO;
    rand uvm_reg_field NOPRE;
    rand uvm_reg_field TXEN;
    rand uvm_reg_field RXEN;

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------
    function new(string name = "eth_moder_reg");
        // 32-bit register, 1 coverage model
        super.new(name, 32, UVM_CVR_ALL);
    endfunction

    // -------------------------------------------------------------------------
    // build() - configure every field
    // configure(parent, size, lsb_pos, access, volatile,
    //           reset_val, has_reset, is_rand, individually_accessible)
    // -------------------------------------------------------------------------
    virtual function void build();

        RECSMALL = uvm_reg_field::type_id::create("RECSMALL");
        PAD      = uvm_reg_field::type_id::create("PAD");
        HUGEN    = uvm_reg_field::type_id::create("HUGEN");
        CRCEN    = uvm_reg_field::type_id::create("CRCEN");
        DLYCRCEN = uvm_reg_field::type_id::create("DLYCRCEN");
        FULLD    = uvm_reg_field::type_id::create("FULLD");
        EXDFREN  = uvm_reg_field::type_id::create("EXDFREN");
        NOBCKOF  = uvm_reg_field::type_id::create("NOBCKOF");
        LOOPBCK  = uvm_reg_field::type_id::create("LOOPBCK");
        IFG      = uvm_reg_field::type_id::create("IFG");
        PRO      = uvm_reg_field::type_id::create("PRO");
        IAM      = uvm_reg_field::type_id::create("IAM");
        BRO      = uvm_reg_field::type_id::create("BRO");
        NOPRE    = uvm_reg_field::type_id::create("NOPRE");
        TXEN     = uvm_reg_field::type_id::create("TXEN");
        RXEN     = uvm_reg_field::type_id::create("RXEN");

        //              parent  sz  lsb  access   vol  reset  has_rst rand  indv
        RECSMALL.configure(this, 1, 16, "RW",     0,  1'b0,   1,      1,    0);
        PAD     .configure(this, 1, 15, "RW",     0,  1'b1,   1,      1,    0); // reset=1
        HUGEN   .configure(this, 1, 14, "RW",     0,  1'b0,   1,      1,    0);
        CRCEN   .configure(this, 1, 13, "RW",     0,  1'b1,   1,      1,    0); // reset=1
        DLYCRCEN.configure(this, 1, 12, "RW",     0,  1'b0,   1,      1,    0);
        // bit 11 reserved - not declared as a field
        FULLD   .configure(this, 1, 10, "RW",     0,  1'b0,   1,      1,    0);
        EXDFREN .configure(this, 1,  9, "RW",     0,  1'b0,   1,      1,    0);
        NOBCKOF .configure(this, 1,  8, "RW",     0,  1'b0,   1,      1,    0); 
        LOOPBCK .configure(this, 1,  7, "RW",     0,  1'b0,   1,      1,    0);
        IFG     .configure(this, 1,  6, "RW",     0,  1'b0,   1,      1,    0);
        PRO     .configure(this, 1,  5, "RW",     0,  1'b0,   1,      1,    0);
        IAM     .configure(this, 1,  4, "RW",     0,  1'b0,   1,      1,    0);
        BRO     .configure(this, 1,  3, "RW",     0,  1'b0,   1,      1,    0);
        NOPRE   .configure(this, 1,  2, "RW",     0,  1'b0,   1,      1,    0);
        TXEN    .configure(this, 1,  1, "RW",     0,  1'b0,   1,      1,    0);
        RXEN    .configure(this, 1,  0, "RW",     0,  1'b0,   1,      1,    0);

    endfunction

endclass : eth_moder_reg

`endif //  ETH_MODER_REG_SV
