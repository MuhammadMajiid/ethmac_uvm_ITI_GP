`ifndef ETH_RX_SCOREBOARD_SV
`define ETH_RX_SCOREBOARD_SV

typedef struct {
    bit         rxen;
    bit         hugen;
    bit         dlycrcen;
    bit         fulld;
    bit         recsmall;   // MODER.RECSMALL
    bit         pro;        // MODER.PRO       - promiscuous
    bit         iam;        // MODER.IAM       - individual hash addr mode
    bit         bro;        // MODER.BRO       - reject broadcast unless PRO
    bit         ifg_byp;    // MODER.IFG       - 1 = accept regardless of IFG
    bit [15:0]  minfl;      // PACKETLEN.MINFL
    bit [15:0]  maxfl;      // PACKETLEN.MAXFL
    bit         passall;    // CTRLMODER.PASSALL
    bit         rxflow;     // CTRLMODER.RXFLOW
    bit [47:0]  mac_addr;   // MAC_ADDR0/1 concatenated
    bit [31:0]  hash0;      // HASH0
    bit [31:0]  hash1;      // HASH1
} eth_rx_reg_cfg_s;

typedef struct {
    byte         exp_pkt[$];    // DA+SA+L/T+payload+CRC, as it should land in memory
    byte         payload[];
    int unsigned exp_len;
    bit          cf_flag;
    bit          miss_bit;
    bit          e_flag;
    bit          or_flag;
    bit          is_flag;
    bit          dn_flag;
    bit          tl_flag;
    bit          sf_flag;
    bit          crc_flag;
    bit          lc_flag;
} eth_rx_expected_s;


class eth_rx_scoreboard extends uvm_scoreboard; 
    `uvm_component_utils(eth_rx_scoreboard)

    uvm_analysis_export #(mii_rx_seq_item)   mii_rx_export;
    uvm_tlm_analysis_fifo #(mii_rx_seq_item) mii_rx_fifo;

    uvm_analysis_export #(wb_bd_seq_item)         wb_bd_export;
    uvm_tlm_analysis_fifo #(wb_bd_seq_item)       wb_m_fifo;

    // RAL model handle
    eth_reg_block                                 m_regmodel;

    // struct
    eth_rx_reg_cfg_s                              reg_s;
    eth_rx_expected_s                             exps;

    int unsigned frames_total;              // all MII frames seen
    int unsigned frames_predicted_drop;     // predictor   HW silently discards
    int unsigned frames_predicted_accept;   // predictor   HW stores to memory
    int unsigned compare_pass;              // comparator passed
    int unsigned compare_fail;              // comparator FAILED         
    
    // Drop sub-category counters (for report_phase detail)
    int unsigned drops_phy_abort;           // Phase A: MRxErr abort
    int unsigned drops_ifg;                 // Phase B: IFG violation
    int unsigned drops_addr;               // Phase C: address filter
    int unsigned drops_length;             // Phase D: length below MINFL

    int      m_bd_index;              // index of the RX BD currently armed, relative to the RX region
    event    m_ev_rxen;               // MODER.RXEN 0 -> 1
    // IFG STATE
    // The scoreboard tracks when the previous frame ended
    // whether the inter-frame gap satisfies the minimum 0.96 µs (960 ns) at 100 Mbps.

    realtime  last_frame_end_time_ns;
    bit       first_frame_seen;   // suppresses IFG check before first frame

    extern function new(string name, uvm_component parent);
    extern function void build_phase(uvm_phase phase);
    extern function void connect_phase(uvm_phase phase);
    extern task run_phase(uvm_phase phase);

    extern task track_rxen();

    extern function automatic void predictor();

    extern function automatic void comparator();

    

    extern function automatic bit compute_hash_hit();

    extern function automatic bit [7:0] reflect_byte();

    extern function automatic bit [31:0] reflect_word();

    extern function automatic bit is_pause_frame();

endclass

// -------------------------------------------------------
// CONSTRUCTOR
// -------------------------------------------------------
function eth_rx_scoreboard::new(string name, uvm_component parent);
    super.new(name, parent);
    
    last_frame_end_time_ns   = 0.0;
    first_frame_seen         = 1'b0;
    // zero statistics
    frames_total             = 0;
    frames_predicted_drop    = 0;
    frames_predicted_accept  = 0;
    compare_pass             = 0;
    compare_fail             = 0;
    drops_phy_abort          = 0;
    drops_ifg                = 0;
    drops_addr               = 0;
    drops_length             = 0;
endfunction

// -------------------------------------------------------
// BUILD PHASE
// -------------------------------------------------------
function void eth_rx_scoreboard::build_phase(uvm_phase phase);
    super.build_phase(phase);
    //analysis export
    mii_rx_export = new("mii_rx_export", this);
    wb_bd_export  = new("wb_bd_export", this);
    // Build fifo
    mii_rx_fifo   = new("mii_rx_fifo", this);
    wb_m_fifo     = new("wb_m_fifo", this);

    // RAL handle — test/env sets this via uvm_config_db
    if (!uvm_config_db #(eth_reg_block)::get(this, "", "m_regmodel", m_regmodel))
    `uvm_fatal("SB/CFG", "eth_rx_scoreboard: cannot retrieve eth_reg_block from uvm_config_db")
endfunction 

// -------------------------------------------------------
// CONNECT PHASE
// -------------------------------------------------------
function void eth_rx_scoreboard::connect_phase(uvm_phase phase);
    mii_rx_export.connect(mii_rx_fifo.analysis_export);
    wb_bd_export.connect(wb_m_fifo.analysis_export);
endfunction

// -------------------------------------------------------
// RUN PHASE
// -------------------------------------------------------
task eth_rx_scoreboard::run_phase(uvm_phase phase);
    super.run_phase(phase);
    mii_rx_seq_item        m_rx_frame;
    wb_bd_seq_item         act_bd;
    wb_bd_seq_item         exp_bd;
    bit                    frame_dropped;

    fork
        track_rxen();
    join_none

    wait (m_ev_rxen.triggered);

    forever begin
        // Step 1: wait for the next PHY-level frame
        mii_rx_fifo.get(m_rx_frame);
        frames_total++;
        `uvm_info("SB/RUN",$sformatf("Got RX frame: %s", m_rx_frame.convert2string()), UVM_MEDIUM)

        // Step 2: predict what the DUT hardware should do
        predictor(m_rx_frame, exp_bd, frame_dropped);

        // Step 3a: predictor says DROPPED   loop without touching wb_m_fifo
        if(frame_dropped) begin
            frames_predicted_drop++;
            // IFG tracking: MRxDV deasserted even for dropped frames, so the
            // next-frame IFG window still starts from this frame's end time.
            last_frame_end_time_ns = m_rx_frame.end_time_ns;
            first_frame_seen       = 1'b1;
            continue;
        end

        // Step 3b: predictor says ACCEPTED collect WB transaction
        frames_predicted_accept++;
        wb_m_fifo.get(act_bd);

        comparator(exp_bd, act_bd, m_rx_frame);

        // Update IFG tracker for next iteration
        last_frame_end_time_ns = m_rx_frame.end_time_ns;
        first_frame_seen       = 1'b1;
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


// -------------------------------------------------------
// PREDICTOR
// -------------------------------------------------------
function automatic void eth_rx_scoreboard::predictor(
    input mii_rx_seq_item frame,
    input wb_bd_seq_item exp_bd,
    output bit frame_dropped
);
    uvm_reg_data_t moder_v, pack_v, ctrl_v;
    uvm_reg_data_t mac0_v,  mac1_v, h0_v, h1_v;

    //  Allocate output transaction ─
    exp_bd        = wb_bd_seq_item::type_id::create("exp_bd");
    frame_dropped = 1'b0; // default to accepted

    //Snapshot register mirror 
    moder_v = m_regmodel.MODER.get();
    pack_v  = m_regmodel.PACKETLEN.get();
    ctrl_v  = m_regmodel.CTRLMODER.get();
    mac0_v  = m_regmodel.MAC_ADDR0.get();
    mac1_v  = m_regmodel.MAC_ADDR1.get();
    h0_v    = m_regmodel.HASH0.get();
    h1_v    = m_regmodel.HASH1.get();

    //  Unpack MODER fields (Spec §3.1 Table 4) 
    //    Bit[16]=RECSMALL [14]=HUGEN [12]=DLYCRCEN [10]=FULLD [6]=IFG
    //    Bit[5]=PRO [4]=IAM [3]=BRO
    reg_s.recsmall  = moder_v[16];
    reg_s.hugen     = moder_v[14];
    reg_s.dlycrcen  = moder_v[12];
    reg_s.fulld     = moder_v[10];
    reg_s.ifg_byp   = moder_v[6];
    reg_s.pro       = moder_v[5];
    reg_s.iam       = moder_v[4];
    reg_s.bro       = moder_v[3];
    //  Unpack PACKETLEN (Spec §3.7 Table 10) 
    //    Bits[31:16] = MINFL,  Bits[15:0] = MAXFL
    reg_s.minfl = pack_v[31:16];
    reg_s.maxfl = pack_v[15:0];
    //  Unpack CTRLMODER (Spec §3.10 Table 13) ─
    //    Bit[1]=RXFLOW,  Bit[0]=PASSALL
    reg_s.rxflow  = ctrl_v[1];
    reg_s.passall = ctrl_v[0];
    //  Reconstruct 48-bit MAC address from MAC_ADDR0 / MAC_ADDR1 
    //    "byte 0 is sent first and byte 5 last."
    //    da[47:40]=byte0 (first byte on wire) matches mac_addr[47:40]
    reg_s.mac_addr = {  mac1_v[15:8],   // byte 0 (first on wire)
                        mac1_v[7:0],    // byte 1
                        mac0_v[31:24],  // byte 2
                        mac0_v[23:16],  // byte 3
                        mac0_v[15:8],   // byte 4
                        mac0_v[7:0]  }; // byte 5 (last on wire)

    reg_s.hash0 = h0_v[31:0];
    reg_s.hash1 = h1_v[31:0];

    //  Raw frame length (DA..CRC inclusive, preamble+SFD already stripped) 
    //exps.exp_len = frame.payload_no_crc.size() + 4;  // +4 = 4 CRC bytes
    exps.exp_len = frame.frame_data_q.size() ;  

    // PHASE A — PHY-LEVEL ABORT
    if (frame.phy_error) begin
        `uvm_info("SB/PRED/A",
            $sformatf("[%0t ns] #%0d Phase A — PHY ABORT (MRxErr asserted). DA=%0h. DROPPED.",
            $realtime, frames_total, frame.destination_addr), UVM_MEDIUM)
        frame_dropped  = 1'b1;
        drops_phy_abort++;
        return;   // < early exit: no WB transaction expected
    end

    //  Phase A.2: capture IS flag (soft error, no drop) Invalid Symbol (BD bit[5])
    exp_s.is_flag = frame.invalid_symbol;

    // PHASE B — IFG VIOLATION
    if (!reg_s.ifg_byp && first_frame_seen) begin
      real gap_ns;
      gap_ns = frame.start_time_ns - last_frame_end_time_ns;
      if (gap_ns < IFG_MIN_NS) begin
        `uvm_info("SB/PRED/B",
            $sformatf("[%0t ns] #%0d Phase B — IFG violation: gap=%.1f ns < %.1f ns. DA=%0h. DROPPED.",
            $realtime, frames_total, gap_ns, IFG_MIN_NS, frame.destination_addr), UVM_MEDIUM)
        frame_dropped = 1'b1;
        drops_ifg++;
        return;   // < early exit
      end
    end

    ///////////////////////////////////////////////////////////////////////
    // PHASE C — ADDRESS RECOGNITION
    
    bit addr_accepted = 1'b0;
    exp_s.miss_bit      = 1'b0;
    exp_s.cf_flag       = 1'b0;

    begin : phase_c_addr
        bit is_bcast, is_mcast, is_ucast;
        bit hash_hit;
        bit addr_would_match_without_pro;

        is_bcast = (frame.destination_addr == BCAST_ADDR);
        // Multicast: bit[0] of DA (first byte) = 1, but NOT broadcast
        is_mcast = (frame.destination_addr[0] == 1'b1) && !is_bcast;
        is_ucast = (frame.destination_addr[0] == 1'b0);

        //  P0: PAUSE / MAC Control frame (§4.5.1 Figure 3) 
        //   Valid PAUSE frame: DA = PAUSE_MCAST or DA = our MAC
        //                      EtherType = 0x8808 at bytes[12:13]
        //                      Opcode    = 0x0001 at bytes[14:15]
        //
        //   PASSALL=0, RXFLOW=x → control module consumes frame; not stored
        //                          to host memory → DROPPED from WB perspective.
        //   PASSALL=0, RXFLOW=1 → RXC interrupt set, PAUSE timer updated,
        //                          frame still NOT in host memory.
        //   PASSALL=1, any RXFLOW → frame stored in memory with CF=1;
        //                            RXB interrupt set (not RXC per §4.5.1 note).
        //
        //   Spec §4.5.1: "If PASSALL bit is set then the control frame is stored
        //   to the memory and related buffer descriptor has the control frame bit
        //   (CF) set to 1."
        if (is_pause_frame(frame)) begin
            exp_s.cf_flag = 1'b1;
            if (!reg_s.passall) begin
            `uvm_info("SB/PRED/C",
                $sformatf("[%0t ns] #%0d Phase C — PAUSE frame, PASSALL=0.Control module processes, NOT stored to memory. DROPPED.",
                $realtime, frames_total), UVM_MEDIUM)
            frame_dropped = 1'b1;
            drops_addr++;
            return;   // < early exit; no WB transaction
            end 
            // PASSALL=1: fall through with exp_s.cf_flag=1; frame will be stored
            addr_accepted = 1'b1;
            exp_s.miss_bit      = 1'b0;  // CF frame: not an address miss
            `uvm_info("SB/PRED/C",
                $sformatf("[%0t ns] #%0d Phase C — PAUSE frame, PASSALL=1. CF=1. ACCEPTED.",
                $realtime, frames_total), UVM_MEDIUM)
            

        /////////////////////////////////////// P1: PRO=1 — accept everything, compute M bit /////////////////////
        end else if (reg_s.pro) begin
            addr_accepted = 1'b1;
            // Determine what address recognition would say WITHOUT PRO
            // to decide the M bit correctly
            if (is_bcast)
            addr_would_match_without_pro = !bro;   // bro=0 → match, bro=1 → miss
            else if (is_ucast)
            addr_would_match_without_pro = (frame.destination_addr == mac_addr);
            else  // multicast
            addr_would_match_without_pro = iam && compute_hash_hit(frame.destination_addr, hash0, hash1);

            exp_s.miss_bit = !addr_would_match_without_pro;
            `uvm_info("SB/PRED/C",
                $sformatf("[%0t ns] #%0d Phase C — PRO=1. ACCEPTED. M=%0b (addr_match_wo_pro=%0b).",
                $realtime, frames_total, exp_s.miss_bit, addr_would_match_without_pro),UVM_MEDIUM)

        end else begin
            // PRO=0: strict address recognition

            ///////////////////////////////////// P2: Broadcast ///////////////////////////////////////
            if (is_bcast) begin
                if (!reg_s.bro) begin
                    addr_accepted = 1'b1;
                    exp_s.miss_bit      = 1'b0;
                    `uvm_info("SB/PRED/C",
                        $sformatf("[%0t ns] #%0d Phase C — BCAST, BRO=0. ACCEPTED.",
                        $realtime, frames_total), UVM_MEDIUM)
                end else begin
                    // BRO=1, PRO=0: spec §3.1 "reject all broadcast unless PRO=1"
                    `uvm_info("SB/PRED/C",
                        $sformatf("[%0t ns] #%0d Phase C — BCAST, BRO=1, PRO=0. DROPPED.",
                        $realtime, frames_total), UVM_MEDIUM)
                    frame_dropped = 1'b1;
                    drops_addr++;
                    return;
                end

            ///////////////////////////////////// P3: Unicast /////////////////////////////////////////////
            end else if (is_ucast) begin
            if (frame.destination_addr == mac_addr) begin
                addr_accepted = 1'b1;
                exp_s.miss_bit      = 1'b0;
                `uvm_info("SB/PRED/C",
                    $sformatf("[%0t ns] #%0d Phase C — UCAST match DA=%0h. ACCEPTED.",
                    $realtime, frames_total, frame.destination_addr), UVM_MEDIUM)
            end else begin
                `uvm_info("SB/PRED/C",
                    $sformatf("[%0t ns] #%0d Phase C — UCAST mismatch DA=%0h, MAC=%0h. DROPPED.",
                    $realtime, frames_total, frame.destination_addr, mac_addr), UVM_MEDIUM)
                frame_dropped = 1'b1;
                drops_addr++;
                return;
            end

            //////////////////////////////////// P4: Multicast (not broadcast) ////////////////////////////////
            end else begin
            if (reg_s.iam) begin
                hash_hit = compute_hash_hit(frame.destination_addr, hash0, hash1);
                if (hash_hit) begin
                addr_accepted = 1'b1;
                exp_s.miss_bit      = 1'b0;
                `uvm_info("SB/PRED/C",
                    $sformatf("[%0t ns] #%0d Phase C — MCAST DA=%0h, IAM=1, hash HIT. ACCEPTED.",
                    $realtime, frames_total, frame.destination_addr), UVM_MEDIUM)
                end else begin
                `uvm_info("SB/PRED/C",
                    $sformatf("[%0t ns] #%0d Phase C — MCAST DA=%0h, IAM=1, hash MISS. DROPPED.",
                    $realtime, frames_total, frame.destination_addr), UVM_MEDIUM)
                frame_dropped = 1'b1;
                drops_addr++;
                return;
                end
            end else begin
                // IAM=0: no hash table; multicast not accepted
                `uvm_info("SB/PRED/C",
                    $sformatf("[%0t ns] #%0d Phase C — MCAST DA=%0h, IAM=0. DROPPED.",
                    $realtime, frames_total, frame.destination_addr), UVM_MEDIUM)
                frame_dropped = 1'b1;
                drops_addr++;
                return;
            end
            end
        end
    end : phase_c_addr

    /////////////////////////////////////////////////////////////////////////////////////
    // PHASE D — LENGTH GATING
    //   Decision matrix:
    //     raw_len < MINFL, RECSMALL=0 → SILENT DROP (BD not consumed)
    //     raw_len < MINFL, RECSMALL=1 → ACCEPT, SF=1 in BD
    //     raw_len ≤ 4                 → ACCEPT with CRC error (§4.2.4 note)
    //                                   RECSMALL must also be 1 to reach here
    //     raw_len > MAXFL, HUGEN=0   → ACCEPT, TL=1, cap exp_s.exp_len at MAXFL
    //     raw_len > MAXFL, HUGEN=1   → ACCEPT, TL=0, exp_s.exp_len = raw_len
    //     MINFL ≤ raw_len ≤ MAXFL   → ACCEPT, SF=0, TL=0

    exp_s.sf_flag  = 1'b0;
    exp_s.tl_flag  = 1'b0;
   

    begin : phase_d_length
        /////////////////////////////// Short frame decision ////////////////////////////////
        if (exps.exp_len < reg_s.minfl) begin
            if (!reg_s.recsmall) begin
            // RECSMALL=0: "Packets smaller than MINFL are ignored."
            // Silently discard: BD not consumed, zero DMA writes.
            `uvm_info("SB/PRED/D",
                $sformatf("[%0t ns] #%0d Phase D — SHORT FRAME len=%0d < MINFL=%0d,RECSMALL=0. DROPPED.",
                $realtime, frames_total, exps.exp_len, minfl), UVM_MEDIUM)
            frame_dropped = 1'b1;
            drops_length++;
            return;   // < early exit
            end else begin
            // RECSMALL=1: "Packets smaller than MINFL are accepted."  SF=1.
            exp_s.sf_flag = 1'b1;
            `uvm_info("SB/PRED/D",
                $sformatf("[%0t ns] #%0d Phase D — SHORT FRAME len=%0d < MINFL=%0d, RECSMALL=1. ACCEPTED, SF=1.",
                $realtime, frames_total, exps.exp_len, minfl), UVM_MEDIUM)
            end
        end

        //   frames ≤ 4 bytes always produce CRC error 
        //   (4-byte frame = only CRC bytes, zero payload ≡ CRC all-wrong)
        //   This check applies INSIDE the "RECSMALL=1 accept" branch above.
        //   We do NOT drop here; CRC error flag is assembled 
        //   (exp_s.crc_flag will be forced for exps.exp_len <= 4.)

        /////////////////////////////////// Oversized frame decision //////////////////////////////////
        if (!reg_s.hugen && (exps.exp_len > reg_s.maxfl)) begin
            // HUGEN=0: truncate at MAXFL.  Frame IS accepted but TL=1.
            // DUT stops DMA after MAXFL bytes; memory has exactly MAXFL bytes.
            exp_s.tl_flag = 1'b1;
            exp_s.exp_len  = reg_s.maxfl;
            `uvm_info("SB/PRED/D",
                $sformatf("[%0t ns] #%0d Phase D — OVERSIZE len=%0d > MAXFL=%0d, HUGEN=0.ACCEPTED, TL=1, truncated to %0d.",
                $realtime, frames_total, exps.exp_len, reg_s.maxfl, reg_s.maxfl), UVM_MEDIUM)
        end else if (reg_s.hugen && (exps.exp_len > reg_s.maxfl)) begin
            // HUGEN=1: accept jumbo frames without truncation.  TL stays 0.
            `uvm_info("SB/PRED/D",
                $sformatf("[%0t ns] #%0d Phase D — JUMBO len=%0d > MAXFL=%0d, HUGEN=1.ACCEPTED (no truncation).",
                $realtime, frames_total, exps.exp_len, reg_s.maxfl), UVM_MEDIUM)
        end

    end : phase_d_length

    ////////////////////////////////////////////////////////////////////////////////////////
    // PHASE E — ERROR BIT ASSEMBLY
    //
    //   Assemble the remaining Rx BD status bits for all frames that have
    //   passed Phases A–D without being silently dropped.

    /////////////////////////////CRC Error ////////////////////////////////////////
    //   Normal mode   (DLYCRCEN=0): CRC computed immediately after SFD.
    //   Delayed mode  (DLYCRCEN=1): CRC computation starts 4 bytes after SFD
    //   The MII monitor provides crc_delayed_ok for this mode.
    //   Frames ≤ 4 bytes (exps.exp_len ≤ 4): CRC is always wrong per §4.2.4 note
    //   (payload ≤ 0 bytes; only CRC bytes present which cannot be valid).

    if ((exps.exp_len - 4) == 0 || exps.exp_len <= 4) begin
      // No payload bytes → CRC inherently invalid
      exp_s.crc_flag = 1'b1;
    end else if (reg_s.dlycrcen) begin
      // tc_rx_delayed_crc: MII monitor computes CRC starting 4 bytes post-SFD
      exp_s.crc_flag = !frame.crc_delayed_ok;
    end else begin
      // Normal CRC check
      exp_s.crc_flag = !frame.crc_ok;
    end

    /////////////////////////Dribble Nibble (BD bit[4])////////////////////////////////
    //   Set when total received nibble count is odd (frame not divisible by 8).
    exp_s.dn_flag = frame.dribble_nibble;

    ///////////////////////// Late Collision (BD bit[0], tc_rx_late_collision, RX-FEAT-012)
    //   Half-duplex only (MODER.FULLD=0).PHY asserts MColl after the COLLVALID window (>64 bytes from preamble).
    exp_s.lc_flag = (!fulld) && frame.late_collision;

    //////////////////////////////////////////////////////////////////////////////////
    // PHASE F — FINAL BD ASSEMBLY
    
    exp_s.e_flag      = 1'b0;             // E MUST be cleared when frame is stored
    exp_s.exp_len;    // LEN = exps.exp_len or MAXFL when TL=1
    exp_s.cf_flag;    // Control frame (PAUSE with PASSALL=1)
    exp_s.miss_bit;   // Miss: accept ed only via PRO
    exp_s.or_flag  = 1'b0;          // Overrun not predictable from PHY data;
                                    // comparator handles OR mismatch gracefully
    exp_s.is_flag;    // Invalid symbol during reception
    exp_s.dn_flag;    // Dribble nibble
    exp_s.tl_flag;    // Too long (HUGEN=0 and raw > MAXFL)
    exp_s.sf_flag;    // Short frame (RECSMALL=1 and len < MINFL)
    exp_s.crc_flag;   // CRC-32 failed (or DLYCRCEN-adjusted)
    exp_s.lc_flag;    // Late collision (half-duplex only)

    /////////////////////////////// Build expected payload slice //////////////////////////////////
    //   Convention (verified against tc_rx_basic_frame: "60-byte payload +
    //   4-byte CRC → LEN=64"):
    //     exp_bd.len includes CRC bytes in the COUNT.
    //     The DUT writes the FULL frame (payload + CRC) to host memory.
    //     LEN = total bytes DMA-written = payload_no_crc.size() + 4 normally,
    //           or MAXFL when truncated.
    //   The comparator will later compare only first (exp_s.exp_len - 4) bytes for
    //   valid-CRC frames (CRC-stripped comparison).  For truncated or CRC-error
    //   frames the comparator compares all exp_s.exp_len bytes without stripping.
    //
    //   exp_bd.payload holds a COPY of the MII frame bytes up to exp_s.exp_len.
    //   For truncated frames: first min(payload_no_crc.size(), exp_s.exp_len) raw bytes.
    begin
        int unsigned payload_bytes_available;
        int unsigned payload_bytes_to_store;

        payload_bytes_available = frame.payload_no_crc.size();

        if (exp_s.tl_flag) begin
            // Truncated: DUT stores MAXFL raw bytes (CRC not stripped, never reached)
            // First min(payload_available, exp_s.exp_len) bytes go to memory
            payload_bytes_to_store = (payload_bytes_available < exp_s.exp_len)
                                    ? payload_bytes_available : exp_s.exp_len;
        end else begin
            // Normal: DUT stores exp_s.exp_len bytes = payload_no_crc + CRC
            // payload_no_crc.size() should equal exp_s.exp_len - 4
            payload_bytes_to_store = payload_bytes_available;
        end

        exp_s.payload = new[payload_bytes_to_store];
        for (int unsigned i = 0; i < payload_bytes_to_store; i++)
            exp_s.payload[i] = frame.payload_no_crc[i];
    end

    `uvm_info("SB/PRED/F",
        $sformatf("[%0t ns] #%0d PREDICT ACCEPT: DA=%0h len=%0d→%0d BD[E=%0b CF=%0b M=%0b OR=?? IS=%0b DN=%0b TL=%0b SF=%0b CRC=%0b LC=%0b]",
            $realtime, frames_total, frame.destination_addr, exps.exp_len, 
            exp_s.exp_len, exp_s.e,  exp_s.cf,  exp_s.m,
            exp_s.is_flag, exp_s.dn, exp_s.tl, exp_s.sf,
            exp_s.crc_flag, exp_s.lc), UVM_MEDIUM)


endfunction

// -------------------------------------------------------
// COMPARATOR
// -------------------------------------------------------

function automatic void eth_rx_scoreboard::comparator(
    input wb_bd_seq_item     exp_bd,
    input wb_bd_seq_item     act_bd,
    input mii_rx_seq_item    frame   
)

    bit pass = 1'b1;
    string msg = "";

    //  BD.E — must be 0 after DUT accepts the frame 
    if (act_bd.e !== 1'b0) begin
      msg  = {msg, $sformatf("\n E-bit : exp=0 act=%0b  ← DUT did not clear E (BD not consumed)", act_bd.e)};
      pass = 1'b0;
    end

    //  CF — Control Frame flag 
    if (act_bd.cf !== exp_s.cf) begin
      msg  = {msg, $sformatf("\n    CF    : exp=%0b act=%0b", exp_s.cf, act_bd.cf)};
      pass = 1'b0;
    end

    //  M — Miss bit 
    //  Critical for address recognition tests 
    if (act_bd.m !== exp_s.m) begin
      msg  = {msg, $sformatf("\n    M-bit : exp=%0b act=%0b  ← address recognition error", exp_s.m, act_bd.m)};
      pass = 1'b0;
    end

    //  OR — Overrun 
    //   Expected OR was deliberately set (e.g., tc_rx_overrun): hard fail if
    //   DUT does not report it.
    //   Unexpected OR (predicted=0 but DUT reports 1): INFO warning only —
    //   cannot deterministically predict WB stalls from PHY timestamps alone.
    if (exp_s.or_flag !== act_bd.or_flag) begin
        if (exp_s.or_flag) begin
            msg  = {msg, $sformatf("\n  OR  : exp=%0b act=%0b  ← expected overrun NOT seen", exp_s.or_flag, act_bd.or_flag)};
            pass = 1'b0;
        end else begin
            `uvm_info("SB/CMP",
                $sformatf("[%0t ns] WARNING — Unexpected OR=1 in act_bd (no WB stall modelled for this frame). Frame DA=%0h",
                $realtime, frame.destination_addr), UVM_MEDIUM)
        end
    end

    //  IS — Invalid Symbol 
    if (act_bd.is_flag !== exp_s.is_flag) begin
      msg  = {msg, $sformatf("\n    IS    : exp=%0b act=%0b", exp_s.is_flag, act_bd.is_flag)};
      pass = 1'b0;
    end

    //  DN — Dribble Nibble 
    if (act_bd.dn !== exp_s.dn) begin
      msg  = {msg, $sformatf("\n    DN    : exp=%0b act=%0b", exp_s.dn, act_bd.dn)};
      pass = 1'b0;
    end

    //  TL — Too Long 
    if (act_bd.tl !== exp_s.tl) begin
      msg  = {msg, $sformatf("\n    TL    : exp=%0b act=%0b", exp_s.tl, act_bd.tl)};
      pass = 1'b0;
    end

    //  SF — Short Frame  
    if (act_bd.sf !== exp_s.sf) begin
      msg  = {msg, $sformatf("\n    SF    : exp=%0b act=%0b", exp_s.sf, act_bd.sf)};
      pass = 1'b0;
    end

    //  CRC — CRC Error 
    if (act_bd.crc_err !== exp_s.crc_err) begin
      msg  = {msg, $sformatf("\n    CRC   : exp=%0b act=%0b", exp_s.crc_err, act_bd.crc_err)};
      pass = 1'b0;
    end

    //  LC — Late Collision 
    if (act_bd.lc !== exp_s.lc) begin
      msg  = {msg, $sformatf("\n    LC    : exp=%0b act=%0b", exp_s.lc, act_bd.lc)};
      pass = 1'b0;
    end

    //  LEN field — skip on overrun (DMA partial, LEN undefined) 
    //   tc_rx_basic_frame: "LEN field value matches received byte count"
    if (!act_bd.or_flag) begin
      if (act_bd.len !== exp_s.len) begin
        msg  = {msg, $sformatf("\n    LEN   : exp=%0d act=%0d  ← byte count mismatch",
                  exp_s.len, act_bd.len)};
        pass = 1'b0;
      end
    end

    //  PAYLOAD byte-by-byte comparison ─
    //
    //   Skip conditions:
    //     1. act_bd.or_flag==1    : memory content undefined after overrun
    //     2. exp_bd.crc_err==1    : payload may be corrupted by deliberate
    //                               CRC injection (tc_rx_crc_check_fail);
    //                               we already checked the CRC flag above
    //     3. tl_flag and payload
    //        already compared     : handled below by adjusting cmp_len
    //
    //   CRC stripping:
    //     For valid-CRC, non-truncated frames: compare first (exp_bd.len - 4)
    //     bytes only.  The last 4 bytes in memory are the CRC; we do not
    //     compare them separately (the CRC bit in the BD is the pass/fail
    //     signal for CRC correctness).
    //     For truncated frames (tl=1): compare all exp_s.payload bytes
    //     (no CRC at the end — frame was cut before CRC bytes were received).
    if (!act_bd.or_flag && !exp_s.crc_err) begin
        int unsigned cmp_len;   // bytes to compare

        if (exp_s.tl) begin
            // Truncated: all exp_s.len bytes stored raw; no CRC stripping
            cmp_len = exp_s.len;
        end else begin
            // Normal: strip 4 CRC bytes (they ARE in memory, just not compared)
            cmp_len = (exp_s.len >= 4) ? (exp_s.len - 4) : 0;
        end

        // Size sanity check
        if (act_bd.payload.size() < cmp_len) begin
            msg  = {msg, $sformatf("\n    PAYLOAD SIZE: exp_cmp=%0d act_payload_size=%0d  ← too few bytes in DMA log",
                    cmp_len, act_bd.payload.size())};
            pass = 1'b0;
        end else if (exp_s.payload.size() < cmp_len) begin
            msg  = {msg, $sformatf("\n    PAYLOAD SIZE: cmp_len=%0d exp_payload_size=%0d  ← scoreboard internal error",
                    cmp_len, exp_s.payload.size())};
            pass = 1'b0;
        end else begin
            // Byte-by-byte comparison (cap error prints at 16 bytes)
            int unsigned first_mismatch = 0;
            int unsigned mismatch_count = 0;
            for (int unsigned b = 0; b < cmp_len; b++) begin
            if (act_bd.payload[b] !== exp_s.payload[b]) begin
                if (mismatch_count == 0) first_mismatch = b;
                mismatch_count++;
                if (mismatch_count <= 16) begin
                msg = {msg, $sformatf("\n    PAYLOAD[%0d]: exp=0x%02h act=0x%02h",
                        b, exp_s.payload[b], act_bd.payload[b])};
                end else if (mismatch_count == 17) begin
                msg = {msg, "\n    ... (further payload mismatches suppressed)"};
                end
            end
            end
            if (mismatch_count > 0) begin
            msg  = {msg, $sformatf("\n    PAYLOAD TOTAL: %0d/%0d bytes mismatched (first@[%0d])",
                        mismatch_count, cmp_len, first_mismatch)};
            pass = 1'b0;
            end
        end
    end

    //  Final verdict ─
    if (pass) begin
      compare_pass++;
      `uvm_info("SB/PASS",
            $sformatf("[%0t ns] PASS #%0d — DA=%0h len=%0d%s%s%s%s",
            $realtime, compare_pass, frame.destination_addr, exp_s.len,
            exp_s.crc_err ? " CRC-ERR" : "",
            exp_s.sf      ? " SF"       : "",
            exp_s.tl      ? " TL"       : "",
            exp_s.cf      ? " CF"       : ""),
            UVM_MEDIUM)
    end else begin
      compare_fail++;
      `uvm_error("SB/FAIL",
        $sformatf("[%0t ns] FAIL #%0d — DA=%0h exp_len=%0d act_len=%0d\n  MISMATCHES:%s",
            $realtime, compare_fail,
            frame.destination_addr, exp_s.len, act_bd.len, msg))
    end

endfunction

function automatic bit is_pause_frame(input mii_rx_seq_item frame);
    uvm_reg_data_t mac0_v, mac1_v;
    bit [47:0]     our_mac;
    bit [15:0]     ethertype, opcode;

    // Need at least DA(6)+SA(6)+Type(2)+Opcode(2) = 16 bytes of payload
    if (frame.payload_no_crc.size() < 16) return 1'b0;

    // Reconstruct our MAC from RAL for DA comparison
    mac0_v  = m_regmodel.MAC_ADDR0.get();
    mac1_v  = m_regmodel.MAC_ADDR1.get();
    our_mac = { mac1_v[15:8], mac1_v[7:0],
                mac0_v[31:24], mac0_v[23:16],
                mac0_v[15:8],  mac0_v[7:0] };

    // EtherType is at payload_no_crc[12:13] (bytes after DA+SA)
    ethertype = { frame.payload_no_crc[12], frame.payload_no_crc[13] };
    // Opcode is at payload_no_crc[14:15]
    opcode    = { frame.payload_no_crc[14], frame.payload_no_crc[15] };

    return ((frame.destination_addr == PAUSE_MCAST) || (frame.destination_addr == our_mac)) &&
           (ethertype == PAUSE_ETYPE) && (opcode    == PAUSE_OPCODE);

endfunction : is_pause_frame

function automatic bit compute_hash_hit(
    input bit [47:0] da,
    input bit [31:0] hash0,
    input bit [31:0] hash1);

    bit [31:0]   crc;
    bit [5:0]    hash_index;
    byte unsigned da_bytes[6];
    bit [7:0]    byte_val;

    //  Unpack DA to byte array; da[47:40] = byte 0 (first on wire) ─
    da_bytes[0] = da[47:40];
    da_bytes[1] = da[39:32];
    da_bytes[2] = da[31:24];
    da_bytes[3] = da[23:16];
    da_bytes[4] = da[15:8];
    da_bytes[5] = da[7:0];

    //  IEEE 802.3 CRC-32 with bit-reflection (LSB-first processing) ─
    crc = 32'hFFFF_FFFF;  // initialisation

    for (int i = 0; i < 6; i++) begin
      byte_val = reflect_byte(da_bytes[i]);  // reflect: MSB→LSB for processing
      for (int b = 7; b >= 0; b--) begin
        if (crc[31] ^ byte_val[b])
          crc = (crc << 1) ^ CRC32_POLY;
        else
          crc = (crc << 1);
      end
    end

    // Final complement
    crc = ~crc;

    // Reflect the full 32-bit result 
    crc = reflect_word(crc);

    //  Hash index = CRC[5:0] 
    hash_index = crc[5:0];

    `uvm_info("SB/HASH",
        $sformatf("DA=%0h CRC=0x%08h hash_index=%0d → %s[%0d]=%0b",
        da, crc, hash_index,
        (hash_index < 32) ? "HASH0" : "HASH1",
        (hash_index < 32) ? hash_index : hash_index - 32,
        (hash_index < 32) ? hash0[hash_index] : hash1[hash_index - 32]), UVM_DEBUG)

    //  Bit lookup ─
    if (hash_index < 32)
        return hash0[hash_index];
    else
        return hash1[hash_index - 32];

endfunction : compute_hash_hit

  //  Byte bit-reflection (bit 7 → bit 0, bit 6 → bit 1, …) 
function automatic bit [7:0] reflect_byte(input byte unsigned b);
    bit [7:0] r;
    for (int i = 0; i < 8; i++) r[i] = b[7-i];
    return r;
endfunction : reflect_byte

  //  32-bit word bit-reflection 
function automatic bit [31:0] reflect_word(input bit [31:0] w);
    bit [31:0] r;
    for (int i = 0; i < 32; i++) r[i] = w[31-i];
    return r;
endfunction : reflect_word



`endif 