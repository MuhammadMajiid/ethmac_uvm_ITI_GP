//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : mdio_sequencer_base.sv
// Author   : Muhammad Majid
// Date     : 2026-06-26
//------------------------------------------------------------------------------
// Description:
//   Base MDIO sequencer for Ethernet MAC management interface. Generates mdio_seq_item_base sequences.
//==============================================================================

`ifndef MDIO_SEQUENCER_BASE_SV
`define MDIO_SEQUENCER_BASE_SV

class mdio_sequencer_base extends uvm_sequencer #(mdio_seq_item_base);
  `uvm_component_utils(mdio_sequencer_base)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

endclass

`endif // MDIO_SEQUENCER_BASE_SV
