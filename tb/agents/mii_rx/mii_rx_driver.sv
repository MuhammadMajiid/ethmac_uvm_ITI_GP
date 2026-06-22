
`ifndef MII_RX_DRIVER_SV
`define MII_RX_DRIVER_SV

class mii_rx_driver extends uvm_driver #(mii_rx_tx);
  `uvm_component_utils(mii_rx_driver)

  virtual mii_rx_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    // vif assigned by agent from config object
  endfunction

  task run_phase(uvm_phase phase);
    forever
    begin
      mii_rx_tx req;
      seq_item_port.try_next_item(req);

      if (req != null)
      begin
        // TODO: Drive DUT interface signals from req
        // e.g. @(posedge vif.clk);
        //      vif.rxd <= req.m_nibble;
        //      vif.rx_dv <= req.m_dv;
        seq_item_port.item_done();
      end
      else
      begin
        // TODO: Drive idle state
        // e.g. @(posedge vif.clk);
        //      vif.rx_dv <= 0;
      end
    end
  endtask

endclass

`endif // MII_RX_DRIVER_SV
