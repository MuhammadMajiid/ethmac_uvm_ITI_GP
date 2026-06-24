import count_pkt::*;
module counter_tb (counter_if.TEST c_if);
    count_class count_obj = new();
    initial begin  
        c_if.rst_n = 0;
        c_if.load_n = 0;
        c_if.ce = 0;
        c_if.up_down = 0;
        c_if.data_load = 0;

        @(posedge c_if.clk);
        c_if.rst_n = 1;
        repeat(1000) begin
            assert (count_obj.randomize());
            c_if.rst_n = count_obj.rst_n;
            c_if.load_n = count_obj.load_n;
            c_if.ce = count_obj.ce;
            c_if.up_down = count_obj.up_down;
            c_if.data_load = count_obj.data_load;
            count_obj.count_out = c_if.count_out;
            @(negedge c_if.clk);
            count_obj.check_notes.sample();
        end
        @(posedge c_if.clk);
        c_if.rst_n = 0;
        $stop;    
    end 
endmodule