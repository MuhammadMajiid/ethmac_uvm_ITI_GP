//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : dma_mem.sv
// Author   : Wael
// Date     : 2026-06-30
//------------------------------------------------------------------------------
// Description:
//   Memory model represents the external memory that the DUT write to it during
//   Reception or reads from it during transmission.
//==============================================================================
`ifndef DMA_MEM_SV
`define DMA_MEM_SV
class dma_mem extends uvm_object;
  `uvm_object_utils(dma_mem)

  // Associative array holding memory elements
  local bit [31:0] dma_mem [int unsigned];

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
  function bit write(int unsigned addr,bit [31:0] data);
    if (addr % 4 != 0) begin
      `uvm_error(get_name(),$sformatf("Can't write in memory, address %0d is not divisible by 4",addr))
      return 0;
    end

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
  function bit read(int unsigned addr,ref bit [31:0] data);
    if (!dma_mem.exists(addr)) begin
      `uvm_error(get_name(),$sformatf("Can't read from memory, address %0d doesn't exist",addr))
      return 0;
    end

    if (addr % 4 != 0) begin
      `uvm_error(get_name(),$sformatf("Can't write in memory, address %0d is not divisible by 4",addr))
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
  function bit addr_exists(int unsigned addr);
    return dma_mem.exists(addr);
  endfunction

endclass

`endif // DMA_MEM_SV