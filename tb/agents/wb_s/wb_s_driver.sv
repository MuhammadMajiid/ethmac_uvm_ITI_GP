
`ifndef WB_S_DRIVER_SV
`define WB_S_DRIVER_SV

class wb_s_driver extends uvm_driver #(wb_tx);
  `uvm_component_utils(wb_s_driver)

  virtual dut_if m_vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    wb_tx req;
    forever
    begin
      seq_item_port.try_next_item(req);
      
      if (req != null)
      begin
        // Drive wishbone slave interface
        seq_item_port.item_done();
        @(posedge m_vif.clk);
      end
      else
      begin
        // Insert idle cycle
        @(posedge m_vif.clk);
      end
    end
  endtask

endclass

`endif // WB_S_DRIVER_SV