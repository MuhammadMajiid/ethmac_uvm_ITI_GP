
`ifndef MII_TX_MONITOR_SV
`define MII_TX_MONITOR_SV

class mii_tx_monitor extends uvm_monitor;
  `uvm_component_utils(mii_tx_monitor)

  uvm_analysis_port #(mii_tx_tx) a_port;

  virtual mii_tx_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    a_port = new("a_port", this);
  endfunction

  task run_phase(uvm_phase phase);
    forever
    begin
      mii_tx_tx tx;
      tx = mii_tx_tx::type_id::create("tx");

      // TODO: Observe DUT interface and populate tx

      a_port.write(tx);
    end
  endtask

endclass

`endif // MII_TX_MONITOR_SV
