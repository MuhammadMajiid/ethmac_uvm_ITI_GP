//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_mac_addr0_reg.sv
// Author   : Nada
// Date     : 2026-06-25
// =============================================================================
// Description:
// Register : MAC_ADDR0 (MAC Address Register 0)
// Address  : 0x40
// Width    : 32 bits
// Access   : RW
// Reset    : 0x0000_0000
//
// Bit map:
//   [31:24] Byte 2 of MAC address
//   [23:16] Byte 3 of MAC address
//   [15:8]  Byte 4 of MAC address
//   [7:0]   Byte 5 of MAC address
//
// Note: Address transmitted byte 0 first (byte 0 is in MAC_ADDR1[15:8])
//       Full 48-bit MAC = {MAC_ADDR1[15:8], MAC_ADDR1[7:0],
//                          MAC_ADDR0[31:24], MAC_ADDR0[23:16],
//                          MAC_ADDR0[15:8],  MAC_ADDR0[7:0]}
// =============================================================================

`ifndef  ETH_MAC_ADDR0_REG_SV
`define  ETH_MAC_ADDR0_REG_SV

class eth_mac_addr0_reg extends uvm_reg;

    `uvm_object_utils(eth_mac_addr0_reg)

    rand uvm_reg_field BYTE2;
    rand uvm_reg_field BYTE3;
    rand uvm_reg_field BYTE4;
    rand uvm_reg_field BYTE5;

    function new(string name = "eth_mac_addr0_reg");
        super.new(name, 32, UVM_CVR_ALL);
    endfunction

    virtual function void build();

        BYTE2 = uvm_reg_field::type_id::create("BYTE2");
        BYTE3 = uvm_reg_field::type_id::create("BYTE3");
        BYTE4 = uvm_reg_field::type_id::create("BYTE4");
        BYTE5 = uvm_reg_field::type_id::create("BYTE5");

        //        parent  sz  lsb  access  vol  reset   has_rst rand  indv
        BYTE2.configure(this, 8, 24, "RW",  0,  8'h0,   1,      1,    0);
        BYTE3.configure(this, 8, 16, "RW",  0,  8'h0,   1,      1,    0);
        BYTE4.configure(this, 8,  8, "RW",  0,  8'h0,   1,      1,    0);
        BYTE5.configure(this, 8,  0, "RW",  0,  8'h0,   1,      1,    0);

    endfunction

endclass : eth_mac_addr0_reg

`endif //ETH_MAC_ADDR0_REG_SV 


//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_mac_addr1_reg.sv
// Author   : Nada
// Date     : 2026-06-25
// =============================================================================
// Description:
// Register : MAC_ADDR1 (MAC Address Register 1)
// Address  : 0x44
// Width    : 32 bits
// Access   : RW
// Reset    : 0x0000_0000
//
// Bit map:
//   [31:16] Reserved
//   [15:8]  Byte 0 of MAC address (transmitted first)
//   [7:0]   Byte 1 of MAC address
// =============================================================================
`ifndef  ETH_MAC_ADDR1_REG_SV
`define  ETH_MAC_ADDR1_REG_SV

class eth_mac_addr1_reg extends uvm_reg;

    `uvm_object_utils(eth_mac_addr1_reg)

    rand uvm_reg_field BYTE0;
    rand uvm_reg_field BYTE1;

    function new(string name = "eth_mac_addr1_reg");
        super.new(name, 32, UVM_CVR_ALL);
    endfunction

    virtual function void build();

        BYTE0 = uvm_reg_field::type_id::create("BYTE0");
        BYTE1 = uvm_reg_field::type_id::create("BYTE1");

        //        parent  sz  lsb  access  vol  reset   has_rst rand  indv
        BYTE0.configure(this, 8, 8,  "RW",  0,  8'h0,   1,      1,    0);
        BYTE1.configure(this, 8, 0,  "RW",  0,  8'h0,   1,      1,    0);

    endfunction

endclass : eth_mac_addr1_reg

`endif //ETH_MAC_ADDR1_REG_SV 

//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_hash0_reg.sv
// Author   : Nada
// Date     : 2026-06-25
// =============================================================================
// Description:
// Register : HASH0 (Hash Register 0)
// Address  : 0x48
// Width    : 32 bits
// Access   : RW
// Reset    : 0x0000_0000
//
// Bit map:
//   [31:0]  Hash0 - Lower 32 bits of 64-bit hash table
//
// Note: Together HASH0 and HASH1 form a 64-bit hash table.
//       Used when IAM=1 in MODER for multicast address filtering.
//       CRC of 48-bit address  6-bit index  bit in HASH0/HASH1
// =============================================================================

`ifndef  ETH_HASH0_REG_SV
`define  ETH_HASH0_REG_SV

class eth_hash0_reg extends uvm_reg;

    `uvm_object_utils(eth_hash0_reg)

    rand uvm_reg_field HASH0;

    function new(string name = "eth_hash0_reg");
        super.new(name, 32, UVM_CVR_ALL);
    endfunction

    virtual function void build();

        HASH0 = uvm_reg_field::type_id::create("HASH0");

        //         parent  sz   lsb  access  vol  reset      has_rst rand  indv
        HASH0.configure(this, 32,   0,  "RW",   0,  32'h0,    1,      1,    0);

    endfunction

endclass : eth_hash0_reg

`endif //ETH_HASH0_REG_SV

//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_hash1_reg.sv
// Author   : Nada
// Date     : 2026-06-25
// =============================================================================
// Description:
// Register : HASH1 (Hash Register 1)
// Address  : 0x4C
// Width    : 32 bits
// Access   : RW
// Reset    : 0x0000_0000
//
// Bit map:
//   [31:0]  Hash1 - Upper 32 bits of 64-bit hash table
// =============================================================================

`ifndef ETH_HASH1_REG_SV
`define ETH_HASH1_REG_SV

class eth_hash1_reg extends uvm_reg;

    `uvm_object_utils(eth_hash1_reg)

    rand uvm_reg_field HASH1;

    function new(string name = "eth_hash1_reg");
        super.new(name, 32, UVM_CVR_ALL);
    endfunction

    virtual function void build();

        HASH1 = uvm_reg_field::type_id::create("HASH1");

        //         parent  sz   lsb  access  vol  reset      has_rst rand  indv
        HASH1.configure(this, 32,   0,  "RW",   0,  32'h0,    1,      1,    0);

    endfunction

endclass : eth_hash1_reg

`endif //ETH_HASH1_REG_SV

//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_txctrl_reg.sv
// Author   : Nada
// Date     : 2026-06-25
// =============================================================================
// Description:
// Register : TXCTRL (TX Control Register)
// Address  : 0x50
// Width    : 32 bits
// Access   : RW
// Reset    : 0x0000_0000
//
// Bit map:
//   [31:17] Reserved
//   [16]    TXPAUSERQ - TX Pause Request
//           Writing 1 starts sending PAUSE control frame.
//           Bit is automatically cleared to 0 after frame sent.
//   [15:0]  TXPAUSETV - TX Pause Timer Value
//           Value sent in the PAUSE control frame timer field.
// =============================================================================

`ifndef ETH_TXCTRL_REG_SV
`define ETH_TXCTRL_REG_SV

class eth_txctrl_reg extends uvm_reg;

    `uvm_object_utils(eth_txctrl_reg)

    rand uvm_reg_field TXPAUSERQ;
    rand uvm_reg_field TXPAUSETV;

    function new(string name = "eth_txctrl_reg");
        super.new(name, 32, UVM_CVR_ALL);
    endfunction

    virtual function void build();

        TXPAUSERQ = uvm_reg_field::type_id::create("TXPAUSERQ");
        TXPAUSETV = uvm_reg_field::type_id::create("TXPAUSETV");

        // TXPAUSERQ: writing 1 triggers PAUSE frame, auto-clears
        // We model as RW because host writes 1 to request
        // Hardware clears it automatically (volatile=1)
        //             parent  sz   lsb  access  vol  reset     has_rst rand  indv
        TXPAUSERQ.configure(this,  1,  16,  "RW",   0,  1'b0,   1,      1,    0);
        TXPAUSETV.configure(this, 16,   0,  "RW",   0,  16'h0,  1,      1,    0);

    endfunction

endclass : eth_txctrl_reg
`endif //ETH_TXCTRL_REG_SV
