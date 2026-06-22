
`ifndef MII_RX_MONITOR_SV
`define MII_RX_MONITOR_SV

class mii_rx_monitor extends uvm_monitor;
  `uvm_component_utils(mii_rx_monitor)

  uvm_analysis_port #(mii_rx_tx) a_port;

  virtual mii_rx_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    a_port = new("a_port", this);
    // vif assigned by agent from config object
  endfunction

  task run_phase(uvm_phase phase);
    forever
    begin
      mii_rx_tx tx;
      tx = mii_rx_tx::type_id::create("tx");

      // TODO: Observe DUT interface and populate tx
      // e.g. @(posedge vif.clk iff vif.rx_dv);
      //      tx.m_nibble = vif.rxd;

      a_port.write(tx);
    end
  endtask

endclass

`endif // MII_RX_MONITOR_SV
