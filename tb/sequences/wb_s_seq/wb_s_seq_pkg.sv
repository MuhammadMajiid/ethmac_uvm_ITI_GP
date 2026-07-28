//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_m_seq_pkg.sv
// Author   : Nada
// Date     : 2026-06-26
//------------------------------------------------------------------------------
// Description:
//   Package for including wisbone master sequences.
//==============================================================================
`timescale 1ns/1ps

`ifndef WB_S_SEQ_PKG_SV
`define WB_S_SEQ_PKG_SV

package wb_s_seq_pkg;
    `include "uvm_macros.svh"
    import uvm_pkg::*;

    // Global package
    import eth_glob_pkg::*;
    // Transaction object package
    import wb_s_seq_item_pkg::*;
    
    // RAL package
    import eth_ral_pkg::*;

    // Sequences
    `include "wb_s_seq_base.sv"
    `include "wb_s_basic_tx_seq.sv"
    `include "wb_s_seq_tx_no_pre.sv"
    `include "wb_s_seq_tx_hugen.sv"
    `include "wb_s_seq_tx_dcrc.sv"
    `include "wb_s_seq_tx_moder.sv"
    `include "wb_s_seq_tx_pad.sv"
	`include "wb_s_seq_tx_minfl.sv"
    `include "wb_s_seq_tx_maxfl.sv"
    `include "wb_s_seq_tx_bd_num.sv"
    `include "wb_s_seq_tx_ipgt.sv"
    `include "wb_s_seq_tx_underrun.sv"
    `include "wb_s_seq_tx_interrupts.sv"
	`include "wb_s_seq_tx_collision_cfg.sv"
    `include "wb_s_seq_tx_cs.sv"
    `include "wb_s_seq_tx_ctrl_flow.sv"
    `include "wb_s_seq_tx_len.sv"
    `include "wb_s_seq_tx_df.sv"
    `include "eth_tx_bd_num_bit_bash_seq.sv"
	`include "eth_max_value_seq.sv"
	`include "eth_rw_pattern_seq.sv"
	`include "eth_bd_mem_walk_seq.sv"
	`include "eth_bd_mem_alternating_seq.sv"
	`include "eth_bd_wr_seq.sv"


    
   

	
endpackage : wb_s_seq_pkg

`endif // WB_S_SEQ_PKG_SV
