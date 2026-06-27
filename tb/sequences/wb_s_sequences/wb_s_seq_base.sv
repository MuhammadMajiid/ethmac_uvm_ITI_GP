//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_s_seq_base.sv
// Author   : Nada
// Date     : 2026-06-24
//------------------------------------------------------------------------------
// Description:
// Base sequence for Wishbone transactions.
//
// Provides common Wishbone read and write tasks that can be reused by
// register, BD, interrupt, and Ethernet MAC test sequences.
//==============================================================================
`ifndef WB_S_SEQ_BASE_SV
`define WB_S_SEQ_BASE_SV
class wb_s_seq_base extends uvm_sequence #(wb_s_seq_item_base); 
                                              
  `uvm_object_utils(wb_s_seq_base)

  //--------------------------------------------------------------------------
  // Constructor
  //--------------------------------------------------------------------------
  function new (string name = "");
    super.new(name);
  endfunction

  //--------------------------------------------------------------------------
  // Wishbone Write
  //--------------------------------------------------------------------------
  task wb_write(
    input bit [31:0] addr,
    input bit [31:0] data
  );
    req = wb_s_seq_item_base::type_id::create("req");
    start_item(req);
    req.m_addr  = addr;
    req.m_wdata = data;
    req.m_we    = 1'b1;
    req.m_sel   = 4'hF;
    finish_item(req);
    if (!req.m_ack)
      `uvm_error(get_type_name(),
                 $sformatf("Write failed at address 0x%08h", addr))
  endtask

  //--------------------------------------------------------------------------
  // Wishbone Read
  //--------------------------------------------------------------------------
  task wb_read(
    input  bit [31:0] addr,
    output bit [31:0] data
  );
    req = wb_s_seq_item_base::type_id::create("req");
    start_item(req);
    req.m_addr  = addr;
    req.m_wdata = '0;
    req.m_we    = 1'b0;
    req.m_sel   = 4'hF;
    finish_item(req);
    if (!req.m_ack)
      `uvm_error(get_type_name(),
                 $sformatf("Read failed at address 0x%08h", addr))
    data = req.m_rdata;
  endtask

  //--------------------------------------------------------------------------
  // Sequence Body
  //--------------------------------------------------------------------------
  task body();
    `uvm_info(get_type_name(), "Executing wb_s_seq_base", UVM_LOW)
  endtask

endclass
`endif // WB_S_SEQ_BASE_SV