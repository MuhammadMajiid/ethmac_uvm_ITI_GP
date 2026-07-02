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
    uvm_analysis_fifo  #(wb_m_seq_item_base)        wb_m_a_export;
    uvm_analysis_fifo  #(mii_tx_seq_item_base)      mii_tx_a_export;
    // =========================================================================
    // Transactions for storing last item pulled from tlm fifo
    // =========================================================================
    wb_m_seq_item_base                              m_wb_m_seq_item;
    mii_tx_seq_item_base                            m_mii_tx_seq_item;
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
    event m_ev_end_scoreboard;  // triggered when all tasks in scoreboard finish
    event m_ev_end_seqs;        // triggerd when all sequences finish
    event m_ev_txen;            // triggered when TXEN bit in MODER register changes from 0 to 1
    event m_ev_rd;              // triggered when RD bit in the current buffer descriptor changes from  0 to 1
    // =========================================================================
    // Structs
    // ========================================================================= 
    eth_tx_expected_s m_eth_tx_expected_s;
    eth_tx_bd_cfg_s   m_eth_tx_bd_cfg_s;

    // =========================================================================
    // Constructor, Build Phase, Connect phase and Run phase
    // =========================================================================
    extern function new(string name, uvm_component parent);
    extern function void build_phase(uvm_phase phase);
    extern function void connect_phase(uvm_phase phase);
    extern task run_phase(uvm_phase phase);
    // -------------------------------------------------------------------------
    //  task : predictor
    // -------------------------------------------------------------------------
    // Description:
    //   Implements golden model of tx, Construct packet and send it to
    //   comparartor.Detects collision, carrier sense errors like underrun and
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

    // Completed
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
    
    // Not Completed
    extern task pred_track_rd();
    extern task pred_track_underrun();
    extern task pred_read_cfg_reg();
    extern task pred_read_cfg_bd();
    // Compatator methods
    extern task comp_compare_pkts();
    extern task comp_pack_pkts();
    extern function void comp_check_crc(eth_tx_pending_record rec, int payload_len);
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

    // Build transactions
    m_mii_tx_seq_item  = mii_tx_seq_item_base::type_id::create("m_mii_tx_seq_item");
    m_wb_m_seq_item  = mii_tx_seq_item_base::type_id::create("m_wb_m_seq_item ");
    
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
        #0 comparartor();
        begin
        wait(m_ev_end_seqs.triggered);
        wait(m_ev_end_scoreboard.triggered)
        disable fork_run_phase;
        end    
    join    
    phase.drop_objection(this);
    `uvm_info(get_type_name(),"Tx scoreboard dropped objection", UVM_LOW)
endtask

// task: predictor
task predictor();

    fork: fork_pred
        pred_track_txen();
        pred_track_rd();
        pred_track_underrun(); 
            forever begin
                wait(m_ev_txen.triggered) 
                    pred_read_cfg_reg();
                    if(!m_tx_bd_cfg_s.tx_pause_req || !m_tx_bd_cfg_s.tx_flow) begin
                        pred_read_cfg_bd();
                        if(pred_check_len_4())
                        pred_construct_data_pkt();                
                    end
            end        
    join

endtask    

// function: pred_construct_data_pkt
function void eth_tx_scoreboard::pred_construct_data_pkt();
    // read data packts from dma memory
    pred_read_mem();
    
    // add padding bytes if required
    pred_add_pad();
    
    // Calculate crc
    bit [31:0] crc;
    crc=pred_calc_crc32(m_eth_tx_expected_s.exp_pkt);
    
    // push crc (4 bytes)
    for(int i = 3; i>=0; i--)
        m_eth_tx_expected_s.exp_pkt.push_back(crc[8*i+:8]);
    
    // check if the packet is greater than maximum size, discard additional bytes
    pred_check_huge();
    
    // add preamble and sfd to the beginning of packet
    pred_add_pream_sfd();
endfunction

// task: get_mii_tx_seq_item
task eth_tx_scoreboard::get_mii_tx_seq_item();
    // Get all keys from semaphore
    m_sem_tx_seq_item.get(SEM_TX_SEQ_ITEM_NO_KEYS);
    // Get transaction item from fifo
    mii_tx_fifo.get(m_mii_tx_seq_item);
    // Put all Keys in semaphore
    m_sem_tx_seq_item.put(SEM_TX_SEQ_ITEM_NO_KEYS);
endtask    

// task: get_wb_m_seq_item
task eth_tx_scoreboard::get_wb_m_seq_item();
    // Get all keys from semaphore
    m_sem_wb_m_seq_item.get(SEM_WB_M_SEQ_ITEM_NO_KEYS);
    // Get transaction item from fifo
    wb_m_fifo.get(m_wb_m_seq_item);
    // Put all Keys in semaphore
    m_sem_wb_m_seq_item.put(SEM_WB_M_SEQ_ITEM_NO_KEYS);
endtask    

// function: pred_construct_ctrl_pkt
function void eth_tx_scoreboard::pred_construct_ctrl_pkt();

        // push destination addr (6 bytes)
        for(int i = 5; i>=0; i--)
            m_eth_tx_expected_s.exp_pkt.push_back(ETH_PAUSE_FRAME_ADDR[8*i+:8]);
        
        // push source addr (6 bytes)
        for(int i = 5; i>=0; i--)
            m_eth_tx_expected_s.exp_pkt.push_back(m_tx_bd_cfg_s.mac_addr[8*i+:8]);
        
        // push lenth_type (2 bytes)
        m_eth_tx_expected_s.exp_pkt.push_back(ETH_PAUSE_LEN_TYPE[15:8]);                // push most significant byte
        m_eth_tx_expected_s.exp_pkt.push_back(ETH_PAUSE_LEN_TYPE[7:0]);                 // push least significant byte

        // push opcode (2 bytes)
        m_eth_tx_expected_s.exp_pkt.push_back(ETH_PAUSE_OPCODE[15:8]);                  // push most significant byte
        m_eth_tx_expected_s.exp_pkt.push_back(ETH_PAUSE_OPCODE[7:0]);                   // push least significant byte        

        // push timer value (2 bytes)
        m_eth_tx_expected_s.exp_pkt.push_back(m_tx_bd_cfg_s.tx_pause_tv[15:8]);          // push most significant byte
        m_eth_tx_expected_s.exp_pkt.push_back(m_tx_bd_cfg_s.tx_pause_tv[7:0]);           // push least significant byte 

        // Push padding bytes (42 byte)
        repeat(42)
            m_eth_tx_expected_s.exp_pkt.push_back(ETH_PAD);        
            
        // Calculate crc
            bit [31:0] crc;
            crc=pred_calc_crc32(m_eth_tx_expected_s.exp_pkt);

        // push crc (4 bytes)
        for(int i = 3; i>=0; i--)
            m_eth_tx_expected_s.exp_pkt.push_back(crc[8*i+:8]);

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

    if(!dma_mem::read(txpnt,rd_data))
        `uvm_fatal(get_name(), $sformatf("Buffer descriptor number %0d Txpnt value doesn't exist in dma memory, txpnt = %0h, buffer",m_tx_bd_cfg_s.bd_index,txpnt))
        

    for (int unsigned i =0; i<len;i++) begin
        // Read each word from memory
        if(!dma_mem::read(txpnt+i*4,rd_data)) begin
            `uvm_fatal(get_name(), $sformatf("Buffer descriptor number %0d address doesn't exist in dma memory, address = %0h, buffer",m_tx_bd_cfg_s.bd_index,txpnt+i*4))
        end
        else begin
            // push word in expected packet queue
            for(int i = 3; i>=0; i--)
                m_eth_tx_expected_s.exp_pkt.push_back(rd_data[8*i+:8]);
        end
    end    

endfunction

// function: insert_pream_sfd
function void eth_tx_scoreboard::pred_add_pream_sfd();

    // push Start of frame delimiter (1 byte)
    m_eth_tx_expected_s.exp_pkt.push_front(ETH_SFD)

    // check if preamble is enabled
    if(!m_tx_bd_cfg_s.no_pre) begin
        // push preamble (7 bytes)
        repeat(7)
            m_eth_tx_expected_s.exp_pkt.push_front(ETH_PREAMBLE);
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
            m_tx_bd_cfg_s.exp_pop_back();
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

    // Length that should exist before CRC insertion
    target_len = m_tx_bd_cfg_s.minfl;

    if (m_tx_bd_cfg_s.eff_crc)
        target_len -= 4;

    if (m_eth_tx_expected_s.exp_pkt.size() >= target_len)
        return;

    pad_bytes = target_len - m_eth_tx_expected_s.exp_pkt.size();

    repeat (pad_bytes)
        m_eth_tx_expected_s.exp_pkt.push_back(ETH_PAD);

    `uvm_info(get_type_name(),
        $sformatf("Added %0d padding bytes (frame length = %0d)",
                  pad_bytes,
                  m_eth_tx_expected_s.exp_pkt.size()),
        UVM_LOW)

endfunction

`endif // ETH_TX_SCOREBOARD_SV