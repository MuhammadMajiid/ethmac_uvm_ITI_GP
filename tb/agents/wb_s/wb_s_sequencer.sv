
`ifndef WB_S_SEQUENCER_SV
`define WB_S_SEQUENCER_SV

class wb_s_sequencer extends uvm_sequencer #(wb_tx);
  `uvm_component_utils(wb_s_sequencer)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

endclass

`endif // WB_S_SEQUENCER_SV
