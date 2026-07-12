//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_s_seq_base.sv
// Author   : Nada
// Date     : 2026-07-06
//------------------------------------------------------------------------------
// Description:
// Base UVM sequence for the Wishbone Slave Agent.
//
// Serves as the parent class for all Wishbone slave sequences used to
// configure the Ethernet MAC. The sequence provides access to the
// Ethernet MAC Register Abstraction Layer (RAL) model through the
// regmodel handle, enabling register and memory accesses using the
// UVM register API instead of raw Wishbone transactions.
//
// Derived sequences use this base class to configure MAC registers,
// program transmit/receive buffer descriptors, and initialize the
// DUT before functional test execution.
//==============================================================================
`ifndef WB_S_SEQ_BASE_SV
`define WB_S_SEQ_BASE_SV

class wb_s_seq_base extends
    uvm_sequence#(
        wb_s_seq_item_base#(
            WB_S_ADDR_WIDTH,
            WB_DATA_WIDTH,
            WB_SEL_WIDTH));

    `uvm_object_utils(wb_s_seq_base)
     eth_reg_block regmodel;
     uvm_status_e status;
    function new(string name="wb_s_seq_base");
        super.new(name);
    endfunction

    virtual task body();
    endtask


endclass
`endif // WB_S_SEQ_BASE_SV