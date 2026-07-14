`ifndef RTH_RX_COVERAGE_SV
`define RTH_RX_COVERAGE_SV

class eth_rx_coverage extends uvm_component #(mii_rx_seq_item);
    `uvm_component_utils(eth_rx_coverage)

    // MII Rx monitor → FIFO → run_phase
    uvm_analysis_export        #(mii_rx_seq_item)   mii_rx_export;
    uvm_tlm_analysis_fifo      #(mii_rx_seq_item)   mii_rx_fifo;

    //  connect to wb_slave_imp (register writes)
    uvm_analysis_imp_wb_slave  #(wb_s_seq_item_t, eth_rx_coverage)    wb_slave_imp;

    // connect to wb_master_imp (DMA memory writes)
    uvm_analysis_imp_wb_master #(wb_m_seq_item_base, eth_rx_coverage) wb_master_imp;

    // connect to bd_status_export (actual BD written by DUT)
    // fires ONLY when the host reads a BD status word with E=0,
    uvm_analysis_export       #(wb_s_seq_item_t) bd_status_export;
    uvm_tlm_analysis_fifo     #(wb_s_seq_item_t) bd_status_fifo;

    // RAL handle — needed to sample register state at coverage time
    eth_reg_block m_regmodel;

    // Internal copies — loaded in write() before sampling
    mii_rx_seq_item  m_frame;     // current frame transaction
    eth_rx_reg_cfg_s m_reg_s;     // current register config 

    // CG1 — Frame Type Distribution
    // Ensures every major frame category is exercised.
    covergroup cg_frame_type;
        
        cp_is_broadcast : coverpoint
            (m_frame.distination_addr ==  48'hFFFF_FFFF_FFFF) {
            bins broadcast     = {1};
            bins not_broadcast = {1};
        }

        cp_is_multicast : coverpoint
            (m_frame.destination_addr[0] == 1'b1 &&
             m_frame.destination_addr != 48'hFF_FF_FF_FF_FF_FF) {
            bins multicast     = {1};
            bins not_multicast = {0};
        }

        cp_is_unicast : coverpoint
            (m_frame.destination_addr[0] == 1'b0) {
            bins unicast     = {1};
            bins not_unicast = {0};
        }

        cp_is_pause : coverpoint m_frame.inject_crc_error {
            // pause frame detection is via frame content —
            // use length_type as proxy
            bins pause_etype     = {0}; // placeholder — see cg_pause below
            bins non_pause_etype = {1};
        }

        cp_has_crc_error : coverpoint m_frame.inject_crc_error {
            bins crc_error = {1};
            bins crc_ok    = {0};
        }

        cp_has_phy_error : coverpoint m_frame.inject_mrxerr {
            bins phy_error    = {1};
            bins no_phy_error = {0};
        }

        cp_has_dribble : coverpoint m_frame.dribble_nibble_en {
            bins dribble    = {1};
            bins no_dribble = {0};
        }

        cp_has_invalid_sym : coverpoint m_frame.inject_invalid_symbol {
            bins invalid_sym    = {1};
            bins no_invalid_sym = {0};
        }

        cp_has_late_coll : coverpoint m_frame.inject_late_collision {
            bins late_collision    = {1};
            bins no_late_collision = {0};
        }

    endgroup : cg_frame_type

    // CG2 — PHY-Level Errors (Scoreboard Phase A)
    // MRxErr causes silent abort — must see it both asserted and clean.
    
    covergroup cg_phy_error;

        cp_mrxerr : coverpoint m_frame.inject_mrxerr {
            bins asserted     = {1};
            bins not_asserted = {0};
        }

        cp_invalid_symbol : coverpoint m_frame.inject_invalid_symbol {
            bins injected     = {1};
            bins not_injected = {0};
        }

        // Cross: both error types could theoretically co-exist
        cx_phy_errors : cross cp_mrxerr, cp_invalid_symbol;

    endgroup : cg_phy_error

    // CG3 — Inter-Frame Gap (Scoreboard Phase B)
    // Must cover: gap OK, gap too small (violation), and IFG bypass enabled.
    
     covergroup cg_ifg;

        cp_ifg_delay : coverpoint m_frame.ifg_delay {
            bins violation   = {[0    :95]};   // < 960ns at 10ns/cycle
            bins minimum     = {[96   :120]};  // at/just above minimum
            bins comfortable = {[121  :$]};    // well above minimum
        }

        cp_ifg_bypass : coverpoint m_reg_s.ifg_byp {
            bins bypassed     = {1};
            bins not_bypassed = {0};
        }

        // Key cross: small gap WITH and WITHOUT bypass
        // bypass=0 + small gap → frame should be DROPPED
        // bypass=1 + small gap → frame should be ACCEPTED
        cx_gap_vs_bypass : cross cp_ifg_delay, cp_ifg_bypass;

    endgroup : cg_ifg

    // CG4 — Address Recognition (Scoreboard Phase C)
    // Must exercise all address recognition paths.

    covergroup cg_address_recognition;

        cp_pro : coverpoint m_reg_s.pro {
            bins promiscuous = {1};
            bins normal      = {0};
        }

        cp_bro : coverpoint m_reg_s.bro {
            bins reject_broadcast = {1};
            bins accept_broadcast = {0};
        }

        cp_iam : coverpoint m_reg_s.iam {
            bins hash_mode   = {1};
            bins direct_mode = {0};
        }

        cp_addr_type : coverpoint
            ({m_frame.destination_addr == 48'hFF_FF_FF_FF_FF_FF,
              m_frame.destination_addr[0]}) {
            bins broadcast = {2'b10};  // [1]=broadcast bit, [0]=multicast bit
            bins multicast = {2'b01};
            bins unicast   = {2'b00};
        }

        cp_unicast_match : coverpoint
            (m_frame.destination_addr == m_reg_s.mac_addr) {
            bins match    = {1};
            bins no_match = {0};
        }

        // Cross: PRO mode vs address type
        // Ensures promiscuous mode is tested with all frame types
        cx_pro_vs_addr_type : cross cp_pro, cp_addr_type;

        // Cross: broadcast frame vs BRO bit
        // MUST cover: bcast+BRO=0 (accept) and bcast+BRO=1 (drop)
        cx_bcast_vs_bro : cross cp_bro, cp_addr_type;

        // Cross: IAM mode vs multicast
        // MUST cover: mcast+IAM=1+hash_hit and mcast+IAM=1+hash_miss
        cx_iam_vs_addr : cross cp_iam, cp_addr_type;

        // Cross: unicast address match vs PRO mode
        cx_unicast_match_vs_pro : cross cp_unicast_match, cp_pro;

    endgroup : cg_address_recognition

    // CG5 — Frame Length / Size Boundaries (Scoreboard Phase D)
    // Must hit all length decision boundaries.
    // Default: MINFL=64, MAXFL=1536

    covergroup cg_frame_length;

        cp_frame_len : coverpoint m_frame.frame_data_q.size() {
            bins tiny           = {[0    :3]};    // ≤4 bytes: always CRC error
            bins below_min      = {[4    :63]};   // < MINFL: short frame
            bins at_min         = {64};            // = MINFL boundary
            bins normal         = {[65   :1517]}; // normal range
            bins at_max         = {1518};          // = MAXFL (1518 is standard max)
            bins above_max      = {[1519 :1535]}; // > MAXFL, < 1536
            bins at_maxfl       = {1536};          // = MAXFL register default
            bins jumbo          = {[1537 :$]};     // jumbo frame
        }

        cp_recsmall : coverpoint m_reg_s.recsmall {
            bins enabled  = {1};
            bins disabled = {0};
        }

        cp_hugen : coverpoint m_reg_s.hugen {
            bins enabled  = {1};
            bins disabled = {0};
        }

        // Key cross: short frames vs RECSMALL bit
        // MUST cover all four combinations:
        //   short + RECSMALL=0 → DROPPED (silent)
        //   short + RECSMALL=1 → ACCEPTED with SF=1
        //   normal + RECSMALL=0 → normal accept
        //   normal + RECSMALL=1 → normal accept
        cx_short_vs_recsmall : cross cp_frame_len, cp_recsmall {
            // Must hit the drop case explicitly
            bins short_dropped  = binsof(cp_frame_len.below_min) &&
                                  binsof(cp_recsmall.disabled);
            bins short_accepted = binsof(cp_frame_len.below_min) &&
                                  binsof(cp_recsmall.enabled);
        }

        // Key cross: jumbo frames vs HUGEN bit
        // MUST cover:
        //   jumbo + HUGEN=0 → truncated at MAXFL, TL=1
        //   jumbo + HUGEN=1 → full frame accepted, TL=0
        cx_jumbo_vs_hugen : cross cp_frame_len, cp_hugen {
            bins jumbo_truncated = binsof(cp_frame_len.jumbo) &&
                                   binsof(cp_hugen.disabled);
            bins jumbo_accepted  = binsof(cp_frame_len.jumbo) &&
                                   binsof(cp_hugen.enabled);
        }

        // Boundary crossing: at_min and at_max must be hit
        cx_boundary_vs_recsmall : cross cp_frame_len, cp_recsmall {
            bins at_min_normal  = binsof(cp_frame_len.at_min)  &&
                                  binsof(cp_recsmall.disabled);
            bins at_max_normal  = binsof(cp_frame_len.at_max)  &&
                                  binsof(cp_hugen.disabled);
        }

    endgroup : cg_frame_length

    // CG6 — CRC Error Handling (Scoreboard Phase E)

     covergroup cg_crc;

        cp_crc_injected : coverpoint m_frame.inject_crc_error {
            bins error    = {1};
            bins no_error = {0};
        }

        cp_dlycrcen : coverpoint m_reg_s.dlycrcen {
            bins delayed = {1};
            bins normal  = {0};
        }

        cp_frame_len_for_crc : coverpoint m_frame.frame_data_q.size() {
            bins le_4_bytes  = {[0:4]};   // always CRC error per spec note
            bins gt_4_bytes  = {[5:$]};
        }

        // Cross: CRC error with and without delayed CRC mode
        cx_crc_vs_dly : cross cp_crc_injected, cp_dlycrcen;

        // Cross: tiny frames (always CRC error) vs CRC injection
        // Both cases must reach the CRC=1 outcome
        cx_tiny_vs_crc : cross cp_frame_len_for_crc, cp_crc_injected;

    endgroup : cg_crc

    // CG7 — Dribble Nibble
    // Must see dribble nibble occurring with and without CRC error
    // (dribble always causes CRC error — verify they're always paired)

    covergroup cg_dribble_nibble;

        cp_dribble : coverpoint m_frame.dribble_nibble_en {
            bins enabled  = {1};
            bins disabled = {0};
        }

        cp_crc_when_dribble : coverpoint
            (m_frame.dribble_nibble_en && m_frame.inject_crc_error) {
            bins dribble_with_crc  = {1}; // both set — expected normal case
            bins dribble_no_crc    = {0}; // dribble without CRC injection
                                           // (dribble itself causes CRC error)
        }

    endgroup : cg_dribble_nibble

    // CG8 — Late Collision on RX Side
    // Must see late collision in both half-duplex and full-duplex modes.
    // In full-duplex, MColl is ignored — LC should not be set.

    covergroup cg_late_collision;

        cp_late_coll : coverpoint m_frame.inject_late_collision {
            bins injected     = {1};
            bins not_injected = {0};
        }

        cp_fulld : coverpoint m_reg_s.fulld {
            bins full_duplex = {1};
            bins half_duplex = {0};
        }

        // Cross: late collision must be tested in BOTH duplex modes
        // half-duplex + late_coll → LC=1 in BD
        // full-duplex + late_coll → LC=0 (MColl ignored)
        cx_lc_vs_duplex : cross cp_late_coll, cp_fulld;

    endgroup : cg_late_collision

    // CG9 — PAUSE Control Frame (Table 14 in spec)
    // Four combinations of PASSALL × RXFLOW — all must be hit.

    covergroup cg_pause_frame;

        cp_is_pause_etype : coverpoint
            (m_frame.length_type == 16'h8808) {
            bins is_pause     = {1};
            bins is_not_pause = {0};
        }

        cp_passall : coverpoint m_reg_s.passall {
            bins enabled  = {1};
            bins disabled = {0};
        }

        cp_rxflow : coverpoint m_reg_s.rxflow {
            bins enabled  = {1};
            bins disabled = {0};
        }

        // The four mandatory combinations from Table 14:
        // (passall=0, rxflow=0): silent ignore
        // (passall=0, rxflow=1): RXC interrupt, timer loaded, NOT stored
        // (passall=1, rxflow=0): stored, CF=1, RXB interrupt
        // (passall=1, rxflow=1): stored, CF=1, RXC interrupt only
        cx_pause_control : cross cp_is_pause_etype, cp_passall, cp_rxflow;

    endgroup : cg_pause_frame

    // CG10 — Register Configuration Cross-Coverage
    // Ensures register combinations that affect RX behavior are all tested.

    covergroup cg_reg_config;

        cp_rxen : coverpoint m_reg_s.rxen {
            bins enabled  = {1};
            bins disabled = {0};
        }

        cp_pro : coverpoint m_reg_s.pro {
            bins promiscuous = {1};
            bins normal      = {0};
        }

        cp_iam : coverpoint m_reg_s.iam {
            bins hash_mode   = {1};
            bins direct_mode = {0};
        }

        cp_bro : coverpoint m_reg_s.bro {
            bins reject = {1};
            bins accept = {0};
        }

        cp_recsmall : coverpoint m_reg_s.recsmall {
            bins enabled  = {1};
            bins disabled = {0};
        }

        cp_hugen : coverpoint m_reg_s.hugen {
            bins enabled  = {1};
            bins disabled = {0};
        }

        cp_dlycrcen : coverpoint m_reg_s.dlycrcen {
            bins delayed = {1};
            bins normal  = {0};
        }

        cp_ifg_byp : coverpoint m_reg_s.ifg_byp {
            bins bypassed     = {1};
            bins not_bypassed = {0};
        }

        // Must test PRO with and without IAM active
        cx_pro_vs_iam : cross cp_pro, cp_iam;

        // Must test RECSMALL with and without HUGEN active
        cx_recsmall_vs_hugen : cross cp_recsmall, cp_hugen;

        // Must test delayed CRC with and without PRO
        cx_dlycrc_vs_pro : cross cp_dlycrcen, cp_pro;

    endgroup : cg_reg_config

    // CG11 — BD Status Bit Combinations
    // Ensures individual status bits and key combinations are hit.

    covergroup cg_bd_status;

        // Each BD status bit must be seen both set and clear
        cp_cf_bit : coverpoint
            (m_frame.length_type == 16'h8808 && m_reg_s.passall) {
            bins set   = {1};
            bins clear = {0};
        }

        cp_crc_bit : coverpoint m_frame.inject_crc_error {
            bins set   = {1};
            bins clear = {0};
        }

        cp_sf_bit : coverpoint
            (m_frame.frame_data_q.size() < m_reg_s.minfl) {
            bins set   = {1};
            bins clear = {0};
        }

        cp_tl_bit : coverpoint
            (m_frame.frame_data_q.size() > m_reg_s.maxfl && !m_reg_s.hugen) {
            bins set   = {1};
            bins clear = {0};
        }

        cp_dn_bit : coverpoint m_frame.dribble_nibble_en {
            bins set   = {1};
            bins clear = {0};
        }

        cp_is_bit : coverpoint m_frame.inject_invalid_symbol {
            bins set   = {1};
            bins clear = {0};
        }

        cp_lc_bit : coverpoint
            (m_frame.inject_late_collision && !m_reg_s.fulld) {
            bins set   = {1};
            bins clear = {0};
        }

        cp_m_bit : coverpoint
            (m_reg_s.pro &&
             m_frame.destination_addr != m_reg_s.mac_addr &&
             m_frame.destination_addr != 48'hFF_FF_FF_FF_FF_FF) {
            bins set   = {1};  // accepted via PRO but not a real address match
            bins clear = {0};
        }

        // Dribble nibble always paired with CRC error — verify combination
        cx_dn_with_crc : cross cp_dn_bit, cp_crc_bit {
            bins dn_and_crc = binsof(cp_dn_bit.set) && binsof(cp_crc_bit.set);
            // This must be hit — dribble always causes CRC error
        }

        // Short frame and CRC error can co-exist (tiny frame)
        cx_sf_with_crc : cross cp_sf_bit, cp_crc_bit;

    endgroup : cg_bd_status

    // CG12 — Payload Size Distribution
    // Ensures the full payload size range from the seq_item constraint is hit.

    covergroup cg_payload_size;

        cp_payload_size : coverpoint m_frame.payload.size() {
            bins min_payload  = {46};           // minimum payload (pad to 64B frame)
            bins small        = {[47   :127]};
            bins medium       = {[128  :511]};
            bins large        = {[512  :1023]};
            bins max_range    = {[1024 :1500]};
            bins max_payload  = {1500};         // maximum from constraint
        }

    endgroup : cg_payload_size

    // CG13 — Error Injection Cross-Coverage
    // Ensures multiple simultaneous error conditions are tested.

    covergroup cg_error_cross;

        cp_crc_err : coverpoint m_frame.inject_crc_error {
            bins yes = {1};
            bins no  = {0};
        }

        cp_phy_err : coverpoint m_frame.inject_mrxerr {
            bins yes = {1};
            bins no  = {0};
        }

        cp_inv_sym : coverpoint m_frame.inject_invalid_symbol {
            bins yes = {1};
            bins no  = {0};
        }

        cp_dribble : coverpoint m_frame.dribble_nibble_en {
            bins yes = {1};
            bins no  = {0};
        }

        cp_late_coll : coverpoint m_frame.inject_late_collision {
            bins yes = {1};
            bins no  = {0};
        }

        // No errors at all — clean frame baseline
        cp_clean_frame : coverpoint
            (!m_frame.inject_crc_error   &&
             !m_frame.inject_mrxerr      &&
             !m_frame.inject_invalid_symbol &&
             !m_frame.dribble_nibble_en  &&
             !m_frame.inject_late_collision) {
            bins clean = {1};
            bins dirty = {0};
        }

        // CRC + dribble always co-occur — cross checks this
        cx_crc_and_dribble : cross cp_crc_err, cp_dribble;

        // Invalid symbol with and without CRC error
        cx_invsym_and_crc : cross cp_inv_sym, cp_crc_err;

        // Late collision with CRC error
        cx_latecoll_and_crc : cross cp_late_coll, cp_crc_err;

    endgroup : cg_error_cross

    
    // Constructor
    
    function new(string name = "eth_rx_coverage", uvm_component parent = null);
        super.new(name, parent);
        // Construct all covergroups
        cg_frame_type          = new();
        cg_phy_error           = new();
        cg_ifg                 = new();
        cg_address_recognition = new();
        cg_frame_length        = new();
        cg_crc                 = new();
        cg_dribble_nibble      = new();
        cg_late_collision      = new();
        cg_pause_frame         = new();
        cg_reg_config          = new();
        cg_bd_status           = new();
        cg_payload_size        = new();
        cg_error_cross         = new();
    endfunction

    
    // build_phase — get RAL handle from config_db

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // MII stream
        mii_rx_export    = new("mii_rx_export", this); // analysis export
        mii_rx_fifo      = new("mii_rx_fifo", this);   // Build fifo

        // WB imp ports 
        wb_slave_imp     = new("wb_slave_imp",  this);
        wb_master_imp    = new("wb_master_imp", this);

        bd_status_export = new("bd_status_export", this);
        bd_status_fifo   = new("bd_status_fifo",   this);

        if (!uvm_config_db #(eth_reg_block)::get(this, "", "m_regmodel", m_regmodel))
            `uvm_fatal("COV/CFG", "eth_rx_coverage: cannot get eth_reg_block from config_db")
    endfunction

    // CONNECT PHASE
    
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        mii_rx_export.connect(mii_rx_fifo.analysis_export);
        bd_status_export.connect(bd_status_fifo .analysis_export);
    endfunction : connect_phase

    task run_phase(uvm_phase phase);
        super.run_phase(phase);           
        forever begin
            mii_rx_fifo.get(m_frame);  
          
            sample_reg_state();
            // 3. Sample all covergroups
            cg_frame_type.sample();
            cg_phy_error.sample();
            cg_ifg.sample();
            cg_address_recognition.sample();
            cg_frame_length.sample();
            cg_crc.sample();
            cg_dribble_nibble.sample();
            cg_late_collision.sample();
            cg_pause_frame.sample();
            cg_reg_config.sample();
            cg_bd_status.sample();
            cg_payload_size.sample();
            cg_error_cross.sample();

            `uvm_info("COV",
                $sformatf("Sampled frame: DA=%0h len=%0d crc_err=%0b mrxerr=%0b",
                    m_frame.destination_addr,
                    m_frame.frame_data_q.size(),
                    m_frame.inject_crc_error,
                    m_frame.inject_mrxerr),
                UVM_HIGH)
        end
    endtask
    
    //--------------------------------------------------------------------------
    // sample_reg_state
    // Reads all relevant register fields from RAL mirror into m_reg_s.
    // Called inside write() — zero simulation time, no bus transaction.
    //--------------------------------------------------------------------------
    function void sample_reg_state();
        m_reg_s.rxen     = m_regmodel.MODER.RXEN.get_mirrored_value();
        m_reg_s.recsmall = m_regmodel.MODER.RECSMALL.get_mirrored_value();
        m_reg_s.hugen    = m_regmodel.MODER.HUGEN.get_mirrored_value();
        m_reg_s.dlycrcen = m_regmodel.MODER.DLYCRCEN.get_mirrored_value();
        m_reg_s.fulld    = m_regmodel.MODER.FULLD.get_mirrored_value();
        m_reg_s.pro      = m_regmodel.MODER.PRO.get_mirrored_value();
        m_reg_s.iam      = m_regmodel.MODER.IAM.get_mirrored_value();
        m_reg_s.bro      = m_regmodel.MODER.BRO.get_mirrored_value();
        m_reg_s.ifg_byp  = m_regmodel.MODER.IFG.get_mirrored_value();
        m_reg_s.minfl    = m_regmodel.PACKETLEN.MINFL.get_mirrored_value();
        m_reg_s.maxfl    = m_regmodel.PACKETLEN.MAXFL.get_mirrored_value();
        m_reg_s.passall  = m_regmodel.CTRLMODER.PASSALL.get_mirrored_value();
        m_reg_s.rxflow   = m_regmodel.CTRLMODER.RXFLOW.get_mirrored_value();
        m_reg_s.mac_addr = m_regmodel.get_mac_address();
        m_reg_s.hash0    = m_regmodel.HASH0.get_mirrored_value();
        m_reg_s.hash1    = m_regmodel.HASH1.get_mirrored_value();
    endfunction

    //--------------------------------------------------------------------------
    // report_phase — print coverage summary
    //--------------------------------------------------------------------------
    function void report_phase(uvm_phase phase);
        `uvm_info("COV",
            $sformatf("\n============================================\n  RX COVERAGE SUMMARY\n  Frame Type        : %.1f%%\n  PHY Errors        : %.1f%%\n  IFG               : %.1f%%\n  Address Recog     : %.1f%%\n  Frame Length      : %.1f%%\n  CRC               : %.1f%%\n  Dribble Nibble    : %.1f%%\n  Late Collision    : %.1f%%\n  PAUSE Frame       : %.1f%%\n  Reg Config        : %.1f%%\n  BD Status         : %.1f%%\n  Payload Size      : %.1f%%\n  Error Cross       : %.1f%%\n============================================",
                cg_frame_type.get_coverage(),
                cg_phy_error.get_coverage(),
                cg_ifg.get_coverage(),
                cg_address_recognition.get_coverage(),
                cg_frame_length.get_coverage(),
                cg_crc.get_coverage(),
                cg_dribble_nibble.get_coverage(),
                cg_late_collision.get_coverage(),
                cg_pause_frame.get_coverage(),
                cg_reg_config.get_coverage(),
                cg_bd_status.get_coverage(),
                cg_payload_size.get_coverage(),
                cg_error_cross.get_coverage()),
            UVM_NONE)
    endfunction

endclass : eth_rx_coverage

`endif