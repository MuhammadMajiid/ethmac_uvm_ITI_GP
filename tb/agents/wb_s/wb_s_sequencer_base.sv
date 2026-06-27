//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_s_sequencer_base.sv
// Author   : Nada
// Date     : 2026-06-23
//------------------------------------------------------------------------------
// Description:
// Base Wishbone slave sequencer.
// Parameterized UVM sequencer that generates wb_slave transactions for the
// slave driver in ACTIVE mode.
//------------------------------------------------------------------------------
`ifndef WB_S_SEQUENCER_BASE_SV
`define WB_S_SEQUENCER_BASE_SV

class wb_s_sequencer_base extends uvm_sequencer #(wb_s_seq_item_base);
  `uvm_component_utils(wb_s_sequencer_base)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

endclass

`endif // WB_S_SEQUENCER_BASE_SV
