//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_tx_cov.sv
// Author   : Wael,Nada
// Date     : 2026-06-30
//------------------------------------------------------------------------------
// Description:
//   Ethernet coverage model contains all covergroups related to TX.
//==============================================================================
`ifndef ETH_TX_COV_SV
`define ETH_TX_COV_SV

class eth_tx_cov extends uvm_component;
    `uvm_component_utils(eth_tx_cov)

    // =========================================================================
    // Analysis fifos for wishbone master ,wishbone master, MII TX
    // =========================================================================
    uvm_tlm_analysis_fifo  #(wb_m_seq_item_base)        wb_m_fifo;
    uvm_tlm_analysis_fifo  #(wb_s_seq_item_base)        wb_s_fifo;
    uvm_tlm_analysis_fifo  #(mii_tx_seq_item_base)      mii_tx_fifo;
    // =========================================================================
    // Analysis exports for wishbone master ,wishbone master, MII TX
    // =========================================================================
    uvm_analysis_export  #(wb_m_seq_item_base)        wb_m_a_export;
    uvm_analysis_export  #(wb_s_seq_item_base)        wb_s_a_export;
    uvm_analysis_export  #(mii_tx_seq_item_base)      mii_tx_a_export;
    // =========================================================================
    // Transactions for storing last item pulled from tlm fifo
    // =========================================================================
    wb_m_seq_item_base                              m_wb_m_seq_item;
    wb_s_seq_item_base                              m_wb_s_seq_item;
    mii_tx_seq_item_base                            m_mii_tx_seq_item;
    /*// =========================================================================
    // Virtual interfaces
    // =========================================================================
    virtual wb_s_if     wb_s_vif;
    virtual wb_m_if     wb_m_vif;
    virtual mii_tx_if   mii_tx_vif;*/
    // =========================================================================
    // Constructor, Build Phase, Connect phase and Run phase
    // =========================================================================
    extern function new(string name, uvm_component parent);
    extern function void build_phase(uvm_phase phase);
    extern function void connect_phase(uvm_phase phase);
    extern task run_phase(uvm_phase phase);


endclass    


// =============================================================================
//  IMPLEMENTATION
// =============================================================================

function eth_tx_cov::new(string name, uvm_component parent);
    super.new(name, parent);
endfunction


function void eth_tx_cov::build_phase(uvm_phase phase);
    super.build_phase(phase);
    // Build fifos
    wb_m_fifo     = new("wb_m_fifo",this);
    wb_s_fifo     = new("wb_s_fifo",this);
    mii_tx_fifo   = new("mii_tx_fifo",this);
    // Build analysis exports
    wb_m_a_export   = new("wb_m_export",this);
    wb_s_a_export   = new("wb_s_export",this);
    mii_tx_a_export = new("mii_tx_export",this);
endfunction

function void eth_tx_cov::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    // Connect each export with it's corrosponding fifo
    wb_m_a_export.connect(wb_m_fifo.analysis_export);
    wb_m_a_export.connect(wb_m_fifo.analysis_export);
    mii_tx_a_export.connect(mii_tx_fifo.analysis_export);
endfunction 

task eth_tx_cov::run_phase(uvm_phase phase);
endtask

`endif // ETH_TX_COV_SV