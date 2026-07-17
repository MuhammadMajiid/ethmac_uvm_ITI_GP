//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_bd_mem_walk_seq.sv
// Author   : Nada
// Date     : 2026-07-15
//------------------------------------------------------------------------------
// Description:
//   Walking-1 / Walking-0 test for Ethernet Buffer Descriptor memory.
//==============================================================================

class eth_bd_mem_walk_seq extends uvm_reg_sequence;

  `uvm_object_utils(eth_bd_mem_walk_seq)

  uvm_status_e    status;
  uvm_reg_data_t  exp_data;
  uvm_reg_data_t  rd_data;

  string          msg;
  eth_reg_block   regmodel;

  localparam int NUM_TX_BD = 20;

  function new(string name = "eth_bd_mem_walk_seq");
    super.new(name);
  endfunction

  virtual task body();

    int addr;
    int i;

    if (regmodel == null)
      `uvm_fatal(get_type_name(), "Register model is NULL")

    // Configure number of TX descriptors
    regmodel.TX_BD_NUM.write(status, NUM_TX_BD);

    //----------------------------------------------------------
    // Walk through every TX BD
    //----------------------------------------------------------
    for (addr = 0; addr < NUM_TX_BD; addr++) begin

      `uvm_info(get_type_name(),
                $sformatf("Walking BD %0d", addr),
                UVM_MEDIUM)

      //--------------------------------------------------------
      // Walking-1
      //--------------------------------------------------------
      for (i = 0; i < 32; i++) begin

        exp_data = 32'h0000_0000;
        exp_data[i] = 1'b1;

        regmodel.eth_bd_mem.write(status, addr, exp_data);

        if (status != UVM_IS_OK)
          `uvm_error(get_type_name(),
                     $sformatf("WRITE failed at addr=%0d", addr))

        regmodel.eth_bd_mem.read(status, addr, rd_data);

        if (status != UVM_IS_OK)
          `uvm_error(get_type_name(),
                     $sformatf("READ failed at addr=%0d", addr))

        if (rd_data[31:0] !== exp_data[31:0]) begin
          msg = $sformatf(
            "Walk1 FAILED Addr=%0d Bit=%0d Exp=0x%08h Got=0x%08h",
            addr,
            i,
            exp_data[31:0],
            rd_data[31:0]);

          `uvm_error(get_type_name(), msg)
        end

      end

      //--------------------------------------------------------
      // Walking-0
      //--------------------------------------------------------
      for (i = 0; i < 32; i++) begin

        exp_data = 32'hFFFF_FFFF;
        exp_data[i] = 1'b0;

        regmodel.eth_bd_mem.write(status, addr, exp_data);

        if (status != UVM_IS_OK)
          `uvm_error(get_type_name(),
                     $sformatf("WRITE failed at addr=%0d", addr))

        regmodel.eth_bd_mem.read(status, addr, rd_data);

        if (status != UVM_IS_OK)
          `uvm_error(get_type_name(),
                     $sformatf("READ failed at addr=%0d", addr))

        if (rd_data[31:0] !== exp_data[31:0]) begin
          msg = $sformatf(
            "Walk0 FAILED Addr=%0d Bit=%0d Exp=0x%08h Got=0x%08h",
            addr,
            i,
            exp_data[31:0],
            rd_data[31:0]);

          `uvm_error(get_type_name(), msg)
        end

      end

    end

    `uvm_info(get_type_name(),
              "BD memory walking test completed successfully",
              UVM_LOW)

  endtask

endclass