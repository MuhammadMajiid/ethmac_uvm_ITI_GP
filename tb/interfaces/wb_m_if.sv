//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_m_if.sv
// Author   : Wael
// Date     : 2026-06-24
//------------------------------------------------------------------------------
// Description:
//   Interface for wishbone master signals.
//==============================================================================

`ifndef WB_M_IF_SV
`define WB_M_IF_SV

interface wb_m_if #(parameter ADDR_WIDTH = 32, DATA_WIDTH = 32,SEL_WIDTH = 4)(
    input logic clk_i,
    input logic rst_i
);

    // -------------------------------------------------------------------------
    // Wishbone Master Signals
    // -------------------------------------------------------------------------

    
    logic [ADDR_WIDTH-1:0] m_addr_o;                 // Memory address
    logic [DATA_WIDTH-1:0] m_data_o;                 // data captured from DUT (For RX)
    logic [DATA_WIDTH-1:0] m_data_i;                 // data read by DUT (For TX)
    logic [SEL_WIDTH-1:0]  m_sel_o;                  // Select which byte lane is valid.
    logic                  m_we_o;                   // write/read enable
    logic                  m_stb_o;                  // Indicates beginning of a valid transfer cycle.
    logic                  m_cyc_o;                  // Indicates that a valid bus cycle is in progress.
    logic                  m_ack_i;                  // Indicates a normal cycle termination.
    logic                  m_err_i;                  // Indicates an abnormal cycle termination.

    // -------------------------------------------------------------------------
    // Clocking Block
    // -------------------------------------------------------------------------

    clocking cb @(posedge clk_i);
        
        // Inputs arrive before 1 time step positive edge of clk
        // Outputs driven after 1 time step positive edge of clk
        default input #1 output #1;

        // DUT outputs
        input   m_addr_o;
        input   m_data_o;
        input   m_sel_o;
        input   m_we_o;
        input   m_stb_o;
        input   m_cyc_o;

        // DUT inputs
        output  m_data_i;
        output  m_ack_i;
        output  m_err_i;
    endclocking

    
    // -------------------------------------------------------------------------
    // Modport
    // -------------------------------------------------------------------------

    modport dut (
        input  clk_i,

        output m_addr_o,
        output m_data_o,
        output m_sel_o,
        output m_we_o,
        output m_stb_o,
        output m_cyc_o,

        input  m_data_i,
        input  m_ack_i,
        input  m_err_i
    );


endinterface : wb_m_if

`endif // WB_M_IF_SV