module counter_mon(counter_if.monitor c_if);
    initial begin
        forever begin
            
            if (c_if.rst_n == 0) begin
                $display("Reset is active, count_out should be 0");
            end else if (c_if.load_n == 0) begin
                $display("Load is active, count_out should be equal to data_load");
            end else if (c_if.ce == 1) begin
                if (c_if.up_down == 1) begin
                    $display("Counting up, count_out should increment");
                end else begin
                    $display("Counting down, count_out should decrement");
                end
            end else begin
                $display("Count is not enabled, count_out should remain the same");
            end
            @(posedge c_if.clk);

            $display("Time: %0t, load_n: %b, up_down: %b, ce: %b, data_load: %d", $time, c_if.load_n, c_if.up_down, c_if.ce, c_if.data_load);
            $display("count_out: %d, max_count: %b, zero: %b", c_if.count_out, c_if.max_count, c_if.zero);
            $display("--------------------------------------------------");
        end
    end
endmodule

