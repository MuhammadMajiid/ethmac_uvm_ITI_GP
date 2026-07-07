class eth_v_seq_tx extends eth_v_seq_base;
 `uvm_object_utils(eth_v_seq_tx)
 
    wb_m_seq_wr_rd m_wb_m_seq_wr_rd;
    wb_s_basic_tx_seq m_wb_s_basic_tx_seq;

    function new(string name ="eth_v_seq_tx");
        super.new(name);
        m_wb_s_basic_tx_seq = wb_s_basic_tx_seq::type_id::create("wb_s_basic_tx_seq");  
        m_wb_m_seq_wr_rd= wb_m_seq_wr_rd::type_id::create("m_wb_m_seq_wr_rd"); 
    endfunction

    virtual task body();

        super.body();    
        `uvm_info(get_type_name(), "Executing virtual sequence", UVM_HIGH)

        // Start wb master seq in join_none as it runs on reactive agent
        fork : fork_v_seq_wr_rd
            m_wb_m_seq_wr_rd.start(m_wb_m_sqr);
        join_none;
            
        // Run wishbone slave sequence
        m_wb_s_basic_tx_seq.start(m_wb_s_sqr);

        `uvm_info(get_type_name(), "virtual sequence completed", UVM_HIGH)

    endtask
endclass 