//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_cov_tx.sv
// Author   : Wael,Nada
// Date     : 2026-07-12
//------------------------------------------------------------------------------
// Description:
//   Ethernet coverage model contains all covergroups related to TX.
//==============================================================================
`ifndef ETH_COV_TX_SV
`define ETH_COV_TX_SV

class eth_cov_tx extends uvm_component;
    `uvm_component_utils(eth_cov_tx)
    // =========================================================================
    // Register model
    // =========================================================================
    eth_reg_block m_regmodel;
    uvm_reg reg_h;
    uvm_reg regs[$];
    // =========================================================================
    // Analysis fifos for wishbone master ,wishbone master, MII TX
    // =========================================================================
    uvm_tlm_analysis_fifo  #(wb_m_seq_item_base)        wb_m_fifo;
    uvm_tlm_analysis_fifo  #(wb_s_seq_item_base)        wb_s_fifo;
    uvm_tlm_analysis_fifo  #(mii_tx_seq_item_base)      mii_tx_fifo;
    // =========================================================================
    // Analysis exports for wishbone master ,wishbone master, MII TX
    // =========================================================================
    uvm_analysis_export  #(wb_m_seq_item_base)        wb_m_a_export;
    uvm_analysis_export  #(wb_s_seq_item_base)        wb_s_a_export;
    uvm_analysis_export  #(mii_tx_seq_item_base)      mii_tx_a_export;
    // =========================================================================
    // Transactions for storing last item pulled from tlm fifo
    // =========================================================================
    wb_m_seq_item_base                              m_wb_m_seq_item;
    wb_s_seq_item_base                              m_wb_s_seq_item;
    mii_tx_seq_item_base                            m_mii_tx_seq_item;
    // =========================================================================
    // Wishbone slave fields
    // =========================================================================    
    logic [WB_S_ADDR_WIDTH-1:0] m_addr;    // ADDR_I
    logic [WB_DATA_WIDTH-1:0]  m_wdata;    // DATA_I
    logic [WB_DATA_WIDTH-1:0]  m_rdata;    // DATA_O
    logic                      m_inta;     // INTA_O
    bit   [8:0]                m_moder_tx; // only tx fields in moder reg
    bit   [15:0]               m_minfl;
    bit   [15:0]               m_maxfl;
    bit   [3:0]                m_retry_max;
    bit   [5:0]                m_coll_v;
    bit   [16:0]               m_txctrl;
    bit                        m_ctrl_moder;
    bit   [31:0]               m_mac_addr0;
    bit   [15:0]               m_mac_addr1;
    bit   [6:0]                m_int_mask;
    bit   [15:0]               m_bd_len;
    bit   [4:0]                m_bd_cfg;
    bit   [3:0]                m_retry_cnt;
    bit   [4:0]                m_bd_stat;
	// =========================================================================
    // Wishbone master fields
    // =========================================================================    
    logic [WB_M_ADDR_WIDTH-1:0] m_addr_o;                 // Memory address
    logic [WB_DATA_WIDTH-1:0] m_data_i;                 // data read by DUT (For TX)
		
	 // =========================================================================
    // mii_tx  fields
    // =========================================================================
 
    logic m_mcoll;                // Collision signal:  The PHY asynchronously asserts it 
    logic  m_mcrs;                 // Carrier Sense: The PHY asynchronously asserts it. MCrS=1 (busy medium)

    logic [3:0] m_txd ;               // Transmit Data Nibble
    logic m_txen;                    // Transmit Enable. indicates to the PHY that the data MTxD is valid and the transmission can start.
    logic m_txerr;                   // Transmit Error
    int unsigned m_current_bit_id;
    bit m_field_value;
    bit m_reserved_value;
    int unsigned m_current_reg_id;
    int unsigned m_current_field_id;    
    
    // =========================================================================
    // Constructor, Build Phase, Connect phase and Run phase
    // =========================================================================
    extern function new(string name, uvm_component parent);
    extern function void build_phase(uvm_phase phase);
    extern function void connect_phase(uvm_phase phase);
    extern task run_phase(uvm_phase phase);
    
    extern task sample_wb_s_item();
	extern task sample_wb_m_item();
	extern task sample_mii_tx_item();
	extern function void sample_rw_reserved_cov(uvm_reg reg_h,logic [31:0] r_data);


    // =============================================================================
    //  Write Configurations cover group
    // =============================================================================
    covergroup m_wr_cfg_cov;
        // Addresses
        cp_addr: coverpoint m_addr{
            bins tx_reg0 = {'h00};
            bins tx_reg1 []= {[10'h02:10'h08]} ;
            bins tx_reg2 []= {['h10:'h11]}; 
            bins tx_reg3   = {'h14};
            bins tx_bd   [] = {[WB_BD_MEM_BASE_ADDR:WB_BD_MEM_OFFSET_ADDR]};
            illegal_bins ill_addr = {[ETH_REG_OFFSET_ADDR+1:WB_BD_MEM_BASE_ADDR-1],[WB_BD_MEM_OFFSET_ADDR+1:'h3FF]};
            bins others = default;
        }
        
        // MODER register (Address 0x00)
        cp_moder: coverpoint m_moder_tx{

        // All configurations
        bins reg_config [] = {['b1_0000_0000:'b1_1111_1111]};
        // padding
        wildcard bins reg_pad [2] = {'b1_1???_????,'b1_0???_????};
        // Normal CRC
        wildcard bins reg_crc [2] = {'b1_??00_????,'b1_??10_????};
        // Delayd CRC
        wildcard bins reg_d_crc [2] = {'b1_??10_????,'b1_??11_????};
        // Hugen
        wildcard bins reg_hugen [2] = {'b1_?0??_????,'b1_?1??_????};
        
        // ignore other values
        bins others = default;
        }
        // INT_MASK coverpoint (Address 0x08)
        cp_int_mask: coverpoint m_int_mask{
            // None is masked
            bins no_mask = {'h0000_0000};
            // TXB mask;
            bins txb_m = {'h0000_0001};
            // TXE mask;
            bins txe_m = {'h0000_0002};
            // TXC mask;
            bins txc_m = {'h0000_0020};
            // TXB & TXE mask;
            bins txbc_m = {'h0000_0003};
            // TXE & TXC mask;
            bins txec_m = {'h0000_0022};
            // TXC & TXB mask;
            bins txcb_m = {'h0000_0021};
            // 3 Masked
            bins tx_all_int_m = {'h0000_0023};
            // ignore other values
            bins others = default;
        }

    // IPGT Register (Address 0x0C)
    cp_ipgt: coverpoint m_wdata iff(m_addr=='h03) {
        bins ipgt_mid = {'h0000_0020};    // Mid value = 64
        bins ipgt_min = {'h0000_0000};    // Minimum = 0 
        bins ipgt_max = {'h0000_007F};    // Maximum = 7'b111_1111

        // ignore other values
        bins others = default;
    }
 

    // IPGR1 Register (Address 0x10)
    cp_ipgr1: coverpoint m_wdata iff(m_addr=='h04) {
        bins ipgr1_mid = {'h0000_0020};    // Mid value = 64
        bins ipgr1_min = {'h0000_0000};    // Minimum = 0 
        bins ipgr1_max = {'h0000_007F};    // Maximum = 7'b111_1111

        // ignore other values
        bins others = default;
    }
 

    // IPGR2 Register (Address 0x14)
    cp_ipgr2: coverpoint m_wdata iff(m_addr=='h05) {
        bins ipgr2_mid = {'h0000_0020};    // Mid value = 64
        bins ipgr2_min = {'h0000_0000};    // Minimum = 0 
        bins ipgr2_max = {'h0000_007F};    // Maximum = 7'b111_1111
        
        // ignore other values
        bins others = default;
    }
 

    // Maximum frame length in PACKETLEN Register (Address 0x18)
    cp_maxfl: coverpoint m_maxfl {

        
        // MAXFL variations
        bins maxfl_4 = {['h0001:'h0004]};                // Less than 4 bytes
        bins maxfl_less_64 = {['h0005:'h003F]};              // More 4 and less or equal than minimum in standard (64 bytes)
        bins maxfl_more_64  = {['h00040:'hFFFE]};      // More 64 and less than or equal maximum
        bins maxfl_std = {'h05EE};                        // Ethernet standard 1518 bytes 
        bins maxfl_max = {'hFFFF};                        // Maximum MAXFL value
        
        // ignore other values
        bins others = default; 
    }

    // Minimum frame length in PACKETLEN Register (Address 0x18)
    cp_minfl: coverpoint m_minfl {
        
        // MINFL variations
       // bins minfl_4  [] = {['h0000:'h0004]};        // Less than 4 bytes
        bins minfl_less_64  = {['h0005:'h003F]};       // More 4 and less than  minimum in standard (64 bytes)
        bins minfl_std      = {'h0040};                // Standard (64 bytes)
        bins minfl_more_64  = {['h00041:'hFFFE]};      // More 64 and less than or equal maximum
        bins minfl_max      = {'hFFFF};                // MAximum MINFL value

        // ignore other values
        bins others = default;
    }
 

    // Maximum Retry COLLCONFIG Register (Address 0x1C)
    cp_retry: coverpoint m_retry_max iff(m_addr=='h07) {
        bins max_retry [] =  {['h0:'hF]};  // All retry values
    }

    // Collision valid COLLCONFIG Register (Address 0x1C)
    cp_collconfig: coverpoint m_wdata iff(m_addr=='h07) {
        bins collvalid_min = {'b11_1111};              // Minimum collision window = 0 byte 
        bins collvalid_any [8]= {['b00_0001:'b11_1110]};   // Any collision window between 0 and 63
        bins collvalid_max = {'b11_1111};              // maximum collision window = 63
        
        // ignore other values
        bins others = default;
    }
 

    // TX_BD_NUM Register (Address 0x40)
    cp_tx_bd_num: coverpoint m_wdata iff(m_addr=='h08) {
        
    bins bd_num_min = {0};

    bins bd0  = {[1:8]};
    bins bd1  = {[9:16]};
    bins bd2  = {[17:24]};
    bins bd3  = {[25:32]};
    bins bd4  = {[33:40]};
    bins bd5  = {[41:48]};
    bins bd6  = {[49:56]};
    bins bd7  = {[57:64]};
    bins bd8  = {[65:72]}; 
    bins bd9  = {[73:80]}; 
    bins bd10 = {[81:88]}; 
    bins bd11 = {[89:96]}; 
    bins bd12 = {[97:104]};
    bins bd13 = {[105:112]}; 
    bins bd14 = {[113:120]}; 
    bins bd15 = {[121:127]}; 

    bins bd_num_max = {128};

        // illegal values
        wildcard illegal_bins ill_bd_num = {['h????_??81:'h????_??FF]};
        
        // ignore other values
        bins others = default;       
    }
 

    // CTRLMODER Register (Address 0x44)
    cp_ctrlmoder: coverpoint m_ctrl_moder {
        // TXFLOW bit 
        bins tx_flow [2] = {0,1};
        
    }
 
 

    // MAC_ADDR0 Register (Address 0x40)
    cp_mac_addr0: coverpoint m_mac_addr0 {
        
        // 64 bins for address range
        bins mac_addr0_all [32] = {['h0000_0000:'hFFFF_FFFF]};     
        
        // ignore other values
        bins others = default;
    }

    // MAC_ADDR1 Register (Address 0x44)
    cp_mac_addr1: coverpoint m_mac_addr1 {
        // 8 bins for address range
        bins mac_addr1_all [8] = {['h0000_0000:'h0000_FFFF]};     
        
        // ignore other values
        bins others = default;
    }
 
    // TXCTRL Register (Address 0x50)
    cp_txctrl: coverpoint m_txctrl {
        // pause request bit (1 & 0)
        wildcard bins tx_pause_req [2] = {'h0000_????,'h0001_????}; 
        // minimum timer value = 0
        bins time_val_min = {'h0001_0000}; 
        // maximum timer value = FFFF
        bins time_val_max = {'h0001_FFFF};      
        // any timer value betwee 0 and FFFF
        bins time_val_any [64]= {['h0001_0001:'h0001_FFFE]};  
        // ignore other values
        bins others = default;
    }

    cp_bd_len: coverpoint m_bd_len {
        // ALl legal lengths
        bins len_all [64] = {['h0005:'hFFFE]};
        // All illegal lengths 
        bins len_4   [5] = {['h0000:'h0004]};
        // Maximum value 
        bins len_max   = {'hFFFF};
    }

    cp_bd_cfg: coverpoint m_bd_cfg {

        // All configurations
        bins bd_config [] = {['b1_0000:'b1_1111]};
        // padding
        wildcard bins bd_pad [2] = {5'b?_??0?,5'b?_??1?};
        // CRC
        wildcard bins bd_crc [2] = {5'b?_???0,5'b?_???1};

        // ignore other values
        bins others = default;
    }


    // TXPNT buffer descriptor Any odd address in buffer descriptor memory range
    cp_txpnt: coverpoint m_wdata iff(m_addr>=WB_BD_MEM_BASE_ADDR && m_addr<=WB_BD_MEM_OFFSET_ADDR && m_addr%2==1) {
        // 64 bins for address range
        bins txpnt_all [64] = {['h0000_0000:'hFFFF_FFFF]};   
        
        // ilegal values : not divisible by 4
        wildcard illegal_bins txpnt_not_div4_mod1 = {32'h????_??01};
        wildcard illegal_bins txpnt_not_div4_mod2 = {32'h????_??02};
        wildcard illegal_bins txpnt_not_div4_mod3 = {32'h????_??03};
    }
    // =============================================================================
    // Cross cover points
    // =============================================================================
    
    // Cross padding between register and bd
    cp_cross_pad: cross cp_moder,cp_bd_cfg{
        ignore_bins ign_pad = binsof(cp_bd_cfg.bd_crc) || binsof(cp_bd_cfg.bd_config) || binsof(cp_moder.reg_crc)
        || binsof(cp_moder.reg_d_crc) || binsof(cp_moder.reg_hugen) || binsof(cp_moder.reg_config);
    }

    // Cross CRC between register and bd
    cp_cross_crc: cross cp_moder,cp_bd_cfg{
        ignore_bins ign_crc = binsof(cp_bd_cfg.bd_pad) || binsof(cp_bd_cfg.bd_config) || binsof(cp_moder.reg_pad)
        || binsof(cp_moder.reg_d_crc) || binsof(cp_moder.reg_hugen) || binsof(cp_moder.reg_config);
    }

    // Cross delayed CRC between register and bd
    cp_cross_d_crc: cross cp_moder,cp_bd_cfg{
        ignore_bins ign_d_crc = binsof(cp_bd_cfg.bd_pad) || binsof(cp_bd_cfg.bd_config) || binsof(cp_moder.reg_pad)
        || binsof(cp_moder.reg_crc) || binsof(cp_moder.reg_hugen) || binsof(cp_moder.reg_config);
    }

    // Cross maxfl and hugen
    cp_cross_maxfl_hugen: cross cp_moder,cp_maxfl{
        ignore_bins ign_max_hugen = binsof(cp_moder.reg_d_crc)  || binsof(cp_moder.reg_crc) || binsof(cp_moder.reg_pad)
        || binsof(cp_moder.reg_config) ;
    }

    // Cross minfl, reg pad and bd pad
    cp_cross_minfl_pad: cross cp_moder,cp_minfl,cp_bd_cfg{
        ignore_bins ign_min_f_pad = binsof(cp_moder.reg_d_crc)  || binsof(cp_moder.reg_crc) || binsof(cp_moder.reg_hugen)
        || binsof(cp_moder.reg_config) || binsof(cp_bd_cfg.bd_crc) || binsof(cp_bd_cfg.bd_config);
        ignore_bins ign_minfl_max = binsof (cp_minfl.minfl_max);
    }
    cp_minfl_g_maxfl: coverpoint (m_minfl > m_maxfl && m_maxfl!=0) {
    bins minfl_g_maxfl = {1};
    }
    cp_minfl_s_maxfl: coverpoint (m_minfl < m_maxfl && m_minfl!=0 ) {
    bins minfl_s_maxfl = {1};
    }
    cp_minfl_eq_maxfl: coverpoint (m_minfl == m_maxfl && m_minfl!=0 ) {
    bins minfl_eq_maxfl = {1};
    }
    /*    // Cross minfl < maxfl 
    cp_cross_minfl_s_maxfl: cross cp_minfl,cp_maxfl{
        ignore_bins ignore_gre_eq = cp_cross_minfl_s_maxfl with (cp_minfl >= cp_maxfl);
    }
    // Cross minfl > maxfl 
    cp_cross_minfl_g_maxfl: cross cp_minfl,cp_maxfl{
        ignore_bins ignore_gre_eq = cp_cross_minfl_g_maxfl with (cp_minfl <= cp_maxfl);
    }
*/
    // Cross txpause req and txflow
    cp_cross_ctrl: cross cp_ctrlmoder,cp_txctrl{
        ignore_bins ign_ctrl = binsof(cp_txctrl.time_val_any) || binsof(cp_txctrl.time_val_max) || binsof(cp_txctrl.time_val_min);
    }

    endgroup

    // =============================================================================
    //  Read Configurations cover group
    // =============================================================================
    covergroup m_rd_cfg_cov;
        
        // Addresses
        cp_addr: coverpoint m_addr{
            bins tx_int = {'h01};
            bins tx_bd   [] = {[WB_BD_MEM_BASE_ADDR:WB_BD_MEM_OFFSET_ADDR]};
            illegal_bins ill_addr = {[ETH_REG_OFFSET_ADDR+1:WB_BD_MEM_BASE_ADDR-1],[WB_BD_MEM_OFFSET_ADDR+1:'h3FF]};
            bins others = default;
        }

        // INT_SOURCE Register (Address 0x04)
        cp_int_source: coverpoint m_rdata iff(m_addr=='h01) {
            // None is fired
            bins no_int = {'h0000_0000};
            // TXB
            wildcard bins txb   = {'b_00000000_00000000_00000000_0???_???1};
            // TXE
            wildcard bins txe = {'b_00000000_00000000_00000000_0???_??1?};
            // TXC 
            wildcard bins txc = {'b_00000000_00000000_00000000_0?1?_????};

            // ignore other values
            bins others = default;
        }

        cp_inta: coverpoint m_inta{
            bins inta_1={1};
            bins inta_0={0};
        } 
        
        cp_bd_stat: coverpoint m_bd_stat iff(m_addr>=WB_BD_MEM_BASE_ADDR && m_addr<=WB_BD_MEM_OFFSET_ADDR && m_addr%2==0) {
            // underrun
            wildcard bins ur_0= {'b0_????};
            wildcard bins ur_1= {'b1_????};
            // maximum
         //   wildcard bins rl  = {'b?_1???};
            // late collision
          //  wildcard bins lc  = {'b?_?1??};
            // deferral
          //  wildcard bins df  = {'b?_??1?};
        }

        /*
        cp_bd_retry: coverpoint m_retry_cnt iff(m_addr>=WB_BD_MEM_BASE_ADDR && m_addr<=WB_BD_MEM_OFFSET_ADDR  && m_addr%2==0) {
            // minimum
            bins retry_min = {'b0000};
            // maximum
            bins retry_max = {'b1111};
            // other values
            bins retry_all [] = {['b0001:'b1110]};
        }*/
        // =============================================================================
        //  Cross cover points
        // =============================================================================
        cross_inta_int_source: cross cp_int_source,cp_inta{
            ignore_bins ign_cross_no_int = binsof(cp_int_source.no_int); 
            ignore_bins ign_cross_inta_txb = binsof(cp_int_source.txb) && binsof(cp_inta.inta_0);
            ignore_bins ign_cross_inta_txc = binsof(cp_int_source.txc) && binsof(cp_inta.inta_0);
            ignore_bins ign_cross_inta_txe = binsof(cp_int_source.txe) && binsof(cp_inta.inta_0);
        }
        /*
        cross_retry_stat_cp: cross cp_bd_retry,cp_bd_stat{
        illegal_bins retry_rl = binsof(cp_bd_retry.retry_max) && binsof(cp_bd_stat.ur);
        //illegal_bins retry_rl = binsof(cp_bd_retry.retry_max) && binsof(cp_bd_stat.ur);
        }*/

    endgroup
    // =============================================================================
    // Wishbone Master Memory Address Coverage
    // =============================================================================

    covergroup m_wb_m_cov;

        // -------------------------------------------------------------------------
        // Memory address accessed by DUT
        // -------------------------------------------------------------------------
        cp_mem_addr: coverpoint m_addr_o {

            // Minimum possible address
            bins addr_min = {32'h0000_0000};


            // Maximum possible word address
            bins addr_max = {32'hFFFF_FFFC};


            // Divide address space into 64 regions
            bins addr_range[64] = {
                [32'h0000_0000 : 32'hFFFF_FFFC]
            };


            // Word aligned addresses
            bins aligned = {2'b00};


            // Non-word aligned addresses
            bins non_aligned[] = {2'b01,2'b10,2'b11};

        }


        // -------------------------------------------------------------------------
        // Memory read data
        // -------------------------------------------------------------------------
    cp_mem_data: coverpoint m_data_i {

        bins data_min = {32'h0000_0000};
        bins data_max = {32'hFFFF_FFFF};

        bins data_all[64] = {
            [32'h0000_0000 : 32'hFFFF_FFFF]
        };

    }
        // -------------------------------------------------------------------------
        // Address alignment vs data
        // -------------------------------------------------------------------------
        cross_addr_data:
            cross cp_mem_addr, cp_mem_data;
    endgroup  

    // =============================================================================
    // MII TX Coverage
    // =============================================================================
    covergroup m_mii_cov_tx;
        // -------------------------------------------------------------------------
        // TX Enable Coverage
        // -------------------------------------------------------------------------
        cp_tx_enable: coverpoint m_txen {

            bins tx_active = {1};
            bins tx_idle   = {0};

        }
        // -------------------------------------------------------------------------
        // TX Data Nibble Coverage
        // Only meaningful when TX is active
        // -------------------------------------------------------------------------
        cp_tx_data: coverpoint m_txd
            iff(m_txen) {


            // Minimum value
            bins data_min = {4'h0};


            // Maximum value
            bins data_max = {4'hF};


            // All possible nibbles
            bins data_all[16] = {
                [4'h0:4'hF]
            };

        }



        // -------------------------------------------------------------------------
        // TX Coding Error Coverage
        // -------------------------------------------------------------------------
        cp_tx_error: coverpoint m_txerr {

            bins no_error = {0};

            bins error = {1};

        }



        // -------------------------------------------------------------------------
        // Collision Coverage
        // -------------------------------------------------------------------------
        cp_collision: coverpoint m_mcoll {

            bins no_collision = {0};

            bins collision = {1};

        }



        // -------------------------------------------------------------------------
        // Carrier Sense Coverage
        // -------------------------------------------------------------------------
        cp_carrier: coverpoint m_mcrs {

            bins idle_medium = {0};

            bins busy_medium = {1};

        }



        // -------------------------------------------------------------------------
        // Cross Coverage
        // -------------------------------------------------------------------------


        // Check errors during active transmission
        cross_tx_error:
            cross cp_tx_enable, cp_tx_error;


        // Collision while transmitting
        cross_tx_collision:
            cross cp_tx_enable, cp_collision;


        // Carrier sense versus transmission
        cross_tx_carrier:
            cross cp_tx_enable, cp_carrier;


        // Data values during transmission
        cross_tx_data_enable:
            cross cp_tx_enable, cp_tx_data;


    endgroup 

    // =============================================================================
    //  Register bit read coverage
    // =============================================================================

    covergroup m_rw_bit_cov;

    cp_reg : coverpoint m_current_reg_id {

        bins regs[21] = {[0:20]};

        ignore_bins ro_regs = {14,15};

    }


        // Every bit in register
        cp_bit : coverpoint m_current_bit_id {

            bins bits[32] = {[0:31]};

        }


        // Bit value
        cp_value : coverpoint m_field_value {

            bins zero = {0};
            bins one  = {1};

        }


        cross_reg_bit :
            cross cp_reg, cp_bit;


        cross_bit_value :
            cross cp_bit, cp_value;


    endgroup

    covergroup m_reserved_bit_cov; 
    cp_reg : coverpoint m_current_reg_id { 
    bins regs[21] = {[0:20]}; 
    ignore_bins no_reserved_fields = {6,16,18,19};
    } 
    cp_reserved : coverpoint m_reserved_value { 
    bins reserved_zero = {0};
    illegal_bins reserved_one = {1}; 
    } 
    cross cp_reg, cp_reserved; 
    endgroup  
endclass


// =============================================================================
//  IMPLEMENTATION
// =============================================================================

function eth_cov_tx::new(string name, uvm_component parent);
    super.new(name, parent);
    m_wr_cfg_cov=new();
    m_rd_cfg_cov=new();
    m_mii_cov_tx=new();
    m_wb_m_cov=new();
    m_rw_bit_cov     = new();
    m_reserved_bit_cov = new();
endfunction


function void eth_cov_tx::build_phase(uvm_phase phase);
    super.build_phase(phase);
    // Build fifos
    wb_m_fifo     = new("wb_m_fifo",this);
    wb_s_fifo     = new("wb_s_fifo",this);
    mii_tx_fifo   = new("mii_tx_fifo",this);
    // Build analysis exports
    wb_m_a_export   = new("wb_m_export",this);
    wb_s_a_export   = new("wb_s_export",this);
    mii_tx_a_export = new("mii_tx_export",this);
endfunction

function void eth_cov_tx::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    // Connect each export with it's corrosponding fifo
    wb_m_a_export.connect(wb_m_fifo.analysis_export);
    wb_s_a_export.connect(wb_s_fifo.analysis_export);
    mii_tx_a_export.connect(mii_tx_fifo.analysis_export);
endfunction 

task eth_cov_tx::run_phase(uvm_phase phase);
    super.run_phase(phase);

    fork:fork_cov_tx
        forever
        sample_mii_tx_item();
        forever
        sample_wb_m_item();
        forever
        sample_wb_s_item();
    join;
   
endtask

task eth_cov_tx::sample_wb_s_item();
    // Get transaction from fifo
    wb_s_fifo.get(m_wb_s_seq_item);

    // Copy transaction field values to local
    m_addr  = m_wb_s_seq_item.m_addr;
    m_wdata = m_wb_s_seq_item.m_wdata;
    m_rdata = m_wb_s_seq_item.m_rdata;
    m_inta  = m_wb_s_seq_item.m_inta;
    if(m_addr=='h00)
        m_moder_tx = {m_wdata[1],m_wdata[15],m_wdata[14],m_wdata[13],m_wdata[12],m_wdata[10],m_wdata[9],m_wdata[8],m_wdata[2]};
    if(m_addr=='h02)
        m_int_mask=m_wdata[6:0];
    if(m_addr=='h06)
    begin
        m_minfl = m_wdata[31:16];
        m_maxfl = m_wdata[15:0];
    end    
    if(m_addr=='h09) begin
        m_ctrl_moder=m_wdata[2];
    end    
    if(m_addr=='h10) begin
        m_mac_addr0=m_wdata[31:0];
    end 
    if(m_addr=='h11) begin
        m_mac_addr1=m_wdata[15:0];
    end    
    if(m_addr=='h14) begin
        m_txctrl=m_wdata[16:0];
    end
    if(m_addr>=WB_BD_MEM_BASE_ADDR && m_addr<=WB_BD_MEM_OFFSET_ADDR && m_addr%2==0) begin
    m_bd_len = m_wdata[31:16];
    m_bd_cfg = m_wdata[15:11];
    end
    m_retry_max = m_wdata[19:16];
    m_coll_v = m_wdata[5:0];

    m_retry_cnt = m_rdata[7:4];
    m_bd_stat ={m_rdata[8],m_rdata[3:0]};


    // if select isn't valid return 
    if(!(&m_wb_s_seq_item.m_sel))
        return;
    
    // if write transaction cover config_group
    if(m_wb_s_seq_item.m_dir==WB_WRITE) begin
        m_wr_cfg_cov.sample();
        `uvm_info(get_full_name(), m_wb_s_seq_item.convert2string(), UVM_HIGH)
        if(m_addr=='h00) begin
            m_moder_tx=0;
            m_int_mask=0;
            m_bd_cfg=0;
            m_bd_len=0;
            m_minfl=0;
            m_maxfl=0;
            m_mac_addr0=0;
            m_mac_addr1=0;
            m_retry_max=0;
            m_coll_v=0;
            m_txctrl=0;
            m_ctrl_moder=0;
        end
    end
    
    // if read transaction voer status_group
    else if(m_wb_s_seq_item.m_dir==WB_READ) begin
        `uvm_info(get_full_name(), m_wb_s_seq_item.convert2string(), UVM_HIGH)
        m_rd_cfg_cov.sample();

        reg_h = null;

        m_regmodel.get_registers(regs);

        foreach(regs[r]) begin
            
            if (regs[r].get_offset() == m_addr) begin
                reg_h = regs[r];
                m_current_reg_id = regs[r].get_offset();
                
                break;
            end
        end

            if (reg_h != null)
                sample_rw_reserved_cov(reg_h, m_rdata);

            end
endtask

task eth_cov_tx::sample_wb_m_item();

    // Get transaction from fifo
    wb_m_fifo.get(m_wb_m_seq_item);

    //--------------------------------------
    // Copy transaction fields
    //--------------------------------------
    m_addr_o   = m_wb_m_seq_item.m_addr_o;
    m_data_i  = m_wb_m_seq_item.m_data_i;


	 // if select isn't valid return 
    if(!(&m_wb_m_seq_item.m_sel_o))
        return;

    
    // if read transaction voer status_group
    else if(m_wb_m_seq_item.m_dir==WB_READ)
        m_wb_m_cov.sample();
    

endtask

task eth_cov_tx::sample_mii_tx_item();

    // Get transaction from FIFO
    mii_tx_fifo.get(m_mii_tx_seq_item);

    //--------------------------------------
    // Copy transaction fields
    //--------------------------------------
    m_mcoll = m_mii_tx_seq_item.MColl;
    m_mcrs  = m_mii_tx_seq_item.MCrS;
    m_txd   = m_mii_tx_seq_item.MTxD;
    m_txen  = m_mii_tx_seq_item.MTxEN;
    m_txerr = m_mii_tx_seq_item.MTxERR;

    //--------------------------------------
    // Sample coverage
    //--------------------------------------
    m_mii_cov_tx.sample();

endtask

function void eth_cov_tx::sample_rw_reserved_cov
(
    uvm_reg reg_h,
    logic [31:0] r_data
);


    uvm_reg_field fields[$];

    logic [31:0] implemented_mask;
    logic [31:0] reserved_mask;

    implemented_mask = 32'b0;


    //-----------------------------------------
    // Get all modeled fields
    //-----------------------------------------

    reg_h.get_fields(fields);



    foreach(fields[i]) begin

        int lsb;
        int width;

        lsb   = fields[i].get_lsb_pos();
        width = fields[i].get_n_bits();



        //-------------------------------------
        // Build implemented bit mask
        //-------------------------------------

        implemented_mask |= 
            (((32'b1 << width)-1) << lsb);



        //-------------------------------------
        // Only RW fields
        //-------------------------------------

     if(fields[i].get_access() inside {"RW","W1C"}) begin

       for(int b=0; b<width; b++) begin

    m_current_bit_id = lsb+b;

    m_field_value = r_data[lsb+b];

    m_rw_bit_cov.sample();

      end
       end
    
 end       

    //-----------------------------------------
    // Reserved bits = bits not in fields
    //-----------------------------------------



    reserved_mask = ~implemented_mask;


    for(int b=0;b<32;b++) begin


        if(reserved_mask[b]) begin


            m_reserved_value = r_data[b];


            m_reserved_bit_cov.sample();



            if(r_data[b]) begin

                `uvm_error(
                    "RESERVED_BIT_WRITE",
                    $sformatf(
                    "%s reserved bit [%0d] written as 1. Data=0x%08h",
                    reg_h.get_name(),
                    b,
                    r_data)
                )

            end


        end

    end


endfunction

`endif // ETH_COV_TX_SV