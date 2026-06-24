
module top ();
    bit clk;
    initial begin
        clk = 0;
        forever begin
            #1 clk = ~clk;
        end
    end

    // Instantiate
    
    counter_if c_if(clk); // Instantiate the interface with the clock
    
    counter_tb TEST (c_if); 

    counter DUT(c_if.clk ,c_if.rst_n, c_if.load_n, c_if.up_down, c_if.ce, c_if.data_load,c_if.count_out, c_if.max_count, c_if.zero); 

    counter_mon monitor (c_if); 
    
    bind counter counter_sva sva_inst(c_if);
endmodule