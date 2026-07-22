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
`timescale 1ns/1ps

// Import UVM base package 
`include "uvm_macros.svh"
import uvm_pkg::*;

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
        
        // Inputs arrive before 1 time step positive edge of clk_i
        // Outputs driven after 1 time step positive edge of clk_i
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



  //--------------------------------------------------------------------------
  // Assertions
  //--------------------------------------------------------------------------

  // WBM_RESET_NO_X_Z_PROPAGATION: Ensures no x z propagation for all ports
  a_rst_x_z_addr: assert property(@(posedge clk_i) disable iff(!rst_i) (rst_i |-> not $isunknown(m_addr_o) ))
    else `uvm_error("A_WB_M",$sformatf("Assertion failed, address = %0d",m_addr_o));
  a_rst_x_z_data_o: assert property(@(posedge clk_i) disable iff(!rst_i) (rst_i |-> not $isunknown(m_data_o) ))
    else `uvm_warning("A_WB_M",$sformatf("Assertion failed, data out = %0d",m_data_o));
  a_rst_x_z_we: assert property(@(posedge clk_i) disable iff(!rst_i)   (rst_i |->  not $isunknown(m_we_o) ))
    else `uvm_error("A_WB_M",$sformatf("Assertion failed, write enable = %0d",m_we_o));
  a_rst_x_z_sel: assert property(@(posedge clk_i) disable iff(!rst_i)   (rst_i |->  not $isunknown(m_sel_o) ))
    else `uvm_error("A_WB_M",$sformatf("Assertion failed, select = %0d",m_sel_o));
  // WBM_RST_STB_DEASSERTED: M_STB_O must be deasserted during reset. MAC is initialized.  
  a_rst_stb: assert property(@(posedge clk_i) disable iff(!rst_i)   (rst_i |-> m_stb_o==1'b0 ))
    else `uvm_error("A_WB_M",$sformatf("Assertion failed, stb = %0d",m_stb_o));
  // WBM_RST_CYC_DEASSERTED: M_CYC_O must be deasserted during reset. 
  a_rst_cyc: assert property(@(posedge clk_i) disable iff(!rst_i)   (rst_i |-> m_cyc_o==1'b0))
    else `uvm_error("A_WB_M",$sformatf("Assertion failed, cyc = %0d",m_cyc_o));


  // WBM_STB_REQUIRES_CYC: M_STB_O must never assert without M_CYC_O also being asserted. 
  property p_stb_cyc;
    @(posedge clk_i)  disable iff(rst_i) (m_stb_o |-> m_cyc_o);
  endproperty
  a_stb_cyc: assert property (p_stb_cyc);
  c_stb_cyc: cover property (p_stb_cyc);

 // WBM_ACK_REQUIRES_STB_CYC: M_ACK_I may only assert when both M_CYC_O and M_STB_O are simultaneously high.
  property p_ack_stb_cyc;
     @(posedge clk_i) disable iff(rst_i) (m_ack_i |-> m_stb_o && m_cyc_o);
  endproperty
  a_ack_stb_cyc: assert property (p_ack_stb_cyc);
  c_ack_stb_cyc: cover property (p_ack_stb_cyc);

 // WBM_ERR_REQUIRES_STB_CYC" M_ERR_I may only assert when both M_CYC_O and M_STB_O are high.  
  property p_err_stb_cyc;
     @(posedge clk_i) disable iff(rst_i) (m_err_i |-> m_stb_o && m_cyc_o);
  endproperty
  a_err_stb_cyc: assert property (p_err_stb_cyc);
  c_err_stb_cyc: cover property (p_err_stb_cyc);

 // WBM_ACK_ERR_MUTEX M_ACK_I: and M_ERR_I must never be asserted simultaneously. 
  property p_ack_err_cyc;
     @(posedge clk_i) disable iff(rst_i) ($onehot({m_ack_i,m_err_i}) || (!m_ack_i && !m_err_i));
  endproperty
  a_ack_err_cyc: assert property (p_ack_err_cyc);
  c_ack_err_cyc: cover property (p_ack_err_cyc);

 // WBM_ACK_ERR_ON_PARTIAL_SEL When M_SEL_O is not 4'hF during a valid bus cycle M_ERR_I must be asserted M_ACK_I must not assert. 
  property p_ack_err_sel;
     @(posedge clk_i) disable iff(rst_i) (m_stb_o && m_cyc_o && !(&m_sel_o)) |=> (m_err_i && !m_ack_i) ;
  endproperty
  a_ack_err_sel: assert property (p_ack_err_sel);
  c_ack_err_sel: cover property (p_ack_err_sel);

  // WBM_WE_STABLE DURING_TRANSFER: During transfer WE_O must remain stable. 
  property p_we_ack;
     @(posedge clk_i) disable iff(rst_i) (m_stb_o && m_cyc_o) |-> ($stable(m_we_o));
  endproperty
  a_we_ack: assert property (p_we_ack);
  c_we_ack: cover property (p_we_ack);


endinterface : wb_m_if

`endif // WB_M_IF_SV