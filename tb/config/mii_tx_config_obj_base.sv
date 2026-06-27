//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : mii_tx_config_obj_base.sv
// Author   : Mounir
// Date     : 2026-06-24
//------------------------------------------------------------------------------
// Description:
// Base configuration object for the MII Transmit Agent.
// Holds static settings that define agent behavior for the entire duration of a test,
// including:
//           - Virtual interface handle (mii_tx_if)
//           - Active/passive mode selection
//           - Duplex mode (HALF_DUPLEX / FULL_DUPLEX) — must match
//             MODER.FULLD register value written to the DUT
//           - Speed mode (10 Mbps / 100 Mbps) for timing calculations
//           - COLLVALID and MAXRET values mirroring COLLCONF register
//             so driver and monitor share the same window boundary
//           - Monitor feature enables (jam pattern check, retry
//             counting, backoff delay measurement)
//==============================================================================

`ifndef MII_TX_CONFIG_OBJ_BASE_SV
`define MII_TX_CONFIG_OBJ_BASE_SV

class mii_tx_config_obj_base extends uvm_object;

    `uvm_object_utils(mii_tx_config_obj_base)
    // enum for holding if the agent is activeor passive
    uvm_active_passive_enum is_active = UVM_ACTIVE;

    virtual mii_tx_if vif;

    function new(string name = "mii_tx_config_obj_base");
        super.new(name);
    endfunction
/*
    // Speed mode
    typedef enum { MBPS_10, MBPS_100 } speed_e;
    speed_e speed = MBPS_100;

    // Half/Full duplex mode
    // Must match MODER.FULLD register value in DUT
    //------------------------------------------------
    typedef enum logic { HALF_DUPLEX = 0, FULL_DUPLEX = 1 } duplex_e;
    duplex_e duplex_mode = HALF_DUPLEX;

    // Default collision/carrier sense behavior
    // Sequences can override per-transaction via
    // sequence_item fields, but these set the
    // agent's baseline behavior

    // MCrS default state (idle = 0)
    logic default_mcrs = 0;

    // Should driver automatically deassert MColl after mcoll_duration cycles?
    logic auto_deassert_mcoll = 1;

    // COLLVALID setting — driver uses this to know the valid collision window boundary
    // Should match COLLCONF.COLLVALID in DUT
    int unsigned collvalid = 63; // default 0x3F

    // MAXRET — used by sequences to know retry limit
    // Should match COLLCONF.MAXRET in DUT
    int unsigned maxret = 15; // default 0xF

    // Monitor settings

    //check jam pattern content
    logic check_jam_pattern  = 1;
    // count retry attempts
    logic count_retries      = 1;
    // measure backoff delays
    logic measure_backoff    = 1;
*/
endclass : mii_tx_config_obj_base

`endif