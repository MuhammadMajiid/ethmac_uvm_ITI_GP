//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_s_seq_item_base.sv
// Author   : Nada
// Date     : 2026-06-24
//------------------------------------------------------------------------------
// Description:
// Base sequence item for Wishbone transactions.
//
// Provides a generic request/response transaction that can be reused by
// register, BD, interrupt, and Ethernet MAC test sequences.
//==============================================================================

`ifndef WB_S_SEQ_ITEM_BASE_SV
`define WB_S_SEQ_ITEM_BASE_SV


class wb_s_seq_item_base #(
    parameter int WB_S_ADDR_WIDTH = 10,
    parameter int WB_DATA_WIDTH  = 32,
    parameter int WB_SEL_WIDTH    = 4
) extends uvm_sequence_item;

  `uvm_object_param_utils(wb_s_seq_item_base#(WB_S_ADDR_WIDTH, WB_DATA_WIDTH,WB_SEL_WIDTH))

  //--------------------------------------------------------------------------
  // Request
  //--------------------------------------------------------------------------
  rand bit [WB_S_ADDR_WIDTH-1:0] m_addr;     // ADDR_I
  rand bit [WB_DATA_WIDTH-1:0] m_wdata;    // DATA_I
  rand wb_dir_t             m_dir;      // Read/Write
  rand bit [WB_SEL_WIDTH -1:0] m_sel;  // Byte enables

  //--------------------------------------------------------------------------
  // Response
  //--------------------------------------------------------------------------
  bit [WB_DATA_WIDTH-1:0] m_rdata;         // DATA_O
  bit                  m_ack;           // ACK_O
  bit                  m_err;           // ERR_O
  bit                  m_inta;          // INTA_O

  //--------------------------------------------------------------------------
  // Constraints
  //--------------------------------------------------------------------------

  // All byte lanes enabled by default.
  constraint c_sel_full {
    m_sel == 4'hF;
  }

  //--------------------------------------------------------------------------
  // Constructor
  //--------------------------------------------------------------------------
  function new(string name = "wb_s_seq_item_base");
    super.new(name);
  endfunction

  //--------------------------------------------------------------------------
  // convert2string()
  //--------------------------------------------------------------------------
  function string convert2string();

    string dir_str;

    dir_str = (m_dir == WB_WRITE) ? "WRITE" : "READ";

    return $sformatf(
      "%s addr=0x%0h dir=%s sel=0x%0h wdata=0x%0h rdata=0x%0h ack=%0b err=%0b inta=%0b",
      super.convert2string(),
      m_addr,
      dir_str,
      m_sel,
      m_wdata,
      m_rdata,
      m_ack,
      m_err,
      m_inta
    );

  endfunction

endclass

`endif // WB_S_SEQ_ITEM_BASE_SV