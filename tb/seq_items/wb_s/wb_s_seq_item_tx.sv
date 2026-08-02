//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_s_seq_item_tx.sv
// Author   : Wael
// Date     : 2026-07-13
//------------------------------------------------------------------------------
// Description:
// Base sequence item for Wishbone transactions.
//
// Provides a generic request/response transaction that can be reused by
// register, BD, interrupt, and Ethernet MAC test sequences.
//==============================================================================

`ifndef WB_S_SEQ_ITEM_TX_SV
`define WB_S_SEQ_ITEM_TX_SV


class wb_s_seq_item_tx #(
    parameter int WB_S_ADDR_WIDTH = 10,
    parameter int WB_DATA_WIDTH  = 32,
    parameter int WB_SEL_WIDTH    = 4
) extends wb_s_seq_item_base;

  `uvm_object_param_utils(wb_s_seq_item_tx#(WB_S_ADDR_WIDTH, WB_DATA_WIDTH,WB_SEL_WIDTH))
  //--------------------------------------------------------------------------
  // Packet Data
  //--------------------------------------------------------------------------
  rand bit [WB_DATA_WIDTH-1:0] pkt_data;
  //--------------------------------------------------------------------------
  // MODER register fields
  //--------------------------------------------------------------------------
  rand bit moder_pad;
  rand bit moder_fd;
  rand bit moder_hugen;
  rand bit moder_crc;
  rand bit moder_dcrc;
  rand bit moder_exdf;
  rand bit moder_nobackoff;
  rand bit moder_nopre;
  randc bit [7:0] moder;
  //--------------------------------------------------------------------------
  // INT_MASK register fields
  //--------------------------------------------------------------------------
  rand bit mask_txb;
  rand bit mask_txc;
  rand bit mask_txe;
  //--------------------------------------------------------------------------
  // IPGT, IPGR1 and IPGR2 register fields
  //--------------------------------------------------------------------------
  rand bit [6:0] ipgt;
  rand bit [6:0] ipgr1;
  rand bit [6:0] ipgr2;
  //--------------------------------------------------------------------------
  // minfl & maxfl register fields
  //--------------------------------------------------------------------------
  rand bit [15:0] minfl;
  rand bit [15:0] maxfl;
  //--------------------------------------------------------------------------
  // macaddr0 & macaddr1 register fields
  //--------------------------------------------------------------------------
  rand bit [15:0] mac_addr1;
  rand bit [31:0] mac_addr0;
  //--------------------------------------------------------------------------
  // maxretry & collv register fields
  //--------------------------------------------------------------------------
  rand bit [3:0] maxretry;
  rand bit [5:0] collv;
  //--------------------------------------------------------------------------
  // tx bd num register field
  //--------------------------------------------------------------------------
  rand bit [7:0] tx_bd_num;
  rand bit [7:0] rand_tx_bd_idx;
  //--------------------------------------------------------------------------
  // pause control frame related register fields
  //--------------------------------------------------------------------------
  rand bit        tx_flow;
  rand bit        pause_req;
  rand bit [15:0] pause_timer;
  //--------------------------------------------------------------------------
  // bd fields in arrray
  //--------------------------------------------------------------------------
  rand bit [31:0] tx_pnt     [];
  rand bit [15:0] pkt_len    [];
  rand bit        bd_crc     [];
  rand bit        bd_pad     [];
  //--------------------------------------------------------------------------
  // Constraints
  //--------------------------------------------------------------------------
  constraint c_tx_bd_num{tx_bd_num inside {['h00:'h80]};}

  constraint c_tx_pnt_len
  {
    tx_pnt.size() == tx_bd_num;
    pkt_len.size() == tx_bd_num;
    foreach (tx_pnt[i]) {
      soft tx_pnt[i]%4==0;
      if(i!=tx_bd_num-1)
        tx_pnt[i]+pkt_len[i]<=tx_pnt[i+1];
    }
  }
  constraint c_bd_crc_pad{
      bd_crc.size() == tx_bd_num;
      bd_pad.size() == tx_bd_num;
  }

  constraint c_minfl_maxfl{
    minfl<maxfl;
  }
constraint c_rand_bd_index{
  rand_tx_bd_idx inside{[0:tx_bd_num]};
}

constraint c_solve_order {
    solve tx_bd_num before tx_pnt, pkt_len, bd_crc, bd_pad,rand_tx_bd_idx;
}
  //--------------------------------------------------------------------------
  // Constructor
  //--------------------------------------------------------------------------
  function new(string name = "wb_s_seq_item_tx");
    super.new(name);
  endfunction


endclass

`endif // WB_S_SEQ_ITEM_TX_SV