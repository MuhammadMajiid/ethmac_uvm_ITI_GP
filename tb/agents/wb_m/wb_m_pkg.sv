//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_m_pkg.sv
// Author   : Wael
// Date     : 2026-06-24
//------------------------------------------------------------------------------
// Description:
//   Package for including wisbone files of agent & it's subcomponents.
//==============================================================================

`ifndef WB_M_PKG_SV
`define WB_M_PKG_SV

package wb_m_pkg;
    `include "uvm_macros.svh"
    import uvm_pkg::*;

    `include "../../seq_items/wb_m/wb_m_seq_item_base.sv"
    `include "../../config/wb_m_config_obj.sv"
    `include "wb_m_sequencer_base.sv"
    `include "wb_m_driver_base.sv"
    `include "wb_m_monitor_base.sv"
    `include "wb_m_agent.sv"

endpackage : wb_m_pkg

`endif // WB_M_PKG_SV
