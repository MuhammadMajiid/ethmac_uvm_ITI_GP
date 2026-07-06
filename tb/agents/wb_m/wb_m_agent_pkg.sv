//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_m_agent_pkg.sv
// Author   : Wael
// Date     : 2026-06-24
//------------------------------------------------------------------------------
// Description:
//   Package for including wisbone files of agent & it's subcomponents.
//==============================================================================

`ifndef WB_M_AGENT_PKG_SV
`define WB_M_AGENT_PKG_SV

package wb_m_agent_pkg;
    

    `include "uvm_macros.svh"
    import uvm_pkg::*;

    // Global package
    import eth_glob_pkg::*;

    // Transaction and configuration object packages
    import wb_m_seq_item_pkg::*;
    // import config package
    import eth_config_pkg::*;
    
    // Agent subcomponents files
    `include "wb_m_sequencer_base.sv"
    `include "wb_m_driver_base.sv"
    `include "wb_m_monitor_base.sv"
    `include "wb_m_agent.sv"

endpackage : wb_m_agent_pkg

`endif // WB_M_AGENT_PKG_SV
