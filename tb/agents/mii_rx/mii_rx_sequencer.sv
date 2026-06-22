
`ifndef MII_RX_SEQUENCER_SV
`define MII_RX_SEQUENCER_SV

class mii_rx_sequencer extends uvm_sequencer #(mii_rx_tx);
  `uvm_component_utils(mii_rx_sequencer)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

endclass

`endif // MII_RX_SEQUENCER_SV
