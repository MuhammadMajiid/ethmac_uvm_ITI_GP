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
	
	//---------------------------------------------------------------------------
    // Wishbone slave analysis implementation
    //---------------------------------------------------------------------------
     uvm_analysis_imp #(wb_s_seq_item_base#(WB_S_ADDR_WIDTH, WB_DATA_WIDTH,WB_SEL_WIDTH), eth_tx_scoreboard) wb_s_imp;

    //---------------------------------------------------------------------------
    // Predictor shadow copy of BD memory
    //---------------------------------------------------------------------------
     bit [31:0] m_bd_shadow [256];
	 
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
    extern function void write(wb_s_seq_item_base tr);
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
	
	// Build analysis imp
	wb_s_imp = new("wb_s_imp", this);

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
            if (m_tx_bd_cfg.tx_bd_num == 0)
                return;

            // Control frame?
            if (m_tx_bd_cfg.tx_pause_req && m_tx_bd_cfg.tx_flow) begin

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
    regmodel.MODER.mirror(
        status,
        UVM_CHECK,
        UVM_BACKDOOR
    );

    rtl_data  = regmodel.MODER.get_mirrored_value();
    prev_txen = rtl_data[1];

    forever begin

        // Read RTL and compare against RAL mirror
        regmodel.MODER.mirror(
            status,
            UVM_CHECK,
            UVM_BACKDOOR
        );

        rtl_data  = regmodel.MODER.get_mirrored_value();
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

//------------------------------------------------------------------------------
// Track TX Buffer Descriptor RD bit
//
// RD : 0 -> 1  : Software armed this BD
// RD : 1 -> 0  : DUT completed transmission
//------------------------------------------------------------------------------
task eth_tx_scoreboard::pred_track_rd();

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

    regmodel.eth_bd_mem.peek(
        status,
        status_idx,
        rtl_data
    );

    prev_rd = rtl_data[15];

    forever begin

        //--------------------------------------------------------
        // Current BD status word index
        //--------------------------------------------------------
        status_idx = m_tx_bd_cfg_s.bd_index * 2;

        //--------------------------------------------------------
        // Read current BD through backdoor
        //--------------------------------------------------------
        regmodel.eth_bd_mem.peek(
            status,
            status_idx,
            rtl_data
        );

        curr_rd  = rtl_data[15];
        wrap_bit = rtl_data[13];

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

            regmodel.eth_bd_mem.peek(
                status,
                status_idx,
                rtl_data
            );

            prev_rd = rtl_data[15];

            continue;
        end

        //--------------------------------------------------------
        // Update previous RD
        //--------------------------------------------------------
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
    regmodel.MODER.mirror(status, UVM_CHECK, UVM_BACKDOOR);

    m_tx_bd_cfg_s.txen         = regmodel.MODER.TXEN.get_mirrored_value();
    m_tx_bd_cfg_s.pad_moder    = regmodel.MODER.PAD.get_mirrored_value();
    m_tx_bd_cfg_s.crcen        = regmodel.MODER.CRCEN.get_mirrored_value();
    m_tx_bd_cfg_s.hugen        = regmodel.MODER.HUGEN.get_mirrored_value();
    m_tx_bd_cfg_s.recsmall     = regmodel.MODER.RECSMALL.get_mirrored_value();
    m_tx_bd_cfg_s.dlycrcen     = regmodel.MODER.DLYCRCEN.get_mirrored_value();
    m_tx_bd_cfg_s.full_duplex  = regmodel.MODER.FULLD.get_mirrored_value();
    m_tx_bd_cfg_s.exdfren      = regmodel.MODER.EXDFREN.get_mirrored_value();
    m_tx_bd_cfg_s.nobackoff    = regmodel.MODER.NOBCKOF.get_mirrored_value();
    m_tx_bd_cfg_s.loopback     = regmodel.MODER.LOOPBCK.get_mirrored_value();
    m_tx_bd_cfg_s.ifg          = regmodel.MODER.IFG.get_mirrored_value();
    m_tx_bd_cfg_s.no_pre       = regmodel.MODER.NOPRE.get_mirrored_value();

    //------------------------------------------
    // PACKETLEN
    //------------------------------------------
    regmodel.PACKETLEN.mirror(status, UVM_CHECK, UVM_BACKDOOR);


    m_tx_bd_cfg_s.minfl = regmodel.PACKETLEN.MINFL.get_mirrored_value();
    m_tx_bd_cfg_s.maxfl = regmodel.PACKETLEN.MAXFL.get_mirrored_value();

    //------------------------------------------
    // COLLCONF
    //------------------------------------------
    regmodel.COLLCONF.mirror(status, UVM_CHECK, UVM_BACKDOOR);

    m_tx_bd_cfg_s.maxret    = regmodel.COLLCONF.MAXRET.get_mirrored_value();
    m_tx_bd_cfg_s.collvalid = regmodel.COLLCONF.COLLVALID.get_mirrored_value();

    //------------------------------------------
    // TX_BD_NUM
    //------------------------------------------
    regmodel.TX_BD_NUM.mirror(status, UVM_CHECK, UVM_BACKDOOR);

    m_tx_bd_cfg_s.tx_bd_num = regmodel.TX_BD_NUM.TX_BD_NUM.get_mirrored_value();

    //------------------------------------------
    // TXCTRL
    //------------------------------------------
    regmodel.TXCTRL.mirror(status, UVM_CHECK, UVM_BACKDOOR);


    m_tx_bd_cfg_s.tx_pause_req = regmodel.TXCTRL.TXPAUSERQ.get_mirrored_value();
    m_tx_bd_cfg_s.tx_pause_tv  = regmodel.TXCTRL.TXPAUSETV.get_mirrored_value();

    //------------------------------------------
    // MAC_ADDR0
    //------------------------------------------
    regmodel.MAC_ADDR0.mirror(status, UVM_CHECK, UVM_BACKDOOR);


    m_tx_bd_cfg_s.mac_addr[39:32] = regmodel.MAC_ADDR0.BYTE2.get_mirrored_value();
    m_tx_bd_cfg_s.mac_addr[31:24] = regmodel.MAC_ADDR0.BYTE3.get_mirrored_value();
    m_tx_bd_cfg_s.mac_addr[23:16] = regmodel.MAC_ADDR0.BYTE4.get_mirrored_value();
    m_tx_bd_cfg_s.mac_addr[15:8]  = regmodel.MAC_ADDR0.BYTE5.get_mirrored_value();

    //------------------------------------------
    // MAC_ADDR1
    //------------------------------------------
    regmodel.MAC_ADDR1.mirror(status, UVM_CHECK, UVM_BACKDOOR);


    m_tx_bd_cfg_s.mac_addr[47:40] = regmodel.MAC_ADDR1.BYTE0.get_mirrored_value();
    m_tx_bd_cfg_s.mac_addr[7:0]   = regmodel.MAC_ADDR1.BYTE1.get_mirrored_value();
	  
	//------------------------------------------
    //CTRLMODER
    //------------------------------------------
	regmodel.CTRLMODER.mirror(status, UVM_CHECK, UVM_BACKDOOR);

	m_tx_bd_cfg_s.tx_flow = regmodel.CTRLMODER.TXFLOW.get_mirrored_value();

endfunction

//------------------------------------------------------------------------------
// Read the currently armed TX Buffer Descriptor
//------------------------------------------------------------------------------

function void eth_tx_scoreboard::pred_read_cfg_bd();

    uvm_status_e   status;
    uvm_reg_data_t data;

    int status_idx;
    int ptr_idx;

    status_idx = m_tx_bd_cfg_s.bd_index * 2;
    ptr_idx    = status_idx + 1;

    //------------------------------------------
    // Read Status Word
    //------------------------------------------
    regmodel.eth_bd_mem.peek(
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
    regmodel.eth_bd_mem.peek(
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

endfunction

//------------------------------------------------------------------------------
// Check minimum transmit length.
// Ethernet MAC does not transmit frames whose length <= 4 bytes.
//------------------------------------------------------------------------------
function bit eth_tx_scoreboard::pred_check_len_4();

    if (m_tx_bd_cfg.len <= 16'd4) begin

        `uvm_info(get_type_name(),
            $sformatf("BD[%0d]: Frame length (%0d bytes) <= 4. Transmission suppressed.",
                      m_tx_bd_cfg.bd_index,
                      m_tx_bd_cfg.len),
            UVM_MEDIUM)

        return 0;
    end

    return 1;

endfunction

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
function void eth_tx_scoreboard::pred_add_pad();

    int target_len;
    int pad_bytes;

    // No padding required
    if (!m_tx_bd_cfg.eff_pad)
        return;

    // Length that should exist before CRC insertion
    target_len = m_tx_bd_cfg.minfl;

    if (m_tx_bd_cfg.eff_crc)
        target_len -= 4;

    if (exp_pkt.size() >= target_len)
        return;

    pad_bytes = target_len - exp_pkt.size();

    repeat (pad_bytes)
        exp_pkt.push_back(8'h00);

    `uvm_info(get_type_name(),
        $sformatf("Added %0d padding bytes (frame length = %0d)",
                  pad_bytes,
                  exp_pkt.size()),
        UVM_LOW)

endfunction

//------------------------------------------------------------------------------
// Function: write
//
// Receives every WB slave transaction.
// Maintains a predictor copy of the BD memory.
//------------------------------------------------------------------------------
function void eth_tx_scoreboard::write( wb_s_seq_item_base#(WB_S_ADDR_WIDTH, WB_DATA_WIDTH,WB_SEL_WIDTH ) tr);

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

task eth_tx_scoreboard::comp_pack_pkt();

    bit [3:0] low_nibble;

    m_tx_pending_s.actual_pkt.delete();

    //--------------------------------------------------------
    // Wait for start of frame
    //--------------------------------------------------------
    do begin
        get_mii_tx_seq_item();
    end while (!m_mii_tx_seq_item.MTxEN);

    //--------------------------------------------------------
    // Capture complete bytes
    //--------------------------------------------------------
    while (m_mii_tx_seq_item.MTxEN) begin

        //--------------------------------------------
        // First nibble (LSB)
        //--------------------------------------------
        low_nibble = m_mii_tx_seq_item.MTxD;

        //--------------------------------------------
        // Expect second nibble
        //--------------------------------------------
        get_mii_tx_seq_item();

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

        //--------------------------------------------
        // Next nibble (or end of frame)
        //--------------------------------------------
        get_mii_tx_seq_item();

    end

    //--------------------------------------------------------
    // Frame completed
    //--------------------------------------------------------
    -> m_ev_start_comp;

    `uvm_info(get_type_name(),
        $sformatf("Captured %0d bytes from MII",
                  m_tx_pending_s.actual_pkt.size()),
        UVM_MEDIUM)

endtask
//------------------------------------------------------------------------------
// Compare one protocol field
//------------------------------------------------------------------------------
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
                "%s mismatch\n\
                 Byte Index : %0d\n\
                 Field Offset : %0d\n\
                 Expected : 0x%02h\n\
                 Actual   : 0x%02h",
                field_name,
                start_idx+i,
                i,
                m_eth_tx_expected_s.exp_pkt[start_idx+i],
                m_tx_pending_s.actual_pkt[start_idx+i]))
        end

    end

endfunction

//------------------------------------------------------------------------------
// Compare expected packet against transmitted packet
//------------------------------------------------------------------------------
task eth_tx_scoreboard::comp_compare_pkt();

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

        payload_len = m_tx_bd_cfg_s.len-6-6-2;

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
        target_len -= 4;

    // Current frame length 
	//with preamble = preamble+ sfd+ DA + SA + Length/Type + Payload 
    //without preamble= sfd+ DA + SA + Length/Type + Payload
	if (!m_tx_bd_cfg_s.no_pre) 
    frame_len = 7+1+ m_tx_bd_cfg_s.len;
	else
    frame_len = 1+ m_tx_bd_cfg_s.len;


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

endtask



`endif // ETH_TX_SCOREBOARD_SV