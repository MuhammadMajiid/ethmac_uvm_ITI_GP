
`ifndef MDIO_DRIVER_SV
`define MDIO_DRIVER_SV

class mdio_driver extends uvm_driver #(mdio_tx);
  `uvm_component_utils(mdio_driver)

  virtual mdio_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    forever
    begin
      mdio_tx req;
      seq_item_port.try_next_item(req);

      if (req != null)
      begin
        // TODO: Drive DUT MDIO interface signals from req
        seq_item_port.item_done();
      end
      else
      begin
        // TODO: Drive idle state
      end
    end
  endtask

endclass

`endif // MDIO_DRIVER_SV
