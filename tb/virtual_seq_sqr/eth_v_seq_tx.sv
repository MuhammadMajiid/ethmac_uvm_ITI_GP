class eth_v_seq_tx extends eth_v_seq_base;
 `uvm_object_utils(eth_v_seq_tx)
 
 function new(string name);
    super.new(name);
 endfunction

 virtual task body();
    wb_m_seq_wr_rd m_wb_m_seq_wr_rd= wb_m_seq_wr_rd::create("m_wb_m_seq_wr_rd");
    super.body();
    
    `uvm_info(get_type_name(), "Executing virtual sequence", UVM_HIGH)
    // Start wb master seq in join_none as it runs on reactive agent
    fork : fork_v_seq_wr_rd
        m_wb_m_seq_wr_rd.start(m_wb_m_sqr);
    join_none;
        
    // Run wishbone slave sequence

    `uvm_info(get_type_name(), "virtual sequence completed", UVM_HIGH)
 endtask
endclass 