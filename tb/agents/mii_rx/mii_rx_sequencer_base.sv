//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : mii_rx_sequencer_base.sv
// Author   : Mariam
// Date     : 2026-06-24
//------------------------------------------------------------------------------
// Description:
//   Sequencer for MII Rx agent.
//==============================================================================

`ifndef MII_RX_SEQUENCER_BASE_SV
`define MII_RX_SEQUENCER_BASE_SV

  `include "uvm_macros.svh"
  import uvm_pkg::*;

class mii_rx_sequencer_base extends uvm_sequencer #(mii_rx_seq_item);
  `uvm_component_utils(mii_rx_sequencer_base)

  //--------------------------------------------------------------------------
  // Constructor
  //--------------------------------------------------------------------------
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

endclass : mii_rx_sequencer_base

`endif // MII_RX_SEQUENCER_BASE_SV