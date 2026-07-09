//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : mii_rx_config_obj.sv
// Author   : Mariam
// Date     : 2026-06-24
//------------------------------------------------------------------------------
// Description:
//   Configuration object for MII Rx Agent.
//==============================================================================

`ifndef MII_RX_CONFIG_OBJ_SV
`define MII_RX_CONFIG_OBJ_SV
  `include "uvm_macros.svh"
  import uvm_pkg::*;

class mii_rx_config_obj extends uvm_object;
  `uvm_object_utils(mii_rx_config_obj)

  // The Virtual Interface
  virtual mii_rx_if              vif;                         // Virtual interface handle
  uvm_active_passive_enum        is_active  = UVM_ACTIVE;     // enum for holding if the agent is activeor passive

  int unsigned                   active_comp_num = 3;
  int unsigned                   monitors_num = 1;

  //--------------------------------------------------------------------------
  // Constructor
  //--------------------------------------------------------------------------
  function new(string name = "");
    super.new(name);
  endfunction

endclass // mii_rx_config_obj 

`endif // MII_RX_CONFIG_OBJ_SV