//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_int_source_reg.sv
// Author   : Nada
// Date     : 2026-06-25
// =============================================================================
// Description:
// Register : INT_SOURCE (Interrupt Source Register)
// Address  : 0x04
// Width    : 32 bits
// Access   : W1C (write 1 to clear each bit)
// Reset    : 0x0000_0000
//
// Bit map:
//   [31:7]  Reserved
//   [6]     RXC   - Receive Control Frame
//   [5]     TXC   - Transmit Control Frame
//   [4]     BUSY  - Busy (buffer discarded)
//   [3]     RXE   - Receive Error
//   [2]     RXB   - Receive Frame
//   [1]     TXE   - Transmit Error
//   [0]     TXB   - Transmit Buffer
// =============================================================================
`ifndef  ETH_INT_SOURCE_REG_SV
`define  ETH_INT_SOURCE_REG_SV

class eth_int_source_reg extends uvm_reg;

    `uvm_object_utils(eth_int_source_reg)

    rand uvm_reg_field RXC;
    rand uvm_reg_field TXC;
    rand uvm_reg_field BUSY;
    rand uvm_reg_field RXE;
    rand uvm_reg_field RXB;
    rand uvm_reg_field TXE;
    rand uvm_reg_field TXB;

    function new(string name = "eth_int_source_reg");
        super.new(name, 32, UVM_CVR_ALL);
    endfunction

    virtual function void build();

        RXC  = uvm_reg_field::type_id::create("RXC");
        TXC  = uvm_reg_field::type_id::create("TXC");
        BUSY = uvm_reg_field::type_id::create("BUSY");
        RXE  = uvm_reg_field::type_id::create("RXE");
        RXB  = uvm_reg_field::type_id::create("RXB");
        TXE  = uvm_reg_field::type_id::create("TXE");
        TXB  = uvm_reg_field::type_id::create("TXB");

        // W1C: writing 1 clears the bit, writing 0 has no effect
        // Hardware sets these bits when events occur
        // volatile=1 because hardware can modify these bits
        //           parent  sz  lsb  access  vol  reset  has_rst rand  indv
        RXC .configure(this,  1,  6,  "W1C",   0,  1'b0,   1,      0,    0);
        TXC .configure(this,  1,  5,  "W1C",   0,  1'b0,   1,      0,    0);
        BUSY.configure(this,  1,  4,  "W1C",   0,  1'b0,   1,      0,    0);
        RXE .configure(this,  1,  3,  "W1C",   0,  1'b0,   1,      0,    0);
        RXB .configure(this,  1,  2,  "W1C",   0,  1'b0,   1,      0,    0);
        TXE .configure(this,  1,  1,  "W1C",   0,  1'b0,   1,      0,    0);
        TXB .configure(this,  1,  0,  "W1C",   0,  1'b0,   1,      0,    0);

    endfunction

endclass : eth_int_source_reg

`endif //  ETH_INT_SOURCE_REG_SV

//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_int_mask_reg.sv
// Author   : Nada
// Date     : 2026-06-25
// =============================================================================
// Description:
// Register : INT_MASK (Interrupt Mask Register)
// Address  : 0x08
// Width    : 32 bits
// Access   : RW
// Reset    : 0x0000_0000
//
// Bit map:
//   [31:7]  Reserved
//   [6]     RXC_M  - Receive Control Frame Mask
//   [5]     TXC_M  - Transmit Control Frame Mask
//   [4]     BUSY_M - Busy Mask
//   [3]     RXE_M  - Receive Error Mask
//   [2]     RXF_M  - Receive Frame Mask
//   [1]     TXE_M  - Transmit Error Mask
//   [0]     TXB_M  - Transmit Buffer Mask
// =============================================================================

`ifndef  ETH_INT_MASK_REG_SV
`define  ETH_INT_MASK_REG_SV

class eth_int_mask_reg extends uvm_reg;

    `uvm_object_utils(eth_int_mask_reg)

    rand uvm_reg_field RXC_M;
    rand uvm_reg_field TXC_M;
    rand uvm_reg_field BUSY_M;
    rand uvm_reg_field RXE_M;
    rand uvm_reg_field RXF_M;
    rand uvm_reg_field TXE_M;
    rand uvm_reg_field TXB_M;

    function new(string name = "eth_int_mask_reg");
        super.new(name, 32, UVM_CVR_ALL);
    endfunction

    virtual function void build();

        RXC_M  = uvm_reg_field::type_id::create("RXC_M");
        TXC_M  = uvm_reg_field::type_id::create("TXC_M");
        BUSY_M = uvm_reg_field::type_id::create("BUSY_M");
        RXE_M  = uvm_reg_field::type_id::create("RXE_M");
        RXF_M  = uvm_reg_field::type_id::create("RXF_M");
        TXE_M  = uvm_reg_field::type_id::create("TXE_M");
        TXB_M  = uvm_reg_field::type_id::create("TXB_M");

        //            parent  sz  lsb  access  vol  reset  has_rst rand  indv
        RXC_M .configure(this, 1,  6,  "RW",   0,  1'b0,   1,      1,    0);
        TXC_M .configure(this, 1,  5,  "RW",   0,  1'b0,   1,      1,    0);
        BUSY_M.configure(this, 1,  4,  "RW",   0,  1'b0,   1,      1,    0);
        RXE_M .configure(this, 1,  3,  "RW",   0,  1'b0,   1,      1,    0);
        RXF_M .configure(this, 1,  2,  "RW",   0,  1'b0,   1,      1,    0);
        TXE_M .configure(this, 1,  1,  "RW",   0,  1'b0,   1,      1,    0);
        TXB_M .configure(this, 1,  0,  "RW",   0,  1'b0,   1,      1,    0);

    endfunction

endclass : eth_int_mask_reg


`endif //  ETH_INT_MASK_REG_SV