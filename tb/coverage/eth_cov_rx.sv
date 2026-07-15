//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_cov_rx.sv
// Author   : Mariam & Mounir
// Date     : 2026-07-14
//------------------------------------------------------------------------------
// Description:
//   Functional coverage model for the Ethernet MAC RX path.
//
//   ARCHITECTURE DECISIONS:
//   ─────────────────────────────────────────────────────────────────────────
//   1. THREE independent analysis FIFOs — one per monitor stream.
//      Each stream is consumed by its own blocking task in run_phase.
//      No stream ever blocks another.
//
//   2. THREE parallel sampling tasks:
//      sample_mii_rx_item() — fires on complete assembled frame.
//                             Reads RAL for config state at that exact moment.
//                             Samples all frame-content covergroups.
//      sample_wb_m_item()   — fires on every DMA write from DUT to memory.
//                             Samples DMA alignment and byte-select groups.
//      sample_wb_s_item()   — fires on every WB Slave transaction.
//                             Samples configuration and interrupt groups.
//                             Uses the transaction value directly (not RAL)
//                             so register write coverage is captured at the
//                             exact moment the register was written.
//
//   3. Register state for frame-content groups uses RAL get_mirrored_value()
//      inside sample_mii_rx_item() — gives the config active during that
//      specific frame, not some earlier or later write.
//
//   4. Two structural illegal_bins detect DUT bugs automatically:
//      - DN=1 with CRC=0 in the same BD  (always paired per spec)
//      - RXC=1 AND RXB=1 simultaneously  (impossible per spec §3.2)
//
//   5. PAUSE coverage is split:
//      - Frame content side (DA, type, opcode, timer value): sample_mii_rx_item
//      - DUT response side (RXC, RXB, INTA, CF bit):        sample_wb_s_item
//
//   CONNECTION (in env connect_phase):
//      mii_rx_monitor.analysis_port    → eth_cov_rx.mii_rx_a_export
//      wb_master_monitor.analysis_port → eth_cov_rx.wb_m_a_export
//      wb_slave_monitor.analysis_port  → eth_cov_rx.wb_s_a_export
//
//   Coverage organised to match:
//     ETH_MAC_VerificationPlan_G4_G5.xlsx  (Group 4: RX, Group 5: Address)
//     Planning_control_flow.xlsx            (PAUSE / Control Frame section)
//==============================================================================

`ifndef ETH_COV_RX_SV
`define ETH_COV_RX_SV

class eth_cov_rx extends uvm_component;
    `uvm_component_utils(eth_cov_rx)

    // =========================================================================
    // RAL handle — read via get_mirrored_value() inside sample_mii_rx_item()
    // =========================================================================
    eth_reg_block m_regmodel;

    // =========================================================================
    // Analysis FIFOs — one per monitor, completely independent
    // =========================================================================
    uvm_tlm_analysis_fifo #(mii_rx_seq_item)    mii_rx_fifo;
    uvm_tlm_analysis_fifo #(wb_m_seq_item_base) wb_m_fifo;
    uvm_tlm_analysis_fifo #(wb_s_seq_item_t)    wb_s_fifo;

    // =========================================================================
    // Analysis exports — connected by environment connect_phase
    // =========================================================================
    uvm_analysis_export #(mii_rx_seq_item)    mii_rx_a_export;
    uvm_analysis_export #(wb_m_seq_item_base) wb_m_a_export;
    uvm_analysis_export #(wb_s_seq_item_t)    wb_s_a_export;

    // =========================================================================
    // Last items pulled — local to each task, declared here for covergroup
    // access (covergroups reference member variables)
    // =========================================================================
    mii_rx_seq_item    m_rx_item;    // current MII Rx frame
    wb_m_seq_item_base m_wb_m_item;  // current DMA write
    wb_s_seq_item_t    m_wb_s_item;  // current WB Slave transaction

    // =========================================================================
    // ── VARIABLES sampled by covergroups ──────────────────────────────────────
    // Populated in the three sample tasks before calling .sample()
    // =========================================================================

    //── From MII Rx item (frame content) ─────────────────────────────────────
    bit [47:0] m_dest_addr;          // destination MAC address
    bit [15:0] m_length_type;        // Ethernet Length/Type field
    int        m_frame_len;          // frame_no_crc byte count
    int        m_payload_size;       // payload[] size
    int        m_preamble_len;       // preamble byte count driven
    int        m_ifg_delay;          // inter-frame gap in nibble times
    bit        m_inject_crc_error;
    bit        m_inject_mrxerr;
    bit        m_inject_invalid_sym;
    bit        m_dribble_nibble_en;
    bit        m_inject_late_coll;

    //── From RAL mirror (read inside sample_mii_rx_item) ─────────────────────
    bit        m_ral_rxen;
    bit        m_ral_recsmall;
    bit        m_ral_hugen;
    bit        m_ral_dlycrcen;
    bit        m_ral_pro;
    bit        m_ral_iam;
    bit        m_ral_bro;
    bit        m_ral_ifg_byp;
    bit        m_ral_loopbck;
    bit        m_ral_fulld;
    bit [15:0] m_ral_minfl;
    bit [15:0] m_ral_maxfl;
    bit        m_ral_passall;
    bit        m_ral_rxflow;
    bit [47:0] m_ral_mac_addr;
    bit [31:0] m_ral_hash0;
    bit [31:0] m_ral_hash1;
    bit        m_ral_rxc_m;
    bit        m_ral_rxe_m;
    bit        m_ral_rxf_m;
    bit        m_ral_busy_m;

    //── From WB Master item (DMA write) ──────────────────────────────────────
    logic [WB_M_ADDR_WIDTH-1:0] m_dma_addr;
    logic [WB_DATA_WIDTH-1:0]   m_dma_data;
    logic [3:0]                 m_dma_sel;

    //── From WB Slave item (register write or read) ──────────────────────────
    logic [WB_S_ADDR_WIDTH-1:0] m_reg_addr;
    logic [WB_DATA_WIDTH-1:0]   m_reg_wdata;
    logic [WB_DATA_WIDTH-1:0]   m_reg_rdata;
    logic                       m_inta;

    // BD status word fields unpacked from WB Slave read of BD memory
    bit        m_bd_e;        // bit 15
    bit        m_bd_irq;      // bit 14
    bit        m_bd_wr;       // bit 13
    bit        m_bd_cf;       // bit  8
    bit        m_bd_m;        // bit  7
    bit        m_bd_or;       // bit  6
    bit        m_bd_is;       // bit  5
    bit        m_bd_dn;       // bit  4
    bit        m_bd_tl;       // bit  3
    bit        m_bd_sf;       // bit  2
    bit        m_bd_crc;      // bit  1
    bit        m_bd_lc;       // bit  0
    bit [15:0] m_bd_len;      // bits [31:16]

    // =========================================================================
    // ── COVERGROUPS ───────────────────────────────────────────────────────────
    // Grouped by which sample task owns them.
    // Comments link each covergroup to the test plan feature ID.
    // =========================================================================

    // ─────────────────────────────────────────────────────────────────────────
    // OWNER: sample_mii_rx_item()
    // These covergroups reference m_rx_item fields and m_ral_xxx fields.
    // They are sampled once per complete received frame.
    // ─────────────────────────────────────────────────────────────────────────

    // ── RX-FEAT-001  Basic frame reception ───────────────────────────────────
    // Payload size distribution (rx_rand_cg in test plan)
    covergroup cg_payload_size;

        cp_payload_size : coverpoint m_payload_size {
            bins small      = {[46:127]};    // min payload to 127B
            bins mid        = {[128:511]};
            bins large      = {[512:1500]};  // up to constraint max
        }

    endgroup : cg_payload_size

    // ── RX-FEAT-002  CRC Checking ─────────────────────────────────────────────
    // (rx_crc_cg, rx_dlycrc_cg in test plan)
    covergroup cg_crc;

        cp_crc_injected : coverpoint m_inject_crc_error {
            bins error    = {1};
            bins no_error = {0};
        }

        cp_dlycrcen : coverpoint m_ral_dlycrcen {
            bins delayed = {1};
            bins normal  = {0};
        }

        // Spec note §4.2.4: frames ≤ 4 bytes always receive CRC error
        // because CRC is 4 bytes — there is no room for valid data + CRC
        cp_tiny_frame : coverpoint m_frame_len {
            bins le_4    = {[0:4]};
            bins gt_4    = {[5:$]};
        }

        // rx_dlycrc_cg: must see CRC error in both normal and delayed mode
        cx_dlycrc_vs_crc : cross cp_dlycrcen, cp_crc_injected;

        // rx_tiny_cg: tiny frames always produce CRC=1 regardless of injection
        cx_tiny_vs_crc : cross cp_tiny_frame, cp_crc_injected;

    endgroup : cg_crc

    // ── RX-FEAT-003  Short frame ──────────────────────────────────────────────
    // (rx_short_cg in test plan)
    covergroup cg_short_frame;

        cp_frame_vs_minfl : coverpoint (m_frame_len < int'(m_ral_minfl)) {
            bins below_min   = {1};
            bins at_or_above = {0};
        }

        cp_recsmall : coverpoint m_ral_recsmall {
            bins enabled  = {1};
            bins disabled = {0};
        }

        // Boundary bins: at exactly MINFL-1, MINFL, MINFL+1
        cp_minfl_boundary : coverpoint m_frame_len {
            bins at_min_minus1 = {63};    // 63 B < default MINFL(64) → short
            bins at_min        = {64};    // exactly MINFL → accepted
            bins at_min_plus1  = {65};    // 65 B → normal
        }

        // KEY cross: all four RECSMALL × short combinations must be hit
        // short+RECSMALL=0 → DROPPED (tc_rx_short_frame_reject)
        // short+RECSMALL=1 → ACCEPTED with SF=1 (tc_rx_short_frame_accept)
        cx_short_vs_recsmall : cross cp_frame_vs_minfl, cp_recsmall {
            bins short_dropped  = binsof(cp_frame_vs_minfl.below_min) &&
                                  binsof(cp_recsmall.disabled);
            bins short_accepted = binsof(cp_frame_vs_minfl.below_min) &&
                                  binsof(cp_recsmall.enabled);
            bins normal_no_recsmall = binsof(cp_frame_vs_minfl.at_or_above) &&
                                      binsof(cp_recsmall.disabled);
            bins normal_recsmall    = binsof(cp_frame_vs_minfl.at_or_above) &&
                                      binsof(cp_recsmall.enabled);
        }

    endgroup : cg_short_frame

    // ── RX-FEAT-004  Oversized frame ──────────────────────────────────────────
    // (rx_toobig_cg in test plan)
    covergroup cg_huge_frame;

        cp_frame_vs_maxfl : coverpoint (m_frame_len > int'(m_ral_maxfl)) {
            bins above_max   = {1};
            bins at_or_below = {0};
        }

        cp_hugen : coverpoint m_ral_hugen {
            bins enabled  = {1};
            bins disabled = {0};
        }

        // Frame size distribution for jumbo testing (rx_huge_cg)
        cp_frame_huge : coverpoint m_frame_len {
            bins normal     = {[64:1518]};
            bins jumbo      = {[1519:4095]};
            bins very_large = {[4096:16383]};
        }

        // MAXFL boundary
        cp_maxfl_boundary : coverpoint m_frame_len {
            bins at_max_minus1 = {1535};  // last accepted byte before truncation
            bins at_max        = {1536};  // exactly MAXFL default
            bins at_max_plus1  = {1537};  // first truncated
        }

        // KEY cross: truncated vs accepted for oversized frames
        // HUGEN=0 + above_max → truncated at MAXFL, TL=1
        // HUGEN=1 + above_max → fully accepted, TL=0
        cx_jumbo_vs_hugen : cross cp_frame_vs_maxfl, cp_hugen {
            bins truncated = binsof(cp_frame_vs_maxfl.above_max) &&
                             binsof(cp_hugen.disabled);
            bins accepted  = binsof(cp_frame_vs_maxfl.above_max) &&
                             binsof(cp_hugen.enabled);
        }

    endgroup : cg_huge_frame

    // ── RX-FEAT-006  Preamble stripping ──────────────────────────────────────
    // (rx_preamble_cg in test plan)
    covergroup cg_preamble;

        cp_preamble_len : coverpoint m_preamble_len {
            bins zero_bytes   = {0};   // only SFD
            bins one_byte     = {1};
            bins two_bytes    = {2};
            bins short_pre    = {[3:6]};
            bins full_7_bytes = {7};   // standard
        }

    endgroup : cg_preamble

    // ── RX-FEAT-007  Error flags (DN, IS, MRxErr) ────────────────────────────
    // (rx_dribble_cg, rx_invalid_sym_cg, rx_phy_err_cg in test plan)
    covergroup cg_error_flags;

        cp_dribble : coverpoint m_dribble_nibble_en {
            bins enabled  = {1};
            bins disabled = {0};
        }

        cp_invalid_sym : coverpoint m_inject_invalid_sym {
            bins injected     = {1};
            bins not_injected = {0};
        }

        cp_mrxerr : coverpoint m_inject_mrxerr {
            bins asserted     = {1};
            bins not_asserted = {0};
        }

        // Dribble and invalid symbol are independent error types
        cx_dribble_vs_invsym : cross cp_dribble, cp_invalid_sym;

        // MRxErr vs dribble — both are PHY-level signals but different paths
        cx_mrxerr_vs_dribble : cross cp_mrxerr, cp_dribble;

    endgroup : cg_error_flags

    // ── RX-FEAT-008  RX FIFO overrun ─────────────────────────────────────────
    // Covered via WB Slave read of INT_SOURCE — see cg_interrupts below.
    // This covergroup captures the frame-side context at overrun time.
    covergroup cg_overrun_context;

        cp_frame_len_at_overrun : coverpoint m_frame_len {
            bins short_frame = {[64:127]};
            bins mid_frame   = {[128:511]};
            bins long_frame  = {[512:$]};
        }

        // Overrun is more likely with large frames + slow WB slave
        // Cross with recsmall to detect overrun on tiny accepted frames
        cp_recsmall_at_overrun : coverpoint m_ral_recsmall {
            bins enabled  = {1};
            bins disabled = {0};
        }

        cx_overrun_frame_size : cross cp_frame_len_at_overrun,
                                      cp_recsmall_at_overrun;

    endgroup : cg_overrun_context

    // ── RX-FEAT-009  IFG enforcement ─────────────────────────────────────────
    // (rx_ifg_cg, rx_ifg_mode_cg in test plan)
    covergroup cg_ifg;

        // IFG gap in nibble times (24 nibble times = 960ns at 100Mbps)
        cp_ifg_gap : coverpoint m_ifg_delay {
            bins too_short   = {[0:23]};   // violation
            bins at_min      = {24};        // exactly 960ns
            bins comfortable = {[25:$]};    // well above minimum
        }

        // MODER.IFG bit (bypass)
        cp_ifg_byp : coverpoint m_ral_ifg_byp {
            bins bypassed     = {1};  // all frames accepted regardless of gap
            bins not_bypassed = {0};  // gap is enforced
        }

        // KEY cross: four quadrants must all be hit
        // too_short + not_bypassed → frame DROPPED (rx_ifg_minimum)
        // too_short + bypassed     → frame ACCEPTED (rx_ifg_disable)
        // ok + not_bypassed        → frame accepted normally
        // ok + bypassed            → frame accepted (bypass irrelevant)
        cx_gap_vs_bypass : cross cp_ifg_gap, cp_ifg_byp {
            bins violation_enforced  = binsof(cp_ifg_gap.too_short) &&
                                       binsof(cp_ifg_byp.not_bypassed);
            bins violation_bypassed  = binsof(cp_ifg_gap.too_short) &&
                                       binsof(cp_ifg_byp.bypassed);
            bins ok_enforced         = binsof(cp_ifg_gap.comfortable) &&
                                       binsof(cp_ifg_byp.not_bypassed);
            bins ok_bypassed         = binsof(cp_ifg_gap.comfortable) &&
                                       binsof(cp_ifg_byp.bypassed);
        }

    endgroup : cg_ifg

    // ── RX-FEAT-012  Late collision on RX ────────────────────────────────────
    // (rx_late_col_cg in test plan)
    covergroup cg_late_collision;

        cp_late_coll : coverpoint m_inject_late_coll {
            bins injected     = {1};
            bins not_injected = {0};
        }

        // Must test in BOTH duplex modes
        // half-duplex: LC=1 in BD (MColl seen and processed)
        // full-duplex: LC=0 (MColl ignored by DUT)
        cp_fulld : coverpoint m_ral_fulld {
            bins half_duplex = {0};
            bins full_duplex = {1};
        }

        cx_lc_vs_duplex : cross cp_late_coll, cp_fulld {
            bins half_coll    = binsof(cp_late_coll.injected) &&
                                binsof(cp_fulld.half_duplex);
            bins full_no_coll = binsof(cp_late_coll.injected) &&
                                binsof(cp_fulld.full_duplex);
        }

    endgroup : cg_late_collision

    // ── RX-FEAT-014  Loopback ─────────────────────────────────────────────────
    covergroup cg_loopback;

        cp_loopbck : coverpoint m_ral_loopbck {
            bins enabled  = {1};
            bins disabled = {0};
        }

    endgroup : cg_loopback

    // ── RX-FEAT-017  Speed ───────────────────────────────────────────────────
    // (rx_speed_cg in test plan)
    // Speed is determined by ifg_delay timing (preamble_len at 2.5 vs 25 MHz)
    covergroup cg_speed;

        // preamble_len combined with ifg_delay indirectly encodes speed
        // but the cleaner proxy is frame_len vs time — here we use ifg_delay
        // as a surrogate: 10Mbps gap is 10x longer in absolute time
        cp_mii_speed : coverpoint m_ifg_delay {
            bins ten_mbps     = {[240:$]};  // 10x longer gap at 10 Mbps
            bins hundred_mbps = {[24:239]}; // normal 100 Mbps range
        }

    endgroup : cg_speed

    // ─────────────────────────────────────────────────────────────────────────
    // GROUP 5 — Address Recognition
    // All sampled in sample_mii_rx_item() using m_dest_addr + m_ral_xxx
    // ─────────────────────────────────────────────────────────────────────────

    // ── ADDR-FEAT-001  Unicast match / mismatch ───────────────────────────────
    // (addr_unicast_cg, addr_mismatch_cg in test plan)
    covergroup cg_addr_unicast;

        cp_da_match : coverpoint (m_dest_addr == m_ral_mac_addr) {
            bins match    = {1};
            bins no_match = {0};
        }

        // Walk all 48 DA bits for single-bit mismatch coverage
        // (ADDR-FEAT-001 exhaustive sweep: 48 frames each with 1 bit flipped)
        cp_da_bit_walk : coverpoint m_dest_addr {
            bins bit_walk[48] = {[48'h0:48'hFFFF_FFFF_FFFF]};
        }

    endgroup : cg_addr_unicast

    // ── ADDR-FEAT-002  Promiscuous mode ───────────────────────────────────────
    // (addr_promisc_cg, miss_bit_cg in test plan)
    covergroup cg_addr_promiscuous;

        cp_pro : coverpoint m_ral_pro {
            bins promiscuous = {1};
            bins normal      = {0};
        }

        // DA type: broadcast, multicast, unicast
        cp_da_type : coverpoint
            ({(m_dest_addr == 48'hFF_FF_FF_FF_FF_FF),
              m_dest_addr[0]}) {
            bins broadcast = {2'b10};
            bins multicast = {2'b01};
            bins unicast   = {2'b00};
        }

        // Whether address actually matched the programmed MAC
        cp_addr_matched : coverpoint (m_dest_addr == m_ral_mac_addr) {
            bins match    = {1};
            bins no_match = {0};
        }

        // KEY 3-way: PRO × DA type × address match
        // Must see PRO=1 with all three DA types (ADDR-FEAT-002)
        cx_pro_da_match : cross cp_pro, cp_da_type, cp_addr_matched;

    endgroup : cg_addr_promiscuous

    // ── ADDR-FEAT-003  Broadcast ──────────────────────────────────────────────
    // (broadcast_cg in test plan)
    covergroup cg_addr_broadcast;

        cp_is_broadcast : coverpoint
            (m_dest_addr == 48'hFF_FF_FF_FF_FF_FF) {
            bins broadcast     = {1};
            bins not_broadcast = {0};
        }

        cp_bro : coverpoint m_ral_bro {
            bins reject = {1};  // BRO=1: reject broadcast unless PRO=1
            bins accept = {0};  // BRO=0: accept broadcast
        }

        cp_pro_bcast : coverpoint m_ral_pro {
            bins promiscuous = {1};  // overrides BRO
            bins normal      = {0};
        }

        // KEY 3-way: BRO × PRO × is_broadcast
        // BRO=1 + PRO=0 + bcast  → REJECTED  (tc_addr_broadcast_reject)
        // BRO=1 + PRO=1 + bcast  → ACCEPTED  (tc_addr_broadcast_pro_override)
        // BRO=0 + PRO=0 + bcast  → ACCEPTED  (tc_addr_broadcast_accept)
        cx_bro_pro_bcast : cross cp_bro, cp_pro_bcast, cp_is_broadcast {
            bins bro_rejects    = binsof(cp_bro.reject)      &&
                                  binsof(cp_pro_bcast.normal) &&
                                  binsof(cp_is_broadcast.broadcast);
            bins pro_overrides  = binsof(cp_bro.reject)           &&
                                  binsof(cp_pro_bcast.promiscuous) &&
                                  binsof(cp_is_broadcast.broadcast);
            bins bro0_accepts   = binsof(cp_bro.accept)      &&
                                  binsof(cp_pro_bcast.normal) &&
                                  binsof(cp_is_broadcast.broadcast);
        }

    endgroup : cg_addr_broadcast

    // ── ADDR-FEAT-004  Multicast hash table ───────────────────────────────────
    // (multicast_hash_cg, hash_walk_cg, iam_cg in test plan)
    covergroup cg_addr_multicast_hash;

        cp_iam : coverpoint m_ral_iam {
            bins hash_mode   = {1};
            bins direct_mode = {0};
        }

        cp_is_multicast : coverpoint m_dest_addr[0] {
            bins multicast = {1};  // LSB=1 is multicast
            bins unicast   = {0};
        }

        // All 64 hash table positions (ADDR-FEAT-004 hash walk exhaustive)
        // Bit [5:0] of the CRC of the DA selects which hash bit to check
        cp_hash_index : coverpoint m_dest_addr[5:0] {
            bins all_64_positions[64] = {[6'h00:6'h3F]};
        }

        // Which hash register bank (HASH0 vs HASH1)
        cp_hash_bank : coverpoint m_dest_addr[5] {
            bins hash0_range = {0};   // indices  0-31 → HASH0[0:31]
            bins hash1_range = {1};   // indices 32-63 → HASH1[0:31]
        }

        // IAM × multicast — hash lookup only applies when IAM=1 AND multicast
        cx_iam_vs_mcast : cross cp_iam, cp_is_multicast;

        // All 64 hash positions × IAM state
        cx_hash_idx_vs_iam : cross cp_hash_index, cp_iam;

    endgroup : cg_addr_multicast_hash

    // ── ADDR-FEAT-005  Random address sweep ───────────────────────────────────
    // (addr_rand_cg in test plan)
    covergroup cg_addr_rand_sweep;

        cp_pro : coverpoint m_ral_pro { bins set={1}; bins clear={0}; }
        cp_iam : coverpoint m_ral_iam { bins set={1}; bins clear={0}; }
        cp_bro : coverpoint m_ral_bro { bins set={1}; bins clear={0}; }

        cp_da_category : coverpoint
            ({(m_dest_addr == 48'hFF_FF_FF_FF_FF_FF),
              m_dest_addr[0],
              (m_dest_addr == m_ral_mac_addr)}) {
            bins unicast_match = {3'b001};  // matched own MAC
            bins unicast_miss  = {3'b000};  // unicast, no match
            bins multicast     = {3'b010};  // multicast DA
            bins broadcast     = {3'b100};  // broadcast
            bins others        = default;
        }

        // KEY 3-way: PRO × IAM × BRO (address recognition truth table)
        // Must hit all 8 combinations (ADDR-FEAT-005 1000-seed sweep)
        cx_pro_iam_bro : cross cp_pro, cp_iam, cp_bro;

        // DA category × mode bits
        cx_da_vs_mode : cross cp_da_category, cp_pro, cp_bro;

    endgroup : cg_addr_rand_sweep

    // ─────────────────────────────────────────────────────────────────────────
    // PAUSE FRAME — CONTENT SIDE
    // Sampled in sample_mii_rx_item() — what the frame itself contained
    // ─────────────────────────────────────────────────────────────────────────

    // ── FD-CFD-01..07  Control frame detection ────────────────────────────────
    covergroup cg_pause_content;

        // Valid PAUSE EtherType 0x8808
        cp_length_type : coverpoint m_length_type {
            bins pause_type  = {16'h8808};         // FD-CFD-01/02
            bins wrong_type  = {16'h0800};         // FD-CFD-04: IP EtherType
            bins other_types = default;
        }

        // DA: reserved multicast 01:80:C2:00:00:01 (FD-CFD-01)
        cp_pause_mcast_da : coverpoint
            (m_dest_addr == 48'h01_80_C2_00_00_01) {
            bins reserved_mcast = {1};
            bins other_da       = {0};
        }

        // DA = own MAC address (FD-CFD-02)
        cp_pause_own_mac : coverpoint (m_dest_addr == m_ral_mac_addr) {
            bins own_mac  = {1};
            bins other_da = {0};
        }

        // Wrong DA — neither reserved mcast nor own MAC (FD-CFD-03)
        cp_wrong_da_for_pause : coverpoint
            (m_dest_addr != 48'h01_80_C2_00_00_01 &&
             m_dest_addr != m_ral_mac_addr) {
            bins wrong_da = {1};
            bins valid_da = {0};
        }

        // PAUSE frame with CRC error (FD-CFD-06)
        cp_pause_with_crc_err : coverpoint
            (m_length_type == 16'h8808 && m_inject_crc_error) {
            bins pause_crc_error = {1};
            bins no_crc_error    = {0};
        }

        // PASSALL × RXFLOW at the time the PAUSE frame arrives (FD-CTR-04..07)
        cp_passall_at_pause : coverpoint m_ral_passall {
            bins enabled  = {1};
            bins disabled = {0};
        }

        cp_rxflow_at_pause : coverpoint m_ral_rxflow {
            bins enabled  = {1};
            bins disabled = {0};
        }

        // KEY: all four Table 14 cases must be hit with actual PAUSE frames
        cx_passall_rxflow : cross cp_passall_at_pause, cp_rxflow_at_pause,
                                  cp_length_type {
            // FD-CTR-04: PASSALL=0, RXFLOW=0 → silent ignore
            bins p0r0 = binsof(cp_length_type.pause_type)     &&
                        binsof(cp_passall_at_pause.disabled)   &&
                        binsof(cp_rxflow_at_pause.disabled);
            // FD-CTR-05: PASSALL=0, RXFLOW=1 → RXC + timer, NOT stored
            bins p0r1 = binsof(cp_length_type.pause_type)     &&
                        binsof(cp_passall_at_pause.disabled)   &&
                        binsof(cp_rxflow_at_pause.enabled);
            // FD-CTR-06: PASSALL=1, RXFLOW=0 → stored, CF=1, RXB
            bins p1r0 = binsof(cp_length_type.pause_type)     &&
                        binsof(cp_passall_at_pause.enabled)    &&
                        binsof(cp_rxflow_at_pause.disabled);
            // FD-CTR-07: PASSALL=1, RXFLOW=1 → stored, CF=1, RXC only
            bins p1r1 = binsof(cp_length_type.pause_type)     &&
                        binsof(cp_passall_at_pause.enabled)    &&
                        binsof(cp_rxflow_at_pause.enabled);
        }

    endgroup : cg_pause_content

    // ─────────────────────────────────────────────────────────────────────────
    // OWNER: sample_wb_m_item()
    // Sampled on every DMA write the DUT makes to memory.
    // These covergroups need the actual WB Master bus signals.
    // ─────────────────────────────────────────────────────────────────────────

    // ── RX-FEAT-013  Unaligned RX buffer pointer ──────────────────────────────
    // (rx_align_cg in test plan)
    covergroup cg_dma_alignment;

        // Address byte offset from word boundary (rx_ptr_align_cp)
        cp_ptr_align : coverpoint m_dma_addr[1:0] {
            bins word_aligned = {2'b00};   // baseline — all writes word-aligned
            bins offset_1     = {2'b01};   // RXPNT +1 byte
            bins offset_2     = {2'b10};   // RXPNT +2 bytes
            bins offset_3     = {2'b11};   // RXPNT +3 bytes
        }

        // Byte select must match alignment on the first word write
        cp_byte_sel : coverpoint m_dma_sel {
            bins all_valid   = {4'b1111};  // full word — subsequent writes
            bins three_bytes = {4'b0111};  // first write, RXPNT[1:0]=01
            bins two_bytes   = {4'b0011};  // first write, RXPNT[1:0]=10
            bins one_byte    = {4'b0001};  // first write, RXPNT[1:0]=11
        }

        // KEY: alignment × byte-select — non-aligned pointers must use
        // correct partial byte selects on the first write
        cx_align_vs_sel : cross cp_ptr_align, cp_byte_sel;

    endgroup : cg_dma_alignment

    // DMA write address range and data coverage (mirrors m_wb_m_cov in tx)
    covergroup cg_dma_write;

        cp_mem_addr : coverpoint m_dma_addr {
            bins addr_min       = {32'h0000_0000};
            bins addr_max       = {32'hFFFF_FFFC};
            bins addr_range[64] = {[32'h0000_0000:32'hFFFF_FFFC]};
        }

        cp_mem_data : coverpoint m_dma_data {
            bins data_min       = {32'h0000_0000};
            bins data_max       = {32'hFFFF_FFFF};
            bins data_range[64] = {[32'h0000_0000:32'hFFFF_FFFF]};
        }

        cx_addr_data : cross cp_mem_addr, cp_mem_data;

    endgroup : cg_dma_write

    // ─────────────────────────────────────────────────────────────────────────
    // OWNER: sample_wb_s_item()
    // Sampled on every WB Slave transaction.
    // Uses m_reg_wdata / m_reg_rdata / m_reg_addr directly from the
    // transaction — not from RAL — so we capture the exact value at
    // the exact moment the register was written or read.
    // ─────────────────────────────────────────────────────────────────────────

    // ── RX-FEAT-005  PACKETLEN programmability ────────────────────────────────
    // (rx_packetlen_cg in test plan)
    covergroup cg_packetlen_config;

        cp_minfl : coverpoint m_reg_wdata[31:16] iff(m_reg_addr == 'h06) {
            bins minfl_64   = {16'h0040};
            bins minfl_128  = {16'h0080};
            bins minfl_256  = {16'h0100};
            bins minfl_512  = {16'h0200};
            bins others     = default;
        }

        cp_maxfl : coverpoint m_reg_wdata[15:0] iff(m_reg_addr == 'h06) {
            bins maxfl_512  = {16'h0200};
            bins maxfl_1518 = {16'h05EE};
            bins maxfl_1536 = {16'h0600};   // default
            bins maxfl_max  = {16'hFFFF};
            bins others     = default;
        }

    endgroup : cg_packetlen_config

    // ── MODER RX configuration register write ─────────────────────────────────
    covergroup cg_moder_rx_config;

        cp_rxen : coverpoint m_reg_wdata[0] iff(m_reg_addr == 'h00) {
            bins enabled  = {1};
            bins disabled = {0};
        }

        cp_recsmall_wr : coverpoint m_reg_wdata[16] iff(m_reg_addr == 'h00) {
            bins enabled  = {1};
            bins disabled = {0};
        }

        cp_hugen_wr : coverpoint m_reg_wdata[14] iff(m_reg_addr == 'h00) {
            bins enabled  = {1};
            bins disabled = {0};
        }

        cp_dlycrcen_wr : coverpoint m_reg_wdata[12] iff(m_reg_addr == 'h00) {
            bins enabled  = {1};
            bins disabled = {0};
        }

        cp_pro_wr : coverpoint m_reg_wdata[5] iff(m_reg_addr == 'h00) {
            bins promiscuous = {1};
            bins normal      = {0};
        }

        cp_iam_wr : coverpoint m_reg_wdata[4] iff(m_reg_addr == 'h00) {
            bins hash_mode   = {1};
            bins direct_mode = {0};
        }

        cp_bro_wr : coverpoint m_reg_wdata[3] iff(m_reg_addr == 'h00) {
            bins reject = {1};
            bins accept = {0};
        }

        cp_ifg_wr : coverpoint m_reg_wdata[6] iff(m_reg_addr == 'h00) {
            bins bypassed     = {1};
            bins not_bypassed = {0};
        }

        cp_loopbck_wr : coverpoint m_reg_wdata[7] iff(m_reg_addr == 'h00) {
            bins enabled  = {1};
            bins disabled = {0};
        }

        cp_fulld_wr : coverpoint m_reg_wdata[10] iff(m_reg_addr == 'h00) {
            bins full_duplex = {1};
            bins half_duplex = {0};
        }

        // PRO × IAM → must see hash mode in both PRO on and off
        cx_pro_vs_iam : cross cp_pro_wr, cp_iam_wr;

        // RECSMALL × HUGEN → must see both limits tested together
        cx_recsmall_vs_hugen : cross cp_recsmall_wr, cp_hugen_wr;

    endgroup : cg_moder_rx_config

    // ── CTRLMODER register write ──────────────────────────────────────────────
    // (FD-CTR-01, FD-CTR-02, FD-CTR-03)
    covergroup cg_ctrlmoder_config;

        cp_passall_wr : coverpoint m_reg_wdata[0] iff(m_reg_addr == 'h09) {
            bins enabled  = {1};
            bins disabled = {0};
        }

        cp_rxflow_wr : coverpoint m_reg_wdata[1] iff(m_reg_addr == 'h09) {
            bins enabled  = {1};
            bins disabled = {0};
        }

        cp_txflow_wr : coverpoint m_reg_wdata[2] iff(m_reg_addr == 'h09) {
            bins enabled  = {1};
            bins disabled = {0};
        }

        // All four PASSALL × RXFLOW combinations (Table 14)
        cx_passall_vs_rxflow : cross cp_passall_wr, cp_rxflow_wr {
            bins p0r0 = binsof(cp_passall_wr.disabled) &&
                        binsof(cp_rxflow_wr.disabled);
            bins p0r1 = binsof(cp_passall_wr.disabled) &&
                        binsof(cp_rxflow_wr.enabled);
            bins p1r0 = binsof(cp_passall_wr.enabled)  &&
                        binsof(cp_rxflow_wr.disabled);
            bins p1r1 = binsof(cp_passall_wr.enabled)  &&
                        binsof(cp_rxflow_wr.enabled);
        }

    endgroup : cg_ctrlmoder_config

    // ── Hash register writes ───────────────────────────────────────────────────
    // (ADDR-FEAT-004 hash register coverage)
    covergroup cg_hash_regs;

        cp_hash0 : coverpoint m_reg_wdata iff(m_reg_addr == 'h12) {
            bins all_zeros  = {32'h0000_0000};
            bins all_ones   = {32'hFFFF_FFFF};
            bins any_val[32] = {[32'h0000_0001:32'hFFFF_FFFE]};
        }

        cp_hash1 : coverpoint m_reg_wdata iff(m_reg_addr == 'h13) {
            bins all_zeros  = {32'h0000_0000};
            bins all_ones   = {32'hFFFF_FFFF};
            bins any_val[32] = {[32'h0000_0001:32'hFFFF_FFFE]};
        }

    endgroup : cg_hash_regs

    // ── RX BD configuration (host arming the BD) ───────────────────────────────
    // (rx_bd_wrap_cg, interrupt enable per-BD)
    covergroup cg_rx_bd_config;

        // E, IRQ, WR bits written by host to arm a BD (bits [15:13])
        cp_bd_e_irq_wr : coverpoint m_reg_wdata[15:13]
            iff(m_reg_addr >= WB_BD_MEM_BASE_ADDR &&
                m_reg_addr <= WB_BD_MEM_OFFSET_ADDR &&
                m_reg_addr % 2 == 0) {
            bins all_set   = {3'b111};   // E=1, IRQ=1, WR=1 (last BD)
            bins e_irq     = {3'b110};   // E=1, IRQ=1, WR=0 (normal BD)
            bins e_only    = {3'b100};   // E=1, IRQ=0, WR=0
            bins others[8] = {[3'b000:3'b111]};
        }

        // RXPNT alignment in BD pointer word (odd addresses in BD range)
        cp_rxpnt : coverpoint m_reg_wdata
            iff(m_reg_addr >= WB_BD_MEM_BASE_ADDR &&
                m_reg_addr <= WB_BD_MEM_OFFSET_ADDR &&
                m_reg_addr % 2 == 1) {
            bins rxpnt_range[64] = {[32'h0000_0000:32'hFFFF_FFFF]};
            // Non-word-aligned RXPNT values (tested in RX-FEAT-013)
            wildcard illegal_bins rxpnt_mod1 = {32'h????_??01};
            wildcard illegal_bins rxpnt_mod2 = {32'h????_??02};
            wildcard illegal_bins rxpnt_mod3 = {32'h????_??03};
        }

    endgroup : cg_rx_bd_config

    // ── BD status read-back (host reading the completed BD) ───────────────────
    // These covergroups sample from m_reg_rdata when host reads a BD.
    // They capture ACTUAL DUT-written status bits.
    // Two illegal_bins detect DUT bugs automatically.
    covergroup cg_bd_status_readback;

        cp_bd_e_cleared : coverpoint m_reg_rdata[15]
            iff(m_reg_addr >= WB_BD_MEM_BASE_ADDR &&
                m_reg_addr <= WB_BD_MEM_OFFSET_ADDR &&
                m_reg_addr % 2 == 0) {
            bins cleared  = {0};   // DUT cleared E → reception done
            bins still_set = {1};  // E=1 → BD not consumed (drop/abort)
        }

        // Individual BD status bits — each must be seen both set and clear
        cp_bd_cf  : coverpoint m_reg_rdata[8]  iff(m_reg_addr >= WB_BD_MEM_BASE_ADDR && m_reg_addr <= WB_BD_MEM_OFFSET_ADDR && m_reg_addr%2==0) { bins set={1}; bins clear={0}; }
        cp_bd_m   : coverpoint m_reg_rdata[7]  iff(m_reg_addr >= WB_BD_MEM_BASE_ADDR && m_reg_addr <= WB_BD_MEM_OFFSET_ADDR && m_reg_addr%2==0) { bins set={1}; bins clear={0}; }
        cp_bd_or  : coverpoint m_reg_rdata[6]  iff(m_reg_addr >= WB_BD_MEM_BASE_ADDR && m_reg_addr <= WB_BD_MEM_OFFSET_ADDR && m_reg_addr%2==0) { bins set={1}; bins clear={0}; }
        cp_bd_is  : coverpoint m_reg_rdata[5]  iff(m_reg_addr >= WB_BD_MEM_BASE_ADDR && m_reg_addr <= WB_BD_MEM_OFFSET_ADDR && m_reg_addr%2==0) { bins set={1}; bins clear={0}; }
        cp_bd_dn  : coverpoint m_reg_rdata[4]  iff(m_reg_addr >= WB_BD_MEM_BASE_ADDR && m_reg_addr <= WB_BD_MEM_OFFSET_ADDR && m_reg_addr%2==0) { bins set={1}; bins clear={0}; }
        cp_bd_tl  : coverpoint m_reg_rdata[3]  iff(m_reg_addr >= WB_BD_MEM_BASE_ADDR && m_reg_addr <= WB_BD_MEM_OFFSET_ADDR && m_reg_addr%2==0) { bins set={1}; bins clear={0}; }
        cp_bd_sf  : coverpoint m_reg_rdata[2]  iff(m_reg_addr >= WB_BD_MEM_BASE_ADDR && m_reg_addr <= WB_BD_MEM_OFFSET_ADDR && m_reg_addr%2==0) { bins set={1}; bins clear={0}; }
        cp_bd_crc : coverpoint m_reg_rdata[1]  iff(m_reg_addr >= WB_BD_MEM_BASE_ADDR && m_reg_addr <= WB_BD_MEM_OFFSET_ADDR && m_reg_addr%2==0) { bins set={1}; bins clear={0}; }
        cp_bd_lc  : coverpoint m_reg_rdata[0]  iff(m_reg_addr >= WB_BD_MEM_BASE_ADDR && m_reg_addr <= WB_BD_MEM_OFFSET_ADDR && m_reg_addr%2==0) { bins set={1}; bins clear={0}; }

        // ── STRUCTURAL ILLEGAL BIN #1 ──────────────────────────────────────
        // DN=1 must ALWAYS be paired with CRC=1 (spec §4.2.2.2 Table 28 bit[4])
        // A dribble nibble always causes a CRC error — if DN=1 and CRC=0
        // that is a DUT bug, flagged automatically by the simulator
        cx_dn_must_pair_crc : cross cp_bd_dn, cp_bd_crc
            iff(m_reg_addr >= WB_BD_MEM_BASE_ADDR &&
                m_reg_addr <= WB_BD_MEM_OFFSET_ADDR &&
                m_reg_addr % 2 == 0) {
            bins dn_with_crc       = binsof(cp_bd_dn.set)   && binsof(cp_bd_crc.set);
            bins no_dn_no_crc      = binsof(cp_bd_dn.clear) && binsof(cp_bd_crc.clear);
            bins no_dn_crc_ok      = binsof(cp_bd_dn.clear) && binsof(cp_bd_crc.set);
            illegal_bins dn_no_crc = binsof(cp_bd_dn.set)   && binsof(cp_bd_crc.clear);
        }

        // CF and M must never both be set:
        // PAUSE dest is either reserved multicast or own MAC — both are
        // genuine address matches, so M=0 always when CF=1
        cx_cf_vs_m : cross cp_bd_cf, cp_bd_m
            iff(m_reg_addr >= WB_BD_MEM_BASE_ADDR &&
                m_reg_addr <= WB_BD_MEM_OFFSET_ADDR &&
                m_reg_addr % 2 == 0) {
            bins cf_only   = binsof(cp_bd_cf.set) && binsof(cp_bd_m.clear);
            bins m_only    = binsof(cp_bd_cf.clear) && binsof(cp_bd_m.set);
            bins neither   = binsof(cp_bd_cf.clear) && binsof(cp_bd_m.clear);
            illegal_bins cf_and_m = binsof(cp_bd_cf.set) && binsof(cp_bd_m.set);
        }

    endgroup : cg_bd_status_readback

    // ── RX Interrupts ─────────────────────────────────────────────────────────
    // (rx_int_cg, rx_rxe_cg in test plan)
    // Sampled from INT_SOURCE reads and INT_MASK writes
    covergroup cg_rx_interrupts;

        // INT_SOURCE read (addr 0x01) — RX-relevant bits
        cp_rxb : coverpoint m_reg_rdata[2] iff(m_reg_addr == 'h01) {
            bins set   = {1};
            bins clear = {0};
        }

        cp_rxe : coverpoint m_reg_rdata[3] iff(m_reg_addr == 'h01) {
            bins set   = {1};
            bins clear = {0};
        }

        cp_rxc_source : coverpoint m_reg_rdata[6] iff(m_reg_addr == 'h01) {
            bins set   = {1};
            bins clear = {0};
        }

        cp_busy : coverpoint m_reg_rdata[4] iff(m_reg_addr == 'h01) {
            bins set   = {1};
            bins clear = {0};
        }

        // INT_MASK write (addr 0x02) — RX-relevant mask bits
        cp_rxf_m : coverpoint m_reg_wdata[2] iff(m_reg_addr == 'h02) {
            bins masked   = {0};
            bins unmasked = {1};
        }

        cp_rxe_m : coverpoint m_reg_wdata[3] iff(m_reg_addr == 'h02) {
            bins masked   = {0};
            bins unmasked = {1};
        }

        cp_rxc_m : coverpoint m_reg_wdata[6] iff(m_reg_addr == 'h02) {
            bins masked   = {0};
            bins unmasked = {1};
        }

        cp_busy_m : coverpoint m_reg_wdata[4] iff(m_reg_addr == 'h02) {
            bins masked   = {0};
            bins unmasked = {1};
        }

        // INTA_O pin
        cp_inta_rx : coverpoint m_inta {
            bins asserted     = {1};
            bins not_asserted = {0};
        }

        // ── STRUCTURAL ILLEGAL BIN #2 ──────────────────────────────────────
        // RXC and RXB must never be set simultaneously.
        // Spec §3.2 bit[2]: "If a control frame is received then RXC bit is
        // set instead of the RXB bit." If both appear it is a DUT bug.
        cx_rxc_vs_rxb : cross cp_rxc_source, cp_rxb
            iff(m_reg_addr == 'h01) {
            bins rxc_only      = binsof(cp_rxc_source.set)   && binsof(cp_rxb.clear);
            bins rxb_only      = binsof(cp_rxc_source.clear) && binsof(cp_rxb.set);
            bins neither       = binsof(cp_rxc_source.clear) && binsof(cp_rxb.clear);
            illegal_bins both  = binsof(cp_rxc_source.set)   && binsof(cp_rxb.set);
        }

        // RXB fires only when IRQ=1 in BD AND RXF_M=1
        cx_rxb_vs_mask  : cross cp_rxb, cp_rxf_m;

        // RXE fires only when IRQ=1 in BD AND RXE_M=1
        cx_rxe_vs_mask  : cross cp_rxe, cp_rxe_m;

        // INTA_O must correlate with at least one unmasked interrupt
        cx_inta_vs_rxb  : cross cp_inta_rx, cp_rxb;
        cx_inta_vs_rxe  : cross cp_inta_rx, cp_rxe;
        cx_inta_vs_rxc  : cross cp_inta_rx, cp_rxc_source;

    endgroup : cg_rx_interrupts

    // ── PAUSE interrupt / response side ───────────────────────────────────────
    // (FD-INT-01..04, FD-CTR-04..07 response side in test plan)
    covergroup cg_pause_response;

        // RXC interrupt set/clear (FD-INT-02, FD-INT-04)
        cp_rxc_set : coverpoint m_reg_rdata[6] iff(m_reg_addr == 'h01) {
            bins set   = {1};
            bins clear = {0};
        }

        // INT_MASK.RXC_M (FD-INT-01: masked, FD-INT-02: unmasked)
        cp_rxc_mask : coverpoint m_reg_wdata[6] iff(m_reg_addr == 'h02) {
            bins masked_rxc   = {0};   // FD-INT-01: RXC masked
            bins unmasked_rxc = {1};   // FD-INT-02: RXC unmasked
        }

        // INTA_O response to RXC
        cp_inta_pause : coverpoint m_inta {
            bins asserted     = {1};
            bins not_asserted = {0};
        }

        // Clear-by-write-1 to RXC (FD-INT-04)
        cp_clear_rxc : coverpoint m_reg_wdata[6]
            iff(m_reg_addr == 'h01 && m_wb_s_item.m_dir == WB_WRITE) {
            bins write_1_to_clear = {1};
            bins no_clear         = {0};
        }

        // KEY: RXC × mask × INTA — three-way
        // When RXC=1 and RXC_M=1 → INTA must assert
        // When RXC=1 and RXC_M=0 → INTA must NOT assert
        cx_rxc_mask_inta : cross cp_rxc_set, cp_rxc_mask, cp_inta_pause {
            bins rxc_masked_no_inta  = binsof(cp_rxc_set.set)          &&
                                       binsof(cp_rxc_mask.masked_rxc)   &&
                                       binsof(cp_inta_pause.not_asserted);
            bins rxc_unmasked_inta   = binsof(cp_rxc_set.set)          &&
                                       binsof(cp_rxc_mask.unmasked_rxc) &&
                                       binsof(cp_inta_pause.asserted);
        }

    endgroup : cg_pause_response

    // ── BUSY interrupt (RX-FEAT-010 no empty BD) ──────────────────────────────
    covergroup cg_busy_interrupt;

        cp_busy_int : coverpoint m_reg_rdata[4] iff(m_reg_addr == 'h01) {
            bins set   = {1};   // BUSY fires when frame dropped — no BD available
            bins clear = {0};
        }

        cp_busy_mask : coverpoint m_reg_wdata[4] iff(m_reg_addr == 'h02) {
            bins masked   = {0};
            bins unmasked = {1};
        }

        // BUSY fires regardless of IRQ bits in BDs (spec §3.2 bit[4])
        // So INTA_O must assert whenever BUSY=1 AND BUSY_M=1
        cp_inta_busy : coverpoint m_inta {
            bins asserted     = {1};
            bins not_asserted = {0};
        }

        cx_busy_mask_inta : cross cp_busy_int, cp_busy_mask, cp_inta_busy {
            bins busy_unmasked_inta = binsof(cp_busy_int.set) &&
                                      binsof(cp_busy_mask.unmasked) &&
                                      binsof(cp_inta_busy.asserted);
        }

    endgroup : cg_busy_interrupt

    // =========================================================================
    // Method declarations
    // =========================================================================
    extern function new(string name, uvm_component parent);
    extern function void build_phase(uvm_phase phase);
    extern function void connect_phase(uvm_phase phase);
    extern task          run_phase(uvm_phase phase);

    extern task sample_mii_rx_item();
    extern task sample_wb_m_item();
    extern task sample_wb_s_item();

    // RAL snapshot helper — called inside sample_mii_rx_item
    extern function void read_ral_state();

endclass : eth_cov_rx


// =============================================================================
//  IMPLEMENTATION
// =============================================================================

function eth_cov_rx::new(string name, uvm_component parent);
    super.new(name, parent);
    // Construct all covergroups
    cg_payload_size        = new();
    cg_crc                 = new();
    cg_short_frame         = new();
    cg_huge_frame          = new();
    cg_preamble            = new();
    cg_error_flags         = new();
    cg_overrun_context     = new();
    cg_ifg                 = new();
    cg_late_collision      = new();
    cg_loopback            = new();
    cg_speed               = new();
    cg_addr_unicast        = new();
    cg_addr_promiscuous    = new();
    cg_addr_broadcast      = new();
    cg_addr_multicast_hash = new();
    cg_addr_rand_sweep     = new();
    cg_pause_content       = new();
    cg_dma_alignment       = new();
    cg_dma_write           = new();
    cg_packetlen_config    = new();
    cg_moder_rx_config     = new();
    cg_ctrlmoder_config    = new();
    cg_hash_regs           = new();
    cg_rx_bd_config        = new();
    cg_bd_status_readback  = new();
    cg_rx_interrupts       = new();
    cg_pause_response      = new();
    cg_busy_interrupt      = new();
endfunction

// -----------------------------------------------------------------------------
function void eth_cov_rx::build_phase(uvm_phase phase);
    super.build_phase(phase);

    mii_rx_fifo    = new("mii_rx_fifo",    this);
    wb_m_fifo      = new("wb_m_fifo",      this);
    wb_s_fifo      = new("wb_s_fifo",      this);

    mii_rx_a_export = new("mii_rx_a_export", this);
    wb_m_a_export   = new("wb_m_a_export",   this);
    wb_s_a_export   = new("wb_s_a_export",   this);

    if (!uvm_config_db #(eth_reg_block)::get(this, "", "m_regmodel", m_regmodel))
        `uvm_fatal(get_full_name(),"eth_cov_rx: cannot get eth_reg_block from config_db")
endfunction

// -----------------------------------------------------------------------------
function void eth_cov_rx::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    mii_rx_a_export.connect(mii_rx_fifo.analysis_export);
    wb_m_a_export.connect(wb_m_fifo.analysis_export);
    wb_s_a_export.connect(wb_s_fifo.analysis_export);
endfunction

// -----------------------------------------------------------------------------
// run_phase: three completely independent parallel tasks.
// Each blocks on its own FIFO — no task ever delays another.
// -----------------------------------------------------------------------------
task eth_cov_rx::run_phase(uvm_phase phase);
    super.run_phase(phase);
    fork : fork_rx_cov
        forever sample_mii_rx_item();
        forever sample_wb_m_item();
        forever sample_wb_s_item();
    join
endtask

// =============================================================================
// sample_mii_rx_item
// Triggered once per complete assembled frame from MII Rx Monitor.
// Reads RAL for config state at this exact simulation time,
// then samples all frame-content covergroups.
// =============================================================================
task eth_cov_rx::sample_mii_rx_item();

    // Block until next complete frame arrives
    mii_rx_fifo.get(m_rx_item);

    // Copy frame fields to member variables (covergroups reference these)
    m_dest_addr         = m_rx_item.destination_addr;
    m_length_type       = m_rx_item.length_type;
    m_frame_len         = m_rx_item.frame_no_crc.size();
    m_payload_size      = m_rx_item.payload.size();
    m_preamble_len      = m_rx_item.preamble_len;
    m_ifg_delay         = m_rx_item.ifg_delay;
    m_inject_crc_error  = m_rx_item.inject_crc_error;
    m_inject_mrxerr     = m_rx_item.inject_mrxerr;
    m_inject_invalid_sym = m_rx_item.inject_invalid_symbol;
    m_dribble_nibble_en = m_rx_item.dribble_nibble_en;
    m_inject_late_coll  = m_rx_item.inject_late_collision;

    // Read RAL mirror — config that was active when this frame was received
    read_ral_state();

    // Sample all frame-content covergroups
    cg_payload_size.sample();
    cg_crc.sample();
    cg_short_frame.sample();
    cg_huge_frame.sample();
    cg_preamble.sample();
    cg_error_flags.sample();
    cg_overrun_context.sample();
    cg_ifg.sample();
    cg_late_collision.sample();
    cg_loopback.sample();
    cg_speed.sample();
    cg_addr_unicast.sample();
    cg_addr_promiscuous.sample();
    cg_addr_broadcast.sample();
    cg_addr_multicast_hash.sample();
    cg_addr_rand_sweep.sample();
    cg_pause_content.sample();    // PAUSE frame content side

    `uvm_info(get_full_name(), m_rx_item.convert2string(), UVM_HIGH)

endtask

// =============================================================================
// sample_wb_m_item
// Triggered on every DMA write from DUT to memory.
// Samples only DMA-related covergroups (alignment, byte select, data).
// =============================================================================
task eth_cov_rx::sample_wb_m_item();

    wb_m_fifo.get(m_wb_m_item);

    // RX path: DUT performs WRITE to store received frame data
    // Skip read transactions (those are TX path)
    if (m_wb_m_item.m_dir != WB_WRITE) return;

    // Skip partial-select transactions
    // (non-aligned first beat IS partial — sample those too for alignment CG)
    m_dma_addr = m_wb_m_item.m_addr_o;
    m_dma_data = m_wb_m_item.m_data_o;
    m_dma_sel  = m_wb_m_item.m_sel_o;

    // Sample DMA covergroups
    cg_dma_alignment.sample();   // needs partial sel — sample before filtering
    cg_dma_write.sample();

endtask

// =============================================================================
// sample_wb_s_item
// Triggered on every WB Slave transaction (register write or read).
// Uses transaction value directly — not RAL — so register write coverage
// captures the exact value at the exact moment it was written.
// Samples config, BD, interrupt, and PAUSE-response covergroups.
// =============================================================================
task eth_cov_rx::sample_wb_s_item();

    wb_s_fifo.get(m_wb_s_item);

    // Copy fields
    m_reg_addr  = m_wb_s_item.m_addr;
    m_reg_wdata = m_wb_s_item.m_wdata;
    m_reg_rdata = m_wb_s_item.m_rdata;
    m_inta      = m_wb_s_item.m_inta;

    // Reject partial-byte transactions (same guard as eth_cov_tx)
    if (!(&m_wb_s_item.m_sel)) return;

    if (m_wb_s_item.m_dir == WB_WRITE) begin
        // Register configuration writes
        cg_packetlen_config.sample();
        cg_moder_rx_config.sample();
        cg_ctrlmoder_config.sample();
        cg_hash_regs.sample();
        cg_rx_bd_config.sample();
        cg_rx_interrupts.sample();   // INT_MASK writes
        cg_pause_response.sample();  // RXC mask write + clear-by-write-1
        cg_busy_interrupt.sample();  // BUSY mask write

        `uvm_info(get_full_name(), m_wb_s_item.convert2string(), UVM_HIGH)

    end else begin
        // Register and BD reads — capture DUT-written status
        cg_bd_status_readback.sample();  // actual BD status bits from DUT
        cg_rx_interrupts.sample();       // INT_SOURCE reads
        cg_pause_response.sample();      // RXC set in INT_SOURCE
        cg_busy_interrupt.sample();      // BUSY in INT_SOURCE
    end

endtask

// =============================================================================
// read_ral_state
// Reads all RX-relevant register fields from RAL mirror.
// Called at the start of sample_mii_rx_item() so every frame-content
// covergroup has the correct config that was active during that frame.
// Zero simulation time — backdoor read of mirror values only.
// =============================================================================
function void eth_cov_rx::read_ral_state();
    m_ral_rxen     = m_regmodel.MODER.RXEN.get_mirrored_value();
    m_ral_recsmall = m_regmodel.MODER.RECSMALL.get_mirrored_value();
    m_ral_hugen    = m_regmodel.MODER.HUGEN.get_mirrored_value();
    m_ral_dlycrcen = m_regmodel.MODER.DLYCRCEN.get_mirrored_value();
    m_ral_pro      = m_regmodel.MODER.PRO.get_mirrored_value();
    m_ral_iam      = m_regmodel.MODER.IAM.get_mirrored_value();
    m_ral_bro      = m_regmodel.MODER.BRO.get_mirrored_value();
    m_ral_ifg_byp  = m_regmodel.MODER.IFG.get_mirrored_value();
    m_ral_loopbck  = m_regmodel.MODER.LOOPBCK.get_mirrored_value();
    m_ral_fulld    = m_regmodel.MODER.FULLD.get_mirrored_value();
    m_ral_minfl    = m_regmodel.PACKETLEN.MINFL.get_mirrored_value();
    m_ral_maxfl    = m_regmodel.PACKETLEN.MAXFL.get_mirrored_value();
    m_ral_passall  = m_regmodel.CTRLMODER.PASSALL.get_mirrored_value();
    m_ral_rxflow   = m_regmodel.CTRLMODER.RXFLOW.get_mirrored_value();
    m_ral_mac_addr = m_regmodel.get_mac_address();
    m_ral_hash0    = m_regmodel.HASH0.get_mirrored_value();
    m_ral_hash1    = m_regmodel.HASH1.get_mirrored_value();
    m_ral_rxc_m    = m_regmodel.INT_MASK.RXC_M.get_mirrored_value();
    m_ral_rxe_m    = m_regmodel.INT_MASK.RXE_M.get_mirrored_value();
    m_ral_rxf_m    = m_regmodel.INT_MASK.RXF_M.get_mirrored_value();
    m_ral_busy_m   = m_regmodel.INT_MASK.BUSY_M.get_mirrored_value();
endfunction

`endif // ETH_COV_RX_SV
