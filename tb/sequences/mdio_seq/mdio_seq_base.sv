`ifndef MDIO_SEQ_BASE_SV
`define MDIO_SEQ_BASE_SV

class mdio_seq_base extends uvm_sequence #(mdio_seq_item_base);
    `uvm_object_utils(mdio_seq_base)

    function new(string name = "mdio_seq_base");
        super.new(name);
    endfunction

    // Base pre_body/post_body hooks can go here if needed for objection handling
endclass
`endif