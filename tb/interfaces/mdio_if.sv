//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : mdio_if.sv
// Author   : Muhammad Majid
// Date     : 2026-06-26
//------------------------------------------------------------------------------
// Description:
//   Physical interface mapping the MDC and MDIO management pins.
//==============================================================================

`ifndef MDIO_IF_SV
`define MDIO_IF_SV

interface mdio_if;
  logic mdc;       // Management Data Clock (Driven by DUT)
  bit mdio_in;      // Bidirectional Management Data Line

  logic mdio_out;
  logic mdio_en;


endinterface

`endif // MDIO_IF_SV
