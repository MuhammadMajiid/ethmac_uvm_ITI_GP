
`ifndef WB_S_SEQUENCER_BASE_SV
`define WB_S_SEQUENCER_BASE_SV

class wb_s_sequencer_base extends uvm_sequencer #(wb_tx);
  `uvm_component_utils(wb_s_sequencer_base)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

endclass

`endif // WB_S_SEQUENCER_BASE_SV
