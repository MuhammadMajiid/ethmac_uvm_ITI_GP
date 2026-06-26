//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : mdio_agent_config.sv
// Author   : Muhammad Majid
// Date     : 2026-06-26
//------------------------------------------------------------------------------
// Description:
//   Configuration object for the MDIO agent. Holds active status and interface.
//==============================================================================

`ifndef MDIO_AGENT_CONFIG_SV
`define MDIO_AGENT_CONFIG_SV

class mdio_agent_config extends uvm_object;
  `uvm_object_utils(mdio_agent_config)

  uvm_active_passive_enum is_active = UVM_ACTIVE;
  virtual mdio_if vif;

  function new(string name = "mdio_agent_config");
    super.new(name);
  endfunction

endclass

`endif // MDIO_AGENT_CONFIG_SV