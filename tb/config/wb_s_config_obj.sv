//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_s_config_obj.sv
// Author   : Nada
// Date     : 2026-06-23
//------------------------------------------------------------------------------
// Description:
// Configuration object for the Wishbone slave agent.
//
// Contains:
//   - Virtual interface handle.
//   - Agent mode (ACTIVE/PASSIVE).
//   - Coverage enable control.
//   - Checks enable control.
//
// Passed through the UVM configuration database to agent components.
//==============================================================================
`ifndef WB_S_CONFIG_OBJ_SV
`define WB_S_CONFIG_OBJ_SV
class wb_s_config_obj extends uvm_object;

  `uvm_object_utils(wb_s_config_obj)

  virtual wb_s_if           vif;               
  uvm_active_passive_enum is_active = UVM_ACTIVE;
  bit               coverage_enable = 1'b1;
  bit                 checks_enable = 1'b1;

  function new(string name = "");
    super.new(name);
  endfunction

endclass
`endif // WB_S_CONFIG_OBJ_SV