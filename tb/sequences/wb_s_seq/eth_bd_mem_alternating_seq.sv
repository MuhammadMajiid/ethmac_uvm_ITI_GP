//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_bd_mem_alternating_seq.sv
// Author   : Nada
// Date     : 2026-07-15
//------------------------------------------------------------------------------
// Description:
//   Alternating pattern test for Ethernet Buffer Descriptor memory.
//   Pass 1 : Even BD -> 0xAAAAAAAA, Odd BD -> 0x55555555
//   Pass 2 : Even BD -> 0x55555555, Odd BD -> 0xAAAAAAAA
//==============================================================================

class eth_bd_mem_alternating_seq extends uvm_reg_sequence;

  `uvm_object_utils(eth_bd_mem_alternating_seq)

  uvm_status_e    status;
  uvm_reg_data_t  wr_data;
  uvm_reg_data_t  rd_data;

  string          msg;
  eth_reg_block   regmodel;

  int NUM_TX_BD = 20;

  function new(string name = "eth_bd_mem_alternating_seq");
    super.new(name);
  endfunction

  virtual task body();

    int addr;

    if (regmodel == null)
      `uvm_fatal(get_type_name(), "Register model handle is NULL")

    //----------------------------------------------------------
    // Configure number of TX descriptors
    //----------------------------------------------------------
    regmodel.TX_BD_NUM.write(status, NUM_TX_BD);

    //----------------------------------------------------------
    // PASS 1
    // Even -> AAAAAAAA
    // Odd  -> 55555555
    //----------------------------------------------------------
    `uvm_info(get_type_name(),
              "Starting Alternating Pattern Test - PASS 1",
              UVM_LOW)

    // Write
    for (addr = 0; addr < NUM_TX_BD; addr++) begin

      if (addr % 2 == 0)
        wr_data = 32'hAAAAAAAA;
      else
        wr_data = 32'h55555555;

      regmodel.eth_bd_mem.write(status,
                                addr,
                                wr_data);

      if (status != UVM_IS_OK)
        `uvm_error(get_type_name(),
                   $sformatf("Write failed at BD %0d", addr))
    end

    // Read & Verify
    for (addr = 0; addr < NUM_TX_BD; addr++) begin

      if (addr % 2 == 0)
        wr_data = 32'hAAAAAAAA;
      else
        wr_data = 32'h55555555;

      regmodel.eth_bd_mem.read(status,
                               addr,
                               rd_data);

      if (status != UVM_IS_OK)
        `uvm_error(get_type_name(),
                   $sformatf("Read failed at BD %0d", addr))

      if (rd_data[31:0] !== wr_data[31:0]) begin

        msg = $sformatf(
          "PASS1 FAILED Addr=%0d Exp=0x%08h Got=0x%08h",
          addr,
          wr_data[31:0],
          rd_data[31:0]);

        `uvm_error(get_type_name(), msg)

      end
    end

    //----------------------------------------------------------
    // PASS 2
    // Even -> 55555555
    // Odd  -> AAAAAAAA
    //----------------------------------------------------------
    `uvm_info(get_type_name(),
              "Starting Alternating Pattern Test - PASS 2",
              UVM_LOW)

    // Write
    for (addr = 0; addr < NUM_TX_BD; addr++) begin

      if (addr % 2 == 0)
        wr_data = 32'h55555555;
      else
        wr_data = 32'hAAAAAAAA;

      regmodel.eth_bd_mem.write(status,
                                addr,
                                wr_data);

      if (status != UVM_IS_OK)
        `uvm_error(get_type_name(),
                   $sformatf("Write failed at BD %0d", addr))
    end

    // Read & Verify
    for (addr = 0; addr < NUM_TX_BD; addr++) begin

      if (addr % 2 == 0)
        wr_data = 32'h55555555;
      else
        wr_data = 32'hAAAAAAAA;

      regmodel.eth_bd_mem.read(status,
                               addr,
                               rd_data);

      if (status != UVM_IS_OK)
        `uvm_error(get_type_name(),
                   $sformatf("Read failed at BD %0d", addr))

      if (rd_data[31:0] !== wr_data[31:0]) begin

        msg = $sformatf(
          "PASS2 FAILED Addr=%0d Exp=0x%08h Got=0x%08h",
          addr,
          wr_data[31:0],
          rd_data[31:0]);

        `uvm_error(get_type_name(), msg)

      end
    end

    `uvm_info(get_type_name(),
              "Alternating BD memory test PASSED",
              UVM_LOW)

  endtask

endclass