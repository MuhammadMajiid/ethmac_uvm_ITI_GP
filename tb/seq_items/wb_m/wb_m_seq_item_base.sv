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


class wb_m_seq_item_base extends uvm_sequence_item;

    `uvm_object_utils(wb_m_seq_item_base)

    //--------------------------------------------------------------------------
    // Transaction fields
    //--------------------------------------------------------------------------


    // Randomized fields
    rand bit [WB_DATA_WIDTH-1:0] m_data_i;                                           // data read by DUT (For TX)
    rand bit                      m_ack_i;                                            // Indicates a normal cycle termination.
    rand bit                      m_err_i;                                            // Indicates an abnormal cycle termination.

    // fields driven by dut, not randomized
    wb_dir_t                      m_dir;                                              // write/read direction
    logic [WB_DATA_WIDTH-1:0]    m_data_o;                                           // data captured from DUT (For RX)
    logic [WB_M_ADDR_WIDTH-1:0]  m_addr_o;                                           // Memory address 
    logic [WB_SEL_WIDTH-1:0]     m_sel_o;                                            // Select which byte lane is valid.
    logic                         m_stb_o;                                            // Indicates beginning of a valid transfer cycle.
    logic                         m_cyc_o;                                            // Indicates that a valid bus cycle is in progress.

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new (string name = "");
        super.new(name);
    endfunction

    //------------------------------------------------------------------------------
    // Print transaction fields
    //------------------------------------------------------------------------------
function string convert2string();

    return $sformatf(
        "\n\
m_dir   = %s\n\
m_addr  = 0x%08h\n\
m_data_o= 0x%08h\n\
m_data_i= 0x%08h\n\
m_sel   = 0x%1h\n\
m_stb   = %0b\n\
m_cyc   = %0b\n\
m_ack   = %0b\n\
m_err   = %0b",
        m_dir.name(),
        m_addr_o,
        m_data_o,
        m_data_i,
        m_sel_o,
        m_stb_o,
        m_cyc_o,
        m_ack_i,
        m_err_i
    );

endfunction

endclass : wb_m_seq_item_base

`endif // WB_M_SEQ_ITEM_BASE_SV
