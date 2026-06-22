
`ifndef WB_M_SEQUENCER_SV
`define WB_M_SEQUENCER_SV

class wb_m_sequencer extends uvm_sequencer #(wb_master_tx);

    `uvm_component_utils(wb_m_sequencer)

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction

endclass : wb_m_sequencer

`endif // WB_M_SEQUENCER_SV
