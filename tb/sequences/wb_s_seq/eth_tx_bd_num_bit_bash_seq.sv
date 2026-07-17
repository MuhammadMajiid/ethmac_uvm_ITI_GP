//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_tx_bd_num_bit_bash_seq.sv
// Author   : Nada
// Date     : 2026-07-14
//------------------------------------------------------------------------------
// Description:
// the bit_bash_seq for tx_bd_num register 
//==============================================================================
class eth_tx_bd_num_bit_bash_seq extends uvm_reg_sequence;

  `uvm_object_utils(eth_tx_bd_num_bit_bash_seq)

  function new(string name="eth_tx_bd_num_bit_bash_seq");
    super.new(name);
  endfunction


virtual task body();

    uvm_status_e status;
    uvm_reg_data_t data;

    eth_reg_block regmodel;
    uvm_reg tx_bd_num;
    uvm_reg_map map;


    if (!$cast(regmodel, model)) begin
      `uvm_fatal("RAL_CAST",
        "Cannot cast model to eth_reg_block")
    end


    tx_bd_num = regmodel.TX_BD_NUM;

    map = regmodel.default_map;


for (int bit_idx = 0; bit_idx < 8; bit_idx++) begin

    uvm_reg_data_t write_data;

    write_data = (1 << bit_idx);

    //---------------------------------
    // Write bit = 1
    //---------------------------------
    tx_bd_num.write(
        status,
        write_data,
        UVM_FRONTDOOR,
        map,
        this
    );


    //---------------------------------
    // Read and check
    //---------------------------------
    tx_bd_num.read(
        status,
        data,
        UVM_FRONTDOOR,
        map,
        this
    );

    if (data != write_data) begin
        `uvm_error("TX_BD_NUM",
          $sformatf(
          "Bit %0d failed: wrote 0x%0h read 0x%0h",
          bit_idx,
          write_data,
          data))
    end


    //---------------------------------
    // Return to zero
    //---------------------------------
    tx_bd_num.write(
        status,
        0,
        UVM_FRONTDOOR,
        map,
        this
    );
	
	  //---------------------------------
    // Read and check
    //---------------------------------
    tx_bd_num.read(
        status,
        data,
        UVM_FRONTDOOR,
        map,
        this
    );

    if (data != 0) begin
        `uvm_error("TX_BD_NUM",
          $sformatf(
          "Bit %0d failed: wrote 0x%0h read 0x%0h",
          bit_idx,
          write_data,
          data))
    end


end

endtask

endclass