// =============================================================================
// File      : eth_tx_scoreboard.sv
// Purpose   : Transmission-only scoreboard component.
//
// See eth_tx_scoreboard_types.sv for the data classes used here.
//
// Connections expected from eth_env.connect_phase():
//
//   env.wb_slave_agt.monitor.ap.connect(tx_scb.ap_wb_slave);
//   env.wb_master_agt.ap.connect(tx_scb.ap_wb_master);
//   env.mii_agt.monitor.ap.connect(tx_scb.ap_mii);
//
// wb_master_agt is the REACTIVE agent described earlier in this
// conversation: it has no sequencer, only a monitor-style analysis
// port reporting every DMA transaction it serviced.
// =============================================================================

`include "eth_tx_scoreboard_types.sv"

class eth_tx_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(eth_tx_scoreboard)

    // =========================================================================
    // Analysis fifos — one for wishbone master, one for MII TX
    // =========================================================================
    uvm_analysis_fifo  #(wb_m_seq_item_base)        wb_m_fifo;
    uvm_analysis_fifo  #(mii_tx_seq_item_base)      mii_tx_fifo;
    
    // =========================================================================
    // Analysis exports — one for wishbone master, one for MII TX
    // =========================================================================
    uvm_analysis_fifo  #(wb_m_seq_item_base)        wb_m_export;
    uvm_analysis_fifo  #(mii_tx_seq_item_base)      mii_tx_export;


    // =========================================================================
    // Configuration — must be kept in sync with whatever the test
    // actually wrote to these registers. A test should call the setter
    // tasks below whenever it changes one of these fields; without
    // that, expected-CRC/expected-length computations will be wrong
    // through no fault of the DUT.
    // =========================================================================
    int  tx_bd_num      = 'h40;   // mirrors TX_BD_NUM register
    bit  crcen          = 1;       // mirrors MODER.CRCEN
    bit  pad_en         = 1;       // mirrors MODER.PAD
    int  minfl          = 64;      // mirrors PACKETLEN.MINFL
    int  maxfl           = 1536;    // mirrors PACKETLEN.MAXFL
    bit  hugen          = 0;       // mirrors MODER.HUGEN

    // =========================================================================
    // Internal state
    // =========================================================================

    // One pending record per BD index currently being tracked.
    // Indexed by bd_index (0..tx_bd_num-1).
    eth_tx_pending_record pending [int];

    // Completed records, kept for final reporting / late lookups.
    eth_tx_pending_record completed_q[$];

    // Statistics
    int unsigned frames_armed;
    int unsigned frames_completed_ok;
    int unsigned frames_completed_error;
    int unsigned data_mismatch_count;
    int unsigned crc_mismatch_count;
    int unsigned length_mismatch_count;
    int unsigned status_mismatch_count;
    int unsigned unmatched_wire_frames;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap_wb_slave  = new("ap_wb_slave",  this);
        ap_wb_master = new("ap_wb_master", this);
        ap_mii       = new("ap_mii",       this);
    endfunction

    // =========================================================================
    // Configuration setters — call these from your test/sequence
    // immediately after writing the corresponding register, so the
    // scoreboard's expected-value computations stay correct.
    // =========================================================================

    function void set_tx_bd_num(int val);       tx_bd_num = val;  endfunction
    function void set_crcen(bit val);            crcen     = val;  endfunction
    function void set_pad_en(bit val);           pad_en    = val;  endfunction
    function void set_minfl(int val);            minfl     = val;  endfunction
    function void set_maxfl(int val);            maxfl     = val;  endfunction
    function void set_hugen(bit val);            hugen     = val;  endfunction

    // =========================================================================
    // BD address helpers — must match eth_bd_utils.sv conventions:
    //   TX BD[i] status word offset = i*2
    //   TX BD[i] pointer word offset = i*2 + 1
    //   WISHBONE address = 0x400 + offset*4
    // =========================================================================

    function int addr_to_tx_bd_index(logic [31:0] addr);
        int word_offset;
        int bd_index;
        if (addr < 32'h400 || addr > 32'h7FC) return -1;
        word_offset = (addr - 32'h400) >> 2;
        bd_index    = word_offset >> 1;
        if (bd_index >= tx_bd_num) return -1;   // belongs to RX region
        return bd_index;
    endfunction

    function bit is_tx_bd_status_word(logic [31:0] addr);
        int word_offset = (addr - 32'h400) >> 2;
        return (word_offset % 2) == 0;
    endfunction




    // =========================================================================
    // write_wb_master()
    // Watches the DMA side: every word the DUT fetches from SRAM while
    // transmitting. wb_master_agent (the reactive agent) reports a
    // wb_transaction for every M_CYC_O+M_STB_O cycle it services.
    // =========================================================================
    function void write_wb_master(wb_transaction tr);

        int bd_idx;

        if (tr.we) return;   // a write on the master IF is RX path, not TX — ignore here

        bd_idx = find_pending_bd_for_address(tr.addr);
        if (bd_idx < 0) begin
            // A DMA read that does not correspond to any currently
            // armed TX BD's TXPNT region is unexpected — either our
            // tracking missed an arm event, or the DUT fetched from
            // an address we did not expect.
            `uvm_warning("TXSCB_UNTRACKED_DMA",
                $sformatf(
                    "DMA read at addr=0x%08X data=0x%08X does not match any " +
                    "currently-armed TX BD's TXPNT region.",
                    tr.addr, tr.rdata))
            return;
        end

        record_dma_word(bd_idx, tr.addr, tr.rdata);

    endfunction


    // -------------------------------------------------------------------------
    // Find which pending TX BD's [TXPNT, TXPNT+padded_length) region a
    // given DMA-read address falls inside.
    // -------------------------------------------------------------------------
    function int find_pending_bd_for_address(logic [31:0] addr);

        foreach (pending[idx]) begin
            int expected_len;
            if (pending[idx].cfg.txpnt == 0 && pending[idx].cfg.length == 0)
                continue; // placeholder record, not yet fully armed

            expected_len = compute_padded_length(pending[idx].cfg.length,
                                                  pending[idx].cfg.pad);

            if (addr >= pending[idx].cfg.txpnt &&
                addr <  pending[idx].cfg.txpnt + expected_len) begin
                return idx;
            end
        end
        return -1;

    endfunction


    // -------------------------------------------------------------------------
    // Record one 32-bit DMA-read word into the per-BD byte buffer,
    // respecting M_SEL_O byte enables and the (possibly unaligned)
    // base TXPNT offset, matching the byte-extraction logic described
    // for tc_bd_pointer_unaligned_tx.
    // -------------------------------------------------------------------------
    function void record_dma_word(int bd_idx, logic [31:0] addr, logic [31:0] data);

        logic [31:0] base;
        int          rel_byte_offset;

        base = pending[bd_idx].cfg.txpnt;

        // Grow the byte buffer lazily as needed
        if (pending[bd_idx].dma_bytes.size() == 0) begin
            int padded_len = compute_padded_length(pending[bd_idx].cfg.length,
                                                    pending[bd_idx].cfg.pad);
            pending[bd_idx].dma_bytes = new[padded_len];
            foreach (pending[bd_idx].dma_bytes[i])
                pending[bd_idx].dma_bytes[i] = 8'hXX; // mark unfilled
        end

        for (int b = 0; b < 4; b++) begin
            logic [31:0] byte_addr = addr + b;
            if (byte_addr < base) continue;
            rel_byte_offset = byte_addr - base;
            if (rel_byte_offset >= pending[bd_idx].dma_bytes.size()) continue;
            pending[bd_idx].dma_bytes[rel_byte_offset] = data[(b*8)+7 -: 8];
        end

    endfunction


    // -------------------------------------------------------------------------
    // Padded length helper: if PAD=1 and LEN < minfl, the DUT pads the
    // payload up to minfl before appending CRC. Used both for sizing
    // the DMA-fetch buffer (only LEN real bytes are actually fetched;
    // padding bytes are generated internally, not fetched from SRAM)
    // and for computing the expected wire-frame length.
    //
    // IMPORTANT: padding bytes are NOT fetched via DMA — only the
    // original `length` bytes are read from SRAM. We size dma_bytes
    // to the padded length only so indices line up conveniently when
    // we later build the "expected transmitted payload" for compare;
    // bytes beyond `length` in dma_bytes simply stay 8'hXX and are
    // never compared against fetched DMA data, only against the
    // wire-frame's own padding region (checked separately as zeros).
    // -------------------------------------------------------------------------
    function int compute_padded_length(int raw_length, bit pad);
        if (pad && raw_length < minfl)
            return minfl;
        return raw_length;
    endfunction


    // =========================================================================
    // write_mii()
    // Watches the WIRE: every transmitted attempt (frame or jam pattern)
    // captured by mii_monitor. mii_monitor is expected to report:
    //   - MII_TX_JAM   transactions for each 0x99999999 jam pattern seen
    //   - MII_TX_FRAME transactions for each complete MTxEn pulse that
    //     carried a real frame (preamble/SFD already stripped by the
    //     monitor, payload[] includes CRC bytes if any were sent)
    // =========================================================================
    function void write_mii(mii_transaction tr);

        case (tr.direction)

            MII_TX_JAM: begin
                handle_jam_observed();
            end

            MII_TX_FRAME: begin
                handle_tx_frame_observed(tr);
            end

            default: ; // RX-direction transactions ignored entirely here —
                       // this is the TX-only scoreboard

        endcase

    endfunction


    // -------------------------------------------------------------------------
    // A jam pattern was observed on MTxD. We do not yet know which BD
    // it belongs to (jam patterns carry no BD identity on the wire) —
    // we attribute it to whichever single TX BD is CURRENTLY armed and
    // has not yet completed. If more than one BD is armed simultaneously
    // (should not normally happen for TX, since TX is serial), we flag
    // an ambiguity rather than silently guessing.
    // -------------------------------------------------------------------------
    function void handle_jam_observed();

        int   candidate_idx = -1;
        int   candidate_count = 0;

        foreach (pending[idx]) begin
            if (pending[idx].status == null) begin
                candidate_idx = idx;
                candidate_count++;
            end
        end

        if (candidate_count == 0) begin
            `uvm_warning("TXSCB_ORPHAN_JAM",
                "Jam pattern observed on MTxD but no TX BD is currently " +
                "armed/in-flight. Possible collision injected outside any " +
                "tracked transmission window.")
            return;
        end

        if (candidate_count > 1) begin
            `uvm_error("TXSCB_AMBIGUOUS_JAM",
                $sformatf(
                    "Jam pattern observed while %0d TX BDs are simultaneously " +
                    "in flight — cannot unambiguously attribute the collision " +
                    "to a single BD. This itself likely indicates a TX " +
                    "concurrency bug, since the design is single-threaded " +
                    "for transmission.", candidate_count))
            return;
        end

        pending[candidate_idx].attempt_count++;
        `uvm_info("TXSCB",
            $sformatf("Jam attributed to TX BD[%0d], attempt_count now %0d",
                      candidate_idx, pending[candidate_idx].attempt_count),
            UVM_MEDIUM)

    endfunction


    // -------------------------------------------------------------------------
    // A complete frame (or final aborted attempt) was captured on MTxD.
    // Same single-in-flight-BD attribution logic as the jam case.
    // -------------------------------------------------------------------------
    function void handle_tx_frame_observed(mii_transaction tr);

        int                idx = -1;
        int                candidate_count = 0;
        eth_tx_wire_frame  wf;

        foreach (pending[bd_idx]) begin
            if (pending[bd_idx].status == null) begin
                idx = bd_idx;
                candidate_count++;
            end
        end

        if (candidate_count == 0) begin
            `uvm_warning("TXSCB_ORPHAN_FRAME",
                $sformatf(
                    "Captured a %0d-byte frame on MTxD but no TX BD is " +
                    "currently tracked as in-flight.", tr.payload.size()))
            unmatched_wire_frames++;
            return;
        end

        if (candidate_count > 1) begin
            `uvm_error("TXSCB_AMBIGUOUS_FRAME",
                $sformatf(
                    "Captured a frame while %0d TX BDs are simultaneously " +
                    "in flight — cannot unambiguously attribute it.",
                    candidate_count))
            unmatched_wire_frames++;
            return;
        end

        wf                = new();
        wf.payload        = tr.payload;
        wf.length         = tr.payload.size();
        wf.start_time_ns  = tr.start_time_ns;
        wf.end_time_ns    = tr.end_time_ns;
        wf.collision_count_before = pending[idx].attempt_count;

        pending[idx].wire_frame = wf;
        pending[idx].attempt_count++;

        `uvm_info("TXSCB",
            $sformatf("Captured %s for TX BD[%0d]", wf.to_string(), idx),
            UVM_MEDIUM)

        check_completed_record(idx);

    endfunction


    // =========================================================================
    // check_completed_record()
    // Called whenever EITHER the wire frame OR the BD status readback
    // newly arrives. Only performs the full check once BOTH are present,
    // since either order is possible depending on relative monitor
    // latency (mii_monitor finishes a cycle or two before the host's
    // subsequent WISHBONE poll returns, or vice versa).
    // =========================================================================
    function void check_completed_record(int bd_idx);

        eth_tx_pending_record rec;

        if (!pending.exists(bd_idx)) return;
        rec = pending[bd_idx];

        if (rec.wire_frame == null || rec.status == null)
            return;   // still waiting on the other half

        do_full_tx_check(rec);

        completed_q.push_back(rec);
        pending.delete(bd_idx);

    endfunction


    // =========================================================================
    // do_full_tx_check()
    // The actual correctness checks, run once per completed TX BD:
    //   1. Length check (raw vs padded vs CRC-appended, matched against
    //      what the spec says should happen for this PAD/CRC/length combo)
    //   2. Payload byte-for-byte check against DMA-fetched SRAM bytes
    //      (padding region checked against zero, not against DMA data,
    //      since padding is generated internally — see compute_padded_length)
    //   3. CRC recomputation and comparison against the trailing 4 bytes
    //      actually transmitted, if CRC was supposed to be present
    //   4. BD status sanity: RD must be 0; if status shows an error
    //      (UR/RL/LC), the captured wire frame must be SHORTER than a
    //      full successful frame, consistent with an aborted attempt;
    //      if status shows success (no error bits), RTRY must equal
    //      collision_count_before exactly
    // =========================================================================
    function void do_full_tx_check(eth_tx_pending_record rec);

        int expected_payload_len;
        int expected_wire_len;
        bit any_error;

        any_error = rec.status.ur || rec.status.rl || rec.status.lc;

        // ---- 1. Length check -------------------------------------------------
        expected_payload_len = compute_padded_length(rec.cfg.length, rec.cfg.pad);
        expected_wire_len    = expected_payload_len + (rec.cfg.crc ? 4 : 0);

        if (!any_error) begin
            if (rec.wire_frame.length !== expected_wire_len) begin
                `uvm_error("TXSCB_LEN",
                    $sformatf(
                        "TX BD[%0d] length mismatch on successful transmission.\n" +
                        "  cfg: %s\n"                                              +
                        "  expected wire length = %0d (payload=%0d + crc=%0d)\n"   +
                        "  actual wire length   = %0d",
                        rec.cfg.bd_index, rec.cfg.to_string(),
                        expected_wire_len, expected_payload_len,
                        (rec.cfg.crc ? 4 : 0),
                        rec.wire_frame.length))
                length_mismatch_count++;
            end
        end
        else begin
            // On an aborted attempt (underrun/retry-limit/late-collision),
            // we do not enforce a specific final length, but we DO enforce
            // that it never EXCEEDS the expected full-success length —
            // an abort producing a longer-than-normal frame would itself
            // be a distinct bug.
            if (rec.wire_frame.length > expected_wire_len) begin
                `uvm_error("TXSCB_LEN_ABORT",
                    $sformatf(
                        "TX BD[%0d] aborted transmission produced a frame " +
                        "LONGER (%0d bytes) than the expected full-success " +
                        "length (%0d bytes) — that should not be possible.",
                        rec.cfg.bd_index, rec.wire_frame.length, expected_wire_len))
                length_mismatch_count++;
            end
        end

        // ---- 2. Payload byte compare (only meaningful on success) -----------
        if (!any_error) begin
            check_payload_bytes(rec, expected_payload_len);
        end

        // ---- 3. CRC compare (only meaningful on success, and only if a
        //         CRC trailer was supposed to be present) ---------------------
        if (!any_error && rec.cfg.crc) begin
            check_crc(rec, expected_payload_len);
        end

        // ---- 4. Status/attempt-count cross-check -----------------------------
        if (!any_error) begin
            if (rec.status.rtry !== rec.wire_frame.collision_count_before) begin
                `uvm_error("TXSCB_RTRY",
                    $sformatf(
                        "TX BD[%0d] RTRY field (%0d) does not match the number " +
                        "of jam patterns actually observed on MTxD before the " +
                        "successful frame (%0d).",
                        rec.cfg.bd_index, rec.status.rtry,
                        rec.wire_frame.collision_count_before))
                status_mismatch_count++;
            end
            if (rec.status.rd !== 1'b0) begin
                `uvm_error("TXSCB_RD",
                    $sformatf(
                        "TX BD[%0d] status read shows RD=1 on what was treated " +
                        "as a completion read — scoreboard bookkeeping or DUT " +
                        "behavior inconsistency.", rec.cfg.bd_index))
                status_mismatch_count++;
            end
            frames_completed_ok++;
        end
        else begin
            frames_completed_error++;
            `uvm_info("TXSCB",
                $sformatf("TX BD[%0d] completed WITH error status: %s",
                          rec.cfg.bd_index, rec.status.to_string()),
                UVM_MEDIUM)
        end

    endfunction


    // -------------------------------------------------------------------------
    // Byte-for-byte payload compare: real-data region against DMA-fetched
    // SRAM bytes, padding region (if any) against zero.
    // -------------------------------------------------------------------------
    function void check_payload_bytes(eth_tx_pending_record rec, int expected_payload_len);

        for (int i = 0; i < expected_payload_len; i++) begin

            byte wire_byte = rec.wire_frame.payload[i];
            byte exp_byte;

            if (i < rec.cfg.length) begin
                // real-data region — compare against what was fetched via DMA
                if (i >= rec.dma_bytes.size()) begin
                    `uvm_error("TXSCB_DMA_MISSING",
                        $sformatf(
                            "TX BD[%0d] byte %0d: no DMA-fetched data recorded " +
                            "for this offset, cannot verify wire byte 0x%02X.",
                            rec.cfg.bd_index, i, wire_byte))
                    data_mismatch_count++;
                    continue;
                end
                exp_byte = rec.dma_bytes[i];
                if (exp_byte === 8'hXX) begin
                    `uvm_error("TXSCB_DMA_MISSING",
                        $sformatf(
                            "TX BD[%0d] byte %0d: DMA-fetched byte was never " +
                            "actually captured (still unfilled marker) — " +
                            "wb_master_monitor likely missed a transaction.",
                            rec.cfg.bd_index, i))
                    data_mismatch_count++;
                    continue;
                end
            end
            else begin
                // padding region — must be zero, per spec PAD behavior
                exp_byte = 8'h00;
            end

            if (wire_byte !== exp_byte) begin
                `uvm_error("TXSCB_DATA",
                    $sformatf(
                        "TX BD[%0d] payload byte %0d mismatch.\n"  +
                        "  Expected: 0x%02X (%s)\n"                +
                        "  Actual on wire: 0x%02X",
                        rec.cfg.bd_index, i, exp_byte,
                        (i < rec.cfg.length) ? "from SRAM via DMA" : "padding, expected zero",
                        wire_byte))
                data_mismatch_count++;
            end
        end

    endfunction


    // -------------------------------------------------------------------------
    // CRC-32 recompute (IEEE 802.3 polynomial, MSB-first bit reversal as
    // used on the wire) over the payload region (real data + padding,
    // NOT including the CRC trailer itself), compared against the 4
    // trailing bytes actually observed on MTxD.
    // -------------------------------------------------------------------------
    function void check_crc(eth_tx_pending_record rec, int payload_len);

        logic [31:0] calc_crc;
        logic [31:0] wire_crc;
        byte         crc_input[];

        if (rec.wire_frame.length < payload_len + 4) begin
            `uvm_error("TXSCB_CRC_TRUNCATED",
                $sformatf(
                    "TX BD[%0d]: wire frame too short (%0d bytes) to contain " +
                    "a %0d-byte payload plus 4-byte CRC.",
                    rec.cfg.bd_index, rec.wire_frame.length, payload_len))
            crc_mismatch_count++;
            return;
        end

        crc_input = new[payload_len];
        for (int i = 0; i < payload_len; i++)
            crc_input[i] = rec.wire_frame.payload[i];

        calc_crc = calc_crc32(crc_input, payload_len);

        wire_crc[7:0]   = rec.wire_frame.payload[payload_len];
        wire_crc[15:8]  = rec.wire_frame.payload[payload_len+1];
        wire_crc[23:16] = rec.wire_frame.payload[payload_len+2];
        wire_crc[31:24] = rec.wire_frame.payload[payload_len+3];

        if (calc_crc !== wire_crc) begin
            `uvm_error("TXSCB_CRC",
                $sformatf(
                    "TX BD[%0d] CRC mismatch.\n"        +
                    "  Recomputed: 0x%08X\n"            +
                    "  On wire:    0x%08X\n"            +
                    "  Payload len used for CRC: %0d bytes",
                    rec.cfg.bd_index, calc_crc, wire_crc, payload_len))
            crc_mismatch_count++;
        end
        else begin
            `uvm_info("TXSCB",
                $sformatf("TX BD[%0d] CRC OK: 0x%08X", rec.cfg.bd_index, wire_crc),
                UVM_HIGH)
        end

    endfunction


    // -------------------------------------------------------------------------
    // CRC-32 calculation, IEEE 802.3 polynomial, matching the algorithm
    // used elsewhere in this verification environment for consistency.
    // -------------------------------------------------------------------------
    function logic [31:0] calc_crc32(byte data[], int len);

        logic [31:0] crc;
        logic [31:0] poly = 32'hEDB88320;
        byte         current_byte;
        logic        b;

        crc = 32'hFFFF_FFFF;

        for (int i = 0; i < len; i++) begin
            current_byte = data[i];
            for (int bit_i = 0; bit_i < 8; bit_i++) begin
                b   = crc[0] ^ current_byte[bit_i];
                crc = crc >> 1;
                if (b) crc = crc ^ poly;
            end
        end

        return ~crc;

    endfunction


    // =========================================================================
    // check_phase — final summary and leftover-state detection
    // =========================================================================
    function void check_phase(uvm_phase phase);

        super.check_phase(phase);

        foreach (pending[idx]) begin
            `uvm_error("TXSCB_LEFTOVER",
                $sformatf(
                    "TX BD[%0d] never reached a fully-matched completion " +
                    "(armed=%0d wire_frame=%0s status=%0s) by end of test.",
                    idx, 1,
                    (pending[idx].wire_frame == null) ? "MISSING" : "present",
                    (pending[idx].status     == null) ? "MISSING" : "present"))
        end

        `uvm_info("TXSCB",
            $sformatf(
                "\n"                                                          +
                "  ┌─────────────────────────────────────────────────┐\n"   +
                "  │         TX SCOREBOARD — FINAL REPORT             │\n"   +
                "  ├──────────────────────────────┬──────────────────┤\n"   +
                "  │ Frames armed                 │ %10d        │\n"        +
                "  │ Completed OK                 │ %10d        │\n"        +
                "  │ Completed with error status  │ %10d        │\n"        +
                "  │ Data mismatches               │ %10d        │\n"        +
                "  │ CRC mismatches                │ %10d        │\n"        +
                "  │ Length mismatches             │ %10d        │\n"        +
                "  │ Status mismatches             │ %10d        │\n"        +
                "  │ Unmatched wire frames         │ %10d        │\n"        +
                "  │ Still pending at end of test  │ %10d        │\n"        +
                "  └────────────────────────────────┴──────────────────┘",
                frames_armed, frames_completed_ok, frames_completed_error,
                data_mismatch_count, crc_mismatch_count, length_mismatch_count,
                status_mismatch_count, unmatched_wire_frames, pending.size()),
            UVM_LOW)

        if (data_mismatch_count   == 0 &&
            crc_mismatch_count    == 0 &&
            length_mismatch_count == 0 &&
            status_mismatch_count == 0 &&
            unmatched_wire_frames == 0 &&
            pending.size()         == 0) begin
            `uvm_info("TXSCB", "*** TX SCOREBOARD: ALL CHECKS PASSED ***", UVM_LOW)
        end
        else begin
            `uvm_error("TXSCB", "*** TX SCOREBOARD: FAILURES DETECTED ***")
        end

    endfunction

endclass : eth_tx_scoreboard
