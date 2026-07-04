//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_rx_scoreboard.sv
//------------------------------------------------------------------------------
// Description:
//   Golden model + checker for the RX path. For every frame seen on the MII
//   RX interface, decides what the DUT should do with it (drop it silently,
//   drop it as BUSY, or store it) and, if stored, what the RX BD status bits
//   and bytes in DMA memory should end up being -- then waits for the DUT to
//   actually finish and compares.
//
// Why this is NOT structured like eth_tx_scoreboard:
//   - TX needs a predictor process racing ahead of a comparator process
//     because the DUT can be preparing BD N+1 in memory while BD N is still
//     being clocked out on the wire. TX also needs semaphore-guarded access
//     to its MII item because the comparator reads it nibble-by-nibble across
//     many time steps.
//   - RX has neither problem: a wire carries one frame at a time, and
//     mii_rx_seq_item arrives as a single, already-complete transaction (built
//     in post_randomize()). So RX is one process, one frame at a time:
//         get frame -> classify (golden model) -> wait for DUT to finish
//         this BD -> compare -> move to next BD -> repeat.
//     No semaphores, no fork/join pipeline, no end-of-test event needed --
//     the loop just gets torn down when the phase ends, like any other
//     `forever` in a scoreboard.
//
//   The single event that matters is the RX BD's E (Empty) bit going 1 -> 0.
//   Per spec 4.2.4: "After the whole frame has been received and stored to
//   the memory, the receive status is written to the BD." That write is what
//   clears E. Everything the comparator needs to check hangs off that one
//   transition.
//==============================================================================
`ifndef ETH_RX_SCOREBOARD_SV
`define ETH_RX_SCOREBOARD_SV

// =============================================================================
//  Golden-model structs
// =============================================================================
typedef struct {
    bit         rxen;
    bit         recsmall;   // MODER.RECSMALL
    bit         hugen;      // MODER.HUGEN     - 0: truncate oversized frames at MAXFL
    bit         dlycrcen;   // MODER.DLYCRCEN  - see check_interrupt/classify_frame note
    bit         fulld;      // MODER.FULLD     - late collision only meaningful in half duplex
    bit         pro;        // MODER.PRO       - promiscuous
    bit         iam;        // MODER.IAM       - individual hash addr mode
    bit         bro;        // MODER.BRO       - reject broadcast unless PRO
    bit         ifg;        // MODER.IFG       - 1 = accept regardless of IFG
    bit [15:0]  minfl;      // PACKETLEN.MINFL
    bit [15:0]  maxfl;      // PACKETLEN.MAXFL
    bit         passall;    // CTRLMODER.PASSALL
    bit         rxflow;     // CTRLMODER.RXFLOW
    bit [47:0]  mac_addr;   // MAC_ADDR0/1 concatenated
    bit [31:0]  hash0;      // HASH0
    bit [31:0]  hash1;      // HASH1
    bit         rxc_m;      // INT_MASK.RXC_M
    bit         busy_m;     // INT_MASK.BUSY_M
    bit         rxe_m;      // INT_MASK.RXE_M
    bit         rxf_m;      // INT_MASK.RXF_M (spec's mask name for the RXB status bit)
} eth_rx_reg_cfg_s;

typedef struct {
    byte        exp_pkt[$];    // DA+SA+L/T+payload+CRC, as it should land in memory
    bit         exp_dropped;   // frame never written to memory / no BD touched
    bit         exp_busy;      // dropped specifically because no BD was empty
    bit         exp_cf;
    bit         exp_m;
    bit         exp_or;
    bit         exp_is;
    bit         exp_dn;
    bit         exp_tl;
    bit         exp_sf;
    bit         exp_crcerr;
    bit         exp_lc;
} eth_rx_expected_s;


class eth_rx_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(eth_rx_scoreboard)

    // =========================================================================
    // Analysis fifo / export -- only need the wire-side item. Actual received
    // data is read straight from dma_mem via the BD pointer once the BD
    // completes; we don't need a WB-master analysis stream for that.
    // =========================================================================
    uvm_analysis_fifo  #(mii_rx_seq_item)  mii_rx_fifo;
    uvm_analysis_export #(mii_rx_seq_item) mii_rx_a_export;

    // =========================================================================
    // Register block (gives us BD addressing + backdoor register mirrors)
    // =========================================================================
    eth_reg_block m_regmodel;

    // =========================================================================
    // Golden-model / bookkeeping state
    // =========================================================================
    eth_rx_reg_cfg_s   m_rx_cfg;
    eth_rx_expected_s  m_rx_expected_s;

    int      m_bd_index;              // index of the RX BD currently armed, relative to the RX region
    event    m_ev_rxen;               // MODER.RXEN 0 -> 1

    realtime last_frame_end_time_ns;
    bit      first_frame_seen;        // suppresses IFG check before the first frame
    parameter real IFG_MIN_NS = 960.0; // 0.96us @100Mbps back-to-back IPG (IPGT default)

    uvm_reg_data_t m_last_status_word; // set by compare_frame(), read by check_interrupt()

    // =========================================================================
    // Phases
    // =========================================================================
    extern function new(string name, uvm_component parent);
    extern function void build_phase(uvm_phase phase);
    extern function void connect_phase(uvm_phase phase);
    extern task run_phase(uvm_phase phase);

    // -------------------------------------------------------------------------
    // Background: catch RXEN 0->1 so we know reception restarts at RX BD 0.
    // -------------------------------------------------------------------------
    extern task track_rxen();

    // -------------------------------------------------------------------------
    // Per-frame pipeline (called once per mii_rx item, fully sequential)
    // -------------------------------------------------------------------------
    extern task process_frame(mii_rx_seq_item fr);
    extern task read_cfg_regs();
    extern function bit check_addr(mii_rx_seq_item fr);
    extern function void classify_frame(mii_rx_seq_item fr, output bit stored);
    extern function int  bd_word_idx(int bd_index);
    extern task wait_bd_done(int bd_index, output uvm_reg_data_t status_word, output uvm_reg_data_t ptr_word);
    extern task compare_frame(int bd_index, uvm_reg_data_t status_word, uvm_reg_data_t ptr_word);
    extern function void compare_bytes(byte actual_pkt[$]);
    extern task check_interrupt();

endclass : eth_rx_scoreboard

// =============================================================================
//  IMPLEMENTATION
// =============================================================================

function eth_rx_scoreboard::new(string name, uvm_component parent);
    super.new(name, parent);
    last_frame_end_time_ns = 0.0;
    first_frame_seen       = 1'b0;
    m_bd_index              = 0;
endfunction

function void eth_rx_scoreboard::build_phase(uvm_phase phase);
    super.build_phase(phase);

    mii_rx_fifo     = new("mii_rx_fifo", this);
    mii_rx_a_export = new("mii_rx_a_export", this);

    if (!uvm_config_db #(eth_reg_block)::get(this, "", "m_regmodel", m_regmodel))
        `uvm_fatal("SB/CFG", "eth_rx_scoreboard: cannot retrieve eth_reg_block from uvm_config_db")
endfunction

function void eth_rx_scoreboard::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    mii_rx_a_export.connect(mii_rx_fifo.analysis_export);
endfunction

// task: run_phase
// Deliberately raises no objection here. Objections belong to the
// sequence/test that drives traffic; this `forever` just gets torn down when
// the phase ends, the same way it would for any monitor. That removes the
// need for an "end of test" event entirely.
task eth_rx_scoreboard::run_phase(uvm_phase phase);
    mii_rx_seq_item fr;

    fork
        track_rxen();
    join_none

    wait (m_ev_rxen.triggered);

    forever begin
        mii_rx_fifo.get(fr);
        process_frame(fr);
    end
endtask

// task: track_rxen
task eth_rx_scoreboard::track_rxen();
    uvm_status_e status;
    bit prev_rxen, curr_rxen;
    bit [7:0] tx_bd_num;

    m_regmodel.MODER.mirror(status, UVM_CHECK, UVM_BACKDOOR);
    prev_rxen = m_regmodel.MODER.RXEN.get_mirrored_value();

    forever begin
        m_regmodel.MODER.mirror(status, UVM_CHECK, UVM_BACKDOOR);
        m_regmodel.TX_BD_NUM.mirror(status, UVM_CHECK, UVM_BACKDOOR);

        curr_rxen = m_regmodel.MODER.RXEN.get_mirrored_value();
        tx_bd_num = m_regmodel.TX_BD_NUM.get_mirrored_value();

        if (!prev_rxen && curr_rxen) begin
            if(tx_bd_num < 'h80) begin 
                m_bd_index = 0;
                -> m_ev_rxen;
                `uvm_info(get_type_name(), "RXEN asserted, RX BD index reset to 0", UVM_MEDIUM)
            end else if (tx_bd_num >='h80) begin 
                `uvm_info("TX_BD_NUM", " you can't receiving as TX_BD_NUM > 0x80 " , UVM_MEDIUM)
            end
        end

        prev_rxen = curr_rxen;
        #1ns;
    end
endtask

// function: bd_word_idx
// Converts an RX-relative BD index into the eth_bd_mem word index. RX BDs
// sit right after the TX BDs in the shared 256-word array; the split point
// comes from TX_BD_NUM (see eth_reg_block::get_rx_bd_addr, byte-addressed --
// divide by 4 for the uvm_mem word index used with .peek()).
function int eth_rx_scoreboard::bd_word_idx(int bd_index);
    int n_tx_bd, n_rx_bd;
    m_regmodel.get_bd_split(n_tx_bd, n_rx_bd);
    return (n_tx_bd + bd_index) * 2;
endfunction

// task: read_cfg_regs
task eth_rx_scoreboard::read_cfg_regs();
    uvm_status_e status;

    m_regmodel.MODER.mirror(status, UVM_CHECK, UVM_BACKDOOR);
    m_rx_cfg.rxen     = m_regmodel.MODER.RXEN.get_mirrored_value();
    m_rx_cfg.recsmall = m_regmodel.MODER.RECSMALL.get_mirrored_value();
    m_rx_cfg.hugen    = m_regmodel.MODER.HUGEN.get_mirrored_value();
    // NOTE: DLYCRCEN is read for completeness, but this scoreboard cannot
    // yet act on it correctly. See classify_frame() comment for why -- the
    // fix belongs in mii_rx_seq_item, not here.
    m_rx_cfg.dlycrcen = m_regmodel.MODER.DLYCRCEN.get_mirrored_value();
    m_rx_cfg.fulld    = m_regmodel.MODER.FULLD.get_mirrored_value();
    m_rx_cfg.pro      = m_regmodel.MODER.PRO.get_mirrored_value();
    m_rx_cfg.iam      = m_regmodel.MODER.IAM.get_mirrored_value();
    m_rx_cfg.bro      = m_regmodel.MODER.BRO.get_mirrored_value();
    m_rx_cfg.ifg      = m_regmodel.MODER.IFG.get_mirrored_value();

    m_regmodel.PACKETLEN.mirror(status, UVM_CHECK, UVM_BACKDOOR);
    m_rx_cfg.minfl = m_regmodel.PACKETLEN.MINFL.get_mirrored_value();
    m_rx_cfg.maxfl = m_regmodel.PACKETLEN.MAXFL.get_mirrored_value();

    m_regmodel.CTRLMODER.mirror(status, UVM_CHECK, UVM_BACKDOOR);
    m_rx_cfg.passall = m_regmodel.CTRLMODER.PASSALL.get_mirrored_value();
    m_rx_cfg.rxflow  = m_regmodel.CTRLMODER.RXFLOW.get_mirrored_value();

    m_regmodel.MAC_ADDR0.mirror(status, UVM_CHECK, UVM_BACKDOOR);
    m_regmodel.MAC_ADDR1.mirror(status, UVM_CHECK, UVM_BACKDOOR);
    m_rx_cfg.mac_addr = m_regmodel.get_mac_address();

    m_regmodel.HASH0.mirror(status, UVM_CHECK, UVM_BACKDOOR);
    m_rx_cfg.hash0 = m_regmodel.HASH0.get_mirrored_value();
    m_regmodel.HASH1.mirror(status, UVM_CHECK, UVM_BACKDOOR);
    m_rx_cfg.hash1 = m_regmodel.HASH1.get_mirrored_value();

    m_regmodel.INT_MASK.mirror(status, UVM_CHECK, UVM_BACKDOOR);
    m_rx_cfg.rxc_m  = m_regmodel.INT_MASK.RXC_M.get_mirrored_value();
    m_rx_cfg.busy_m = m_regmodel.INT_MASK.BUSY_M.get_mirrored_value();
    m_rx_cfg.rxe_m  = m_regmodel.INT_MASK.RXE_M.get_mirrored_value();
    m_rx_cfg.rxf_m  = m_regmodel.INT_MASK.RXF_M.get_mirrored_value();
endtask

// function: check_addr
// Address recognition golden model, per MODER.PRO/IAM/BRO (spec 3.1).
// Returns 1 if this frame's DA is considered a "hit".
function bit eth_rx_scoreboard::check_addr(mii_rx_seq_item fr);
    bit is_broadcast;

    is_broadcast = (fr.destination_addr == 48'hFF_FF_FF_FF_FF_FF);
    if (is_broadcast)
        return !m_rx_cfg.bro; // BRO=1 rejects broadcast (unless PRO, handled by caller)

    if (m_rx_cfg.iam) begin
        // Standard IEEE 802.3 multicast hash: CRC-32 of the 6 DA bytes
        // (reflected in/out, poly 0x04C11DB7), low 6 bits of the result
        // select a bit across {HASH1,HASH0}. ASSUMPTION: confirm this
        // exact indexing against the RTL -- the spec doesn't define it.
        bit [31:0] crc = 32'hFFFF_FFFF;
        bit [5:0]  hash_idx;
        byte       da_bytes[6];
        da_bytes[0] = fr.destination_addr[47:40];
        da_bytes[1] = fr.destination_addr[39:32];
        da_bytes[2] = fr.destination_addr[31:24];
        da_bytes[3] = fr.destination_addr[23:16];
        da_bytes[4] = fr.destination_addr[15:8];
        da_bytes[5] = fr.destination_addr[7:0];

        foreach (da_bytes[i]) begin
            byte reflected;
            foreach (reflected[b]) reflected[b] = da_bytes[i][7-b];
            for (int b = 7; b >= 0; b--)
                crc = (crc[31] ^ reflected[b]) ? (crc << 1) ^ 32'h04C1_1DB7 : (crc << 1);
        end
        crc = ~crc;
        begin
            bit [31:0] crc_r;
            foreach (crc_r[b]) crc_r[b] = crc[31-b];
            hash_idx = crc_r[5:0];
        end

        return (hash_idx < 32) ? m_rx_cfg.hash0[hash_idx] : m_rx_cfg.hash1[hash_idx-32];
    end

    return (fr.destination_addr == m_rx_cfg.mac_addr);
endfunction

// function: classify_frame
// Golden model of "what should the MAC do with this frame". Sets
// m_rx_expected_s. `stored` tells the caller whether to wait for a BD at all.
function void eth_rx_scoreboard::classify_frame(mii_rx_seq_item fr, output bit stored);
    bit is_pause_frame;
    bit addr_hit;

    m_rx_expected_s = '{default:'0};
    stored = 0;

    //--------------------------------------------------------------------
    // RXEN=0 -> silently discarded, nothing touched
    //--------------------------------------------------------------------
    if (!m_rx_cfg.rxen) begin
        m_rx_expected_s.exp_dropped = 1;
        `uvm_info(get_type_name(), "RXEN=0, frame ignored", UVM_MEDIUM)
        return;
    end

    //--------------------------------------------------------------------
    // IFG violation -> silently discarded (MODER.IFG=1 disables this check)
    //--------------------------------------------------------------------
    if (!m_rx_cfg.ifg && first_frame_seen && (fr.ifg_delay < IFG_MIN_NS)) begin
        m_rx_expected_s.exp_dropped = 1;
        `uvm_info(get_type_name(),
            $sformatf("IFG violation (%0dns < %0.1fns), frame ignored", fr.ifg_delay, IFG_MIN_NS),
            UVM_MEDIUM)
        return;
    end

    //--------------------------------------------------------------------
    // Control-frame (PAUSE) detection, spec 4.5.1 / Table 14
    //--------------------------------------------------------------------
    is_pause_frame = (fr.destination_addr == ETH_PAUSE_FRAME_ADDR ||
                       fr.destination_addr == m_rx_cfg.mac_addr)
                   && (fr.length_type == ETH_PAUSE_LEN_TYPE);

    if (is_pause_frame) begin
        if (!m_rx_cfg.passall) begin
            // Table 14 rows 1 & 2: never stored (RXC fires only if RXFLOW=1)
            m_rx_expected_s.exp_dropped = 1;
            `uvm_info(get_type_name(), "PAUSE frame consumed, not stored", UVM_MEDIUM)
            return;
        end
        // rows 3 & 4 (PASSALL=1): falls through to normal storage, tagged CF=1
        m_rx_expected_s.exp_cf = 1;
    end
    else begin
        //----------------------------------------------------------------
        // Address recognition for normal data frames
        //----------------------------------------------------------------
        addr_hit = check_addr(fr);

        if (m_rx_cfg.pro)
            m_rx_expected_s.exp_m = !addr_hit; // accepted via promiscuous mode
        else if (!addr_hit) begin
            m_rx_expected_s.exp_dropped = 1;
            `uvm_info(get_type_name(), "Address mismatch, frame discarded", UVM_MEDIUM)
            return;
        end
    end

    //--------------------------------------------------------------------
    // Length gating, spec 3.1 RECSMALL / HUGEN + 3.7 PACKETLEN.
    //
    // RECSMALL=0 means short frames are IGNORED (dropped), not just
    // flagged -- spec 3.1: "Packets smaller than MINFL are ignored."
    // HUGEN=0 means oversized frames are truncated to MAXFL and stored
    // with TL=1; HUGEN=1 stores the full jumbo frame with TL=0.
    //--------------------------------------------------------------------
    m_rx_expected_s.exp_pkt = fr.frame_data_q; // DA+SA+L/T+payload+FCS, untouched for now

    if (m_rx_expected_s.exp_pkt.size() < m_rx_cfg.minfl) begin
        if (!m_rx_cfg.recsmall) begin
            m_rx_expected_s.exp_dropped = 1;
            `uvm_info(get_type_name(),
                $sformatf("Frame len=%0d < MINFL=%0d, RECSMALL=0, ignored",
                    m_rx_expected_s.exp_pkt.size(), m_rx_cfg.minfl), UVM_MEDIUM)
            return;
        end
        m_rx_expected_s.exp_sf = 1;
    end

    if (m_rx_expected_s.exp_pkt.size() > m_rx_cfg.maxfl) begin
        if (!m_rx_cfg.hugen) begin
            m_rx_expected_s.exp_tl = 1;
            m_rx_expected_s.exp_pkt = m_rx_expected_s.exp_pkt[0:m_rx_cfg.maxfl-1]; // truncate
        end
        // HUGEN=1: stored in full, TL stays 0
    end

    //--------------------------------------------------------------------
    // Frame would be stored -- but only if the current RX BD is empty.
    // Checked last: nothing above this point ever touches a BD.
    //--------------------------------------------------------------------
    begin
        uvm_status_e   status;
        uvm_reg_data_t data;
        m_regmodel.eth_bd_mem.peek(status, bd_word_idx(m_bd_index), data);

        if (!data[15]) begin // E bit, spec Table 28
            m_rx_expected_s.exp_dropped = 1;
            m_rx_expected_s.exp_busy    = 1;
            `uvm_info(get_type_name(),
                $sformatf("RX BD[%0d] not empty, BUSY", m_bd_index), UVM_MEDIUM)
            return;
        end
    end

    //--------------------------------------------------------------------
    // Remaining status bits, spec Table 28.
    // Note (spec 4.2.4): frames of 4 bytes or fewer are only CRC bytes,
    // so they are always reported with a CRC error, regardless of what
    // the sequence item's own crc-injection knob says.
    //--------------------------------------------------------------------
    if (fr.inject_invalid_symbol) m_rx_expected_s.exp_is = 1;
    if (fr.dribble_nibble_en)     m_rx_expected_s.exp_dn = 1;
    if (!m_rx_cfg.fulld && fr.inject_late_collision) m_rx_expected_s.exp_lc = 1;

    if (fr.inject_crc_error || m_rx_expected_s.exp_pkt.size() <= 4)
        m_rx_expected_s.exp_crcerr = 1;

    // DLYCRCEN limitation: this scoreboard trusts fr.frame_data_q's trailing
    // 4 bytes as "whatever CRC the item decided to put on the wire" and
    // never recomputes CRC itself (deliberately -- one CRC implementation
    // to get right, in the item, not two). That's fine when DLYCRCEN=0.
    // Under DLYCRCEN=1 the DUT computes its CRC starting 4 bytes after SFD
    // (skipping the first 4 bytes of DA), so a "normal-window" CRC built by
    // the item will look like a CRC error to the DUT even when none was
    // injected. Until mii_rx_seq_item grows a DLYCRCEN-aware CRC build mode
    // (see chat notes), treat any DLYCRCEN=1 run as CRC-untestable:
    if (m_rx_cfg.dlycrcen)
        m_rx_expected_s.exp_crcerr = 1;

    // ASSUMPTION: a mid-frame PHY error (MRxErr) is treated as a hard PHY
    // abort -- the RX MAC drops the frame entirely, no BD is touched, no
    // interrupt fires (mirrors OR being a DMA/WB-side condition, not a
    // wire-side one). If your RTL instead stores a truncated frame with
    // OR=1 on MRxErr, move this block above the length-gating section and
    // set exp_or=1 + truncate exp_pkt at fr.err_pos instead of dropping.
    if (fr.inject_mrxerr) begin
        m_rx_expected_s.exp_dropped = 1;
        `uvm_info(get_type_name(), "MRxErr asserted mid-frame, treated as PHY abort", UVM_MEDIUM)
        return;
    end

    stored = 1;

    `uvm_info(get_type_name(),
        $sformatf("RX BD[%0d] classified: len=%0d cf=%0b m=%0b or=%0b is=%0b dn=%0b tl=%0b sf=%0b crc=%0b lc=%0b",
            m_bd_index, m_rx_expected_s.exp_pkt.size(), m_rx_expected_s.exp_cf,
            m_rx_expected_s.exp_m, m_rx_expected_s.exp_or, m_rx_expected_s.exp_is,
            m_rx_expected_s.exp_dn, m_rx_expected_s.exp_tl, m_rx_expected_s.exp_sf,
            m_rx_expected_s.exp_crcerr, m_rx_expected_s.exp_lc),
        UVM_MEDIUM)
endfunction

// task: wait_bd_done
// Blocks until the current RX BD's E bit goes 1 -> 0 -- the one event that
// means "DUT finished this frame" (spec 4.2.4).
task eth_rx_scoreboard::wait_bd_done(int bd_index, output uvm_reg_data_t status_word, output uvm_reg_data_t ptr_word);
    uvm_status_e status;
    int idx = bd_word_idx(bd_index);
    longint unsigned waited_ns = 0;
    parameter longint unsigned TIMEOUT_NS = 1_000_000;

    forever begin
        m_regmodel.eth_bd_mem.peek(status, idx, status_word);
        if (!status_word[15]) break; // E cleared
        #1ns;
        waited_ns++;
        if (waited_ns > TIMEOUT_NS)
            `uvm_fatal(get_type_name(), $sformatf("RX BD[%0d] never completed (E stuck at 1)", bd_index))
    end

    m_regmodel.eth_bd_mem.peek(status, idx+1, ptr_word);
endtask

// function: compare_bytes
function void eth_rx_scoreboard::compare_bytes(byte actual_pkt[$]);
    bit err = 0;

    if (m_rx_expected_s.exp_pkt.size() != actual_pkt.size()) begin
        `uvm_error(get_type_name(),
            $sformatf("RX BD[%0d] length mismatch: Expected=%0d Actual=%0d",
                m_bd_index, m_rx_expected_s.exp_pkt.size(), actual_pkt.size()))
        return;
    end

    foreach (m_rx_expected_s.exp_pkt[i]) begin
        if (m_rx_expected_s.exp_pkt[i] !== actual_pkt[i]) begin
            err = 1;
            `uvm_error(get_type_name(),
                $sformatf("RX BD[%0d] byte %0d mismatch: Expected=0x%02h Actual=0x%02h",
                    m_bd_index, i, m_rx_expected_s.exp_pkt[i], actual_pkt[i]))
        end
    end

    if (!err)
        `uvm_info(get_type_name(),
            $sformatf("RX BD[%0d] packet comparison PASSED (%0d bytes)", m_bd_index, actual_pkt.size()),
            UVM_LOW)
endfunction

// task: compare_frame
task eth_rx_scoreboard::compare_frame(int bd_index, uvm_reg_data_t status_word, uvm_reg_data_t ptr_word);
    bit [15:0] actual_len;
    bit [31:0] rxpnt;
    bit [31:0] rd_data;
    byte       actual_pkt[$];
    int        nwords;
    bit        err = 0;

    actual_len = status_word[31:16];
    rxpnt      = ptr_word;

    nwords = (actual_len + 3) / 4;
    for (int unsigned i = 0; i < nwords; i++) begin
        if (!dma_mem::read(rxpnt + i*4, rd_data))
            `uvm_fatal(get_type_name(),
                $sformatf("RX BD[%0d]: address doesn't exist in dma memory, address=0x%0h",
                    bd_index, rxpnt + i*4))
        for (int b = 3; b >= 0; b--)
            actual_pkt.push_back(rd_data[8*b +: 8]);
    end
    while (actual_pkt.size() > actual_len)
        void'(actual_pkt.pop_back());

    compare_bytes(actual_pkt);

    // Status bits, spec Table 28
    if (status_word[8]  !== m_rx_expected_s.exp_cf)     begin `uvm_error(get_type_name(), $sformatf("RX BD[%0d] CF mismatch: actual=%0b expected=%0b", bd_index, status_word[8],  m_rx_expected_s.exp_cf))     err=1; end
    if (status_word[7]  !== m_rx_expected_s.exp_m)      begin `uvm_error(get_type_name(), $sformatf("RX BD[%0d] M mismatch: actual=%0b expected=%0b",  bd_index, status_word[7],  m_rx_expected_s.exp_m))      err=1; end
    // OR (Overrun, spec Table 28 bit[6]) reflects internal RX-FIFO/DMA
    // backpressure, not something derivable from the MII wire content. We
    // never predict exp_or=1 (see classify_frame), so only flag it as a
    // warning if the DUT reports one -- it may be legitimate (e.g. a
    // deliberately congested WB bus test) rather than a real bug.
    if (status_word[6] !== m_rx_expected_s.exp_or)
        `uvm_info(get_type_name(),
            $sformatf("RX BD[%0d] OR=%0b seen, not modeled from the wire -- verify intentional",
                bd_index, status_word[6]), UVM_LOW)
    if (status_word[5]  !== m_rx_expected_s.exp_is)     begin `uvm_error(get_type_name(), $sformatf("RX BD[%0d] IS mismatch: actual=%0b expected=%0b", bd_index, status_word[5],  m_rx_expected_s.exp_is))     err=1; end
    if (status_word[4]  !== m_rx_expected_s.exp_dn)     begin `uvm_error(get_type_name(), $sformatf("RX BD[%0d] DN mismatch: actual=%0b expected=%0b", bd_index, status_word[4],  m_rx_expected_s.exp_dn))     err=1; end
    if (status_word[3]  !== m_rx_expected_s.exp_tl)     begin `uvm_error(get_type_name(), $sformatf("RX BD[%0d] TL mismatch: actual=%0b expected=%0b", bd_index, status_word[3],  m_rx_expected_s.exp_tl))     err=1; end
    if (status_word[2]  !== m_rx_expected_s.exp_sf)     begin `uvm_error(get_type_name(), $sformatf("RX BD[%0d] SF mismatch: actual=%0b expected=%0b", bd_index, status_word[2],  m_rx_expected_s.exp_sf))     err=1; end
    if (status_word[1]  !== m_rx_expected_s.exp_crcerr) begin `uvm_error(get_type_name(), $sformatf("RX BD[%0d] CRC mismatch: actual=%0b expected=%0b",bd_index, status_word[1],  m_rx_expected_s.exp_crcerr)) err=1; end
    if (status_word[0]  !== m_rx_expected_s.exp_lc)     begin `uvm_error(get_type_name(), $sformatf("RX BD[%0d] LC mismatch: actual=%0b expected=%0b", bd_index, status_word[0],  m_rx_expected_s.exp_lc))     err=1; end

    if (!err)
        `uvm_info(get_type_name(), $sformatf("RX BD[%0d] status bits PASSED", bd_index), UVM_LOW)

    m_last_status_word = status_word;
    check_interrupt();
endtask

// task: check_interrupt
// Note field names follow the spec exactly: INT_SOURCE.RXB is masked by
// INT_MASK.RXF_M -- the spec itself uses different names for the status bit
// and its mask (Table 5 vs Table 6).
task eth_rx_scoreboard::check_interrupt();
    uvm_status_e   status;
    uvm_reg_data_t rxc, busy, rxe, rxb;
    bit            bd_irq;

    // BUSY and RXC never depend on a particular BD's IRQ bit (BUSY: no BD
    // was even used; RXC: control-frame-only path with PASSALL=0 never
    // touches a BD either). RXB/RXE are per-BD outcomes and DO require the
    // BD's own IRQ bit to be set, per spec 3.2 / plan topic 12.
    bd_irq = m_last_status_word[14];

    if (m_rx_expected_s.exp_busy && m_rx_cfg.busy_m) begin
        m_regmodel.INT_SOURCE.BUSY.predict(1);
        m_regmodel.INT_SOURCE.BUSY.mirror(status, UVM_CHECK, UVM_BACKDOOR);
    end
    else if (m_rx_expected_s.exp_cf && m_rx_cfg.rxflow && m_rx_cfg.rxc_m) begin
        m_regmodel.INT_SOURCE.RXC.predict(1);
        m_regmodel.INT_SOURCE.RXC.mirror(status, UVM_CHECK, UVM_BACKDOOR);
    end
    else if (bd_irq && (m_rx_expected_s.exp_or || m_rx_expected_s.exp_crcerr ||
              m_rx_expected_s.exp_is || m_rx_expected_s.exp_lc) && m_rx_cfg.rxe_m) begin
        m_regmodel.INT_SOURCE.RXE.predict(1);
        m_regmodel.INT_SOURCE.RXE.mirror(status, UVM_CHECK, UVM_BACKDOOR);
    end
    else if (bd_irq && m_rx_cfg.rxf_m) begin
        m_regmodel.INT_SOURCE.RXB.predict(1);
        m_regmodel.INT_SOURCE.RXB.mirror(status, UVM_CHECK, UVM_BACKDOOR);
    end

    m_regmodel.INT_SOURCE.RXC.read(status, rxc,  UVM_BACKDOOR);
    m_regmodel.INT_SOURCE.RXE.read(status, rxe,  UVM_BACKDOOR);
    m_regmodel.INT_SOURCE.RXB.read(status, rxb,  UVM_BACKDOOR);

    // Spec 3.10: RXC and RXB are mutually exclusive when a control frame is
    // received. BUSY can coincide with either (spec 3.2 bit4 note), so it's
    // excluded from the one-hot check.
    assert ($onehot0({rxc[0], rxe[0], rxb[0]}))
    else `uvm_error(get_type_name(),
        $sformatf("More than one Rx interrupt fired at once: RXC=%0b RXE=%0b RXB=%0b", rxc, rxe, rxb))
endtask

// task: process_frame
// The whole per-frame procedure, sequential, one frame at a time.
task eth_rx_scoreboard::process_frame(mii_rx_seq_item fr);
    bit            stored;
    uvm_reg_data_t status_word, ptr_word;

    read_cfg_regs();
    classify_frame(fr, stored);

    if (stored) begin
        wait_bd_done(m_bd_index, status_word, ptr_word);
        compare_frame(m_bd_index, status_word, ptr_word);

        // Advance to next RX BD, honoring wrap (WR bit, spec Table 28 bit 13)
        if (status_word[13])
            m_bd_index = 0;
        else
            m_bd_index++;
    end
    // else: dropped/busy -- no BD was touched, m_bd_index stays put.

    last_frame_end_time_ns = $realtime;
    first_frame_seen       = 1'b1;
endtask

`endif // ETH_RX_SCOREBOARD_SV
