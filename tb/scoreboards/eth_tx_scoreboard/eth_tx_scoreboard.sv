//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_tx_scoreboard.sv
// Author   : Wael,Nada
// Date     : 2026-06-30
//------------------------------------------------------------------------------
// Description:
//   Ethernet scoreboard responsible for implementation of golden model of tx
//   and comparing it's expected packet with the actual tx packet. 
//==============================================================================
`ifndef ETH_TX_SCOREBOARD_SV
`define ETH_TX_SCOREBOARD_SV

class eth_tx_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(eth_tx_scoreboard)
    // =========================================================================
    // Parameters for semaphore keys
    // =========================================================================
    parameter SEM_TX_SEQ_ITEM_NO_KEYS = 7;
    parameter SEM_WB_M_SEQ_ITEM_NO_KEYS = 1;

    // =========================================================================
    // Analysis fifos — one for wishbone master, one for MII TX
    // =========================================================================
    uvm_tlm_analysis_fifo  #(wb_m_seq_item_base)        wb_m_fifo;
    uvm_tlm_analysis_fifo  #(mii_tx_seq_item_base)      mii_tx_fifo;
    // =========================================================================
    // Analysis exports — one for wishbone master, one for MII TX
    // =========================================================================
    uvm_analysis_export  #(wb_m_seq_item_base)        wb_m_a_export;
    uvm_analysis_export  #(mii_tx_seq_item_base)      mii_tx_a_export;
    // =========================================================================
    // Wishbone slave analysis implementation
    // =========================================================================
     uvm_analysis_imp #(wb_s_seq_item_base#(WB_S_ADDR_WIDTH, WB_DATA_WIDTH,WB_SEL_WIDTH), eth_tx_scoreboard) wb_s_imp;    
    // =========================================================================
    // Transactions for storing last item pulled from tlm fifo
    // =========================================================================
    wb_m_seq_item_base                              m_wb_m_seq_item;
    mii_tx_seq_item_base                            m_mii_tx_seq_item;
    // =========================================================================
    //  Configuration object 
    // =========================================================================
    eth_tx_scoreboard_config_obj                    m_config;
    // =========================================================================
    // Register block
    // =========================================================================
    eth_reg_block                                   m_regmodel;   
    // =========================================================================
    // Semaphores
    // =========================================================================
    semaphore m_sem_tx_seq_item; // for getting mii tx transaction from fifo
    semaphore m_sem_wb_m_seq_item; // for getting wb master transaction from fifo
    // =========================================================================
    // Events
    // =========================================================================    
    event m_ev_end_pkt;      // triggered when each packet is compared
    event m_ev_end_seqs;    // triggerd when running sequence finish
    event m_ev_txen;        // triggered when TXEN bit in MODER register changes from 0 to 1
    event m_ev_start_comp;  // triggered when packet ends to start comparison
    // =========================================================================
    // Structs
    // ========================================================================= 
    eth_tx_expected_s m_tx_expected_s;
    eth_tx_bd_cfg_s   m_tx_bd_cfg_s;
    eth_tx_pending_s  m_tx_pending_s;

    // =========================================================================
    // Constructor, write tlm function, Build Phase, Connect phase and Run phase
    // =========================================================================
    extern function new(string name, uvm_component parent);
    extern function void build_phase(uvm_phase phase);
    extern function void connect_phase(uvm_phase phase);
    extern task run_phase(uvm_phase phase);
    extern function void write(wb_s_seq_item_base#(WB_S_ADDR_WIDTH, WB_DATA_WIDTH,WB_SEL_WIDTH ) tr);
    // -------------------------------------------------------------------------
    //  task : predictor
    // -------------------------------------------------------------------------
    // Description:
    //   Implements golden model of tx, Construct packet and send it to
    //   comparator.Detects collision, carrier sense errors like underrun and
    //   huge packet.   
    // Arguments: None
    //
    // -------------------------------------------------------------------------
    extern task predictor();
    // -------------------------------------------------------------------------
    //  task : comparator
    // -------------------------------------------------------------------------
    // Description:
    //   Compare the expected packet sent from predictor with actual sent from
    //   DUT. Reports error if they don't match.   
    // Arguments: None
    //
    // -------------------------------------------------------------------------    
    extern task comparator();
    // -------------------------------------------------------------------------
    //  task : get_mii_tx_seq_item
    // -------------------------------------------------------------------------
    // Description:
    //   pull the next transaction from mii_tx fifo.it only gets it when it
    //   gets all the semaphore keys to ensure that the new transaction doesn't
    //   override the old when another process needs it.   
    // Arguments: None
    //
    // -------------------------------------------------------------------------  
    extern task get_mii_tx_seq_item();
    // -------------------------------------------------------------------------
    //  task : get_wb_m_seq_item
    // -------------------------------------------------------------------------
    // Description:
    //   pull the next transaction from wb_master fifo.it only gets it when it
    //   gets all the semaphore keys to ensure that the new transaction doesn't
    //   override the old when another process needs it.   
    // Arguments: None
    //
    // ------------------------------------------------------------------------- 
    extern task get_wb_m_seq_item();
    // =============================================================================
    //  Predictor methods
    // ============================================================================= 
    // -------------------------------------------------------------------------
    //  function : pred_construct_data_pkt
    // -------------------------------------------------------------------------
    // Description:
    //   responsible calling functions that will read data from dma_memory,pad
    //   bytes,discard bytes from huge frame,add crc,add preamble   
    // Arguments: None
    //
    // ------------------------------------------------------------------------- 
    extern function void pred_construct_data_pkt();
    // -------------------------------------------------------------------------
    //  function : pred_construct_ctrl_pkt
    // -------------------------------------------------------------------------
    // Description:
    //   construct control packet (pause frame). it adds fields of control 
    //   packet (destination & source address,type,opcode,pause timer value crc)
    //   and call functions to add pramble & sfd.  
    // Arguments: None
    //
    // ------------------------------------------------------------------------- 
    extern function void pred_construct_ctrl_pkt();
    // -------------------------------------------------------------------------
    //  function : pred_add_pad
    // -------------------------------------------------------------------------
    // Description:
    //   add padding to packet based on minimum packet length in MINFL field.  
    // Arguments: None
    //
    // ------------------------------------------------------------------------- 
    extern function void pred_add_pad();
    // -------------------------------------------------------------------------
    //  function : pred_add_preamble_sfd
    // -------------------------------------------------------------------------
    // Description:
    //   add 7 bytes preamble based on NOPRE configuration & 1 byte start frame 
    //   delimiter (SFD) to the beginning of packet.  
    // Arguments: None
    //
    // ------------------------------------------------------------------------- 
    extern function void pred_add_pream_sfd();
    // -------------------------------------------------------------------------
    //  function : pred_check_len_4
    // -------------------------------------------------------------------------
    // Description:
    //   Check if the frame length configured in buffer descriptor greater than 
    //   4 bytes.  
    // Arguments: None
    // Return: bit
    // 1: frame length is more than 4 bytes
    // 0: frame length is less than 4 bytes
    //
    // ------------------------------------------------------------------------- 
    extern function bit  pred_check_len_4();
    // -------------------------------------------------------------------------
    //  function : pred_check_huge
    // -------------------------------------------------------------------------
    // Description:
    //   In case HUGEN bit is 0, checks if packet length is less than maximum  
    //   frame length and if not it discards additional bytes (SFD).  
    // Arguments: None
    //
    // ------------------------------------------------------------------------- 
    extern function void pred_check_huge();
    // -------------------------------------------------------------------------
    //  function : pred_read_mem
    // -------------------------------------------------------------------------
    // Description:
    //   Read dma memory model data and put it in expected packet queue.
    // Arguments: None
    //
    // -------------------------------------------------------------------------     
    extern function void pred_read_mem();
    // -------------------------------------------------------------------------
    //  task : pred_track_txen
    // -------------------------------------------------------------------------
    // Description:
    //   always check txen bit in register model and when it rises to high, 
    //   trigger event m_ev_txen. 
    // Arguments: None
    //
    // -------------------------------------------------------------------------     
    extern task pred_track_txen();    
    // -------------------------------------------------------------------------
    //  task : pred_track_rd
    // -------------------------------------------------------------------------
    // Description:
    //   always check rd bit of each BD in register model and when it's high set
    //   a flag and when it falls increment current bd.
    // Arguments: None
    //
    // -------------------------------------------------------------------------     
    extern task pred_track_rd();
    // -------------------------------------------------------------------------
    //  task : pred_track_underrun
    // -------------------------------------------------------------------------
    // Description:
    //   always check the number of transmitted packets on TX and read data on 
    //   wishbone to check if underrun occurs
    // Arguments: None
    //
    // ------------------------------------------------------------------------- 
    extern task pred_track_underrun();
    // -------------------------------------------------------------------------
    //  task : pred_read_cfg_reg
    // -------------------------------------------------------------------------
    // Description:
    //   Read configurations of register file through backdoor access
    // Arguments: None
    //
    // ------------------------------------------------------------------------- 
    extern task pred_read_cfg_reg();
    // -------------------------------------------------------------------------
    //  task : pred_read_cfg_bd
    // -------------------------------------------------------------------------
    // Description:
    //   Read configurations of one buffer descriptor file through backdoor access
    // Arguments: None
    //
    // ------------------------------------------------------------------------- 
    extern task pred_read_cfg_bd();
    // -------------------------------------------------------------------------
    //  task : pred_defer
    // -------------------------------------------------------------------------
    // Description:
    //   Predict occurence of packet deferral 
    // Arguments: None
    //
    // ------------------------------------------------------------------------- 
    extern task pred_defer();
    // -------------------------------------------------------------------------
    //  task : pred_coll
    // -------------------------------------------------------------------------
    // Description:
    //   Predict occurence of late collision 
    // Arguments: None
    //
    // -------------------------------------------------------------------------
    extern task pred_coll();
    // -------------------------------------------------------------------------
    //  task : pred_check_jam_retry
    // -------------------------------------------------------------------------
    // Description:
    //   count number of transmitted jam signals to count retry count  
    // Arguments: None
    //
    // -------------------------------------------------------------------------
    extern task pred_check_jam_retry();
    // =============================================================================
    //  Compatator methods
    // =============================================================================    
    //  task : comp_pack_pkt
    // -------------------------------------------------------------------------
    // Description:
    //   pack the transmitted nibbles of dut in queue 
    // Arguments: None
    //
    // -------------------------------------------------------------------------
    extern task comp_pack_pkt();
    // -------------------------------------------------------------------------
    //  function : comp_compare_field
    // -------------------------------------------------------------------------
    // Description:
    //   compare field of actual packet and expected 
    // Arguments: 
    // field_name: Name of field in packet (ex SFD,CRC..)
    // start_idx: first byte in the field
    // num_bytes: number of bytes of the field
    // error_found: set if there's mismatch , it's ref to can be seen by 
    //              comp_compare_pkt function.
    // -------------------------------------------------------------------------
    extern function void comp_compare_field(string field_name,int start_idx,int num_bytes,ref bit error_found);
    // -------------------------------------------------------------------------
    //  function : comp_compare_pkt
    // -------------------------------------------------------------------------
    // Description:
    //   compare between actual and expected packet 
    // Arguments: None
    //
    // -------------------------------------------------------------------------
    extern function void comp_compare_pkt();
    // -------------------------------------------------------------------------
    //  function : comp_check_txerr
    // -------------------------------------------------------------------------
    // Description:
    //   check MTXerr asserted when error condition occur (underrun or 
    //   huge packet more than maximum frame length)
    // Arguments: None
    //
    // -------------------------------------------------------------------------
    extern function void comp_check_txerr();
    // -------------------------------------------------------------------------
    //  task : comp_check_interrupt
    // -------------------------------------------------------------------------
    // Description:
    //   check interrupt status after packet transmission
    // Arguments: None
    //
    // -------------------------------------------------------------------------
    extern task comp_check_interrupt();
    // -------------------------------------------------------------------------
    //  task : comp_check_bd_status
    // -------------------------------------------------------------------------
    // Description:
    //   check buffer descriptor status bits after packet transmission
    // Arguments: None
    //
    // -------------------------------------------------------------------------
    extern task comp_check_bd_status();
    // -------------------------------------------------------------------------
    //  task : comp_check_ipgt
    // -------------------------------------------------------------------------
    // Description:
    //   calculate ipgt period and compare it with value in register
    // Arguments: None
    //
    // -------------------------------------------------------------------------
    extern task comp_check_ipgt();
    // -------------------------------------------------------------------------
    //  task : comp_check_ipgr
    // -------------------------------------------------------------------------
    // Description:
    //   calculate ipgr2 period 
    // Arguments: None
    //
    // -------------------------------------------------------------------------
    extern task comp_check_ipg();
    // -------------------------------------------------------------------------
    //  function : clear
    // -------------------------------------------------------------------------
    // Description:
    //   reset all structs to it's default value after packet comparison 
    // Arguments: None
    //
    // -------------------------------------------------------------------------
    extern function void clear();
endclass : eth_tx_scoreboard

// =============================================================================
//  IMPLEMENTATION
// =============================================================================

function eth_tx_scoreboard::new(string name, uvm_component parent);
    super.new(name, parent);
endfunction




function void eth_tx_scoreboard::build_phase(uvm_phase phase);
    super.build_phase(phase);
    // Build fifos
    wb_m_fifo     = new("wb_m_fifo",this);
    mii_tx_fifo   = new("mii_tx_fifo",this);
    // Build analysis exports
    wb_m_a_export   = new("wb_m_export",this);
    mii_tx_a_export = new("mii_tx_export",this);

    // Build analysis import
    wb_s_imp = new("wb_s_imp", this);

    // Creating semaphore objects
    m_sem_tx_seq_item=new(SEM_TX_SEQ_ITEM_NO_KEYS);
    m_sem_wb_m_seq_item=new(SEM_WB_M_SEQ_ITEM_NO_KEYS);

    // get config object from database
    if (!uvm_config_db #(eth_tx_scoreboard_config_obj)::get(this, "", "config", m_config))
      `uvm_error(get_type_name(), "eth_tx_scoreboard_config not found in config_db")

endfunction



function void eth_tx_scoreboard::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    // assign ral handle to it's corresponding in config
    m_regmodel=m_config.m_regmodel;
    // assign end seq event handle to it's corresponding in config
    m_ev_end_seqs=m_config.m_ev_end_seqs;
    
    // Connect each export with it's corrosponding fifo
    wb_m_a_export.connect(wb_m_fifo.analysis_export);
    mii_tx_a_export.connect(mii_tx_fifo.analysis_export);
endfunction    



task eth_tx_scoreboard::run_phase(uvm_phase phase);
    super.run_phase(phase);
    phase.raise_objection(this);
    `uvm_info(get_type_name(),"Tx scoreboard raised objection", UVM_LOW)
    fork: fork_run_phase 
        get_mii_tx_seq_item();
        //get_wb_m_seq_item();
        #0.1 predictor();
        #0.1 comparator();
        begin
            wait(m_ev_end_seqs.triggered);
            wait(m_ev_end_pkt.triggered);
            #0.2;
            repeat(m_tx_bd_cfg_s.tx_bd_num-1) begin
            wait(m_ev_end_pkt.triggered);
            #0.2;
        end
        disable fork_run_phase;
        end    
    join    
    phase.drop_objection(this);
    `uvm_info(get_type_name(),"Tx scoreboard dropped objection", UVM_LOW)
endtask



function void eth_tx_scoreboard::write( wb_s_seq_item_base#(WB_S_ADDR_WIDTH, WB_DATA_WIDTH,WB_SEL_WIDTH ) tr);
//------------------------------------------------------------------------------
// Receives every WB slave transaction.
// Maintains a predictor copy of the BD memory.
//------------------------------------------------------------------------------
    int mem_idx;

    //-------------------------------------------------------
    // Ignore reads
    //-------------------------------------------------------
    if (tr.m_dir==WB_READ)
        return;

    //-------------------------------------------------------
    // Is this transaction targeting BD memory?
    //
    // BD memory occupies:
    // 10'h100 -> 10'h1FF
    //-------------------------------------------------------
    if (tr.m_addr[9:8] == 2'b01 && (&tr.m_sel)) begin

        mem_idx = tr.m_addr[7:0];

        bd_mem::write(mem_idx,tr.m_wdata);

        `uvm_info(get_type_name(),
            $sformatf(
            "BD_MEM[%0d] <= 0x%08h",
            mem_idx,
            tr.m_wdata),
            UVM_HIGH)

    end

endfunction



task eth_tx_scoreboard::predictor();

    fork: fork_pred
        pred_track_txen();
        pred_track_rd();
        //pred_track_underrun(); 
             begin
                wait(m_ev_txen.triggered);
                    pred_read_cfg_reg();
                forever begin
                    if(!m_tx_bd_cfg_s.full_duplex) begin
            
                    end 
                    if(!m_tx_bd_cfg_s.tx_pause_req || !m_tx_bd_cfg_s.tx_flow) begin
                        wait(m_tx_pending_s.flag_rd);
                        pred_read_cfg_bd();
                        if(pred_check_len_4())
                        pred_construct_data_pkt();                
                        //dma_mem::print();
                    end
                    else begin
                        pred_construct_ctrl_pkt();
                    end    
                    wait(m_ev_end_pkt.triggered);
                    pred_read_cfg_reg();
                    #1;
                end    
            end        
    join

endtask    



task eth_tx_scoreboard::comparator();
   forever begin
    fork : fork_comp
    comp_pack_pkt();
    //comp_compare_ipgt();
    comp_check_ipgt();
    begin
        wait(m_ev_start_comp.triggered);
        comp_compare_pkt();
        comp_check_txerr();
        comp_check_interrupt();
        comp_check_bd_status();
        clear();
        -> m_ev_end_pkt;
        disable fork_comp;
    end    
    join 
    #0.1;    
end 
endtask



task eth_tx_scoreboard::get_mii_tx_seq_item();
    forever begin
        // Get all keys from semaphore
        repeat(SEM_TX_SEQ_ITEM_NO_KEYS)
        m_sem_tx_seq_item.get(1);
        // Get transaction item from fifo
        mii_tx_fifo.get(m_mii_tx_seq_item);
        `uvm_info(get_type_name(),m_mii_tx_seq_item.convert2string(),UVM_HIGH)
        // Put all Keys in semaphore
        m_sem_tx_seq_item.put(SEM_TX_SEQ_ITEM_NO_KEYS);
    end
endtask    



task eth_tx_scoreboard::get_wb_m_seq_item();
    forever begin
        // Get all keys from semaphore
        repeat(SEM_WB_M_SEQ_ITEM_NO_KEYS)
        m_sem_wb_m_seq_item.get(1);
        // Get transaction item from fifo
        wb_m_fifo.get(m_wb_m_seq_item);
        `uvm_info(get_type_name(),m_wb_m_seq_item.convert2string(),UVM_HIGH)
        // Put all Keys in semaphore
        m_sem_wb_m_seq_item.put(SEM_WB_M_SEQ_ITEM_NO_KEYS);
    end
endtask 



function void eth_tx_scoreboard::pred_construct_data_pkt();
    bit [31:0] crc;
    `uvm_info(get_name(),"Begin constructing data packet",UVM_HIGH )
    // read data packts from dma memory
    pred_read_mem();
    
    // add padding bytes if required
    pred_add_pad();

    // check if crc is enabled 
    if (m_tx_bd_cfg_s.eff_crc) begin
        // Check if delay crc  is enabled
        if(m_tx_bd_cfg_s.dlycrcen) begin
        bytes_q pkt_copy=m_tx_expected_s.exp_pkt;
        // pop first 4 bytes from packet copy to calculate crc of remaining bytes
        repeat(4)
            pkt_copy.pop_front();
        // Calculate delayed crc
            crc=calc_crc32(pkt_copy);    
        end  
        else begin
            // Calculate crc
            crc=calc_crc32(m_tx_expected_s.exp_pkt);
        end
        // push crc (4 bytes)
        for(int i = 0; i<ETH_CRC_LEN; i++)
            m_tx_expected_s.exp_pkt.push_back(crc[8*i+:8]);
    end

    // check if the packet is greater than maximum size, discard additional bytes
    pred_check_huge();
    
    // add preamble and sfd to the beginning of packet
    pred_add_pream_sfd();
endfunction   



function void eth_tx_scoreboard::pred_construct_ctrl_pkt();
        bit [31:0] crc;
        `uvm_info(get_name(),"Begin constructing control packet",UVM_HIGH )       
        // push destination addr (6 bytes)
        for(int i = ETH_ADDR_LEN-1; i>=0; i--)
            m_tx_expected_s.exp_pkt.push_back(ETH_PAUSE_FRAME_ADDR[8*i+:8]);
        
        // push source addr (6 bytes)
        for(int i = ETH_ADDR_LEN-1; i>=0; i--)
            m_tx_expected_s.exp_pkt.push_back(m_tx_bd_cfg_s.mac_addr[8*i+:8]);
        
        // push lenth_type (2 bytes)
        m_tx_expected_s.exp_pkt.push_back(ETH_PAUSE_LEN_TYPE[15:8]);                // push most significant byte
        m_tx_expected_s.exp_pkt.push_back(ETH_PAUSE_LEN_TYPE[7:0]);                 // push least significant byte

        // push opcode (2 bytes)
        m_tx_expected_s.exp_pkt.push_back(ETH_PAUSE_OPCODE[15:8]);                  // push most significant byte
        m_tx_expected_s.exp_pkt.push_back(ETH_PAUSE_OPCODE[7:0]);                   // push least significant byte        

        // push timer value (2 bytes)
        m_tx_expected_s.exp_pkt.push_back(m_tx_bd_cfg_s.tx_pause_tv[15:8]);          // push most significant byte
        m_tx_expected_s.exp_pkt.push_back(m_tx_bd_cfg_s.tx_pause_tv[7:0]);           // push least significant byte 

        // Push padding bytes (42 byte)
        repeat(42)
            m_tx_expected_s.exp_pkt.push_back(ETH_PAD);        
            
        // Calculate crc
            crc=calc_crc32(m_tx_expected_s.exp_pkt);

        // push crc (4 bytes)
        for(int i = 0; i<ETH_CRC_LEN; i++)
            m_tx_expected_s.exp_pkt.push_back(crc[8*i+:8]);

        // add preamble (7 bytes) & SFD (1 byte)     
        pred_add_pream_sfd();

endfunction  



function void eth_tx_scoreboard::pred_add_pad();
//------------------------------------------------------------------------------
// Add zero padding if required
//
// Ethernet minimum frame size includes the CRC.
// Since the CRC is appended later, pad only until:
//
//      frame_size_without_crc = MINFL - 4
//
// Padding bytes are always 8'h00.
//------------------------------------------------------------------------------


    int target_len= m_tx_bd_cfg_s.minfl;
    int pad_bytes;

    // No padding required
    if (!m_tx_bd_cfg_s.eff_pad)
        return;

    // Length that should exist before CRC insertion (4 bytes) 
    if(m_tx_bd_cfg_s.eff_crc)
    target_len -= ETH_CRC_LEN;

    // if the length become negative after subtraction, it should be 0
    if(target_len<0)
        target_len=0;

    if (m_tx_expected_s.exp_pkt.size() >= target_len)
        return;

    pad_bytes = target_len - m_tx_expected_s.exp_pkt.size();

    repeat (pad_bytes)
        m_tx_expected_s.exp_pkt.push_back(ETH_PAD);

    `uvm_info(get_type_name(),
        $sformatf("Added %0d padding bytes (frame length = %0d)",
                  pad_bytes,
                  m_tx_expected_s.exp_pkt.size()),
        UVM_LOW)

endfunction



function void eth_tx_scoreboard::pred_add_pream_sfd();

    // push Start of frame delimiter (1 byte)
    m_tx_expected_s.exp_pkt.push_front(ETH_SFD);

    // check if preamble is enabled
    if(!m_tx_bd_cfg_s.no_pre) begin
        // push preamble (7 bytes)
        repeat(ETH_PREAMBLE_LEN)
            m_tx_expected_s.exp_pkt.push_front(ETH_PREAMBLE);
    end  

endfunction    



function bit eth_tx_scoreboard::pred_check_len_4();
//------------------------------------------------------------------------------
// Check minimum transmit length.
// Ethernet MAC does not transmit frames whose length <= 4 bytes.
//------------------------------------------------------------------------------
    if (m_tx_bd_cfg_s.len <= 16'd4) begin

        `uvm_info(get_type_name(),
            $sformatf("BD[%0d]: Frame length (%0d bytes) <= 4. Transmission suppressed.",
                      m_tx_bd_cfg_s.bd_index,
                      m_tx_bd_cfg_s.len),
            UVM_MEDIUM)

        return 0;
    end

    return 1;

endfunction




function void eth_tx_scoreboard::pred_check_huge();
    // if Huge enavle = 1 , send packet regardless of it's size
    if(m_tx_bd_cfg_s.hugen)
        return;
    // if packet length is smaller than maximum packet size, send packet
    if (m_tx_bd_cfg_s.len <= m_tx_bd_cfg_s.maxfl)
        return;

    // if packet length is greater than maximum packet size, discard additional bytes
    else begin
        // number of discarded bytes 
        int discarded_bytes=m_tx_bd_cfg_s.len - m_tx_bd_cfg_s.maxfl;
        if(m_tx_bd_cfg_s.eff_crc)
            discarded_bytes+=ETH_CRC_LEN;
        // pop number of discarded bytes from back of queue
        repeat(discarded_bytes)
            m_tx_expected_s.exp_pkt.pop_back();
            
        // Set huge error flag    
        m_tx_expected_s.exp_huge=1;    
    end
endfunction



function void eth_tx_scoreboard::pred_read_mem();
    // length of packet in BD
    bit [15:0] len =  m_tx_bd_cfg_s.len;
    // base address of packet
    bit [WB_DATA_WIDTH-1:0] txpnt =  m_tx_bd_cfg_s.txpnt;
    // Read data from dma memory (4 bytes)
    bit [WB_DATA_WIDTH-1:0] rd_data;

    // Check that txpnt value exists in memory
    if(!dma_mem::read(txpnt,rd_data))
        `uvm_fatal(get_name(), $sformatf("Buffer descriptor number %0d Txpnt value doesn't exist in dma memory, txpnt = %0h",m_tx_bd_cfg_s.bd_index,txpnt))
      
    for (int unsigned i =0; i<len/4;i++) begin
        // Read each word from memory
        if(!dma_mem::read(txpnt+i*4,rd_data)) begin
            `uvm_fatal(get_name(), $sformatf("In buffer descriptor number %0d, address doesn't exist in dma memory, address = %0h",m_tx_bd_cfg_s.bd_index,txpnt+i*4))
        end
        else begin
            // push word in expected packet queue
            for(int i = 3; i>=0; i--)
                m_tx_expected_s.exp_pkt.push_back(rd_data[8*i+:8]);
        end
    end    

    // push remaining bytes if length isn't divisble by 4
    if(len%4!=0) begin
        dma_mem::read(txpnt+len-len%4,rd_data);
        for(int i=1;i<=len%4;i++)
              m_tx_expected_s.exp_pkt.push_back(rd_data[8*(4-i)+:8]);
    end  

endfunction



task eth_tx_scoreboard::pred_track_txen();

    uvm_status_e   status;
    uvm_reg_data_t rtl_data;

    bit prev_txen;
    bit curr_txen;

    // ---------------------------------------------------------
    // Initialize previous value from RTL
    // ---------------------------------------------------------
    m_regmodel.MODER.mirror(
        status,
        UVM_CHECK,
        UVM_BACKDOOR
    );

    rtl_data  = m_regmodel.MODER.get_mirrored_value();
    prev_txen = rtl_data[1];

    forever begin

        // Read RTL and compare against RAL mirror
        m_regmodel.MODER.mirror(
            status,
            UVM_CHECK,
            UVM_BACKDOOR
        );

        rtl_data  = m_regmodel.MODER.get_mirrored_value();
        curr_txen = rtl_data[1];

        // Detect 0 -> 1 transition
        if (!prev_txen && curr_txen) begin
            -> m_ev_txen;

            `uvm_info(get_type_name(),
                "TXEN asserted",
                UVM_MEDIUM)
        end

        prev_txen = curr_txen;

        #1ns;
    end

endtask



task eth_tx_scoreboard::pred_track_rd();
//------------------------------------------------------------------------------
// Track TX Buffer Descriptor RD bit
//
// RD : 0 -> 1  : Software armed this BD
// RD : 1 -> 0  : DUT completed transmission
//------------------------------------------------------------------------------
    uvm_status_e   status;
    uvm_reg_data_t rtl_data;

    bit prev_rd;
    bit curr_rd;
    bit wrap_bit;

    int status_idx;

    //------------------------------------------------------------
    // Start from first TX BD
    //------------------------------------------------------------
    m_tx_bd_cfg_s.bd_index = 0;

    //------------------------------------------------------------
    // Initialize previous RD
    //------------------------------------------------------------
    status_idx = m_tx_bd_cfg_s.bd_index * 2;

    m_regmodel.eth_bd_mem.peek(
        status,
        status_idx,
        rtl_data
    );

    prev_rd = rtl_data[WB_TX_BD_RD_POS];

    forever begin

        //--------------------------------------------------------
        // Current BD status word index
        //--------------------------------------------------------
        status_idx = m_tx_bd_cfg_s.bd_index * 2;

        //--------------------------------------------------------
        // Read current BD through backdoor
        //--------------------------------------------------------
        m_regmodel.eth_bd_mem.peek(
            status,
            status_idx,
            rtl_data
        );

        curr_rd  = rtl_data[WB_TX_BD_RD_POS];
        wrap_bit = rtl_data[WB_TX_BD_WR_POS];

        //--------------------------------------------------------
        // Software armed this BD (RD : 0 -> 1)
        //--------------------------------------------------------
        if (curr_rd) begin

            //`uvm_info(get_type_name(),
              //  $sformatf("TX BD[%0d] armed",
                //          m_tx_bd_cfg_s.bd_index),
                //UVM_MEDIUM)

            m_tx_pending_s.flag_rd=1;

        end

        //--------------------------------------------------------
        // DUT completed this BD (RD : 1 -> 0)
        //--------------------------------------------------------
        if (prev_rd && !curr_rd) begin
            `uvm_info(get_type_name(),
                $sformatf("TX BD[%0d] completed",
                          m_tx_bd_cfg_s.bd_index),
                UVM_MEDIUM)

            //----------------------------------------------------
            // Move to next BD
            //----------------------------------------------------
            if (wrap_bit) begin
                m_tx_bd_cfg_s.bd_index = 0;
                `uvm_info(get_type_name(),"WRAPP",UVM_HIGH)
            end
            else
                m_tx_bd_cfg_s.bd_index++;

            //----------------------------------------------------
            // Initialize prev_rd for the new BD
            //----------------------------------------------------
            status_idx = m_tx_bd_cfg_s.bd_index * 2;

            m_regmodel.eth_bd_mem.peek(
                status,
                status_idx,
                rtl_data
            );

            prev_rd = rtl_data[WB_TX_BD_RD_POS];
            #1ns;
            continue;
        end

        //--------------------------------------------------------
        // Update previous RD
        //--------------------------------------------------------
        prev_rd = curr_rd;

        #1ns;

    end

endtask



task eth_tx_scoreboard::pred_track_underrun();
    // Number of bytes read from memory by wb interface
    longint unsigned rd_bytes=0;
    longint unsigned pkt_len=0;
    int      pre_crc_bytes =0;

    wait(m_ev_txen.triggered);     
    
    forever
    begin
        fork: fork_underrun
            begin
                #1;
                pkt_len=m_tx_bd_cfg_s.len+ETH_SFD_LEN;
                pre_crc_bytes =ETH_SFD_LEN;

                if(!m_tx_bd_cfg_s.no_pre) begin
                    pkt_len+=ETH_PREAMBLE_LEN;
                    pre_crc_bytes+=ETH_PREAMBLE_LEN;
                end  
                if(m_tx_bd_cfg_s.eff_crc) begin
                    pkt_len+=ETH_CRC_LEN;
                    pre_crc_bytes+=ETH_CRC_LEN;
                end 
                forever 
                    begin
                        // Get Semaphore
                        m_sem_wb_m_seq_item.get(1);
                        
                        // check if it's read transaction
                        if(m_wb_m_seq_item.m_dir==WB_READ && m_wb_m_seq_item.m_stb_o
                        && m_wb_m_seq_item.m_cyc_o && (&m_wb_m_seq_item.m_sel_o)) begin
                            rd_bytes++;
                        end  
                        if(m_tx_expected_s.exp_pkt.size()>=(rd_bytes+pre_crc_bytes) && m_tx_expected_s.exp_pkt.size()<pkt_len)
                            m_tx_expected_s.exp_ur=1;
                            
                        // Put Semaphore
                        m_sem_wb_m_seq_item.put(1);
                        #1;
                    end
            end
            begin
                wait(m_ev_end_pkt.triggered);
                disable fork_underrun;
            end    
        join
        #1;    
    end

endtask



task eth_tx_scoreboard::pred_read_cfg_reg();
//------------------------------------------------------------------------------
// Read all TX configuration registers
//------------------------------------------------------------------------------

    uvm_status_e   status;
    uvm_reg_data_t data;

    //------------------------------------------
    // MODER
    //------------------------------------------
    m_regmodel.MODER.mirror(status, UVM_CHECK, UVM_BACKDOOR);

    m_tx_bd_cfg_s.txen         = m_regmodel.MODER.TXEN.get_mirrored_value();
    m_tx_bd_cfg_s.pad_moder    = m_regmodel.MODER.PAD.get_mirrored_value();
    m_tx_bd_cfg_s.crcen        = m_regmodel.MODER.CRCEN.get_mirrored_value();
    m_tx_bd_cfg_s.hugen        = m_regmodel.MODER.HUGEN.get_mirrored_value();
    m_tx_bd_cfg_s.recsmall     = m_regmodel.MODER.RECSMALL.get_mirrored_value();
    m_tx_bd_cfg_s.dlycrcen     = m_regmodel.MODER.DLYCRCEN.get_mirrored_value();
    m_tx_bd_cfg_s.full_duplex  = m_regmodel.MODER.FULLD.get_mirrored_value();
    m_tx_bd_cfg_s.exdfren      = m_regmodel.MODER.EXDFREN.get_mirrored_value();
    m_tx_bd_cfg_s.nobackoff    = m_regmodel.MODER.NOBCKOF.get_mirrored_value();
    m_tx_bd_cfg_s.loopback     = m_regmodel.MODER.LOOPBCK.get_mirrored_value();
    m_tx_bd_cfg_s.no_pre       = m_regmodel.MODER.NOPRE.get_mirrored_value();

    //------------------------------------------
    // PACKETLEN
    //------------------------------------------
    m_regmodel.PACKETLEN.mirror(status, UVM_CHECK, UVM_BACKDOOR);


    m_tx_bd_cfg_s.minfl = m_regmodel.PACKETLEN.MINFL.get_mirrored_value();
    m_tx_bd_cfg_s.maxfl = m_regmodel.PACKETLEN.MAXFL.get_mirrored_value();

    //------------------------------------------
    // COLLCONF
    //------------------------------------------
    m_regmodel.COLLCONF.mirror(status, UVM_CHECK, UVM_BACKDOOR);

    m_tx_bd_cfg_s.maxret    = m_regmodel.COLLCONF.MAXRET.get_mirrored_value();
    m_tx_bd_cfg_s.collvalid = m_regmodel.COLLCONF.COLLVALID.get_mirrored_value();

    //------------------------------------------
    // TX_BD_NUM
    //------------------------------------------
    m_regmodel.TX_BD_NUM.mirror(status, UVM_CHECK, UVM_BACKDOOR);

    m_tx_bd_cfg_s.tx_bd_num = m_regmodel.TX_BD_NUM.TX_BD_NUM.get_mirrored_value();

    //------------------------------------------
    // TXCTRL
    //------------------------------------------
    m_regmodel.TXCTRL.mirror(status, UVM_CHECK, UVM_BACKDOOR);


    m_tx_bd_cfg_s.tx_pause_req = m_regmodel.TXCTRL.TXPAUSERQ.get_mirrored_value();
    m_tx_bd_cfg_s.tx_pause_tv  = m_regmodel.TXCTRL.TXPAUSETV.get_mirrored_value();

    
    //------------------------------------------
    // MAC_ADDR0
    //------------------------------------------
    m_regmodel.MAC_ADDR0.mirror(status, UVM_CHECK, UVM_BACKDOOR);


    m_tx_bd_cfg_s.mac_addr[31:24] = m_regmodel.MAC_ADDR0.BYTE2.get_mirrored_value();
    m_tx_bd_cfg_s.mac_addr[23:16] = m_regmodel.MAC_ADDR0.BYTE3.get_mirrored_value();
    m_tx_bd_cfg_s.mac_addr[15:8] = m_regmodel.MAC_ADDR0.BYTE4.get_mirrored_value();
    m_tx_bd_cfg_s.mac_addr[7:0]  = m_regmodel.MAC_ADDR0.BYTE5.get_mirrored_value();

    //------------------------------------------
    // MAC_ADDR1
    //------------------------------------------
    m_regmodel.MAC_ADDR1.mirror(status, UVM_CHECK, UVM_BACKDOOR);


    m_tx_bd_cfg_s.mac_addr[47:40] = m_regmodel.MAC_ADDR1.BYTE0.get_mirrored_value();
    m_tx_bd_cfg_s.mac_addr[39:32]   = m_regmodel.MAC_ADDR1.BYTE1.get_mirrored_value();
	  
	//------------------------------------------
    //CTRLMODER
    //------------------------------------------
	m_regmodel.CTRLMODER.mirror(status, UVM_CHECK, UVM_BACKDOOR);

	m_tx_bd_cfg_s.tx_flow = m_regmodel.CTRLMODER.TXFLOW.get_mirrored_value();

    //------------------------------------------
    // IPGT
    //------------------------------------------
    m_regmodel.IPGT.mirror(status, UVM_CHECK, UVM_BACKDOOR);

    m_tx_bd_cfg_s.ipgt = m_regmodel.IPGT.get_mirrored_value();

    //------------------------------------------
    // INT_MASK
    //------------------------------------------
    m_regmodel.INT_MASK.mirror(status, UVM_CHECK, UVM_BACKDOOR);


    m_tx_bd_cfg_s.txc_m = m_regmodel.INT_MASK.TXC_M.get_mirrored_value();
    m_tx_bd_cfg_s.txe_m = m_regmodel.INT_MASK.TXE_M.get_mirrored_value();
    m_tx_bd_cfg_s.txb_m = m_regmodel.INT_MASK.TXB_M.get_mirrored_value();

    //m_regmodel.PACKETLEN.print();
    //$display("Minfl = %d",m_tx_bd_cfg_s.minfl);
endtask





task eth_tx_scoreboard::pred_read_cfg_bd();
//------------------------------------------------------------------------------
// Read the currently armed TX Buffer Descriptor
//------------------------------------------------------------------------------
    uvm_status_e   status;
    uvm_reg_data_t data;

    int status_idx;
    int ptr_idx;
    bit [WB_DATA_WIDTH-1:0] rd_data;

    status_idx = m_tx_bd_cfg_s.bd_index * 2;
    ptr_idx    = status_idx + 1;

    //------------------------------------------
    // Read Status Word
    //------------------------------------------
    m_regmodel.eth_bd_mem.peek(
        status,
        status_idx,
        data
    );

    rd_data = bd_mem::read(status_idx);
    // Compare against software-written shadow copy
    if (data !== rd_data) begin
        `uvm_error(get_type_name(),
            $sformatf(
            "TX BD[%0d] STATUS mismatch\nRTL      = 0x%08h\nExpected = 0x%08h",
            m_tx_bd_cfg_s.bd_index,
            data,
            rd_data))
    end

    m_tx_bd_cfg_s.len     = data[31:16];
    m_tx_bd_cfg_s.rd      = data[15];
    m_tx_bd_cfg_s.irq     = data[14];
    m_tx_bd_cfg_s.wr      = data[13];
    m_tx_bd_cfg_s.pad_bd  = data[12];
    m_tx_bd_cfg_s.crc_bd  = data[11];

    //------------------------------------------
    // Read Pointer Word
    //------------------------------------------
    m_regmodel.eth_bd_mem.peek(
        status,
        ptr_idx,
        data
    );

    rd_data = bd_mem::read(ptr_idx);

    if (data !== rd_data) begin
        `uvm_error(get_type_name(),
            $sformatf(
            "TX BD[%0d] POINTER mismatch\nRTL      = 0x%08h\nExpected = 0x%08h",
            m_tx_bd_cfg_s.bd_index,
            data,
            rd_data))
    end

    m_tx_bd_cfg_s.txpnt = data;

    //------------------------------------------
    // Derived fields
    //------------------------------------------
    m_tx_bd_cfg_s.eff_pad = m_tx_bd_cfg_s.pad_bd | m_tx_bd_cfg_s.pad_moder;
    m_tx_bd_cfg_s.eff_crc = m_tx_bd_cfg_s.crc_bd | m_tx_bd_cfg_s.crcen;

    m_tx_bd_cfg_s.armed_time_ns = $time;

    //------------------------------------------
    // Debug
    //------------------------------------------
    `uvm_info(get_type_name(),
        $sformatf(
        "TX BD[%0d] LEN=%0d RD=%0b IRQ=%0b WR=%0b PAD=%0b CRC=%0b PTR=0x%08h",
        m_tx_bd_cfg_s.bd_index,
        m_tx_bd_cfg_s.len,
        m_tx_bd_cfg_s.rd,
        m_tx_bd_cfg_s.irq,
        m_tx_bd_cfg_s.wr,
        m_tx_bd_cfg_s.eff_pad,
        m_tx_bd_cfg_s.eff_crc,
        m_tx_bd_cfg_s.txpnt),
        UVM_MEDIUM)

endtask



task eth_tx_scoreboard::pred_defer();
    int i;
    forever
    begin
        // Conditions of starting deferral counter 
        // 1- Collision occurs and no backoff
        // 2- Retry limit is reached
        // 3- Carrier sense at beginning transmission of packet
        // 4- Carrier sense at IPGR1
        m_sem_tx_seq_item.get(1);
        // Collision conditions
        if (m_tx_bd_cfg_s.nobackoff && m_mii_tx_seq_item.MColl // 1
            || m_tx_expected_s.exp_rl)                         // 2                                                
        begin
            m_sem_tx_seq_item.put(1);
            #1;
            // Start counter
            for(i=0; i<ETH_EXCESS_DEFER_LIMIT; i++) begin
                m_sem_tx_seq_item.get(1);
                if(!m_mii_tx_seq_item.MColl) begin
                    m_sem_tx_seq_item.put(1);
                    break;
                end    
                m_sem_tx_seq_item.put(1);
                #ETH_PHY_TX_CLK_PERIOD_NS;
            end     
        end
        // Carrier sense conditions
        if (m_mii_tx_seq_item.MCrS && (m_tx_expected_s.exp_df||1))                         //3,4                                                
        begin
            m_sem_tx_seq_item.put(1);
            #1;
            // Start counter
            for(i=0; i<ETH_EXCESS_DEFER_LIMIT; i++) begin
                m_sem_tx_seq_item.get(1);
                if(!m_mii_tx_seq_item.MColl) begin
                    m_sem_tx_seq_item.put(1);
                    break;
                end    
                m_sem_tx_seq_item.put(1);
                #ETH_PHY_TX_CLK_PERIOD_NS;
            end     
        end
        // check if counter reaches excessive deferral limit
        if(i==ETH_EXCESS_DEFER_LIMIT)
            m_tx_pending_s.flag_abort=1;
        #1; 
    end    
endtask

task eth_tx_scoreboard::pred_coll();
    forever begin
        m_sem_tx_seq_item.get(1);
        if(m_mii_tx_seq_item.MColl) begin
            #0.1;
            // check if collision occurs after collsion window
            if(m_tx_pending_s.actual_pkt.size()>=m_tx_bd_cfg_s.collvalid)
                m_tx_expected_s.exp_lc=1;
        end    
        m_sem_tx_seq_item.put(1);
        #1;
    end
endtask

task eth_tx_scoreboard::comp_pack_pkt();

    bit [3:0] low_nibble;

    //--------------------------------------------------------
    // Wait for start of frame
    //--------------------------------------------------------
    forever begin
    m_sem_tx_seq_item.get(1);
    if(m_mii_tx_seq_item.MTxEN)
    break;
    m_sem_tx_seq_item.put(1); 
    #1ns;
    end
    `uvm_info(get_type_name(),"Comp_pack: MTXEN asserted",UVM_MEDIUM)
    //--------------------------------------------------------
    // Capture complete bytes
    //--------------------------------------------------------
    do begin
        //--------------------------------------------
        // if MTxErr is asserted raise flag
        //--------------------------------------------
       if (m_mii_tx_seq_item.MTxERR) begin
            m_tx_pending_s.flag_txerr=1;
       
        end
        //--------------------------------------------
        // In half duplex check if carrier sense dropped 
        //--------------------------------------------
       if (!m_tx_bd_cfg_s.full_duplex && !m_mii_tx_seq_item.MCrS) begin
            m_tx_expected_s.exp_cs=1;
       end
        //--------------------------------------------
        // First nibble (LSB)
        //--------------------------------------------
        low_nibble = m_mii_tx_seq_item.MTxD;
        //--------------------------------------------
        // Put key in semaphore then wait until it's
        // available
        //--------------------------------------------
        m_sem_tx_seq_item.put(1); 
        #1ns;
        m_sem_tx_seq_item.get(1);
        //--------------------------------------------
        // if MTxErr is asserted raise flag
        //--------------------------------------------
       if (m_mii_tx_seq_item.MTxERR) begin
            m_tx_pending_s.flag_txerr=1;
       end
        //--------------------------------------------
        // In half duplex check if carrier sense dropped 
        //--------------------------------------------
       if (!m_tx_bd_cfg_s.full_duplex && !m_mii_tx_seq_item.MCrS) begin
            m_tx_expected_s.exp_cs=1;
       end
        //--------------------------------------------
        // Expect second nibble
        //--------------------------------------------
        if (!m_mii_tx_seq_item.MTxEN) begin
            if(!m_tx_pending_s.flag_txerr) begin
            `uvm_error(get_type_name(),
                "MTxEN deasserted after only one nibble was transmitted")
            end
            break;
        end
        //--------------------------------------------
        // Store one byte
        //--------------------------------------------
        m_tx_pending_s.actual_pkt.push_back(
            {m_mii_tx_seq_item.MTxD, low_nibble}
        );
        //--------------------------------------------
        // Put key in semaphore then wait until it's
        // available
        //--------------------------------------------
        m_sem_tx_seq_item.put(1); 
        #1ns;
        m_sem_tx_seq_item.get(1);
    end
    while (m_mii_tx_seq_item.MTxEN);
    m_sem_tx_seq_item.put(1); 
    //--------------------------------------------------------
    // Frame completed
    //--------------------------------------------------------
    -> m_ev_start_comp;

    `uvm_info(get_type_name(),
        $sformatf("Captured %0d bytes from MII",
                  m_tx_pending_s.actual_pkt.size()),
        UVM_MEDIUM)

endtask



function void eth_tx_scoreboard::comp_compare_pkt();

    bit        error_found = 0;
    bit [15:0] type_len;
    int        idx;
    int        payload_len;
    int        pad_len;
	

    //----------------------------------------------------------
    // Compare packet size
    //----------------------------------------------------------
    if (m_tx_expected_s.exp_pkt.size() != m_tx_pending_s.actual_pkt.size()) 
		begin

        `uvm_error(get_type_name(),
            $sformatf("Packet size mismatch Expected=%0d Actual=%0d",
                m_tx_expected_s.exp_pkt.size(),
                m_tx_pending_s.actual_pkt.size()))

        return;
    end

    //----------------------------------------------------------
    // Preamble / SFD
    //----------------------------------------------------------
    idx = 0;

    if (!m_tx_bd_cfg_s.no_pre) 
	begin

        comp_compare_field("Preamble", idx, ETH_PREAMBLE_LEN, error_found);
        idx += ETH_PREAMBLE_LEN;
		
	end

        comp_compare_field("SFD", idx, ETH_SFD_LEN, error_found);
        idx += ETH_SFD_LEN;

    
    if(m_tx_expected_s.exp_pkt.size()-idx >= ETH_ADDR_LEN)
    begin
        //----------------------------------------------------------
        // Destination Address
        //----------------------------------------------------------
        comp_compare_field("Destination Address", idx, ETH_ADDR_LEN, error_found);
        idx += ETH_ADDR_LEN;
    end
   if(m_tx_expected_s.exp_pkt.size()-idx >= ETH_ADDR_LEN)
   begin
        //----------------------------------------------------------
        // Source Address
        //----------------------------------------------------------
        comp_compare_field("Source Address", idx, ETH_ADDR_LEN, error_found);
        idx += ETH_ADDR_LEN;
   end
   if(m_tx_expected_s.exp_pkt.size()-idx >= ETH_TYPE_LEN)
   begin
        //----------------------------------------------------------
        // Length / Type
        //----------------------------------------------------------
        comp_compare_field("Length/Type", idx, ETH_TYPE_LEN, error_found);
        idx += ETH_TYPE_LEN;
   end
    //----------------------------------------------------------
    // Pause frame
    //----------------------------------------------------------
    if (m_tx_bd_cfg_s.tx_pause_req && m_tx_bd_cfg_s.tx_flow) 
	begin

        comp_compare_field("Opcode", idx, ETH_PAUSE_OPCODE_LEN, error_found);
        idx += ETH_PAUSE_OPCODE_LEN;

        comp_compare_field("Pause Timer", idx, ETH_PAUSE_TIMER_LEN, error_found);
        idx += ETH_PAUSE_TIMER_LEN;

        comp_compare_field("Reserved", idx, ETH_PAUSE_RESERVED_LEN, error_found);
        idx += ETH_PAUSE_RESERVED_LEN;
        
        comp_compare_field("CRC",idx,ETH_CRC_LEN,error_found);
        idx += ETH_CRC_LEN;
    end

    //----------------------------------------------------------
    // Data frame
    //----------------------------------------------------------
    else 
	begin

        payload_len = m_tx_bd_cfg_s.len-ETH_ADDR_LEN*2-ETH_TYPE_LEN;
        if(payload_len < 0)
            payload_len=0;
        comp_compare_field("Payload",
                           idx,
                           payload_len,
                           error_found);

        idx += payload_len;

        //------------------------------------------------------
        // Optional padding
        //------------------------------------------------------
    if (m_tx_bd_cfg_s.eff_pad)
	begin

    int target_len;
    int frame_len;

    // Minimum frame length 
    target_len = m_tx_bd_cfg_s.minfl;

    // CRC occupies 4 bytes of MINFL
    if (m_tx_bd_cfg_s.eff_crc)
        target_len -= ETH_CRC_LEN;

    // Current frame length 
	//with preamble = preamble+ sfd+ DA + SA + Length/Type + Payload 
    //without preamble= sfd+ DA + SA + Length/Type + Payload
	if (!m_tx_bd_cfg_s.no_pre) 
    frame_len = ETH_SFD_LEN+ETH_PREAMBLE_LEN+ m_tx_bd_cfg_s.len;
	else
    frame_len = ETH_SFD_LEN+ m_tx_bd_cfg_s.len;


    if (frame_len < target_len) 
	begin

        pad_len = target_len - frame_len;

        comp_compare_field(
            "Padding",
            idx,
            pad_len,
            error_found);

        idx += pad_len;
    end

   end
    //----------------------------------------------------------
    // Optional CRC
    //----------------------------------------------------------
    if (m_tx_bd_cfg_s.eff_crc) begin

        comp_compare_field("CRC",
                           idx,
                           ETH_CRC_LEN,
                           error_found);

        idx += ETH_CRC_LEN;

    end
  end

    //----------------------------------------------------------
    // Final result
    //----------------------------------------------------------
    if (!error_found)
        `uvm_info(get_type_name(),
            $sformatf("Packet comparison PASSED (%0d bytes)",
                      m_tx_pending_s.actual_pkt.size()),
            UVM_LOW)
    else
        `uvm_error(get_type_name(),
            "Packet comparison FAILED")

endfunction



function void eth_tx_scoreboard::comp_check_txerr();
    // Txerror occurs when underrun occurs or packet length is greater than configured maximum value 
    m_tx_expected_s.exp_txerr= m_tx_expected_s.exp_huge | m_tx_expected_s.exp_ur;
    
    // Check if expected error is different than actual
    if(m_tx_pending_s.flag_txerr!=m_tx_expected_s.exp_txerr) begin
            `uvm_error(get_name(),
            $sformatf("Actual tx error isn't equal to expected,underrun error = %0b huge packet error = %0b actual error = %0b expected = %0b",
            m_tx_expected_s.exp_ur,m_tx_expected_s.exp_huge,m_tx_pending_s.flag_txerr,m_tx_expected_s.exp_txerr))
    end    
endfunction



task eth_tx_scoreboard::comp_check_interrupt();
        uvm_status_e   status;
        uvm_reg_data_t txe,txc,txb;        
       
        // Return if interrupt request is disabled in buffer dwscriptor
        if(!m_tx_bd_cfg_s.irq)
            return;

        // Check TXE interrupt, triggered if Tx error is asserted
        if (m_tx_bd_cfg_s.txe_m && (m_tx_expected_s.exp_ur || m_tx_expected_s.exp_lc || m_tx_expected_s.exp_rl || m_tx_expected_s.exp_cs)) begin
            // Put 1 in mirrored value
            m_regmodel.INT_SOURCE.TXE.predict(1);

            // Mirror to check DUT value = mirror value
	        m_regmodel.INT_SOURCE.TXE.mirror(status, UVM_CHECK, UVM_BACKDOOR);  

        end    
        // Check TXC interrupt & a ctrl frame is sent
        else if (m_tx_bd_cfg_s.txc_m && m_tx_bd_cfg_s.tx_pause_req && m_tx_bd_cfg_s.tx_flow) begin
            // Put 1 in mirrored value
            m_regmodel.INT_SOURCE.TXC.predict(1);

            // Mirror to check DUT value = mirror value
	        m_regmodel.INT_SOURCE.TXC.mirror(status, UVM_CHECK, UVM_BACKDOOR);  
                      
        end   
        // Else packet is transmitted successfully
        else if (m_tx_bd_cfg_s.txb_m) begin
            // Put 1 in mirrored value
            m_regmodel.INT_SOURCE.TXB.predict(1);
            // Mirror to check DUT value = mirror value
	        m_regmodel.INT_SOURCE.TXB.mirror(status, UVM_CHECK, UVM_BACKDOOR);     
        end 
        
        //Read 3 values from register file
        m_regmodel.INT_SOURCE.TXE.read(status,txe,UVM_BACKDOOR);  
        m_regmodel.INT_SOURCE.TXC.read(status,txc,UVM_BACKDOOR);  
        m_regmodel.INT_SOURCE.TXB.read(status,txb,UVM_BACKDOOR); 

        // check that only one interrupt fires in the 3
        if(!$onehot({txe[0],txc[0],txb[0]}) && (txe[0] || txc[0] || txb[0]))
         begin
            `uvm_error(get_name(),
            $sformatf("More than one Tx interrupt fired at the same time, TXE = %0b TXC = %0b TXB = %0b",txe,txc,txb))
        end
endtask



task eth_tx_scoreboard::comp_check_bd_status();
        uvm_status_e   status;
        uvm_reg_data_t bd_data;
        int status_idx; 
    //--------------------------------------------------------
    // Read current BD through backdoor
    //--------------------------------------------------------
    status_idx = m_tx_bd_cfg_s.bd_index * 2;
    m_regmodel.eth_bd_mem.peek(status,status_idx,bd_data);

    // check underrun expected equal actal
    if(bd_data[WB_TX_BD_UR_POS]!=m_tx_expected_s.exp_ur) begin
            `uvm_error(get_name(),$sformatf("Actual underrun error isn't equal to expected,actual error = %0b expected = %0b",
                bd_data[WB_TX_BD_UR_POS],m_tx_expected_s.exp_ur))
    end    

    // check RTRY count expected equal actal
    if(bd_data[WB_TX_RC_MSB_POS:WB_TX_RC_LSB_POS]!=m_tx_expected_s.exp_rtry) begin
            `uvm_error(get_name(),$sformatf("Actual Retry count  isn't equal to expected,actual  = %0b expected = %0b",
                bd_data[WB_TX_RC_MSB_POS:WB_TX_RC_LSB_POS],m_tx_expected_s.exp_rtry))
    end 

    // check Retransmission limit expected equal actal
    if(bd_data[WB_TX_RL_POS]!=m_tx_expected_s.exp_rl) begin
            `uvm_error(get_name(),$sformatf("Actual Retrnsmission limit  isn't equal to expected,actual  = %0b expected = %0b",
                bd_data[WB_TX_RL_POS],m_tx_expected_s.exp_rl))
    end     

    // check late collision expected equal actal
    if(bd_data[WB_TX_LC_POS]!=m_tx_expected_s.exp_lc) begin
            `uvm_error(get_name(),$sformatf("Actual Late collision  isn't equal to expected,actual  = %0b expected = %0b",
                bd_data[WB_TX_LC_POS],m_tx_expected_s.exp_lc))
    end 

    // check Deferral indication expected equal actal
    if(bd_data[WB_TX_DF_POS]!=m_tx_expected_s.exp_df) begin
            `uvm_error(get_name(),$sformatf("Actual Deferral indication  isn't equal to expected,actual  = %0b expected = %0b",
                bd_data[WB_TX_DF_POS],m_tx_expected_s.exp_df))
    end 

    // check Carrier sense lost expected equal actal
    if(bd_data[WB_TX_CS_POS]!=m_tx_expected_s.exp_cs) begin
            `uvm_error(get_name(),$sformatf("Actual Carrier sense lost count  isn't equal to expected,actual  = %0b expected = %0b",
                bd_data[WB_TX_CS_POS],m_tx_expected_s.exp_cs))
    end 

    // check if it's control frame
    if(m_tx_bd_cfg_s.tx_pause_req ==1 && m_tx_bd_cfg_s.tx_flow ==1) begin
        // update mirror value of pausereq with 0 because it is cleared after the frame is sent
        m_regmodel.TXCTRL.TXPAUSERQ.predict(0);
        // check that pausereq is cleared in dut register file
        m_regmodel.TXCTRL.TXPAUSERQ.mirror(status, UVM_CHECK, UVM_BACKDOOR);
    end
endtask



function void eth_tx_scoreboard::comp_compare_field(
    string field_name,
    int    start_idx,
    int    num_bytes,
    ref bit error_found
);

    for (int i = 0; i < num_bytes; i++) 
	begin

        if (m_tx_expected_s.exp_pkt[start_idx+i] !== m_tx_pending_s.actual_pkt[start_idx+i]) 
		begin

            error_found = 1;

            `uvm_error(get_type_name(),
                $sformatf(
                "%s mismatch Byte Index: %0d Field Offset: %0d\n Expected: 0x%02h\n Actual: 0x%02h",
                field_name,
                start_idx+i,
                i,
                m_tx_expected_s.exp_pkt[start_idx+i],
                m_tx_pending_s.actual_pkt[start_idx+i]))
        end

    end

endfunction



//------------------------------------------------------------------------------
// Measure Inter Packet Gap Time (IPGT)
//------------------------------------------------------------------------------
task eth_tx_scoreboard::comp_check_ipgt();

    static ipg_state_e state = WAIT_FIRST_FRAME;

    static bit prev_txen = 0;

    static int unsigned cycle_cnt = 0;

    //--------------------------------------------------------
    // Default values
    //--------------------------------------------------------
   m_tx_pending_s.ipgt_valid  = 0;
   m_tx_pending_s.ipgt_cycles = 0;
   
   forever 
   begin
   
    m_sem_tx_seq_item.get(1); 

    case(state)

    //--------------------------------------------------------
    // Wait for first frame
    //--------------------------------------------------------
    WAIT_FIRST_FRAME: begin

        if (!prev_txen && m_mii_tx_seq_item.MTxEN)
            state = WAIT_END_FRAME;
            
            m_tx_pending_s.ipgt_valid  = 0;

    end

    //--------------------------------------------------------
    // Wait for end of current frame
    //--------------------------------------------------------
    WAIT_END_FRAME: begin

        if (prev_txen && !m_mii_tx_seq_item.MTxEN) begin

             cycle_cnt = 1;      // First idle clock

            state = COUNT_IPGT;

            m_tx_pending_s.ipgt_valid  = 0;
        end

    end

    //--------------------------------------------------------
    // Count idle clocks
    //--------------------------------------------------------
    COUNT_IPGT: begin

        if (!m_mii_tx_seq_item.MTxEN) begin

            cycle_cnt++;

        end
        else if (!prev_txen && m_mii_tx_seq_item.MTxEN) begin
            int exp_cycles;
            m_tx_pending_s.ipgt_valid  = 1;
            m_tx_pending_s.ipgt_cycles = cycle_cnt;

            `uvm_info(get_type_name(),
                $sformatf("Measured IPGT = %0d MII clock cycles",
                          cycle_cnt),
                UVM_LOW)

            cycle_cnt = 0;

            state = WAIT_END_FRAME;
            
            //------------------------------------------------------
            // Calculate expected IPGT
            //------------------------------------------------------
            if (m_tx_bd_cfg_s.full_duplex)
                exp_cycles = m_tx_bd_cfg_s.ipgt + 6;
            else
                exp_cycles = m_tx_bd_cfg_s.ipgt + 3;

            //------------------------------------------------------
            // Compare
            //------------------------------------------------------
            if (m_tx_pending_s.ipgt_cycles < exp_cycles) begin

                `uvm_error(get_type_name(),
                    $sformatf(
                    "IPGT mismatch\n\
                    Mode           : %s\n\
                    Register IPGT  : 0x%02h\n\
                    Expected       : %0d MII cycles\n\
                    Measured       : %0d MII cycles",
                    m_tx_bd_cfg_s.full_duplex ? "Full Duplex" : "Half Duplex",
                    m_tx_bd_cfg_s.ipgt,
                    exp_cycles,
                    m_tx_pending_s.ipgt_cycles))

            end
            else  begin

                `uvm_info(get_type_name(),
                    $sformatf(
                    "IPGT PASS (%0d MII cycles)",
                    exp_cycles),
                    UVM_LOW)

            end
        end

    end

    endcase

    //--------------------------------------------------------
    // Save current TXEN
    //--------------------------------------------------------
    prev_txen = m_mii_tx_seq_item.MTxEN;
	 
   m_sem_tx_seq_item.put(1);
   #1ns;
	
  end	

endtask


task eth_tx_scoreboard::pred_check_jam_retry();

//------------------------------------------------------------------------------
// Check JAM sequence and retry limit after collision.
// IEEE802.3/OpenCores JAM = 0x99999999 = 8 nibbles of 0x9.
//------------------------------------------------------------------------------
// Collision handling:
// 1. PHY asserts MColl when collision is detected.
// 2. MAC transmits JAM pattern 
// 3. MAC retries after backoff.
// 4. After MAX_RETRY collisions, MAC aborts transmission.
//------------------------------------------------------------------------------

    int unsigned jam_cnt;
    int unsigned retry_cnt;

    jam_cnt   = 0;
    retry_cnt = 0;

    forever begin

        //--------------------------------------------------
        // Wait for a TX MII sample
        //--------------------------------------------------
        m_sem_tx_seq_item.get(1);

        //--------------------------------------------------
        // Collision detected while transmitting
        //--------------------------------------------------
        if (m_mii_tx_seq_item.MColl && m_mii_tx_seq_item.MTxEN)
        begin

            retry_cnt++;

            `uvm_info(get_type_name(),
                $sformatf(
                "Collision detected. Retry attempt = %0d",
                retry_cnt),
                UVM_MEDIUM)

            //--------------------------------------------------
            // Release current collision sample
            //--------------------------------------------------
            m_sem_tx_seq_item.put(1);
            #1ns

            //--------------------------------------------------
            // Check JAM sequence
            // MColl is ignored here because PHY may deassert
            // it while JAM is still transmitted.
            //--------------------------------------------------
            jam_cnt = 0;

            while (jam_cnt < ETH_JAM_NIBBLES)
            begin

                m_sem_tx_seq_item.get(1);

                if (m_mii_tx_seq_item.MTxD != ETH_JAM_PATTERN)
                begin

                    `uvm_error(get_type_name(),
                        $sformatf(
                        "Invalid JAM nibble at index %0d. Expected %0h, Got %0h",
                        jam_cnt,
                        ETH_JAM_PATTERN,
                        m_mii_tx_seq_item.MTxD))

                    m_sem_tx_seq_item.put(1);
					#1ns;

                    return;

                end
            

                jam_cnt++;

                m_sem_tx_seq_item.put(1);

                #1ns;

            end

            `uvm_info(get_type_name(),
                $sformatf(
                "Correct JAM sequence detected (%0d nibbles)",
                ETH_JAM_NIBBLES),
                UVM_MEDIUM)

            //--------------------------------------------------
            // Check retry limit
            //--------------------------------------------------
            if (retry_cnt >= m_tx_bd_cfg_s.maxret)
            begin

                //--------------------------------------------------
                // Wait for next TX state after JAM
                //--------------------------------------------------
                m_sem_tx_seq_item.get(1);

                if (m_mii_tx_seq_item.MTxEN)
                begin

                    `uvm_error(get_type_name(),
                        "MAC continued transmitting after retry limit")

                end
                else
                begin

                    `uvm_info(get_type_name(),
                        "Retry limit reached. Transmission aborted correctly",
                        UVM_MEDIUM)

                end

                m_sem_tx_seq_item.put(1);
				#1ns;

                return;

            end

            //--------------------------------------------------
            // Continue monitoring for next retry
            //--------------------------------------------------
            continue;

        end

        //--------------------------------------------------
        // Successful transmission completed
        // Retry counter belongs to one frame only.
        //--------------------------------------------------
        if (!m_tx_pending_s.flag_rd)
        begin

            retry_cnt = 0;

        end

        //--------------------------------------------------
        // Release TX sample
        //--------------------------------------------------
        m_sem_tx_seq_item.put(1);

        #1ns;

    end

endtask

//------------------------------------------------------------------------------
// Check IPGT/IPGR behavior including:
//  - Normal back-to-back IPGT
//  - Carrier sense defer
//  - Collision recovery IPGR
//------------------------------------------------------------------------------
task eth_tx_scoreboard::comp_check_ipg();

    static ipg_state_e ipg_state = WAIT_FIRST_FRAME;

    static bit ipg_prev_txen = 0;

    static int unsigned ipg_cnt = 0;

    //--------------------------------------------------
    // Default values
    //--------------------------------------------------
   m_tx_pending_s.ipgt_valid  = 0;
   m_tx_pending_s.ipgt_cycles = 0;
   m_tx_expected_s.exp_df = 0;
   m_tx_pending_s.collision_seen = 0;
   
   forever 
   begin
    m_sem_tx_seq_item.get(1); 
    
	case(ipg_state)

    //--------------------------------------------------
    // Wait first packet
    //--------------------------------------------------
    WAIT_FIRST_FRAME:
    begin

        if(! ipg_prev_txen && m_mii_tx_seq_item.MTxEN)
            ipg_state = WAIT_END_FRAME;

    end

    //--------------------------------------------------
    // Wait frame completion
    //--------------------------------------------------
    WAIT_END_FRAME:
    begin

        //--------------------------------------------------
        // Collision has priority
        //--------------------------------------------------
        if(m_mii_tx_seq_item.MColl && m_mii_tx_seq_item.MTxEN)
        begin

            m_tx_pending_s.collision_seen = 1;

            ipg_cnt = 0;

            ipg_state = WAIT_COLLISION_END;

        end

        else if( ipg_prev_txen && !m_mii_tx_seq_item.MTxEN)
        begin

            ipg_cnt = 1;      // First idle clock

            ipg_state = COUNT_IPGT;

        end

    end

    //--------------------------------------------------
    // Count IPGT
    //--------------------------------------------------
    COUNT_IPGT:
    begin

        //--------------------------------------------------
        // Collision during IPGT
        //--------------------------------------------------
        if(m_mii_tx_seq_item.MColl)
        begin

            ipg_cnt = 0;

            ipg_state = WAIT_COLLISION_END;

        end

        else
        begin

            ipg_cnt++;

            //--------------------------------------------------
            // IPGT completed
            //--------------------------------------------------
            if(ipg_cnt >= m_tx_bd_cfg_s.ipgt)
            begin

                //--------------------------------------------------
                // Medium idle
                //--------------------------------------------------
                if(!m_mii_tx_seq_item.MCrS)
                begin

                    m_tx_pending_s.ipgt_valid  = 1;

                    m_tx_pending_s.ipgt_cycles = ipg_cnt;

                    ipg_cnt = 0;

                    ipg_state= WAIT_END_FRAME;

                end

                //--------------------------------------------------
                // Carrier active -> DEFER
                //--------------------------------------------------
                else
                begin

                    m_tx_expected_s.exp_df = 1;

                    ipg_cnt = 0;

                    ipg_state = DEFER;

                end

            end

        end

    end

    //--------------------------------------------------
    // Wait carrier sense release
    //--------------------------------------------------
    DEFER:
    begin

        if(!m_mii_tx_seq_item.MCrS)
        begin

            ipg_cnt = 0;

            ipg_state = COUNT_IPGR1;

        end

    end

    //--------------------------------------------------
    // Collision recovery wait
    //--------------------------------------------------
    WAIT_COLLISION_END:
    begin

        //--------------------------------------------------
        // Collision finished and medium idle
        //--------------------------------------------------
        if(!m_mii_tx_seq_item.MColl && !m_mii_tx_seq_item.MCrS)
        begin

            ipg_cnt = 0;

            ipg_state = COUNT_IPGR1;

        end

    end

    //--------------------------------------------------
    // IPGR1 window
    //--------------------------------------------------
    COUNT_IPGR1:
    begin

        //--------------------------------------------------
        // Carrier appeared inside IPGR1
        //--------------------------------------------------
        if(m_mii_tx_seq_item.MCrS)
        begin

            ipg_cnt = 0;

            ipg_state = DEFER;

        end

        else
        begin

            ipg_cnt++;

            //--------------------------------------------------
            // Move to IPGR2
            //--------------------------------------------------
            if(ipg_cnt >= m_tx_bd_cfg_s.ipgr1)
            begin

                ipg_state = COUNT_IPGR2;

            end

        end

    end

    //--------------------------------------------------
    // IPGR2 window
    //--------------------------------------------------
    COUNT_IPGR2:
    begin

        ipg_cnt++;

        //--------------------------------------------------
        // Carrier here does NOT reset counter
        //--------------------------------------------------

        if(ipg_cnt >= m_tx_bd_cfg_s.ipgr2)
        begin

            if(m_mii_tx_seq_item.MTxEN)
            begin

                m_tx_pending_s.ipgr_valid  = 1;

                m_tx_pending_s.ipgr_cycles = ipg_cnt;

                ipg_cnt = 0;

                ipg_state = WAIT_END_FRAME;

            end

        end

    end

    endcase

    //--------------------------------------------------
    // Save previous TX enable
    //--------------------------------------------------
     ipg_prev_txen = m_mii_tx_seq_item.MTxEN;
	 m_sem_tx_seq_item.put(1);
   #1ns;
	
end
endtask










function void eth_tx_scoreboard::clear();
    //----------------------------------------------------------
    // Clear structs
    //----------------------------------------------------------  
    m_tx_bd_cfg_s        ='{default:'0,bd_index: m_tx_bd_cfg_s.bd_index};
    m_tx_expected_s      ='{default:'0,exp_pkt: {}};
    m_tx_pending_s       ='{default:'0,actual_pkt: {}};

endfunction



`endif // ETH_TX_SCOREBOARD_SV
