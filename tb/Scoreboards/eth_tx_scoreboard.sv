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
    // wb_m transaction for storing last item pulled from wb_m fifo
    wb_m_seq_item_base                              m_wb_m_seq_item;
    // mii_tx transaction for storing last item pulled from mii_tx fifo
    mii_tx_seq_item_base                            m_mii_tx_seq_item;
    // Register block
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

    extern task pred_track_txen();
    extern task pred_track_rd();
    extern task pred_track_underrun();
    extern task pred_read_mem();
    extern function pred_read_cfg();
    extern function pred_construct_data_pkt();
    extern function bit pred_construct_ctrl_pkt();
    extern function pred_add_pad();
    extern function pred_insert_pream();
    extern function pred_check_len_4();
    extern function pred_check_huge();
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
        begin 
            forever
                wait(txen.triggered) 
                    pred_read_pause_cfg();
                    if(!pred_construct_ctrl_pkt()) begin
                        pred_read_cfg();
                        if(pred_check_len_4)
                        pred_construct_data_pkt();
                
            end
            end
        end        
    join

endtask    

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

// function: pred_construct_ctrl_pkt();
function bit eth_tx_scoreboard::pred_construct_ctrl_pkt();
    // Check if pause request is asserted
    if(m_tx_bd_cfg_s.tx_pause_req && m_tx_bd_cfg_s.tx_flow) begin

        // push destination addr (6 bytes)
        for(int i = 5; i>=0; i--)
            m_tx_bd_cfg_s.m_exp_pkt.push_back(ETH_PAUSE_FRAME_ADDR[8*i+:8]);
        
        // push source addr (6 bytes)
        for(int i = 5; i>=0; i--)
            m_tx_bd_cfg_s.m_exp_pkt.push_back(m_tx_bd_cfg_s.mac_addr[8*i+:8]);
        
        // push lenth_type (2 bytes)
        m_tx_bd_cfg_s.m_exp_pkt.push_back(ETH_PAUSE_LEN_TYPE[15:8]);                // push most significant byte
        m_tx_bd_cfg_s.m_exp_pkt.push_back(ETH_PAUSE_LEN_TYPE[7:0]);                 // push least significant byte

        // push opcode (2 bytes)
        m_tx_bd_cfg_s.m_exp_pkt.push_back(ETH_PAUSE_OPCODE[15:8]);                  // push most significant byte
        m_tx_bd_cfg_s.m_exp_pkt.push_back(ETH_PAUSE_OPCODE[7:0]);                   // push least significant byte        

        // push timer value (2 bytes)
        m_tx_bd_cfg_s.m_exp_pkt.push_back(m_tx_bd_cfg_s.tx_pause_tv[15:8]);          // push most significant byte
        m_tx_bd_cfg_s.m_exp_pkt.push_back(m_tx_bd_cfg_s.tx_pause_tv[7:0]);           // push least significant byte 

        // Push padding bytes (42 byte)
        for(int i = 0; i<42; i++)
            m_tx_bd_cfg_s.m_exp_pkt.push_back(ETH_PAUSE_PAD);        
            
        // Calculate crc
            bit [31:0] crc;
            crc=pred_calc_crc32(m_tx_bd_cfg_s.m_exp_pkt);

        // push crc (4 bytes)
        for(int i = 3; i>=0; i--)
            m_tx_bd_cfg_s.m_exp_pkt.push_back(crc[8*i+:8]);

        // push Start of frame delimiter (1 byte)
        m_tx_bd_cfg_s.m_exp_pkt.push_front(ETH_SFD)

        // check if preamble is enabled
        if(!m_tx_bd_cfg_s.no_pre) begin
            // push preamble (7 bytes)
            for(int i = 0; i<7; i++)
                m_tx_bd_cfg_s.m_exp_pkt.push_front(ETH_PREAMBLE);
        end

        return 1;    
    end    
    else begin
        return 0;
    end
endfunction  


`endif // ETH_TX_SCOREBOARD_SV