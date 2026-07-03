//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_tx_scoreboard.sv
// Author   : Wael
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
    parameter SEM_TX_SEQ_ITEM_NO_KEYS = 2;
    parameter SEM_WB_M_SEQ_ITEM_NO_KEYS = 1;

    // =========================================================================
    // Analysis fifos — one for wishbone master, one for MII TX
    // =========================================================================
    uvm_analysis_fifo  #(wb_m_seq_item_base)        wb_m_fifo;
    uvm_analysis_fifo  #(mii_tx_seq_item_base)      mii_tx_fifo;
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
    // Register block
    // =========================================================================
    eth_reg_block                                   m_regmodel;
    //---------------------------------------------------------------------------
    // Predictor shadow copy of BD memory
    //---------------------------------------------------------------------------
     bit [WB_DATA_WIDTH-1:0] m_bd_shadow [WB_BD_MEM_DEPTH];    
    // =========================================================================
    // Semaphores
    // =========================================================================
    semaphore m_sem_tx_seq_item; // for getting mii tx transaction from fifo
    semaphore m_sem_wb_m_seq_item; // for getting wb master transaction from fifo
    // =========================================================================
    // Events
    // =========================================================================    
    event m_ev_end_scoreboard;  // triggered when all tasks in scoreboard finish
    event m_ev_end_seqs;        // triggerd when all sequences finish
    event m_ev_txen;            // triggered when TXEN bit in MODER register changes from 0 to 1
    event m_ev_rd;              // triggered when RD bit in the current buffer descriptor changes from  0 to 1
    event m_ev_start_comp;      // triggered when packet ends to start comparison
    // =========================================================================
    // Structs
    // ========================================================================= 
    eth_tx_expected_s m_tx_expected_s;
    eth_tx_bd_cfg_s   m_tx_bd_cfg_s;
    eth_tx_pending_s  m_tx_pending_s;
    // =========================================================================
    // Flags
    // ========================================================================= 
    bit m_flag_txerr;           // set when Tx error is asserted 
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
    //  function : pred_track_txen
    // -------------------------------------------------------------------------
    // Description:
    //   always check txen bit in register model and when it rises to high, 
    //   trigger event m_ev_txen. 
    // Arguments: None
    //
    // -------------------------------------------------------------------------     
    extern task pred_track_txen();    
    

    extern task pred_track_rd();
    extern task pred_track_underrun();
    extern task pred_read_cfg_reg();
    extern task pred_read_cfg_bd();
    // =============================================================================
    //  Compatator methods
    // =============================================================================    
    extern task comp_pack_pkt();
    //extern function void comp_compare_pkt();
    extern function void comp_check_txerr();
    extern task comp_check_interrupt();
    extern task comp_check_bd_status();
    extern function void comp_compare_field(string field_name,int start_idx,int num_bytes,ref bit error_found);
    extern function void clear();
endclass : eth_tx_scoreboard

// =============================================================================
//  IMPLEMENTATION
// =============================================================================

// function: new
function eth_tx_scoreboard::new(string name, uvm_component parent);
    super.new(name, parent);
endfunction


// function: build_phase
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

    // Build transactions
    m_mii_tx_seq_item  = mii_tx_seq_item_base::type_id::create("m_mii_tx_seq_item");
    m_wb_m_seq_item    = wb_m_seq_item_base::type_id::create("m_wb_m_seq_item ");
    
    // Creating semaphore objects
    m_sem_tx_seq_item=new(SEM_TX_SEQ_ITEM_NO_KEYS);
    m_sem_wb_m_seq_item=new(SEM_WB_M_SEQ_ITEM_NO_KEYS);
endfunction

// function: connect_phase
function void eth_tx_scoreboard::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // Connect each export with it's corrosponding fifo
    wb_m_a_export.connect(wb_m_fifo.analysis_export);
    mii_tx_a_export.connect(mii_tx_fifo.analysis_export);
endfunction    

// task: run_phase
task eth_tx_scoreboard::run_phase(uvm_phase phase);
    super.run_phase(phase);
    phase.raise_objection(this);
    `uvm_info(get_type_name(),"Tx scoreboard raised objection", UVM_LOW)
    fork: fork_run_phase 
        get_mii_tx_seq_item();
        get_wb_m_seq_item();
        #0 predictor();
        #0 comparator();
        begin
        wait(m_ev_end_seqs.triggered);
        wait(m_ev_end_scoreboard.triggered);
        disable fork_run_phase;
        end    
    join    
    phase.drop_objection(this);
    `uvm_info(get_type_name(),"Tx scoreboard dropped objection", UVM_LOW)
endtask


// function: write
function void eth_tx_scoreboard::write( wb_s_seq_item_base#(WB_S_ADDR_WIDTH, WB_DATA_WIDTH,WB_SEL_WIDTH ) tr);
//------------------------------------------------------------------------------
// Receives every WB slave transaction.
// Maintains a predictor copy of the BD memory.
//------------------------------------------------------------------------------
    int mem_idx;

    //-------------------------------------------------------
    // Ignore reads
    //-------------------------------------------------------
    if (!tr.we)
        return;

    //-------------------------------------------------------
    // Is this transaction targeting BD memory?
    //
    // BD memory occupies:
    // 10'h100 -> 10'h1FF
    //-------------------------------------------------------
    if (tr.addr[9:8] == 2'b01) begin

        mem_idx = tr.addr[7:0];

        m_bd_shadow[mem_idx] = tr.data;

        `uvm_info(get_type_name(),
            $sformatf(
            "BD_MEM[%0d] <= 0x%08h",
            mem_idx,
            tr.data),
            UVM_HIGH)

    end

endfunction

// task: get_mii_tx_seq_item
task eth_tx_scoreboard::get_mii_tx_seq_item();
    // Get all keys from semaphore
    repeat(SEM_TX_SEQ_ITEM_NO_KEYS)
    m_sem_tx_seq_item.get(1);
    // Get transaction item from fifo
    mii_tx_fifo.get(m_mii_tx_seq_item);
    // Put all Keys in semaphore
    m_sem_tx_seq_item.put(SEM_TX_SEQ_ITEM_NO_KEYS);
endtask    

// task: get_wb_m_seq_item
task eth_tx_scoreboard::get_wb_m_seq_item();
    // Get all keys from semaphore
    repeat(SEM_WB_M_SEQ_ITEM_NO_KEYS)
    m_sem_wb_m_seq_item.get(1);
    // Get transaction item from fifo
    wb_m_fifo.get(m_wb_m_seq_item);
    // Put all Keys in semaphore
    m_sem_wb_m_seq_item.put(SEM_WB_M_SEQ_ITEM_NO_KEYS);
endtask 

// task: predictor
task eth_tx_scoreboard::predictor();

    fork: fork_pred
        pred_track_txen();
        pred_track_rd();
        pred_track_underrun(); 
            forever begin
                wait(m_ev_txen.triggered) ;
                    pred_read_cfg_reg();
                    if(!m_tx_bd_cfg_s.tx_pause_req || !m_tx_bd_cfg_s.tx_flow) begin
                        pred_read_cfg_bd();
                        if(pred_check_len_4())
                        pred_construct_data_pkt();                
                    end
            end        
    join

endtask    

// task: comparator
task eth_tx_scoreboard::comparator();
   forever begin
    fork : fork_comp
    comp_pack_pkt();
    begin
        wait(m_ev_start_comp);
        comp_compare_pkt();
        comp_check_txerr();
        comp_check_interrupt();
        comp_check_bd_status();
        (-> m_ev_end_scoreboard);
        disable fork_comp;
    end    
    join     
end 
endtask

// function: pred_construct_data_pkt
function void eth_tx_scoreboard::pred_construct_data_pkt();
    bit [31:0] crc;
    // read data packts from dma memory
    pred_read_mem();
    
    // add padding bytes if required
    pred_add_pad();
    
    // check if crc is enabled 
    if (m_tx_bd_cfg_s.eff_crc) begin
        // Calculate crc
        crc=calc_crc32(m_tx_expected_s.exp_pkt);
        
        // push crc (4 bytes)
        for(int i = 3; i>=0; i--)
            m_tx_expected_s.exp_pkt.push_back(crc[8*i+:8]);
    end
    // check if the packet is greater than maximum size, discard additional bytes
    pred_check_huge();
    
    // add preamble and sfd to the beginning of packet
    pred_add_pream_sfd();
endfunction   

// function: pred_construct_ctrl_pkt
function void eth_tx_scoreboard::pred_construct_ctrl_pkt();
        bit [31:0] crc;
        // push destination addr (6 bytes)
        for(int i = 5; i>=0; i--)
            m_tx_expected_s.exp_pkt.push_back(ETH_PAUSE_FRAME_ADDR[8*i+:8]);
        
        // push source addr (6 bytes)
        for(int i = 5; i>=0; i--)
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
        for(int i = 3; i>=0; i--)
            m_tx_expected_s.exp_pkt.push_back(crc[8*i+:8]);

        // add preamble (7 bytes) & SFD (1 byte)     
        pred_add_pream_sfd();

endfunction  

// function: pred_read_mem 
function void eth_tx_scoreboard::pred_read_mem();
    // length of packet in BD
    bit [15:0] len =  m_tx_bd_cfg_s.len;
    // base address of packet
    bit [31:0] txpnt =  m_tx_bd_cfg_s.txpnt;
    // Read data from dma memory (4 bytes)
    bit [31:0] rd_data;

    // Check that txpnt value exists in memory
    if(!dma_mem::read(txpnt,rd_data))
        `uvm_fatal(get_name(), $sformatf("Buffer descriptor number %0d Txpnt value doesn't exist in dma memory, txpnt = %0h",m_tx_bd_cfg_s.bd_index,txpnt))
    
    // Check that length is divisble by 4
    if(len%4!=0)
        `uvm_fatal(get_name(), $sformatf("Buffer descriptor number %0d Packet length isn't divisible by 4, length = %0d",m_tx_bd_cfg_s.bd_index,len))
            

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

endfunction

// function: insert_pream_sfd
function void eth_tx_scoreboard::pred_add_pream_sfd();

    // push Start of frame delimiter (1 byte)
    m_tx_expected_s.exp_pkt.push_front(ETH_SFD);

    // check if preamble is enabled
    if(!m_tx_bd_cfg_s.no_pre) begin
        // push preamble (7 bytes)
        repeat(7)
            m_tx_expected_s.exp_pkt.push_front(ETH_PREAMBLE);
    end  

endfunction    

// function: pred_check_huge
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
        int unsigned discarded_bytes=m_tx_bd_cfg_s.len - m_tx_bd_cfg_s.maxfl;
        // pop number of discarded bytes from back of queue
        for (int unsigned i =0;i<discarded_bytes;i++)
            m_tx_expected_s.exp_pkt.pop_back();
            
        // Set huge error flag    
        m_tx_expected_s.exp_huge=1;    
    end
endfunction

// function: pred_track_txen
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

// task: pred_track_rd
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

    m_regmodel.WB_TX_BD_mem.peek(
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
        m_regmodel.WB_TX_BD_mem.peek(
            status,
            status_idx,
            rtl_data
        );

        curr_rd  = rtl_data[WB_TX_BD_RD_POS];
        wrap_bit = rtl_data[WB_TX_BD_WR_POS];

        //--------------------------------------------------------
        // Software armed this BD (RD : 0 -> 1)
        //--------------------------------------------------------
        if (!prev_rd && curr_rd) begin

            `uvm_info(get_type_name(),
                $sformatf("TX BD[%0d] armed",
                          m_tx_bd_cfg_s.bd_index),
                UVM_MEDIUM)

            -> m_ev_rd;

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
            if (wrap_bit)
                m_tx_bd_cfg_s.bd_index = 0;
            else
                m_tx_bd_cfg_s.bd_index++;

            //----------------------------------------------------
            // Initialize prev_rd for the new BD
            //----------------------------------------------------
            status_idx = m_tx_bd_cfg_s.bd_index * 2;

            m_regmodel.WB_TX_BD_mem.peek(
                status,
                status_idx,
                rtl_data
            );

            prev_rd = rtl_data[WB_TX_BD_RD_POS];

            continue;
        end

        //--------------------------------------------------------
        // Update previous RD
        //--------------------------------------------------------
        prev_rd = curr_rd;

        #1ns;

    end

endtask

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


    int target_len;
    int pad_bytes;

    // No padding required
    if (!m_tx_bd_cfg_s.eff_pad)
        return;

    // Length that should exist before CRC insertion (4 bytes) & preamble & SFD (8 bytes)
    target_len = m_tx_bd_cfg_s.minfl-8-4;

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
    m_tx_bd_cfg_s.ifg          = m_regmodel.MODER.IFG.get_mirrored_value();
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


    m_tx_bd_cfg_s.mac_addr[39:32] = m_regmodel.MAC_ADDR0.BYTE2.get_mirrored_value();
    m_tx_bd_cfg_s.mac_addr[31:24] = m_regmodel.MAC_ADDR0.BYTE3.get_mirrored_value();
    m_tx_bd_cfg_s.mac_addr[23:16] = m_regmodel.MAC_ADDR0.BYTE4.get_mirrored_value();
    m_tx_bd_cfg_s.mac_addr[15:8]  = m_regmodel.MAC_ADDR0.BYTE5.get_mirrored_value();

    //------------------------------------------
    // MAC_ADDR1
    //------------------------------------------
    m_regmodel.MAC_ADDR1.mirror(status, UVM_CHECK, UVM_BACKDOOR);


    m_tx_bd_cfg_s.mac_addr[47:40] = m_regmodel.MAC_ADDR1.BYTE0.get_mirrored_value();
    m_tx_bd_cfg_s.mac_addr[7:0]   = m_regmodel.MAC_ADDR1.BYTE1.get_mirrored_value();
	  
	//------------------------------------------
    //CTRLMODER
    //------------------------------------------
	m_regmodel.CTRLMODER.mirror(status, UVM_CHECK, UVM_BACKDOOR);

	m_tx_bd_cfg_s.tx_flow = m_regmodel.CTRLMODER.TXFLOW.get_mirrored_value();

    //------------------------------------------
    // INT_MASK
    //------------------------------------------
    m_regmodel.INT_MASK.mirror(status, UVM_CHECK, UVM_BACKDOOR);


    m_tx_bd_cfg_s.txc_m = m_regmodel.INT_MASK.TXC_M.get_mirrored_value();
    m_tx_bd_cfg_s.txe_m = m_regmodel.INT_MASK.TXE_M.get_mirrored_value();
    m_tx_bd_cfg_s.txb_m = m_regmodel.INT_MASK.TXB_M.get_mirrored_value();


endtask



task eth_tx_scoreboard::pred_read_cfg_bd();
//------------------------------------------------------------------------------
// Read the currently armed TX Buffer Descriptor
//------------------------------------------------------------------------------
    uvm_status_e   status;
    uvm_reg_data_t data;

    int status_idx;
    int ptr_idx;

    status_idx = m_tx_bd_cfg_s.bd_index * 2;
    ptr_idx    = status_idx + 1;

    //------------------------------------------
    // Read Status Word
    //------------------------------------------
    m_regmodel.WB_TX_BD_mem.peek(
        status,
        status_idx,
        data
    );

    // Compare against software-written shadow copy
    if (data !== m_bd_shadow[status_idx]) begin
        `uvm_error(get_type_name(),
            $sformatf(
            "TX BD[%0d] STATUS mismatch\nRTL      = 0x%08h\nExpected = 0x%08h",
            m_tx_bd_cfg_s.bd_index,
            data,
            m_bd_shadow[status_idx]))
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
    m_regmodel.WB_TX_BD_mem.peek(
        status,
        ptr_idx,
        data
    );

    if (data !== m_bd_shadow[ptr_idx]) begin
        `uvm_error(get_type_name(),
            $sformatf(
            "TX BD[%0d] POINTER mismatch\nRTL      = 0x%08h\nExpected = 0x%08h",
            m_tx_bd_cfg_s.bd_index,
            data,
            m_bd_shadow[ptr_idx]))
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

task eth_tx_scoreboard::comp_check_interrupt();
        uvm_status_e   status;
        uvm_reg_data_t txe,txc,txb;        
       

        // Check TXE interrupt, triggered if Tx error is asserted
        if (m_tx_bd_cfg_s.txe_m==1 && m_tx_expected_s.exp_txerr ==1) begin
            // Put 1 in mirrored value
            m_regmodel.INT_SOURCE.TXE.predict(1);

            // Mirror to check DUT value = mirror value
	        m_regmodel.INT_SOURCE.TXE.mirror(status, UVM_CHECK, UVM_BACKDOOR);  

        end    
        // Check TXC interrupt & a ctrl frame is sent
        if (m_tx_bd_cfg_s.txc_m==1 && m_tx_bd_cfg_s.tx_pause_req ==1 && m_tx_bd_cfg_s.tx_flow ==1) begin
            // Put 1 in mirrored value
            m_regmodel.INT_SOURCE.TXC.predict(1);

            // Mirror to check DUT value = mirror value
	        m_regmodel.INT_SOURCE.TXC.mirror(status, UVM_CHECK, UVM_BACKDOOR);  
                      
        end   
        // Else packet is transmitted successfully
        else begin
            // Put 1 in mirrored value
            m_regmodel.INT_SOURCE.TXB.predict(1);

            // Mirror to check DUT value = mirror value
	        m_regmodel.INT_SOURCE.TXB.mirror(status, UVM_CHECK, UVM_BACKDOOR);     
        end

        //Read 3 values from register file
        m_regmodel.INT_SOURCE.TXE_E.read(status,txe,UVM_BACKDOOR);  
        m_regmodel.INT_SOURCE.TXC_E.read(status,txc,UVM_BACKDOOR);  
        m_regmodel.INT_SOURCE.TXB_E.read(status,txb,UVM_BACKDOOR) ; 

        // check that only one interrupt fires in the 3
        assert($onehot({txe[0],txc[0],txb[0]}))
        else begin
            `uvm_error(get_name(),
            $sformatf("More than one Tx interrupt fired at the same time, TXE = %0b TXC = %0b TXB = %0b",txe,txc,txb))
        end
endtask

// task: comp_check_bd_status
task eth_tx_scoreboard::comp_check_bd_status();
        uvm_status_e   status;
        uvm_reg_data_t bd_data;
        int status_idx; 
    //--------------------------------------------------------
    // Read current BD through backdoor
    //--------------------------------------------------------
    status_idx = m_tx_bd_cfg_s.bd_index * 2;
    m_regmodel.WB_TX_BD_mem.peek(status,status_idx,bd_data);

    // check that underrun actual error equal actal
    if(bd_data[WB_TX_BD_UR_POS]!=m_tx_expected_s.exp_ur) begin
            `uvm_error(get_name(),$sformatf("Actual underrun error isn't equal to expected,actual error = %0b expected = %0b",
                bd_data[WB_TX_BD_UR_POS],m_tx_expected_s.exp_ur))
    end    

endtask

// function: comp_check_txerr
function void eth_tx_scoreboard::comp_check_txerr();
    // Txerror occurs when underrun occurs or packet length is greater than configured maximum value 
    m_tx_expected_s.exp_txerr= m_tx_expected_s.exp_huge | m_tx_expected_s.exp_ur;
    
    // Check if expected error is different than actual
    if(m_flag_txerr!=m_tx_expected_s.exp_txerr) begin
            `uvm_error(get_name(),
            $sformatf("Actual tx error isn't equal to expected,underrun error = %0b huge packet error = %0b actual error = %0b expected = %0b",
            m_tx_expected_s.exp_ur,m_tx_expected_s.exp_huge,m_flag_txerr,m_tx_expected_s.exp_txerr))
    end    
endfunction

// task: comp_pack_pkt
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
    //--------------------------------------------------------
    // Capture complete bytes
    //--------------------------------------------------------
    do begin
        //--------------------------------------------
        // Put key in semaphore then wait until it's
        // available
        //--------------------------------------------
        m_sem_tx_seq_item.put(1); 
        #1ns;
        m_sem_tx_seq_item.get(1);
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
            m_flag_txerr=1;
       end
        //--------------------------------------------
        // Expect second nibble
        //--------------------------------------------
        if (!m_mii_tx_seq_item.MTxEN) begin
            `uvm_error(get_type_name(),
                "MTxEN deasserted after only one nibble was transmitted")
            break;
        end
        //--------------------------------------------
        // Store one byte
        //--------------------------------------------
        m_tx_pending_s.actual_pkt.push_back(
            {m_mii_tx_seq_item.MTxD, low_nibble}
        );

    end
    while (m_mii_tx_seq_item.MTxEN);

    //--------------------------------------------------------
    // Frame completed
    //--------------------------------------------------------
    -> m_ev_start_comp;

    `uvm_info(get_type_name(),
        $sformatf("Captured %0d bytes from MII",
                  m_tx_pending_s.actual_pkt.size()),
        UVM_MEDIUM)

endtask

// function: comp_compare_field
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
                "%s mismatch\n" +
                "Byte Index : %0d\n" +
                "Field Offset : %0d\n" +
                "Expected : 0x%02h\n" +
                "Actual   : 0x%02h",
                field_name,
                start_idx+i,
                i,
                m_tx_expected_s.exp_pkt[start_idx+i],
                m_tx_pending_s.actual_pkt[start_idx+i]))
        end

    end

endfunction
/*
// function: comp_compare_pkt
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

        comp_compare_field("Preamble", idx, 7, error_found);
        idx += 7;
		
	end

        comp_compare_field("SFD", idx, 1, error_found);
        idx += 1;

    

    //----------------------------------------------------------
    // Destination Address
    //----------------------------------------------------------
    comp_compare_field("Destination Address", idx, 6, error_found);
    idx += 6;

    //----------------------------------------------------------
    // Source Address
    //----------------------------------------------------------
    comp_compare_field("Source Address", idx, 6, error_found);
    idx += 6;

    //----------------------------------------------------------
    // Length / Type
    //----------------------------------------------------------
    comp_compare_field("Length/Type", idx, 2, error_found);

    type_len = {
        m_tx_expected_s.exp_pkt[idx],
        m_tx_expected_s.exp_pkt[idx+1]
    };

    idx += 2;

    //----------------------------------------------------------
    // Pause frame
    //----------------------------------------------------------
    if (type_len == 16'h8808) 
	begin

        comp_compare_field("Opcode", idx, 2, error_found);
        idx += 2;

        comp_compare_field("Pause Timer", idx, 2, error_found);
        idx += 2;

        comp_compare_field("Reserved", idx, 42, error_found);
        idx += 42;

    end

    //----------------------------------------------------------
    // Data frame
    //----------------------------------------------------------
    else 
	begin

        payload_len = m_tx_bd_cfg_s.len;

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
    int frame_len_no_preamble;

    // Minimum frame length excluding preamble/SFD
    target_len = m_tx_bd_cfg_s.minfl;

    // CRC occupies 4 bytes of MINFL
    if (m_tx_bd_cfg_s.eff_crc)
        target_len -= 4;

    // Current frame length excluding preamble/SFD, 
    // = DA + SA + Length/Type + Payload
	
    frame_len = 6 + 6 + 2 + payload_len;


    if (frame_len_no_preamble < target_len) 
	begin

        pad_len = target_len - frame_len_no_preamble;

        comp_compare_field(
            "Padding",
            idx,
            pad_len,
            error_found);

        idx += pad_len;
    end

   end

  end

    //----------------------------------------------------------
    // Optional CRC
    //----------------------------------------------------------
    if (m_tx_bd_cfg_s.eff_crc) begin

        comp_compare_field("CRC",
                           idx,
                           4,
                           error_found);

        idx += 4;

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
*/
// function clear
function void eth_tx_scoreboard::clear();

    //----------------------------------------------------------
    // Clear flags
    //----------------------------------------------------------    
    m_flag_txerr=0;
    //----------------------------------------------------------
    // Clear structs
    //----------------------------------------------------------  
    m_tx_bd_cfg_s        ='{default:'0};
    m_tx_expected_s      ='{default:'0};
    m_tx_pending_s       ='{default:'0};

endfunction

`endif // ETH_TX_SCOREBOARD_SV