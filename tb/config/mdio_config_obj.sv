//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : mdio_config_obj.sv
// Author   : Muhammad Majid
// Date     : 2026-06-26
//------------------------------------------------------------------------------
// Description:
//   Configuration object for the MDIO agent. Holds active status and interface.
//==============================================================================

`ifndef MDIO_CONFIG_OBJ_SV
`define MDIO_CONFIG_OBJ_SV

class mdio_config_obj extends uvm_object;
  `uvm_object_utils(mdio_config_obj)

  uvm_active_passive_enum is_active = UVM_ACTIVE;
  virtual mdio_if vif;
  eth_reg_block m_regmodel;

  function new(string name = "mdio_config_obj");
    super.new(name);
  endfunction

endclass

`endif // MDIO_CONFIG_OBJ_SV