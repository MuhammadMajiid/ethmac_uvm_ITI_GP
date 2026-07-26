//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_tx_scoreboard_struct.sv
// Author   : Nada
// Date     : 2026-07-1
//------------------------------------------------------------------------------
// Description:
//   Contains structs used by tx scoreboard.
//==============================================================================

`ifndef ETH_TX_SCOREBOARD_STRUCT_SV
`define ETH_TX_SCOREBOARD_STRUCT_SV

// =============================================================================
// struct: eth_tx_bd_cfg_s
// Captures every field the predictor needs from one TX BD and from the
// configuration registers at the moment that BD is armed (RD goes 1).
//
// Sources (all RTL-verified against eth_wishbone.v / eth_top.v):
//
//   BD status word layout (observed by wb_slave_monitor on DATA_I):
//       [31:16] LEN          -> number of payload bytes to transmit
//       [15]    RD           -> 1 = BD is armed / owned by DUT
//       [14]    IRQ          -> TxIRQEn   (eth_wishbone TxStatus[14])
//       [13]    WR           -> WrapTxStatusBit (TxStatus[13])
//       [12]    PAD          -> PerPacketPad    (TxStatus[12])
//       [11]    CRC          -> PerPacketCrcEn  (TxStatus[11])
//
//   BD pointer word (DATA_I of the pointer-word write):
//       [31:0]  TXPNT        -> base address for DMA reads
//
//   MODER register (address 0x00):
//       [15]    PAD_MODER    -> global pad enable
//       [13]    CRCEN        -> global CRC enable
//       [14]    HUGEN        -> huge packet enable (no max-length truncation)
//       [1]     TXEN         -> transmitter enabled
//
//   PACKETLEN register (address 0x18):
//       [31:16] MINFL        -> minimum frame length (default 64)
//       [15:0]  MAXFL        -> maximum frame length (default 1518)
//
//   COLLCONF register (address 0x1C):
//       [19:16] MAXRET       -> maximum retries before RL abort
//       [5:0]   COLLVALID    -> collision-valid window in bytes
//
//   TX_BD_NUM register (address 0x20):
//       [7:0]   tx_bd_num    -> number of TX BDs (determines RX BD start)
// =============================================================================

typedef struct {
    
    // ------------------------------------------------------------------
    // From the TX BD status word (wb_slave_monitor observed DATA_I)
    // ------------------------------------------------------------------
    bit [15:0] len;           // BD[31:16] – payload byte count
    bit        rd;            // BD[15]    – ready / armed flag
    bit        irq;           // BD[14]    – per-BD interrupt enable
    bit        wr;            // BD[13]    – wrap bit (last BD in ring)
    bit        pad_bd;        // BD[12]    – per-packet pad enable
    bit        crc_bd;        // BD[11]    – per-packet CRC enable
    bit [31:0] txpnt;         // Pointer word – DMA source address

    // ------------------------------------------------------------------
    // From configuration registers (read via RAL frontdoor in pred_read_cfg)
    // ------------------------------------------------------------------
    // MODER (0x00)
    bit        pad_moder;     // MODER[15] – global pad enable
    bit        crcen;         // MODER[13] – global CRC enable
    bit        hugen;         // MODER[14] – huge packet enable
    bit        txen;          // MODER[1]  – transmit enable
    bit recsmall;
    bit dlycrcen;
    bit full_duplex;
    bit exdfren;
    bit no_pre;
    bit nobackoff;
    bit loopback;

    // PACKETLEN (0x18)
    bit [15:0] minfl;         // [31:16]   – minimum frame length
    bit [15:0] maxfl;         // [15:0]    – maximum frame length

    // COLLCONF (0x1C)
    bit [4:0]  maxret;        // [19:16]   – maximum retry count
    bit [5:0]  collvalid;     // [5:0]     – collision valid window (bytes)

    // TX_BD_NUM (0x20)
    bit [7:0]  tx_bd_num;     // [7:0]     – number of TX BDs in ring

    //--------------------------------------------
    // TXCTRL Register
    //--------------------------------------------
    bit        tx_pause_req;
    bit[15:0] tx_pause_tv;
    //--------------------------------------------
    // INT_MASK Register (0x00)
    //--------------------------------------------
    bit   txc_m;
    bit   txe_m;      
    bit   txb_m;   

    //--------------------------------------------
    // CTRL_CONFIG Register (0x00)
    //--------------------------------------------
    bit tx_flow;

    //--------------------------------------------
    // MAC Address Registers
    //--------------------------------------------
     bit [47:0] mac_addr;

    //--------------------------------------------
    //IPGT (Back to Back Inter Packet Gap Register)
    //--------------------------------------------
   bit [6:0] ipgt;
    //--------------------------------------------
    //IPGR1 (Non Back to Back Inter Packet Gap Register)
    //--------------------------------------------
    bit [6:0] ipgr1;
    //--------------------------------------------
    //IPGR1 (Non Back to Back Inter Packet Gap Register)
    //--------------------------------------------
    bit [6:0] ipgr2;
    // ------------------------------------------------------------------
    // Derived / computed fields (set inside pred_read_cfg)
    // ------------------------------------------------------------------
    // Effective PAD = per-BD pad OR global MODER pad
    // (eth_maccontrol: PadIn = r_Pad | PerPacketPad)
    bit        eff_pad;       // pad_bd | pad_moder
    // Effective CRC = per-BD CRC OR global MODER CRC
    // (eth_maccontrol: CrcEnIn = r_CrcEn | PerPacketCrcEn)
    bit        eff_crc;       // crc_bd | crcen

    // BD index this configuration snapshot belongs to
    int unsigned bd_index;

    // Simulation timestamp when RD=1 was observed (for debug)
    longint unsigned armed_time_ns;

} eth_tx_bd_cfg_s;


// =============================================================================
// struct: eth_tx_expected_s
// Object pushed into the predictor-to-comparator FIFO once a BD has both
// a captured wire frame AND a DUT-written status available.
// The comparator performs a pure diff between this and the wire capture.
// =============================================================================

typedef struct {
    // Expected packet bytes
    bytes_q       exp_pkt;
    int unsigned  exp_length;    // total expected wire length incl. CRC if any

    // Expected status field values (all exact, all deterministic from evidence)
    // Backoff DURATION is deliberately NOT included — it is randomized by
    // eth_random.v binary-exponential algorithm and belongs in an SVA bound
    // check, never in this comparator's exact-value comparison.
    bit          exp_ur;        // underrun expected?  (from pred_track_underrun)
    bit          exp_lc;        // late collision?     (from mii_monitor nibble offset vs COLLVALID)
    bit          exp_cs;        // carrier sense lost? (from mii_monitor MCrS mid-frame drop)
    bit          exp_df;        // deferred?           (from mii_monitor MCrS busy before MTxEn)
    int          exp_rtry;      // retry count         (= jam_count, exact from mii_monitor)
    bit          exp_rl;        // retry limit hit?    (exp_rtry >= cfg.maxret + 1)
    

    bit         exp_huge;              // huge frame error 
    bit         exp_txerr;             // Mtxerr
} eth_tx_expected_s;



// =============================================================================
// struct: eth_tx_pending_s
// Internal scoreboard record maintained while a TX BD is in flight.
// Populated incrementally as evidence arrives from the three monitors.
// Emitted to the comparator FIFO once the completion-read is observed.
// =============================================================================

typedef struct {

    // Collision / error tracking (populated from mii_monitor events)
    int unsigned retry_cnt;         // total MTxEn pulses seen for this BD
    int unsigned attempt_count;         // total MTxEn pulses seen for this BD
    int unsigned jam_cnt;             // jam patterns (0x99999999) observed
    bit          flag_txerr;           // set when Tx error is asserted 
    bit          flag_rd;
    bit          flag_abort;             // frame abort
    bit          flag_start_frame;       //
    int unsigned ipgt_cycles;
	bit          ipgt_valid;
	int unsigned ipgr_cycles;
	bit          ipgr_valid ;
	bit          collision_seen;
    // actual frame captured by mii_monitor (populated on MII_TX_FRAME event)
    // INCLUDING any CRC trailer if CRC was appended
    bytes_q      actual_pkt;


} eth_tx_pending_s;

`endif // ETH_TX_SCOREBOARD_STRUCT_SV