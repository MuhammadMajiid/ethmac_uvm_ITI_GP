class eth_v_seq_tx extends eth_v_seq_base;
 `uvm_object_utils(eth_v_seq_tx)
 
    wb_m_seq_base   m_wb_m_seq_base;
    wb_s_seq_base   m_wb_s_seq_base;
    function new(string name ="eth_v_seq_tx");
        super.new(name);
        m_wb_s_seq_base = wb_s_seq_base::type_id::create("m_wb_s_seq_base");  
        m_wb_m_seq_base= wb_m_seq_base::type_id::create("m_wb_m_seq_base"); 
    endfunction

    virtual task body();

        super.body();    
        `uvm_info(get_type_name(), "Executing virtual sequence", UVM_LOW)

        // Start wb master seq in join_none as it runs on reactive agent
        fork : fork_v_seq_wr_rd
            m_wb_m_seq_base.start(m_wb_m_sqr);
        join_none;
        
        // Run wishbone slave sequence
        m_wb_s_seq_base.start(m_wb_s_sqr);

        `uvm_info(get_type_name(), "virtual sequence completed", UVM_LOW)

    endtask
endclass 