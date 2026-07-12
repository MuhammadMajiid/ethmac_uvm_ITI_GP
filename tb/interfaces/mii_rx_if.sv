`ifndef MII_RX_IF_SV
`define MII_RX_IF_SV

interface mii_rx_if;

  logic        MRxClk;
  logic        MRxDV;
  logic        MRxErr;
  logic [3:0]  MRxD;


endinterface

`endif