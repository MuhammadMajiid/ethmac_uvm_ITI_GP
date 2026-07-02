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

    event m_ev_txen; // triggered when TXEN bit in MODER register changes from 0 to 1
    event m_ev_rd; // triggered when RD bit in the current buffer descriptor changes from  0 to 1
    // =========================================================================
    // Structs
    // ========================================================================= 
    eth_tx_expected_s m_eth_tx_expected_s;


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
    //   huge packet.   
    // Arguments: None
    //
    // -------------------------------------------------------------------------    
    extern task comparator();

    extern task get_mii_tx_seq_item();
    extern task get_wb_m_seq_item();
    
    extern task pred_track_txen();
    extern task pred_track_rd();
    extern task pred_track_underrun();
    extern task pred_read_mem();
    extern function pred_read_cfg_rg();
	extern function pred_read_cfg_bd();
    extern function pred_construct_data_pkt();
    extern function pred_construct_ctrl_pkt();
    extern function pred_add_pad();
    extern function pred_insert_pream();
    extern function pred_check_len_4();
    extern function pred_check_huge();
    extern task comp_compare_pkts();
    extern task comp_pack_pkts();
    extern function logic [31:0] pred_calc_crc32(byte data[], int len);
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
    forever begin
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
   end
endtask


task eth_tx_scoreboard::predictor();

    fork
        pred_track_txen();        // Generates m_ev_txen
        pred_track_rd();          // Generates m_ev_rd
        pred_track_underrun();

        begin

            // Wait until transmitter is enabled
            wait(m_ev_txen.triggered);

            // Read all global configuration registers
            pred_read_cfg_rg();

            // No TX BDs configured -> nothing to transmit
            if (m_tx_bd_cfg_s.tx_bd_num == 0)
                return;

            // Control frame?
            if (m_tx_bd_cfg_s.tx_pause_req && m_tx_bd_cfg_s.tx_flow) begin

                pred_construct_ctrl_pkt();

            end
            else begin

                // Wait for BD to be ready and read it
				wait(m_ev_rd.triggered);
                pred_read_cfg_bd();

                // Build packet only if legal length
                if (pred_check_len_4())
                    pred_construct_data_pkt();

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

// task: 
task eth_tx_scoreboard::get_wb_m_seq_item();
    // Get all keys from semaphore
    m_sem_wb_m_seq_item.get(SEM_WB_M_SEQ_ITEM_NO_KEYS);
    // Get transaction item from fifo
    wb_m_fifo.get(m_wb_m_seq_item);
    // Put all Keys in semaphore
    m_sem_wb_m_seq_item.put(SEM_WB_M_SEQ_ITEM_NO_KEYS);
endtask
  

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

    uvm_status_e   status;
    uvm_reg_data_t rtl_data;
    uvm_reg_data_t mirror_data;

    bit prev_rd;
    bit curr_rd;
    bit wrap_bit;

    // Start from first TX BD
    m_tx_bd_cfg_s_s.bd_index = 0;

    // Initialize previous RD
    m_regmodel.eth_bd_mem.peek(status,
                             m_tx_bd_cfg_s_s.bd_index,
                             rtl_data);

    prev_rd = rtl_data[15];

    forever begin

        //--------------------------------------------
        // Read current BD through backdoor
        //--------------------------------------------
        m_regmodel.eth_bd_mem.peek(status,
                                 m_tx_bd_cfg_s_s.bd_index*2,
                                 rtl_data);

        //--------------------------------------------
        // Compare RTL with RAL mirror
        //--------------------------------------------
        mirror_data = m_regmodel.eth_bd_mem.get_mirrored_value(
                          m_tx_bd_cfg_s_s.bd_index*2);

        if (rtl_data !== mirror_data)
            `uvm_error(get_type_name(),
                $sformatf("BD[%0d] Mirror mismatch RTL=%08h Mirror=%08h",
                          m_tx_bd_cfg_s_s.bd_index,
                          rtl_data,
                          mirror_data))

        curr_rd  = rtl_data[15];
        wrap_bit = rtl_data[13];

        //----------------------------------------------------
        // 0 -> 1 : Software armed this BD
        //----------------------------------------------------
        if (!prev_rd && curr_rd) begin

            -> m_ev_rd;

            `uvm_info(get_type_name(),
                $sformatf("BD[%0d] armed (RD 0->1)",
                          m_tx_bd_cfg_s_s.bd_index),
                UVM_MEDIUM)
        end

        //----------------------------------------------------
        // 1 -> 0 : DUT finished this BD
        //----------------------------------------------------
        if (prev_rd && !curr_rd) begin

            `uvm_info(get_type_name(),
                $sformatf("BD[%0d] completed (RD 1->0)",
                          m_tx_bd_cfg_s_s.bd_index),
                UVM_MEDIUM)

            // Advance to next BD
            if (wrap_bit)
                m_tx_bd_cfg_s_s.bd_index = 0;
            else
                m_tx_bd_cfg_s_s.bd_index++;

            // Initialize previous RD for the new BD
            m_regmodel.eth_bd_mem.peek(status,
                                     m_tx_bd_cfg_s_s.bd_index*2,
                                     rtl_data);

            prev_rd = rtl_data[15];

            continue;
        end

        prev_rd = curr_rd;

        #1ns;

    end

endtask

//------------------------------------------------------------------------------
// Read all TX configuration registers
//------------------------------------------------------------------------------
function void eth_tx_scoreboard::pred_read_cfg_rg();

    uvm_status_e   status;
    uvm_reg_data_t data;

    //------------------------------------------
    // MODER
    //------------------------------------------
    m_regmodel.MODER.mirror(status, UVM_CHECK, UVM_BACKDOOR);

    m_tx_bd_cfg_s_s.txen         = m_regmodel.MODER.TXEN.get();
    m_tx_bd_cfg_s_s.pad_moder    = m_regmodel.MODER.PAD.get();
    m_tx_bd_cfg_s_s.crcen        = m_regmodel.MODER.CRCEN.get();
    m_tx_bd_cfg_s_s.hugen        = m_regmodel.MODER.HUGEN.get();
    m_tx_bd_cfg_s_s.recsmall     = m_regmodel.MODER.RECSMALL.get();
    m_tx_bd_cfg_s_s.dlycrcen     = m_regmodel.MODER.DLYCRCEN.get();
    m_tx_bd_cfg_s_s.full_duplex  = m_regmodel.MODER.FULLD.get();
    m_tx_bd_cfg_s_s.exdfren      = m_regmodel.MODER.EXDFREN.get();
    m_tx_bd_cfg_s_s.nobackoff    = m_regmodel.MODER.NOBCKOF.get();
    m_tx_bd_cfg_s_s.loopback     = m_regmodel.MODER.LOOPBCK.get();
    m_tx_bd_cfg_s_s.ifg          = m_regmodel.MODER.IFG.get();
    m_tx_bd_cfg_s_s.no_pre       = m_regmodel.MODER.NOPRE.get();

    //------------------------------------------
    // PACKETLEN
    //------------------------------------------
    m_regmodel.PACKETLEN.mirror(status, UVM_CHECK, UVM_BACKDOOR);


    m_tx_bd_cfg_s_s.minfl = m_regmodel.PACKETLEN.MINFL.get();
    m_tx_bd_cfg_s_s.maxfl = m_regmodel.PACKETLEN.MAXFL.get();

    //------------------------------------------
    // COLLCONF
    //------------------------------------------
    m_regmodel.COLLCONF.mirror(status, UVM_CHECK, UVM_BACKDOOR);

    m_tx_bd_cfg_s_s.maxret    = m_regmodel.COLLCONF.MAXRET.get();
    m_tx_bd_cfg_s_s.collvalid = m_regmodel.COLLCONF.COLLVALID.get();

    //------------------------------------------
    // TX_BD_NUM
    //------------------------------------------
    m_regmodel.TX_BD_NUM.mirror(status, UVM_CHECK, UVM_BACKDOOR);

    m_tx_bd_cfg_s_s.tx_bd_num = m_regmodel.TX_BD_NUM.TX_BD_NUM.get();

    //------------------------------------------
    // TXCTRL
    //------------------------------------------
    m_regmodel.TXCTRL.mirror(status, UVM_CHECK, UVM_BACKDOOR);


    m_tx_bd_cfg_s_s.tx_pause_req = m_regmodel.TXCTRL.TXPAUSERQ.get();
    m_tx_bd_cfg_s_s.tx_pause_tv  = m_regmodel.TXCTRL.TXPAUSETV.get();

    //------------------------------------------
    // MAC_ADDR0
    //------------------------------------------
    m_regmodel.MAC_ADDR0.mirror(status, UVM_CHECK, UVM_BACKDOOR);


    m_tx_bd_cfg_s_s.mac_addr[39:32] = m_regmodel.MAC_ADDR0.BYTE2.get();
    m_tx_bd_cfg_s_s.mac_addr[31:24] = m_regmodel.MAC_ADDR0.BYTE3.get();
    m_tx_bd_cfg_s_s.mac_addr[23:16] = m_regmodel.MAC_ADDR0.BYTE4.get();
    m_tx_bd_cfg_s_s.mac_addr[15:8]  = m_regmodel.MAC_ADDR0.BYTE5.get();

    //------------------------------------------
    // MAC_ADDR1
    //------------------------------------------
    m_regmodel.MAC_ADDR1.mirror(status, UVM_CHECK, UVM_BACKDOOR);


    m_tx_bd_cfg_s_s.mac_addr[47:40] = m_regmodel.MAC_ADDR1.BYTE0.get();
    m_tx_bd_cfg_s_s.mac_addr[7:0]   = m_regmodel.MAC_ADDR1.BYTE1.get();
	  
	//------------------------------------------
    //CTRLMODER
    //------------------------------------------
	m_regmodel.CTRLMODER.mirror(status, UVM_CHECK, UVM_BACKDOOR);

	m_tx_bd_cfg_s_s.tx_flow = m_regmodel.CTRLMODER.TXFLOW.get();

endfunction

//------------------------------------------------------------------------------
// Read the currently armed TX Buffer Descriptor
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
// Read currently armed TX Buffer Descriptor
//------------------------------------------------------------------------------
function void eth_tx_scoreboard::pred_read_cfg_bd();

    uvm_status_e   status;
    uvm_reg_data_t data;
	int status_idx;
    int ptr_idx;

    status_idx = m_tx_bd_cfg_s_s.bd_index * 2;
    ptr_idx    = status_idx + 1;

    //------------------------------------------
    // Status word
    //------------------------------------------
  m_regmodel.eth_bd_mem.mirror(status,
                           status_idx,
                           UVM_CHECK,
                           UVM_BACKDOOR);


    data = m_regmodel.eth_bd_mem.get(status_idx);

    m_tx_bd_cfg_s_s.len     = data[31:16];
    m_tx_bd_cfg_s_s.rd      = data[15];
    m_tx_bd_cfg_s_s.irq     = data[14];
    m_tx_bd_cfg_s_s.wr      = data[13];
    m_tx_bd_cfg_s_s.pad_bd  = data[12];
    m_tx_bd_cfg_s_s.crc_bd  = data[11];

    //------------------------------------------
    // Pointer word
    //------------------------------------------
    m_regmodel.eth_bd_mem.mirror(status,
                           ptr_idx,
                           UVM_CHECK,
                           UVM_BACKDOOR);
    data = m_regmodel.eth_bd_mem.get(ptr_idx);

    m_tx_bd_cfg_s_s.txpnt = data;

    //------------------------------------------
    // Derived fields
    //------------------------------------------
    m_tx_bd_cfg_s_s.eff_pad  = m_tx_bd_cfg_s_s.pad_bd | m_tx_bd_cfg_s_s.pad_moder;
    m_tx_bd_cfg_s_s.eff_crc  = m_tx_bd_cfg_s_s.crc_bd | m_tx_bd_cfg_s_s.crcen;

    m_tx_bd_cfg_s_s.armed_time_ns  = $time;
	
	   `uvm_info(get_type_name(),
        $sformatf("Read TX BD[%0d]: LEN=%0d RD=%0b PAD=%0b CRC=%0b PTR=0x%08h",
                  m_tx_bd_cfg_s.bd_index,
                  m_tx_bd_cfg_s.len,
                  m_tx_bd_cfg_s.rd,
                  m_tx_bd_cfg_s.eff_pad,
                  m_tx_bd_cfg_s.eff_crc,
                  m_tx_bd_cfg_s.txpnt),
        UVM_MEDIUM)

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

    if (m_tx_bd_cfg_s.exp_pkt.size() >= target_len)
        return;

    pad_bytes = target_len - m_tx_bd_cfg_s.exp_pkt.size();

    repeat (pad_bytes)
        m_tx_bd_cfg_s.exp_pkt.push_back(ETH_PAD);

    `uvm_info(get_type_name(),
        $sformatf("Added %0d padding bytes (frame length = %0d)",
                  pad_bytes,
                  m_tx_bd_cfg_s.exp_pkt.size()),
        UVM_LOW)

endfunction



`endif // ETH_TX_SCOREBOARD_SV