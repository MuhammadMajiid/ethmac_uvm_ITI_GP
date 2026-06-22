
`ifndef MII_TX_SEQUENCER_BASE_SV
`define MII_TX_SEQUENCER_BASE_SV

class mii_tx_sequencer_base extends uvm_sequencer #(mii_tx_tx);
  `uvm_component_utils(mii_tx_sequencer_base)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

endclass

`endif // MII_TX_SEQUENCER_BASE_SV
