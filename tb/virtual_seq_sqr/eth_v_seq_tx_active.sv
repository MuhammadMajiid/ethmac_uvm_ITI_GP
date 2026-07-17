class eth_v_seq_tx_active extends eth_v_seq_tx;
 `uvm_object_utils(eth_v_seq_tx_active)
    mii_tx_seq_base m_mii_tx_seq_base;
    function new(string name ="eth_v_seq_tx_active");
        super.new(name);
        m_mii_tx_seq_base= mii_tx_seq_base::type_id::create("m_mii_tx_seq_base"); 
    endfunction

    virtual task body();
        `uvm_info(get_type_name(), "Executing virtual sequence", UVM_LOW)


        fork : fork_v_tx
       forever     m_mii_tx_seq_base.start(m_mii_tx_sqr);
        join_none;

        super.body();

        `uvm_info(get_type_name(), "virtual sequence completed", UVM_LOW)

    endtask
endclass 