//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_tx_cov.sv
// Author   : Wael,Nada
// Date     : 2026-07-12
//------------------------------------------------------------------------------
// Description:
//   Ethernet coverage model contains all covergroups related to TX.
//==============================================================================
`ifndef ETH_TX_COV_SV
`define ETH_TX_COV_SV

class eth_tx_cov extends uvm_component;
    `uvm_component_utils(eth_tx_cov)

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
    /*// =========================================================================
    // Virtual interfaces
    // =========================================================================
    virtual wb_s_if     wb_s_vif;
    virtual wb_m_if     wb_m_vif;
    virtual mii_tx_if   mii_tx_vif;*/
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
    bit   [15:0]               m_bd_len;
    bit   [4:0]                m_bd_cfg;
    logic   [3:0]                m_retry_cnt;
    logic   [4:0]                m_bd_stat;
    // =========================================================================
    // Constructor, Build Phase, Connect phase and Run phase
    // =========================================================================
    extern function new(string name, uvm_component parent);
    extern function void build_phase(uvm_phase phase);
    extern function void connect_phase(uvm_phase phase);
    extern task run_phase(uvm_phase phase);
    
    extern task sample_wb_s_item();

    // =============================================================================
    //  Write Configurations cover group
    // =============================================================================
    covergroup m_wr_cfg_cov;
        // MODER register (Address 0x00)
        cp_moder: coverpoint m_moder_tx iff(m_addr=='h00){

        // All configurations
        bins reg_config [] = {['b1_0000_0000:'b1_1111_1111]};
        
        // ignore other values
        bins others = default;
        }
        // INT_MASK coverpoint (Address 0x08)
        cp_int_mask: coverpoint m_wdata iff(m_addr=='h08){
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
    cp_ipgt: coverpoint m_wdata iff(m_addr=='h0C) {
        bins ipgt_mid = {'h0000_0020};    // Mid value = 64
        bins ipgt_min = {'h0000_0000};    // Minimum = 0 
        bins ipgt_max = {'h0000_007F};    // Maximum = 7'b111_1111

        // ignore other values
        bins others = default;
    }
 

    // IPGR1 Register (Address 0x10)
    cp_ipgr1: coverpoint m_wdata iff(m_addr=='h10) {
        bins ipgr1_mid = {'h0000_0020};    // Mid value = 64
        bins ipgr1_min = {'h0000_0000};    // Minimum = 0 
        bins ipgr1_max = {'h0000_007F};    // Maximum = 7'b111_1111

        // ignore other values
        bins others = default;
    }
 

    // IPGR2 Register (Address 0x14)
    cp_ipgr2: coverpoint m_wdata iff(m_addr=='h14) {
        bins ipgr2_mid = {'h0000_0020};    // Mid value = 64
        bins ipgr2_min = {'h0000_0000};    // Minimum = 0 
        bins ipgr2_max = {'h0000_007F};    // Maximum = 7'b111_1111
        
        // ignore other values
        bins others = default;
    }
 

    // Maximum frame length in PACKETLEN Register (Address 0x18)
    cp_maxfl: coverpoint m_maxfl iff(m_addr=='h18) {

        
        // MAXFL variations
        bins maxfl_4 []= {['h0000:'h0004]};                // Less than 4 bytes
        bins maxfl_64 []= {['h0005:'h003F]};              // More 4 and less than minimum in standard (64 bytes)
        bins maxfl_std = {'h05EE};                        // Ethernet standard 1518 bytes 
        bins maxfl_max = {'hFFFF};                        // Maximum MAXFL value
        
        // ignore other values
        bins others = default; 
    }

    // Minimum frame length in PACKETLEN Register (Address 0x18)
    cp_minfl: coverpoint m_minfl iff(m_addr=='h18) {
        
        // MINFL variations
        wildcard bins minfl_4  [] = {['h0000:'h0004]};        // Less than 4 bytes
        wildcard bins minfl_64 [] = {['h0005:'h003F]};       // More 4 and less than minimum in standard (64 bytes)
        wildcard bins minfl_max = {'hFFFF};                  // MAximum MINFL value

        // ignore other values
        bins others = default;
    }
 

    // Maximum Retry COLLCONFIG Register (Address 0x1C)
    cp_retry: coverpoint m_retry_max iff(m_addr=='h1C) {
        bins max_retry [] =  {['h0:'hF]};  // All retry values
    }

    // Collision valid COLLCONFIG Register (Address 0x1C)
    cp_collconfig: coverpoint m_wdata iff(m_addr=='h1C) {
        wildcard bins collvalid_min = {'b11_1111};              // Minimum collision window = 0 byte 
        wildcard bins collvalid_any [8]= {['b00_0001:'b11_1110]};   // Any collision window between 0 and 63
        wildcard bins collvalid_max = {'b11_1111};              // maximum collision window = 63
        
        // ignore other values
        bins others = default;
    }
 

    // TX_BD_NUM Register (Address 0x40)
    cp_tx_bd_num: coverpoint m_wdata iff(m_addr=='h20) {
        
        ignore_bins upper_bits = {['h0000_0100:'hFFFF_FFFF]};
    }
 

    // CTRLMODER Register (Address 0x44)
    cp_ctrlmoder: coverpoint m_wdata iff(m_addr=='h24) {
        // TXFLOW bit 
        bins tx_flow [] = {'h0000_0000,'h0000_0004};
        
        // ignore other values
        bins others = default;
        
    }
 
 

    // MAC_ADDR0 Register (Address 0x40)
    cp_mac_addr0: coverpoint m_wdata iff(m_addr=='h40) {
        
        // 64 bins for address range
        bins mac_addr0_all [64] = {['h0000_0000:'hFFFF_FFFF]};     
        
        // ignore other values
        bins others = default;
    }

    // MAC_ADDR1 Register (Address 0x44)
    cp_mac_addr1: coverpoint m_wdata iff(m_addr=='h44) {
        // 8 bins for address range
        bins mac_addr1_all [8] = {['h0000_0000:'h0000_FFFF]};     
        
        // ignore other values
        bins others = default;
    }
 
    // TXCTRL Register (Address 0x50)
    cp_txctrl: coverpoint m_wdata iff(m_addr=='h50) {
        // pause request bit (1 & 0)
        wildcard bins tx_pause_req_0 = {'h0000_????}; 
        wildcard bins tx_pause_req_1 = {'h0001_????};   
        // minimum timer value = 0
        bins time_val_min = {'h0001_0000}; 
        // maximum timer value = FFFF
        bins time_val_max = {'h0001_FFFF};      
        // any timer value betwee 0 and FFFF
        bins time_val_any [64]= {['h0001_0001:'h0001_FFFE]};  
        // ignore other values
        bins others = default;
    }

    cp_bd_len: coverpoint m_bd_len iff(m_addr>='h400 && m_addr<='h7FF && m_addr%2==0) {
        // ALl legal lengths
        bins len_all [64] = {['h0005:'hFFFE]};
        // All illegal lengths 
        bins len_4   [5] = {['h0000:'h0004]};
        // Maximum value 
        bins len_max   = {'hFFFF};
    }

    cp_bd_cfg: coverpoint m_bd_cfg iff(m_addr>='h400 && m_addr<='h7FF && m_addr%2==0) {

        // All configurations
        bins bd_config [] = {['b00_0000:'b11_111]};
        
        // ignore other values
        bins others = default;
    }


    // TXPNT buffer descriptor Any odd address in buffer descriptor memory range
    cp_txpnt: coverpoint m_wdata iff(m_addr>='h400 && m_addr<='h7FF && m_addr%2==1) {
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

    endgroup

    // =============================================================================
    //  Read Configurations cover group
    // =============================================================================
    covergroup m_rd_cfg_cov;
        
        // INT_SOURCE Register (Address 0x04)
        cp_int_source: coverpoint m_wdata iff(m_addr=='h04) {
            // None is masked
            bins no_int = {'h0000_0000};
            // TXB
            bins txb   = {'h0000_0001};
            // TXE
            bins txe = {'h0000_0002};
            // TXC 
            bins txc = {'h0000_0020};
            // Any combinations between more than 2 interrupts is illegal;
            illegal_bins ill_int = {'h0000_0003,'h0000_0022,'h0000_0021,'h0000_0023};

            // ignore other values
            bins others = default;
        }

        cp_inta: coverpoint m_inta{
            bins inta_1={1};
            bins inta_0={0};
        } 

        cp_bd_stat: coverpoint m_bd_stat iff(m_addr>='h400 && m_addr<='h7FF && m_addr%2==0) {
            // underrun
            wildcard bins ur []= {'b1_????};
            // maximum
            wildcard bins rl [] = {'b?_1???};
            // late collision
            wildcard bins lc [] = {'b?_?1??};
            // deferral
            wildcard bins df [] = {'b?_??1?};
        }


        cp_bd_retry: coverpoint m_retry_cnt iff(m_addr>='h400 && m_addr<='h7FF && m_addr%2==0) {
            // minimum
            bins retry_min = {'b0000};
            // maximum
            bins retry_max = {'b1111};
            // other values
            bins retry_all [] = {['b0001:'b1110]};
        }
        // =============================================================================
        //  Cross cover points
        // =============================================================================
        cross_inta_int_source: cross cp_int_source,cp_inta;

        cross_retry_stat_cp: cross cp_bd_retry,cp_bd_stat{
        illegal_bins retry_rl = binsof(cp_bd_retry.retry_max) && binsof(cp_bd_stat.ur);
        //illegal_bins retry_rl = binsof(cp_bd_retry.retry_max) && binsof(cp_bd_stat.ur);
        }

    endgroup
endclass    


// =============================================================================
//  IMPLEMENTATION
// =============================================================================

function eth_tx_cov::new(string name, uvm_component parent);
    super.new(name, parent);
    m_wr_cfg_cov=new();
    m_rd_cfg_cov=new();
endfunction


function void eth_tx_cov::build_phase(uvm_phase phase);
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

function void eth_tx_cov::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    // Connect each export with it's corrosponding fifo
    wb_m_a_export.connect(wb_m_fifo.analysis_export);
    wb_s_a_export.connect(wb_s_fifo.analysis_export);
    mii_tx_a_export.connect(mii_tx_fifo.analysis_export);
endfunction 

task eth_tx_cov::run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever 
    begin
        fork:fork_tx_cov
            //sample_tx_item();
            //sample_wb_m_item();
            sample_wb_s_item();
        join;
    end
endtask

task eth_tx_cov::sample_wb_s_item();
    // Get transaction from fifo
    wb_s_fifo.get(m_wb_s_seq_item);

    // Copy transaction field values to local
    m_addr  = m_wb_s_seq_item.m_addr;
    m_wdata = m_wb_s_seq_item.m_wdata;
    m_rdata = m_wb_s_seq_item.m_rdata;
    m_inta  = m_wb_s_seq_item.m_inta;
    m_moder_tx = {m_wdata[1],m_wdata[15],m_wdata[14],m_wdata[13],m_wdata[12],m_wdata[10],m_wdata[9],m_wdata[8],m_wdata[2]};
    m_minfl = m_wdata[31:16];
    m_maxfl = m_wdata[15:0];
    m_retry_max = m_wdata[19:16];
    m_coll_v = m_wdata[5:0];
    m_bd_len = m_wdata[31:16];
    m_bd_cfg = m_wdata[15:11];
    m_retry_cnt = m_wdata[7:4];
    m_bd_stat ={m_wdata[8],m_wdata[3:0]};

    // if address isn't inside register or bd range return
    if(! ((m_addr inside{WB_BD_MEM_BASE_ADDR,WB_BD_MEM_OFFSET_ADDR}) || (m_addr inside{ETH_REG_BASE_ADDR,ETH_REG_OFFSET_ADDR})))
        return;

    // if select isn't valid return 
    if(!(&m_wb_s_seq_item.m_sel))
        return;

    // if write transaction cover config_group
    if(m_wb_s_seq_item.m_dir==WB_WRITE) begin
        m_wr_cfg_cov.sample();
        `uvm_info(get_name(), "SAMPLED", UVM_NONE)
        
    end
    
    // if read transaction voer status_group
    else if(m_wb_s_seq_item.m_dir==WB_READ)
        m_rd_cfg_cov.sample();
endtask

`endif // ETH_TX_COV_SV