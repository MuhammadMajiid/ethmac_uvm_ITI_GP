module counter_sva (); // SVA module for the counter interface

    //Reset
    always_comb begin 
        if(!c_if.rst_n) begin
            assert_reset: assert final(c_if.count_out == 0 && c_if.max_count== 0 && c_if.zero == 1'b1); // Assert reset condition
            cover_reset : cover final(c_if.count_out == 0 && c_if.max_count== 0 && c_if.zero == 1'b1); // Cover reset condition
        end
    end 
    always_comb begin 
        if((c_if.count_out == 2**c_if.WIDTH - 1'b1))begin
            assert_max_count: assert final (c_if.max_count == 1'b1);
            cover_max_count: cover final (c_if.max_count == 1'b1);
        end   
        if (c_if.count_out == 0) begin
            assert_zero: assert final (c_if.zero == 1'b1);
            cover_zero: cover final (c_if.zero == 1'b1);
        end
    end
        //Counter_1
    property active_load;
        @(posedge c_if.clk) disable iff (!c_if.rst_n)
        (!c_if.load_n) |=> (c_if.count_out == $past(c_if.data_load));
    endproperty
        //Counter_4
    property not_change;
        @(posedge c_if.clk) disable iff (!c_if.rst_n)
        (c_if.load_n && !c_if.ce) |=> ($stable(c_if.count_out));
    endproperty
        //Counter_2
    property count_up;
        @(posedge c_if.clk) disable iff (!c_if.rst_n)
        (c_if.load_n && c_if.ce && c_if.up_down) |=> (c_if.count_out == $past(c_if.count_out) + 1'b1);
    endproperty
    //Counter_3
    property count_down;
        @(posedge c_if.clk) disable iff (!c_if.rst_n)
        (c_if.ce && c_if.load_n && !c_if.up_down) |=> (c_if.count_out == $past(c_if.count_out) - 1'b1);
    endproperty

    p_active_load :assert property (active_load);
    p_not_change  :assert property (not_change);
    p_count_up    :assert property (count_up);
    p_count_down  :assert property (count_down);
    
    c_active_load : cover property (active_load); // Cover property for active load
    c_not_change  : cover property (not_change); // Cover property for not change
    c_count_up    : cover property (count_up); // Cover property for count up
    c_count_down  : cover property (count_down); // Cover property for count down
    
endmodule