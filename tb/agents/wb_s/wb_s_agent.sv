
`ifndef WB_S_AGENT_SV
`define WB_S_AGENT_SV

class wb_s_agent extends uvm_agent;
  `uvm_component_utils(wb_s_agent)

  uvm_analysis_port #(wb_tx) a_port;

  wb_s_sequencer m_sequencer;
  wb_s_driver m_driver;
  wb_s_monitor m_monitor;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    if (get_is_active() == UVM_ACTIVE)
    begin
      m_sequencer = wb_s_sequencer::type_id::create("m_sequencer", this);
      m_driver = wb_s_driver::type_id::create("m_driver", this);
    end
    m_monitor = wb_s_monitor::type_id::create("m_monitor", this);
    a_port = new("a_port", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    if (get_is_active() == UVM_ACTIVE)
      m_driver.seq_item_port.connect(m_sequencer.seq_item_export);
    m_monitor.a_port.connect(a_port);
  endfunction

endclass

`endif // WB_S_AGENT_SV