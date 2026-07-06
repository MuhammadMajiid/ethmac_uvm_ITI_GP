//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_m_config_obj.sv
// Author   : Wael
// Date     : 2026-06-24
//------------------------------------------------------------------------------
// Description:
//   Configuration object for wishbone master agent.
//==============================================================================

`ifndef WB_M_CONFIG_OBJ_SV
`define WB_M_CONFIG_OBJ_SV

class wb_m_config_obj extends uvm_object;

    `uvm_object_utils(wb_m_config_obj)

    virtual wb_m_if                vif;                         // Virtual interface handle
    uvm_active_passive_enum        is_active  = UVM_ACTIVE;     // enum for holding if the agent is activeor passive

    function new (string name = "");
        super.new(name);
    endfunction

endclass : wb_m_config_obj

`endif //WB_M_CONFIG_OBJ
