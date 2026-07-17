class eth_bd_wr_seq extends uvm_sequence;

  `uvm_object_utils(eth_bd_wr_seq)

  eth_reg_block model;

  function new(string name="eth_bd_rw_seq");
    super.new(name);
  endfunction

  virtual task body();

    uvm_status_e status;
    uvm_reg_data_t rdata;
    uvm_reg_data_t wdata;
	 int NUM_TX_BD = 128;

    //--------------------------------------------------------
    // Write every BD location
    //--------------------------------------------------------

  // Enable automatic compare on reads
  
      // Configure number of TX descriptors
    model.TX_BD_NUM.write(status, NUM_TX_BD);
 

    for(int i=0;i<256;i++) begin

      wdata = 32'hA5A50000 + i;

      model.eth_bd_mem.write(
          status,
          i,
          wdata,
          UVM_FRONTDOOR);

      if(status != UVM_IS_OK)
        `uvm_error("BD_WRITE",
          $sformatf("Write failed at location %0d",i));

    end


    //--------------------------------------------------------
    // Read every BD location
    //--------------------------------------------------------
//--------------------------------------------------------
//--------------------------------------------------------
 // Read every BD location
  // UVM automatically compares against the mirror
  //--------------------------------------------------------
  for (int i = 0; i < 256; i++) begin

    model.eth_bd_mem.read(
      status,
      i,
      rdata,
      UVM_FRONTDOOR
    );

    if (status != UVM_IS_OK)
      `uvm_error("BD_READ",
        $sformatf("Read failed at location %0d", i))
    else
      `uvm_info("BD_READ",
        $sformatf("Read PASS at location %0d Data=%08h", i, rdata),
        UVM_LOW)

  end

  endtask

endclass
