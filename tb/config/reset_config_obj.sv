//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : reset_config_obj.sv
// Author   : Nada
// Date     : 2026-07-16
//------------------------------------------------------------------------------
// Description:
// Configuration object for the reset agent.
//
// Contains:
//   - Virtual interface handle.
//   - Agent mode (ACTIVE/PASSIVE).
// Passed through the UVM configuration database to agent components.
//==============================================================================
class reset_config_obj extends uvm_object;

  `uvm_object_utils(reset_config_obj) 

  virtual reset_if vif;

  uvm_active_passive_enum is_active = UVM_ACTIVE;

  function new(string name="reset_config_obj");
    super.new(name);
  endfunction

endclass