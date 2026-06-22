
`ifndef MDIO_SEQUENCER_BASE_SV
`define MDIO_SEQUENCER_BASE_SV

class mdio_sequencer_base extends uvm_sequencer #(mdio_tx);
  `uvm_component_utils(mdio_sequencer_base)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

endclass

`endif // MDIO_SEQUENCER_BASE_SV
