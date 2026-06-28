//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_tx_bd_num_reg.sv
// Author   : Nada
// Date     : 2026-06-25
// =============================================================================
// Description:
// Register : TX_BD_NUM (Transmit Buffer Descriptor Number Register)
// Address  : 0x20
// Width    : 32 bits
// Access   : RW
// Reset    : 0x0000_0040 (64 TX BDs by default)
//
// Bit map:
//   [31:8]  Reserved
//   [7:0]   TX_BD_NUM - Number of TX Buffer Descriptors
//           Range: 0x00 to 0x80
//           Values > 0x80 are ignored
//           0x80 means all 128 BDs are TX (no RX BDs)
//           0x00 means all 128 BDs are RX (no TX BDs)
//
// Note: Number of RX BDs = 0x80 - TX_BD_NUM
// =============================================================================

`ifndef  ETH_TX_BD_NUM_REG_SV
`define  ETH_TX_BD_NUM_REG_SV

class eth_tx_bd_num_reg extends uvm_reg;

    `uvm_object_utils(eth_tx_bd_num_reg)

    rand uvm_reg_field TX_BD_NUM;

    // Constraint: legal range is 0x00 to 0x80
    constraint c_tx_bd_num_range {
        TX_BD_NUM.value inside {[0:128]};
    }

    function new(string name = "eth_tx_bd_num_reg");
        super.new(name, 32, UVM_CVR_ALL);
    endfunction

    virtual function void build();

        TX_BD_NUM = uvm_reg_field::type_id::create("TX_BD_NUM");

        //            parent  sz  lsb  access  vol  reset    has_rst rand  indv
        TX_BD_NUM.configure(this, 8,  0,  "RW",   0,  8'h40,  1,      1,    0);                                         
        //                                   default 64 TX BDs (0x40)

    endfunction

endclass : eth_tx_bd_num_reg

`endif //ETH_TX_BD_NUM_REG_SV

//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_ctrlmoder_reg.sv
// Author   : Nada
// Date     : 2026-06-25
// =============================================================================
// Description:
// Register : CTRLMODER (Control Module Mode Register)
// Address  : 0x24
// Width    : 32 bits
// Access   : RW
// Reset    : 0x0000_0000
//
// Bit map:
//   [31:3]  Reserved
//   [2]     TXFLOW  - Transmit Flow Control
//   [1]     RXFLOW  - Receive Flow Control
//   [0]     PASSALL - Pass All Receive Frames
// =============================================================================
`ifndef ETH_CTRLMODER_REG_SV
`define ETH_CTRLMODER_REG_SV
class eth_ctrlmoder_reg extends uvm_reg;

    `uvm_object_utils(eth_ctrlmoder_reg)

    rand uvm_reg_field TXFLOW;
    rand uvm_reg_field RXFLOW;
    rand uvm_reg_field PASSALL;

    function new(string name = "eth_ctrlmoder_reg");
        super.new(name, 32, UVM_CVR_ALL);
    endfunction

    virtual function void build();

        TXFLOW  = uvm_reg_field::type_id::create("TXFLOW");
        RXFLOW  = uvm_reg_field::type_id::create("RXFLOW");
        PASSALL = uvm_reg_field::type_id::create("PASSALL");

        //           parent  sz  lsb  access  vol  reset  has_rst rand  indv
        TXFLOW .configure(this, 1,  2,  "RW",   0,  1'b0,  1,      1,    0);
        RXFLOW .configure(this, 1,  1,  "RW",   0,  1'b0,  1,      1,    0);
        PASSALL.configure(this, 1,  0,  "RW",   0,  1'b0,  1,      1,    0);

    endfunction

endclass : eth_ctrlmoder_reg

`endif //ETH_CTRLMODER_REG_SV
