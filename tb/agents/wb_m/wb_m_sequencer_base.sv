
`ifndef WB_M_SEQUENCER_BASE_SV
`define WB_M_SEQUENCER_BASE_SV

class wb_m_sequencer_base extends uvm_sequencer #(wb_master_tx);

    `uvm_component_utils(wb_m_sequencer_base)

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction

endclass : wb_m_sequencer_base

`endif // WB_M_SEQUENCER_BASE_SV
