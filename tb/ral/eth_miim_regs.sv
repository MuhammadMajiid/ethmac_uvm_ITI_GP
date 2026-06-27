//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_miimoder_reg.sv
// Author   : Nada
// Date     : 2026-06-25
// =============================================================================
// Description:
// Register : MIIMODER (MII Mode Register)
// Address  : 0x28
// Width    : 32 bits
// Access   : RW
// Reset    : 0x0000_0064
//
// Bit map:
//   [31:9]  Reserved
//   [8]     MIINOPRE - No Preamble (0=32-bit preamble, 1=no preamble)
//   [7:0]   CLKDIV   - Clock Divider (reset=0x64=100)
//           MDC = Host_CLK / (2 * CLKDIV)
// =============================================================================
`ifndef  ETH_MIIMODER_REG_SV
`define  ETH_MIIMODER_REG_SV

class eth_miimoder_reg extends uvm_reg;

    `uvm_object_utils(eth_miimoder_reg)

    rand uvm_reg_field MIINOPRE;
    rand uvm_reg_field CLKDIV;

    function new(string name = "eth_miimoder_reg");
        super.new(name, 32, UVM_CVR_ALL);
    endfunction

    virtual function void build();

        MIINOPRE = uvm_reg_field::type_id::create("MIINOPRE");
        CLKDIV   = uvm_reg_field::type_id::create("CLKDIV");

        //            parent  sz  lsb  access  vol  reset    has_rst rand  indv
        MIINOPRE.configure(this, 1,  8,  "RW",   0,  1'b0,   1,      1,    0);
        CLKDIV  .configure(this, 8,  0,  "RW",   0,  8'h64,  1,      1,    0);                                         
        //                                   default divider = 100 (0x64)

    endfunction

endclass : eth_miimoder_reg
`endif //ETH_MIIMODER_REG_SV

//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_miicommand_reg.sv
// Author   : Nada
// Date     : 2026-06-25
// =============================================================================
// Description:
// Register : MIICOMMAND (MII Command Register)
// Address  : 0x2C
// Width    : 32 bits
// Access   : RW
// Reset    : 0x0000_0000
//
// Bit map:
//   [31:3]  Reserved
//   [2]     WCTRLDATA - Write Control Data to PHY
//   [1]     RSTAT     - Read Status from PHY
//   [0]     SCANSTAT  - Scan Status (continuous read)
//
// Note: Only one command bit should be set at a time.
//       BUSY in MIISTATUS is set while command is executing.
//       Next command must wait until BUSY=0.
// =============================================================================
`ifndef  ETH_MIICOMMAND_REG_SV
`define  ETH_MIICOMMAND_REG_SV
class eth_miicommand_reg extends uvm_reg;

    `uvm_object_utils(eth_miicommand_reg)

    rand uvm_reg_field WCTRLDATA;
    rand uvm_reg_field RSTAT;
    rand uvm_reg_field SCANSTAT;

    // Constraint: only one command bit at a time
    constraint c_one_command {
        $onehot0({WCTRLDATA.value, RSTAT.value, SCANSTAT.value});
    }

    function new(string name = "eth_miicommand_reg");
        super.new(name, 32, UVM_CVR_ALL);
    endfunction

    virtual function void build();

        WCTRLDATA = uvm_reg_field::type_id::create("WCTRLDATA");
        RSTAT     = uvm_reg_field::type_id::create("RSTAT");
        SCANSTAT  = uvm_reg_field::type_id::create("SCANSTAT");

        //             parent  sz  lsb  access  vol  reset  has_rst rand  indv
        WCTRLDATA.configure(this, 1,  2,  "RW",   0,  1'b0,  1,      1,    0);
        RSTAT    .configure(this, 1,  1,  "RW",   0,  1'b0,  1,      1,    0);
        SCANSTAT .configure(this, 1,  0,  "RW",   0,  1'b0,  1,      1,    0);

    endfunction

endclass : eth_miicommand_reg
`endif //ETH_MIICOMMAND_REG_SV

//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_miiaddress_reg.sv
// Author   : Nada
// Date     : 2026-06-25
// =============================================================================
// Description:
// Register : MIIADDRESS (MII Address Register)
// Address  : 0x30
// Width    : 32 bits
// Access   : RW
// Reset    : 0x0000_0000
//
// Bit map:
//   [31:13] Reserved
//   [12:8]  RGAD - Register Address within selected PHY  (5 bits)
//   [7:5]   Reserved
//   [4:0]   FIAD - PHY Address                           (5 bits)
// =============================================================================
`ifndef  ETH_MIIADDRESS_REG_SV
`define  ETH_MIIADDRESS_REG_SV
class eth_miiaddress_reg extends uvm_reg;

    `uvm_object_utils(eth_miiaddress_reg)

    rand uvm_reg_field RGAD;
    rand uvm_reg_field FIAD;

    function new(string name = "eth_miiaddress_reg");
        super.new(name, 32, UVM_CVR_ALL);
    endfunction

    virtual function void build();

        RGAD = uvm_reg_field::type_id::create("RGAD");
        FIAD = uvm_reg_field::type_id::create("FIAD");

        //       parent  sz  lsb  access  vol  reset  has_rst rand  indv
        RGAD.configure(this, 5,  8,  "RW",   0,  5'h0,  1,      1,    0);
        FIAD.configure(this, 5,  0,  "RW",   0,  5'h0,  1,      1,    0);

    endfunction

endclass : eth_miiaddress_reg
`endif //ETH_MIIADDRESS_REG_SV

//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_miitx_data_reg
// Author   : Nada
// Date     : 2026-06-25
// =============================================================================
// Description:
// Register : MIITX_DATA (MII Transmit Data Register)
// Address  : 0x34
// Width    : 32 bits
// Access   : RW
// Reset    : 0x0000_0000
//
// Bit map:
//   [31:16] Reserved
//   [15:0]  CTRLDATA - Control Data to write to PHY register
// =============================================================================
`ifndef ETH_MIITX_DATA_REG_SV
`define ETH_MIITX_DATA_REG_SV

class eth_miitx_data_reg extends uvm_reg;

    `uvm_object_utils(eth_miitx_data_reg)

    rand uvm_reg_field CTRLDATA;

    function new(string name = "eth_miitx_data_reg");
        super.new(name, 32, UVM_CVR_ALL);
    endfunction

    virtual function void build();

        CTRLDATA = uvm_reg_field::type_id::create("CTRLDATA");

        //           parent  sz   lsb  access  vol  reset     has_rst rand  indv
        CTRLDATA.configure(this, 16,   0,  "RW",   0,  16'h0,   1,      1,    0);

    endfunction

endclass : eth_miitx_data_reg
`endif //ETH_MIITX_DATA_REG_SV

//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_miirx_data_reg
// Author   : Nada
// Date     : 2026-06-25
// =============================================================================
// Description:
// Register : MIIRX_DATA (MII Receive Data Register)
// Address  : 0x38
// Width    : 32 bits
// Access   : RO (read only - written by hardware after PHY read)
// Reset    : 0x0000_0000
//
// Bit map:
//   [31:16] Reserved
//   [15:0]  PRSD - Received Data from PHY (read only)
// =============================================================================
`ifndef ETH_MIIRX_DATA_REG_SV
`define ETH_MIIRX_DATA_REG_SV

class eth_miirx_data_reg extends uvm_reg;

    `uvm_object_utils(eth_miirx_data_reg)

    rand uvm_reg_field PRSD;

    function new(string name = "eth_miirx_data_reg");
        super.new(name, 32, UVM_CVR_ALL);
    endfunction

    virtual function void build();

        PRSD = uvm_reg_field::type_id::create("PRSD");

        // RO: read only, hardware writes this after PHY read completes
        // volatile=1: hardware updates this field
        // rand=0: we never randomize read-only fields
        //       parent  sz   lsb  access  vol  reset    has_rst rand  indv
        PRSD.configure(this, 16,   0,  "RO",   1,  16'h0,  1,      0,    0);

    endfunction

endclass : eth_miirx_data_reg
`endif //ETH_MIIRX_DATA_REG_SV

//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_miistatus_reg
// Author   : Nada
// Date     : 2026-06-25
// =============================================================================
// Description:
// Register : MIISTATUS (MII Status Register)
// Address  : 0x3C
// Width    : 32 bits
// Access   : RO (all bits read-only, set/cleared by hardware)
// Reset    : 0x0000_0000
//
// Bit map:
//   [31:3]  Reserved
//   [2]     NVALID   - Invalid (1=data invalid during scan)
//   [1]     BUSY     - MII busy (1=operation in progress)
//   [0]     LINKFAIL - Link Failed
// =============================================================================
`ifndef ETH_MIISTATUS_REG_SV
`define ETH_MIISTATUS_REG_SV
class eth_miistatus_reg extends uvm_reg;

    `uvm_object_utils(eth_miistatus_reg)

    rand uvm_reg_field NVALID;
    rand uvm_reg_field BUSY;
    rand uvm_reg_field LINKFAIL;

    function new(string name = "eth_miistatus_reg");
        super.new(name, 32, UVM_CVR_ALL);
    endfunction

    virtual function void build();

        NVALID   = uvm_reg_field::type_id::create("NVALID");
        BUSY     = uvm_reg_field::type_id::create("BUSY");
        LINKFAIL = uvm_reg_field::type_id::create("LINKFAIL");

        // All RO: hardware sets/clears these
        // volatile=1: hardware modifies these fields
        // rand=0: never randomize read-only fields
        //          parent  sz  lsb  access  vol  reset  has_rst rand  indv
        NVALID  .configure(this, 1,  2,  "RO",   1,  1'b0,  1,      0,    0);
        BUSY    .configure(this, 1,  1,  "RO",   1,  1'b0,  1,      0,    0);
        LINKFAIL.configure(this, 1,  0,  "RO",   1,  1'b0,  1,      0,    0);

    endfunction

endclass : eth_miistatus_reg

`endif //ETH_MIISTATUS_REG_SV
