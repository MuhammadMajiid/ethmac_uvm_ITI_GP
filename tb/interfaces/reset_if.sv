//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : reset_if.sv
// Author   : Nada
// Date     : 2026-07-16
//------------------------------------------------------------------------------
// Description:
// Reset interface used between the UVM testbench and the DUT.
// Provides the reset signal and associated clock required by the
// reset agent to drive hardware resets through a dedicated interface.
//==============================================================================

interface reset_if(input logic clk);

  logic rst = 1'b0; // Active high reset signal, initially de-asserted

endinterface