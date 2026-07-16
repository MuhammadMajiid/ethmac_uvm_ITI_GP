//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : mem_model.sv
// Author   : Wael
// Date     : 2026-06-30
//------------------------------------------------------------------------------
// Description:
//   Contains 2 classes represent  2 memory models, the first represents the
//   external memory that the DUT write to it during Reception or reads from it
//   during transmission. the second models buffer descriptors in the DUT.
//   
//==============================================================================
`ifndef MEM_MODEL_SV
`define MEM_MODEL_SV

class dma_mem extends uvm_object;
  `uvm_object_utils(dma_mem)

  // Associative array holding tx&rx data memory elements
  static local bit [WB_DATA_WIDTH-1:0] dma_mem [int unsigned];

  function new(string name = "dma_mem");
    super.new(name);
  endfunction
  // -------------------------------------------------------------------------
  //  function : write
  // -------------------------------------------------------------------------
  // Description:
  //  Write data to memory if it's width is 4 bytes because it's the word 
  //  length of both the memory and wishbone bus.
  //
  // Arguments: 
  //  addr: Memory Address
  //  data  Data written to memory
  //  
  // Return: 
  //  1: Data is written successfully
  //  0: Data isn't written due to byte alignment error.
  // -------------------------------------------------------------------------
  static function bit write(int unsigned addr,bit [WB_DATA_WIDTH-1:0] data);
    if (addr % 4 != 0) begin
      `uvm_error_context("DMA_ERROR",$sformatf("Can't write in memory, address %0h is not divisible by 4",addr),uvm_root::get());
      return 0;
    end

      // if addr isn't divisible by 4, round to the nearest lower address divisble by 4
      addr=(addr%4==0)?addr:addr-addr%4;

    dma_mem[addr] = data;
    return 1;
  endfunction

  // -------------------------------------------------------------------------
  //  function : read
  // -------------------------------------------------------------------------
  // Description:
  //  Read data from memory if the address exists and if the data width is 4
  //  bytes because it's the word length of both the memory and wishbone bus.
  //
  // Arguments: 
  //  addr: Memory Address
  //  data  reference to the desired data to be read 
  //  
  // Return: 
  //  1: Data is read successfully
  //  0: Data isn't written due to address existance or byte alignment errors.
  // -------------------------------------------------------------------------
  static function bit read(int unsigned addr,ref bit [WB_DATA_WIDTH-1:0] data);
    if (!dma_mem.exists(addr)) begin
      `uvm_error_context("DMA_ERROR",$sformatf("Can't read from memory, address %0h doesn't exist",addr),uvm_root::get());
      return 0;
    end

    data = dma_mem[addr];
    return 1;
  endfunction
  // -------------------------------------------------------------------------
  //  function : addr_exists
  // -------------------------------------------------------------------------
  // Description:
  //  Check if the address exists in memory or not.
  //
  // Arguments: 
  //  addr: Memory Address
  //  
  // Return: 
  //  1: Address exists
  //  0: Address doesn't exist.
  // -------------------------------------------------------------------------
  static function bit addr_exists(int unsigned addr);
    return dma_mem.exists(addr);
  endfunction

  static function print();
    $display("Dma memory contents: %0p",dma_mem);
  endfunction

endclass


class bd_mem extends uvm_object;
  `uvm_object_utils(bd_mem)

  // Memory array holding BD data memory elements
  static local bit [WB_DATA_WIDTH-1:0] bd_mem [WB_BD_MEM_DEPTH];

  function new(string name = "bd_mem");
    super.new(name);
  endfunction
  // -------------------------------------------------------------------------
  //  function : write
  // -------------------------------------------------------------------------
  // Description:
  //  Write data to memory.
  //
  // Arguments: 
  //  addr: Memory Address
  //  data  Data written to memory
  //  
  // -------------------------------------------------------------------------
  static function void write(bit [$clog2(WB_BD_MEM_DEPTH)-1:0] addr,bit [WB_DATA_WIDTH-1:0] data);
    bd_mem[addr] = data;
  endfunction
  // -------------------------------------------------------------------------
  //  function : read
  // -------------------------------------------------------------------------
  // Description:
  //  Read data from memory.
  //
  // Arguments: 
  //  addr: Memory Address
  //  data  reference to the desired data to be read 
  //  
  // -------------------------------------------------------------------------
  static function bit [WB_DATA_WIDTH-1:0] read(bit [$clog2(WB_BD_MEM_DEPTH)-1:0] addr);
    return(bd_mem[addr]);
  endfunction

endclass


`endif // MEM_MODEL_SV