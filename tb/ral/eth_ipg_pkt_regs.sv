//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_ipgt_reg.sv
// Author   : Nada
// Date     : 2026-06-25
//------------------------------------------------------------------------------
// Description:
// Register : IPGT (Back-to-Back Inter Packet Gap Register)
// Address  : 0x0C
// Width    : 32 bits
// Access   : RW
// Reset    : 0x0000_0012
//
// Bit map:
//   [31:7]  Reserved
//   [6:0]   IPGT - Back to Back Inter Packet Gap value
//           Full duplex recommended: 0x15
//           Half duplex recommended/default: 0x12
// =============================================================================
`ifndef ETH_IPGT_REG_SV
`define ETH_IPGT_REG_SV

class eth_ipgt_reg extends uvm_reg;

    `uvm_object_utils(eth_ipgt_reg)

    rand uvm_reg_field IPGT;

    function new(string name = "eth_ipgt_reg");
        super.new(name, 32, UVM_CVR_ALL);
    endfunction

    virtual function void build();

        IPGT = uvm_reg_field::type_id::create("IPGT");

        //        parent  sz  lsb  access  vol  reset       has_rst rand  indv
        IPGT.configure(this, 7,  0,  "RW",   0,  7'h12,     1,      1,    0);                               
        //                                    reset = 0x12

    endfunction

endclass : eth_ipgt_reg

`endif //  ETH_IPGT_REG_SV

//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_ipgr1_reg.sv
// Author   : Nada
// Date     : 2026-06-25
//------------------------------------------------------------------------------
// Description:
// Register : IPGR1 (Non Back-to-Back Inter Packet Gap Register 1)
// Address  : 0x10
// Width    : 32 bits
// Access   : RW
// Reset    : 0x0000_000C
//
// Bit map:
//   [31:7]  Reserved
//   [6:0]   IPGR1 - Non Back to Back IPG 1
//           Recommended/default: 0x0C
//           Must be within range [0, IPGR2]
// =============================================================================
`ifndef ETH_IPGR1_REG_SV
`define ETH_IPGR1_REG_SV
class eth_ipgr1_reg extends uvm_reg;

    `uvm_object_utils(eth_ipgr1_reg)

    rand uvm_reg_field IPGR1;

    function new(string name = "eth_ipgr1_reg");
        super.new(name, 32, UVM_CVR_ALL);
    endfunction

    virtual function void build();

        IPGR1 = uvm_reg_field::type_id::create("IPGR1");

        //         parent  sz  lsb  access  vol  reset    has_rst rand  indv
        IPGR1.configure(this, 7,  0,  "RW",   0,  7'h0C,  1,      1,    0);

    endfunction

endclass : eth_ipgr1_reg

`endif //  ETH_IPGR1_REG_SV

//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_ipgr2_reg.sv
// Author   : Nada
// Date     : 2026-06-25
//------------------------------------------------------------------------------
// Description:
// Register : IPGR2 (Non Back-to-Back Inter Packet Gap Register 2)
// Address  : 0x14
// Width    : 32 bits
// Access   : RW
// Reset    : 0x0000_0012
//
// Bit map:
//   [31:7]  Reserved
//   [6:0]   IPGR2 - Non Back to Back IPG 2
//           Recommended/default: 0x12
// =============================================================================
`ifndef ETH_IPGR2_REG_SV
`define ETH_IPGR2_REG_SV
class eth_ipgr2_reg extends uvm_reg;

    `uvm_object_utils(eth_ipgr2_reg)

    rand uvm_reg_field IPGR2;

    function new(string name = "eth_ipgr2_reg");
        super.new(name, 32, UVM_CVR_ALL);
    endfunction

    virtual function void build();

        IPGR2 = uvm_reg_field::type_id::create("IPGR2");

        //         parent  sz  lsb  access  vol  reset    has_rst rand  indv
        IPGR2.configure(this, 7,  0,  "RW",   0,  7'h12,  1,      1,    0);

    endfunction

endclass : eth_ipgr2_reg

`endif //ETH_IPGR2_REG_SV

//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_packetlen_reg.sv
// Author   : Nada
// Date     : 2026-06-25
//------------------------------------------------------------------------------
// Description:
// Register : PACKETLEN (Packet Length Register)
// Address  : 0x18
// Width    : 32 bits
// Access   : RW
// Reset    : 0x0040_0600
//
// Bit map:
//   [31:16] MINFL - Minimum Frame Length  (reset = 0x0040 = 64)
//   [15:0]  MAXFL - Maximum Frame Length  (reset = 0x0600 = 1536)
// =============================================================================
`ifndef ETH_PACKETLEN_REG_SV
`define ETH_PACKETLEN_REG_SV

class eth_packetlen_reg extends uvm_reg;

    `uvm_object_utils(eth_packetlen_reg)

    rand uvm_reg_field MINFL;
    rand uvm_reg_field MAXFL;

    function new(string name = "eth_packetlen_reg");
        super.new(name, 32, UVM_CVR_ALL);
    endfunction

    virtual function void build();

        MINFL = uvm_reg_field::type_id::create("MINFL");
        MAXFL = uvm_reg_field::type_id::create("MAXFL");

        //        parent  sz   lsb  access  vol  reset       has_rst rand  indv
        MINFL.configure(this, 16,  16, "RW",  0,  16'h0040,  1,      1,    0);
        MAXFL.configure(this, 16,   0, "RW",  0,  16'h0600,  1,      1,    0);

    endfunction

endclass : eth_packetlen_reg

`endif //ETH_PACKETLEN_REG_SV

//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_collconf_reg.sv
// Author   : Nada
// Date     : 2026-06-25
//------------------------------------------------------------------------------
// Description:
// Register : COLLCONF (Collision and Retry Configuration Register)
// Address  : 0x1C
// Width    : 32 bits
// Access   : RW
// Reset    : 0x000F_003F
//
// Bit map:
//   [31:20] Reserved
//   [19:16] MAXRET   - Maximum Retry         (reset = 0xF = 15)
//   [15:6]  Reserved
//   [5:0]   COLLVALID - Collision Valid Window (reset = 0x3F = 63)
// =============================================================================


`ifndef ETH_COLLCONF_REG_SV
`define ETH_COLLCONF_REG_SV

class eth_collconf_reg extends uvm_reg;

    `uvm_object_utils(eth_collconf_reg)

    rand uvm_reg_field MAXRET;
    rand uvm_reg_field COLLVALID;

    function new(string name = "eth_collconf_reg");
        super.new(name, 32, UVM_CVR_ALL);
    endfunction

    virtual function void build();

        MAXRET    = uvm_reg_field::type_id::create("MAXRET");
        COLLVALID = uvm_reg_field::type_id::create("COLLVALID");

        //            parent  sz  lsb  access  vol  reset    has_rst rand  indv
        MAXRET   .configure(this, 4, 16, "RW",  0,  4'hF,   1,      1,    0);
        COLLVALID.configure(this, 6,  0, "RW",  0,  6'h3F,  1,      1,    0);

    endfunction

endclass : eth_collconf_reg

`endif //ETH_COLLCONF_REG_SV
