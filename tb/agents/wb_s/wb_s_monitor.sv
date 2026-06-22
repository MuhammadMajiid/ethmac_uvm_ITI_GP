
`ifndef WB_M_MONITOR_SV
`define WB_M_MONITOR_SV

class wb_s_monitor extends uvm_monitor;
  `uvm_component_utils(wb_s_monitor)

  virtual dut_if m_vif;

  uvm_analysis_port #(wb_tx) a_port;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    a_port = new("a_port", this);
  endfunction

  task run_phase(uvm_phase phase);
    // Monitor implementation goes here
    // Passive monitoring of wishbone slave interface
  endtask

endclass

`endif // WB_S_MONITOR_SV