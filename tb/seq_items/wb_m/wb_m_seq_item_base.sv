//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_m_seq_item_base.sv
// Author   : Wael
// Date     : 2026-06-24
//------------------------------------------------------------------------------
// Description:
//   Transaction contains wishbone interface ports.
//==============================================================================

`ifndef WB_M_SEQ_ITEM_BASE_SV
`define WB_M_SEQ_ITEM_BASE_SV

    `include "uvm_macros.svh"
    import uvm_pkg::*;

class wb_m_seq_item_base extends uvm_sequence_item;

    `uvm_object_utils(wb_m_seq_item_base)

    //--------------------------------------------------------------------------
    // Transaction fields
    //--------------------------------------------------------------------------
    // Enum represents write/read
    typedef enum logic { WB_READ = 1'b0, WB_WRITE = 1'b1 , UNKNOWN= 1'bx, HIGH_IMP= 1'bz} wb_dir_t;    


    // Randomized fields
    rand bit [31:0] m_data_i;                                           // data read by DUT (For TX)
    rand bit        m_ack_i;                                            // Indicates a normal cycle termination.
    rand bit        m_err_i;                                            // Indicates an abnormal cycle termination.

    // fields driven by dut, not randomized
    wb_dir_t        m_dir;                                              // write/read direction
    logic [31:0]    m_data_o;                                           // data captured from DUT (For RX)
    logic [31:0]    m_addr_o;                                           // Memory address 
    logic [3:0]     m_sel_o;                                            // Select which byte lane is valid.
    logic           m_stb_o;                                            // Indicates beginning of a valid transfer cycle.
    logic           m_cyc_o;                                            // Indicates that a valid bus cycle is in progress.

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new (string name = "");
        super.new(name);
    endfunction


endclass : wb_m_seq_item_base

`endif // WB_M_SEQ_ITEM_BASE_SV
