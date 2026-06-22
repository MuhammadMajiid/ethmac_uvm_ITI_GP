
`ifndef MDIO_MONITOR_SV
`define MDIO_MONITOR_SV

class mdio_monitor extends uvm_monitor;
  `uvm_component_utils(mdio_monitor)

  uvm_analysis_port #(mdio_tx) a_port;

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
      mdio_tx tx;
      tx = mdio_tx::type_id::create("tx");

      // TODO: Observe DUT MDIO interface and populate tx

      a_port.write(tx);
    end
  endtask

endclass

`endif // MDIO_MONITOR_SV
