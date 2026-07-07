//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_v_seq.sv
// Author   : Wael
// Date     : 2026-07-06
//------------------------------------------------------------------------------
// Description:
//   Base virtual sequence declare p_sequencer and assign each sequencer handle
//   to it's corresponding in virtual sequencer.
//==============================================================================
`ifndef ETH_V_SEQ_BASE_SV
`define ETH_V_SEQ_BASE_SV
    class eth_v_seq_base extends uvm_sequence;
    `uvm_object_utils(eth_v_seq_base)
    `uvm_declare_p_sequencer(eth_v_sequencer)

    wb_m_sequencer_base m_wb_m_sqr;
    wb_s_sequencer_base m_wb_s_sqr;
    mii_tx_sequencer_base m_mii_tx_sqr;

    function new(string name ="eth_v_seq_base");
    super.new(name);
    endfunction

    virtual task body();
    m_wb_m_sqr   = p_sequencer.m_wb_m_sqr;
    m_wb_s_sqr   = p_sequencer.m_wb_s_sqr;
    m_mii_tx_sqr = p_sequencer.m_mii_tx_sqr;
    
    endtask
    endclass
`endif