
`ifndef WB_M_PKG_SV
`define WB_M_PKG_SV

package wb_m_pkg;
    `include "uvm_macros.svh"
    import uvm_pkg::*;

    `include "wb_m_tx.sv"
    `include "wb_m_config.sv"
    `include "wb_m_sqr.sv"
    `include "wb_m_driver.sv"
    `include "wb_m_monitor.sv"
    `include "wb_m_agent.sv"

endpackage : wb_m_pkg

`endif // WB_M_PKG_SV
