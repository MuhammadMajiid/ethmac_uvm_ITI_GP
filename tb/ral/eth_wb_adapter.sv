//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_wb_adapter.sv
// Author   : Nada
// Date     : 2026-06-25
//------------------------------------------------------------------------------
// Description:
//UVM Register Adapter - translates between uvm_reg_bus_op
//             (abstract RAL operations) and wb_s_seq_item_base
//             (concrete WISHBONE bus transactions)
//
// This is the bridge between the RAL model and the physical WISHBONE
// interface. Every reg.read() and reg.write() call flows through this
// adapter.
//
// reg2bus: converts abstract register operation -> wb_s_seq_item_base
// bus2reg: converts wb_s_seq_item_base response -> abstract register data
// =============================================================================
`ifndef ETH_WB_ADAPTER_SV
`define ETH_WB_ADAPTER_SV



class eth_wb_adapter extends uvm_reg_adapter;

  `uvm_object_utils(eth_wb_adapter)

  function new (string name = "");
    super.new(name);
    supports_byte_enable = 1;
    provides_responses   = 0;
  endfunction

  //----------------------------------------------------------------------
  // reg2bus()
  //
  // Called by RAL when it wants to perform a register access.
  // Converts the abstract uvm_reg_bus_op into a wb_s_seq_item_base.
  //
  // rw.kind   = UVM_READ or UVM_WRITE
  // rw.addr   = register offset
  // rw.data   = data to write (ignored for reads)
  // rw.n_bits = number of bits (32 for this bus)
  //----------------------------------------------------------------------
  virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
    wb_s_seq_item_base tr;
    tr = wb_s_seq_item_base::type_id::create("tr");

    tr.m_addr  = rw.addr;
    tr.m_wdata = rw.data;
    tr.m_we    = (rw.kind == UVM_WRITE) ? 1'b1 : 1'b0;
    tr.m_sel   = 4'hF;

    return tr;
  endfunction : reg2bus

  //----------------------------------------------------------------------
  // bus2reg()
  //
  // Called by RAL once the driver has completed the transaction. Since
  // provides_responses = 0, bus_item here is the SAME object instance
  // returned from reg2bus() above, now populated by the driver.
  //
  // After this function:
  //   rw.data   = data read from hardware (for reads)
  //   rw.status = UVM_IS_OK or UVM_NOT_OK
  //----------------------------------------------------------------------
  virtual function void bus2reg(uvm_sequence_item bus_item,
                                 ref uvm_reg_bus_op rw);
    wb_s_seq_item_base tr;

    if (!$cast(tr, bus_item))
      `uvm_fatal("CAST_FAIL", "bus2reg: failed to cast bus_item to wb_s_seq_item_base")

    rw.data   = tr.m_rdata;
    rw.status = (tr.m_ack && !tr.m_err) ? UVM_IS_OK : UVM_NOT_OK;
  endfunction : bus2reg

endclass : eth_wb_adapter

`endif // ETH_WB_ADAPTER_SV
