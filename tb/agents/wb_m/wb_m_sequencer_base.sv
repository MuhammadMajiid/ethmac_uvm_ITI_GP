//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_m_sequencer_base.sv
// Author   : Wael
// Date     : 2026-06-24
//------------------------------------------------------------------------------
// Description:
//   Sequencer for wishbone master agent. In addition to sending transactons to
//   driver, it receives requests from monitor on separate analysis port.
//==============================================================================
`ifndef WB_M_SEQUENCER_BASE_SV
`define WB_M_SEQUENCER_BASE_SV

class wb_m_sequencer_base extends uvm_sequencer #(wb_m_seq_item_base);

    `uvm_component_utils(wb_m_sequencer_base)

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction

endclass : wb_m_sequencer_base

`endif // WB_M_SEQUENCER_BASE_SV
