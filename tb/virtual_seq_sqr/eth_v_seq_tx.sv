class eth_v_seq_tx extends eth_v_seq_base;
 `uvm_object_utils(eth_v_seq_tx)
 
    wb_m_seq_base   m_wb_m_seq_base;
    wb_s_seq_base   m_wb_s_seq_base;
    reset_seq       m_reset_seq;
    function new(string name ="eth_v_seq_tx");
        super.new(name);
        m_wb_m_seq_base= wb_m_seq_base::type_id::create("m_wb_m_seq_base"); 
        m_reset_seq = reset_seq::type_id::create("m_reset_seq");
        m_wb_s_seq_base = wb_s_seq_base::type_id::create("m_wb_s_seq_base"); 
    endfunction
	
	
	virtual task body();
        int seq_num;
        super.body();
        `uvm_info(get_type_name(), "Executing virtual sequence", UVM_LOW)
        // Reset before everything
        m_reset_seq.start(m_reset_sqr);
        // Start wb master seq in join_none as it runs on reactive agent
        fork
            m_wb_m_seq_base.start(m_wb_m_sqr);
        join_none

        // Get number of running sequences from vsim command
        if (!$value$plusargs("seq_num=%0d", seq_num))
            seq_num = 1;

        `uvm_info(get_name(), $sformatf("Running %0d sequence",seq_num), UVM_LOW)
        
        // Run wishbone slave sequence
        for (int i=0; i<seq_num; i++) begin
            `uvm_info(get_name(), $sformatf("Running sequence number %0d",i), UVM_LOW)
            m_wb_s_seq_base.start(m_wb_s_sqr);
               // Reset only if another iteration follows
           if (i != seq_num-1)
          m_reset_seq.start(m_reset_sqr);
        end  
        
        `uvm_info(get_type_name(), "virtual sequence completed", UVM_LOW)

    endtask

    
endclass 