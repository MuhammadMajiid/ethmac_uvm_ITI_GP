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
  wire  mdio;      // Bidirectional Management Data Line

  // Internal driving logic for bidirectional handling
  logic mdio_out;
  logic mdio_en;

  assign mdio = mdio_en ? mdio_out : 1'bz;

  // Modport for the MAC (Design Under Test)
  modport mac (
    output mdc,
    inout  mdio
  );

  // Modport for the PHY (Your UVM Agent)
  modport phy (
    input mdc,
    inout mdio
  );

endinterface

`endif // MDIO_IF_SV
