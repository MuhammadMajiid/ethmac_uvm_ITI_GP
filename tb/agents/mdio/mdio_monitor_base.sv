
`ifndef MDIO_MONITOR_BASE_SV
`define MDIO_MONITOR_BASE_SV

class mdio_monitor_base extends uvm_monitor ;
  `uvm_component_utils(mdio_monitor_base)

  uvm_analysis_port #(mdio_seq_item) a_port;

  virtual mdio_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    a_port = new("a_port", this);
  endfunction

  task run_phase(uvm_phase phase);
    forever
    begin

      // TODO: Observe DUT MDIO interface and populate transactions

    end
  endtask

endclass

`endif // MDIO_MONITOR_BASE_SV
