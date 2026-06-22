
`ifndef MII_TX_SEQUENCER_SV
`define MII_TX_SEQUENCER_SV

class mii_tx_sequencer extends uvm_sequencer #(mii_tx_tx);
  `uvm_component_utils(mii_tx_sequencer)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

endclass

`endif // MII_TX_SEQUENCER_SV
