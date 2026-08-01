
//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_reg_block.sv
// Author   : Nada
// Date     : 2026-06-25
// =============================================================================
// Description:
// Purpose   : Complete UVM Register Block for Ethernet MAC IP Core
//
// Contains:
//   - All 21 configuration/status registers
//   - BD RAM modeled as uvm_mem (256 x 32-bit words)
//   - Single WISHBONE register map
//   - Adapter connection point
//
// Register map (WISHBONE slave interface):
//   0x00  MODER
//   0x04  INT_SOURCE
//   0x08  INT_MASK
//   0x0C  IPGT
//   0x10  IPGR1
//   0x14  IPGR2
//   0x18  PACKETLEN
//   0x1C  COLLCONF
//   0x20  TX_BD_NUM
//   0x24  CTRLMODER
//   0x28  MIIMODER
//   0x2C  MIICOMMAND
//   0x30  MIIADDRESS
//   0x34  MIITX_DATA
//   0x38  MIIRX_DATA
//   0x3C  MIISTATUS
//   0x40  MAC_ADDR0
//   0x44  MAC_ADDR1
//   0x48  HASH0
//   0x4C  HASH1
//   0x50  TXCTRL
//   0x400-0x7FF  BD RAM (128 BDs x 8 bytes = 256 x 32-bit words)
// =============================================================================



class eth_reg_block extends uvm_reg_block;
    `uvm_object_utils(eth_reg_block)
    // =========================================================================
    // Register handles ? one per register in the DUT
    // =========================================================================

    // Core mode and control
    rand eth_moder_reg        MODER;        // 0x00
    rand eth_int_source_reg   INT_SOURCE;   // 0x04
    rand eth_int_mask_reg     INT_MASK;     // 0x08

    // Inter-packet gap
    rand eth_ipgt_reg         IPGT;         // 0x0C
    rand eth_ipgr1_reg        IPGR1;        // 0x10
    rand eth_ipgr2_reg        IPGR2;        // 0x14

    // Packet length and collision
    rand eth_packetlen_reg    PACKETLEN;    // 0x18
    rand eth_collconf_reg     COLLCONF;     // 0x1C

    // Buffer descriptor and flow control
    rand eth_tx_bd_num_reg    TX_BD_NUM;    // 0x20
    rand eth_ctrlmoder_reg    CTRLMODER;    // 0x24

    // MIIM interface
    rand eth_miimoder_reg     MIIMODER;     // 0x28
    rand eth_miicommand_reg   MIICOMMAND;   // 0x2C
    rand eth_miiaddress_reg   MIIADDRESS;   // 0x30
    rand eth_miitx_data_reg   MIITX_DATA;  // 0x34
    rand eth_miirx_data_reg   MIIRX_DATA;  // 0x38  (RO)
    rand eth_miistatus_reg    MIISTATUS;    // 0x3C  (RO)

    // MAC addressing
    rand eth_mac_addr0_reg    MAC_ADDR0;    // 0x40
    rand eth_mac_addr1_reg    MAC_ADDR1;    // 0x44

    // Hash table for multicast
    rand eth_hash0_reg        HASH0;        // 0x48
    rand eth_hash1_reg        HASH1;        // 0x4C

    // TX flow control
    rand eth_txctrl_reg       TXCTRL;       // 0x50

    // =========================================================================
    // BD RAM ? modeled as uvm_mem
    // 256 locations x 32 bits = 1024 bytes
    // WISHBONE address range: 0x400 - 0x7FC
    // =========================================================================
    uvm_mem eth_bd_mem;

    // =========================================================================
    // Register map ? single WISHBONE slave map
    // =========================================================================
    uvm_reg_map reg_map;

    // =========================================================================
    // Constructor
    // =========================================================================
    function new(string name = "eth_reg_block");
        // UVM_NO_COVERAGE: use UVM_CVR_ALL to enable all coverage
        super.new(name, UVM_NO_COVERAGE);
    endfunction

    // =========================================================================
    // build() ? create and configure all registers and the map
    // =========================================================================
    virtual function void build();

        // ---------------------------------------------------------------------
        // Step 1: Create all register objects
        // ---------------------------------------------------------------------
        MODER      = eth_moder_reg::type_id::create("MODER");
        INT_SOURCE = eth_int_source_reg::type_id::create("INT_SOURCE");
        INT_MASK   = eth_int_mask_reg::type_id::create("INT_MASK");
        IPGT       = eth_ipgt_reg::type_id::create("IPGT");
        IPGR1      = eth_ipgr1_reg::type_id::create("IPGR1");
        IPGR2      = eth_ipgr2_reg::type_id::create("IPGR2");
        PACKETLEN  = eth_packetlen_reg::type_id::create("PACKETLEN");
        COLLCONF   = eth_collconf_reg::type_id::create("COLLCONF");
        TX_BD_NUM  = eth_tx_bd_num_reg::type_id::create("TX_BD_NUM");
        CTRLMODER  = eth_ctrlmoder_reg::type_id::create("CTRLMODER");
        MIIMODER   = eth_miimoder_reg::type_id::create("MIIMODER");
        MIICOMMAND = eth_miicommand_reg::type_id::create("MIICOMMAND");
        MIIADDRESS = eth_miiaddress_reg::type_id::create("MIIADDRESS");
        MIITX_DATA = eth_miitx_data_reg::type_id::create("MIITX_DATA");
        MIIRX_DATA = eth_miirx_data_reg::type_id::create("MIIRX_DATA");
        MIISTATUS  = eth_miistatus_reg::type_id::create("MIISTATUS");
        MAC_ADDR0  = eth_mac_addr0_reg::type_id::create("MAC_ADDR0");
        MAC_ADDR1  = eth_mac_addr1_reg::type_id::create("MAC_ADDR1");
        HASH0      = eth_hash0_reg::type_id::create("HASH0");
        HASH1      = eth_hash1_reg::type_id::create("HASH1");
        TXCTRL     = eth_txctrl_reg::type_id::create("TXCTRL");

    // -----------------------------------------------------
    // Configure + build registers 
    // -----------------------------------------------------
    MODER.configure(this);  MODER.build();
     
    INT_SOURCE.configure(this); INT_SOURCE.build();
    INT_MASK.configure(this); INT_MASK.build();
   
    IPGT.configure(this); IPGT.build();
    IPGR1.configure(this); IPGR1.build();
    IPGR2.configure(this); IPGR2.build();
    
    PACKETLEN.configure(this); PACKETLEN.build();
    COLLCONF.configure(this); COLLCONF.build();

    TX_BD_NUM.configure(this); TX_BD_NUM.build();
    CTRLMODER.configure(this); CTRLMODER.build();
    MIIMODER.configure(this); MIIMODER.build();
    MIICOMMAND.configure(this); MIICOMMAND.build();
    MIIADDRESS.configure(this); MIIADDRESS.build();
    MIITX_DATA.configure(this); MIITX_DATA.build();
    MIIRX_DATA.configure(this); MIIRX_DATA.build();
    MIISTATUS.configure(this); MIISTATUS.build();
    MAC_ADDR0.configure(this); MAC_ADDR0.build();
    MAC_ADDR1.configure(this); MAC_ADDR1.build();
    HASH0.configure(this); HASH0.build();
    HASH1.configure(this); HASH1.build();
    TXCTRL .configure(this); TXCTRL.build();
    // -----------------------------------------------------
    // Create register map
    // -----------------------------------------------------
  reg_map = create_map(
    "reg_map",
    0,
    4,
    UVM_LITTLE_ENDIAN,
    0          // byte_addressing = 0
);
    default_map = reg_map;

    // -----------------------------------------------------
    // Add registers to map
    // -----------------------------------------------------
reg_map.add_reg(MODER,      'h000, "RW");
reg_map.add_reg(INT_SOURCE, 'h001, "RW");
reg_map.add_reg(INT_MASK,   'h002, "RW");

reg_map.add_reg(IPGT,       'h003, "RW");
reg_map.add_reg(IPGR1,      'h004, "RW");
reg_map.add_reg(IPGR2,      'h005, "RW");

reg_map.add_reg(PACKETLEN,  'h006, "RW");
reg_map.add_reg(COLLCONF,   'h007, "RW");

reg_map.add_reg(TX_BD_NUM,  'h008, "RW");
reg_map.add_reg(CTRLMODER,  'h009, "RW");

reg_map.add_reg(MIIMODER,   'h00A, "RW");
reg_map.add_reg(MIICOMMAND, 'h00B, "RW");
reg_map.add_reg(MIIADDRESS, 'h00C, "RW");

reg_map.add_reg(MIITX_DATA, 'h00D, "RW");
reg_map.add_reg(MIIRX_DATA, 'h00E, "RO");
reg_map.add_reg(MIISTATUS,  'h00F, "RO");

reg_map.add_reg(MAC_ADDR0,  'h010, "RW");
reg_map.add_reg(MAC_ADDR1,  'h011, "RW");
reg_map.add_reg(HASH0,      'h012, "RW");
reg_map.add_reg(HASH1,      'h013, "RW");

reg_map.add_reg(TXCTRL,     'h014, "RW");
 // -----------------------------------------------------
 // BD RAM  
// offset = 0x400 ? BD RAM starts here in WISHBONE address space
// Location 0 ? WISHBONE addr 0x400 (first TX BD status word)
// Location 1 ? WISHBONE addr 0x404 (first TX BD pointer word)
// Location 255 ? WISHBONE addr 0x7FC (last BD pointer word)
// ---------------------------------------------------------------------

eth_bd_mem = new(
    "eth_bd_mem",
    256,
    32,
    "RW",
    UVM_NO_COVERAGE
);

eth_bd_mem.configure(this);

reg_map.add_mem(eth_bd_mem, 'h100, "RW");


  //------------------------------------------------------
  // HDL Backdoor
  //------------------------------------------------------
add_hdl_path("eth_tb.dut");

MODER.add_hdl_path_slice("ethreg1.MODER_0.DataOut", 0, 8);
MODER.add_hdl_path_slice("ethreg1.MODER_1.DataOut", 8, 8);
MODER.add_hdl_path_slice("ethreg1.MODER_2.DataOut",16, 8);


INT_MASK.add_hdl_path_slice("ethreg1.INT_MASK_0.DataOut",0,8);
INT_SOURCE.add_hdl_path_slice("ethreg1.INT_SOURCEOut",0,8);

IPGT.add_hdl_path_slice("ethreg1.IPGT_0.DataOut",0,8);

IPGR1.add_hdl_path_slice("ethreg1.IPGR1_0.DataOut",0,8);

IPGR2.add_hdl_path_slice("ethreg1.IPGR2_0.DataOut",0,8);

PACKETLEN.add_hdl_path_slice("ethreg1.PACKETLEN_0.DataOut", 0, 8);
PACKETLEN.add_hdl_path_slice("ethreg1.PACKETLEN_1.DataOut", 8, 8);
PACKETLEN.add_hdl_path_slice("ethreg1.PACKETLEN_2.DataOut",16, 8);
PACKETLEN.add_hdl_path_slice("ethreg1.PACKETLEN_3.DataOut",24, 8);

COLLCONF.add_hdl_path_slice("ethreg1.COLLCONF_0.DataOut",0,8);
COLLCONF.add_hdl_path_slice("ethreg1.COLLCONF_2.DataOut",16,8);

TX_BD_NUM.add_hdl_path_slice("ethreg1.TX_BD_NUM_0.DataOut",0,8);

CTRLMODER.add_hdl_path_slice("ethreg1.CTRLMODER_0.DataOut",0,8);

MIIMODER.add_hdl_path_slice("ethreg1.MIIMODER_0.DataOut",0,8);
// MIIMODER.add_hdl_path_slice("ethreg1.MIIMODER_1.DataOut",8,8);
MIIMODER.add_hdl_path_slice("ethreg1.MIIMODER_1.DataOut", 8, 1);

MIICOMMAND.add_hdl_path_slice("ethreg1.MIICOMMAND0.DataOut",0,1);
MIICOMMAND.add_hdl_path_slice("ethreg1.MIICOMMAND1.DataOut",1,1);
MIICOMMAND.add_hdl_path_slice("ethreg1.MIICOMMAND2.DataOut",2,1);

MIIADDRESS.add_hdl_path_slice("ethreg1.MIIADDRESS_0.DataOut",0,8);
MIIADDRESS.add_hdl_path_slice("ethreg1.MIIADDRESS_1.DataOut",8,8);

MIITX_DATA.add_hdl_path_slice("ethreg1.MIITX_DATA_0.DataOut",0,8);
MIITX_DATA.add_hdl_path_slice("ethreg1.MIITX_DATA_1.DataOut",8,8);

MIIRX_DATA.add_hdl_path_slice("ethreg1.MIIRX_DATA.DataOut",0,16);

MIISTATUS.add_hdl_path_slice("ethreg1.MIISTATUSOut", 0, 3);

MAC_ADDR0.add_hdl_path_slice("ethreg1.MAC_ADDR0_0.DataOut", 0,8);
MAC_ADDR0.add_hdl_path_slice("ethreg1.MAC_ADDR0_1.DataOut", 8,8);
MAC_ADDR0.add_hdl_path_slice("ethreg1.MAC_ADDR0_2.DataOut",16,8);
MAC_ADDR0.add_hdl_path_slice("ethreg1.MAC_ADDR0_3.DataOut",24,8);

MAC_ADDR1.add_hdl_path_slice("ethreg1.MAC_ADDR1_0.DataOut",0,8);
MAC_ADDR1.add_hdl_path_slice("ethreg1.MAC_ADDR1_1.DataOut",8,8);

HASH0.add_hdl_path_slice("ethreg1.RXHASH0_0.DataOut", 0,8);
HASH0.add_hdl_path_slice("ethreg1.RXHASH0_1.DataOut", 8,8);
HASH0.add_hdl_path_slice("ethreg1.RXHASH0_2.DataOut",16,8);
HASH0.add_hdl_path_slice("ethreg1.RXHASH0_3.DataOut",24,8);

HASH1.add_hdl_path_slice("ethreg1.RXHASH1_0.DataOut", 0,8);
HASH1.add_hdl_path_slice("ethreg1.RXHASH1_1.DataOut", 8,8);
HASH1.add_hdl_path_slice("ethreg1.RXHASH1_2.DataOut",16,8);
HASH1.add_hdl_path_slice("ethreg1.RXHASH1_3.DataOut",24,8);

TXCTRL.add_hdl_path_slice("ethreg1.TXCTRL_0.DataOut", 0,8);
TXCTRL.add_hdl_path_slice("ethreg1.TXCTRL_1.DataOut", 8,8);
TXCTRL.add_hdl_path_slice("ethreg1.TXCTRL_2.DataOut",16,8);



eth_bd_mem.add_hdl_path_slice(
    "wishbone.bd_ram.mem0",0,8);

eth_bd_mem.add_hdl_path_slice(
    "wishbone.bd_ram.mem1",8,8);

eth_bd_mem.add_hdl_path_slice(
    "wishbone.bd_ram.mem2",16,8);

eth_bd_mem.add_hdl_path_slice(
    "wishbone.bd_ram.mem3",24,8);


  endfunction


  // =========================================================
  // Convenience functions 
  // =========================================================

  function logic [47:0] get_mac_address();
    logic [47:0] mac;
    mac[47:40] = MAC_ADDR1.BYTE0.get();
    mac[39:32] = MAC_ADDR1.BYTE1.get();
    mac[31:24] = MAC_ADDR0.BYTE2.get();
    mac[23:16] = MAC_ADDR0.BYTE3.get();
    mac[15:8]  = MAC_ADDR0.BYTE4.get();
    mac[7:0]   = MAC_ADDR0.BYTE5.get();
    return mac;
  endfunction

  function void set_mac_address_mirror(logic [47:0] mac);
    MAC_ADDR1.BYTE0.set(mac[47:40]);
    MAC_ADDR1.BYTE1.set(mac[39:32]);
    MAC_ADDR0.BYTE2.set(mac[31:24]);
    MAC_ADDR0.BYTE3.set(mac[23:16]);
    MAC_ADDR0.BYTE4.set(mac[15:8]);
    MAC_ADDR0.BYTE5.set(mac[7:0]);
  endfunction

  
function void get_bd_split(output int n_tx_bd, output int n_rx_bd);
    n_tx_bd = TX_BD_NUM.TX_BD_NUM.get();
    n_rx_bd = 128 - n_tx_bd;
  endfunction

  function logic [31:0] get_tx_bd_addr(int bd_index);
    return 32'h400 + (bd_index * 8);
  endfunction

  function logic [31:0] get_rx_bd_addr(int bd_index);
    int tx_count;
    tx_count = TX_BD_NUM.TX_BD_NUM.get();
    return 32'h400 + ((tx_count + bd_index) * 8);
  endfunction

// -------------------------------------------------------------------------
// Check if MIIM module is busy (poll MIISTATUS.BUSY)
// Returns 1 if busy, 0 if ready
// -------------------------------------------------------------------------
  task is_miim_busy(output bit busy);
    uvm_status_e status;
    uvm_reg_data_t rdata;
    MIISTATUS.read(status, rdata);
    busy = rdata[1];
  endtask

// -------------------------------------------------------------------------
// Wait for MIIM operation to complete
// Polls MIISTATUS.BUSY until cleared
// -------------------------------------------------------------------------
  task wait_miim_done(int timeout_cycles = 100000);
    uvm_status_e status;
    uvm_reg_data_t rdata;
    int count = 0;
    do begin
      MIISTATUS.read(status, rdata);
      count++;
      if (count >= timeout_cycles)
        `uvm_fatal("MIIM_TIMEOUT", "MIIM busy timeout")
    end while (rdata[1]);
  endtask

// -------------------------------------------------------------------------
// Check if any interrupt is pending in INT_SOURCE
// Returns the raw INT_SOURCE value
// -------------------------------------------------------------------------
task read_int_source(output uvm_reg_data_t  int_src);
uvm_status_e status;
INT_SOURCE.read(status, int_src);
endtask
 
// -------------------------------------------------------------------------
// Clear specific interrupt bits by writing 1 to them (W1C)
// mask: bitmask of interrupts to clear (1=clear, 0=leave)
// -------------------------------------------------------------------------
task clear_interrupts(uvm_reg_data_t  mask);
uvm_status_e status;
INT_SOURCE.write(status, mask);
// W1C: writing 1 to a bit clears it
// writing 0 to a bit has no effect
endtask
 
// -------------------------------------------------------------------------
// Clear ALL pending interrupts
// -------------------------------------------------------------------------
task clear_all_interrupts();
clear_interrupts(32'h0000_007F); // all 7 interrupt bits
endtask
 
endclass : eth_reg_block

