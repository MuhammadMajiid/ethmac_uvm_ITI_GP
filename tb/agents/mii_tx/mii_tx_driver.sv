
`ifndef MII_TX_DRIVER_SV
`define MII_TX_DRIVER_SV

class mii_tx_driver extends uvm_driver #(mii_tx_tx);
  `uvm_component_utils(mii_tx_driver)

  virtual mii_tx_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    forever
    begin
      mii_tx_tx req;
      seq_item_port.try_next_item(req);

      if (req != null)
      begin
        // TODO: Drive DUT interface signals from req
        seq_item_port.item_done();
      end
      else
      begin
        // TODO: Drive idle state
      end
    end
  endtask

endclass

`endif // MII_TX_DRIVER_SV
