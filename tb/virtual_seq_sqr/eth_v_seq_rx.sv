class eth_v_seq_rx_base extends eth_v_seq_base;
  `uvm_object_utils(eth_v_seq_rx_base)

  function new(string name = "eth_v_seq_rx_base");
    super.new(name);
  endfunction

  // ---------------------------------------------------------------------------
  // Helper Tasks for MAC Configuration (Using Wishbone Slave)
  // ---------------------------------------------------------------------------
  
  // Task to configure MAC registers (e.g., enable RXEN)
  virtual task configure_mac_rx();
    `uvm_info("V_SEQ", "Configuring MAC RX Registers...", UVM_LOW)
  endtask

  // Task to initialize RX Buffer Descriptors in memory
  virtual task setup_rx_bds(int num_bds);
    `uvm_info("V_SEQ", $sformatf("Setting up %0d RX BDs via Wishbone...", num_bds), UVM_LOW)
  endtask

endclass