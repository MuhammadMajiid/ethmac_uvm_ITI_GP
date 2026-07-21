`ifndef ETH_V_SEQ_TX_COLLISION_SV
`define ETH_V_SEQ_TX_COLLISION_SV

class eth_v_seq_tx_collision extends eth_v_seq_tx;

    `uvm_object_utils(eth_v_seq_tx_collision)

    mii_tx_seq_collision m_mii_tx_seq_collision;

    function new(string name = "eth_v_seq_tx_collision");
        super.new(name);
        m_mii_tx_seq_collision =
            mii_tx_seq_collision::type_id::create("m_mii_tx_seq_collision");
    endfunction

    virtual task body();
        int coll_num;

        `uvm_info(get_type_name(), "Executing collision virtual sequence", UVM_LOW)

        if (!$value$plusargs("coll_num=%0d", coll_num))
            coll_num = 1;

        // Run the collision sequence coll_num times
        fork : fork_mii
            repeat (coll_num)
                m_mii_tx_seq_collision.start(m_mii_tx_sqr);
        join_none

        // Run the normal TX virtual sequence
        super.body();

        disable fork_mii;
		

        `uvm_info(get_type_name(), "Collision virtual sequence completed", UVM_LOW)

    endtask

endclass

`endif