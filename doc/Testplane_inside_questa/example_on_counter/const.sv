package count_pkt;
    parameter WIDTH = 4;
    class count_class;
        bit clk;
        rand bit rst_n;
        rand bit load_n;
        rand bit ce;
        rand bit up_down;
        rand bit [WIDTH-1 :0] data_load;
        bit [WIDTH-1 :0] count_out;
        //Reset
        constraint c_reset {rst_n dist {0:=10 , 1:=90};}
        //counter_1
        constraint c_load {load_n dist {0:=30 , 1:=70};}
        //counter_2 //counter_3
        constraint c_en {ce dist {0:=30 , 1:=70};}
        covergroup check_notes ;
            load_cp: coverpoint data_load iff(!load_n && rst_n);
            cp_increment: coverpoint count_out iff(rst_n && ce && up_down);
            cp_max_to_zero: coverpoint count_out iff(rst_n && ce && up_down) {bins count_out = ((2**WIDTH)-1 => 0);}

            cp_decrement: coverpoint count_out iff(rst_n && ce && !up_down);
            cp_zero_to_max: coverpoint count_out iff(rst_n && ce && !up_down){bins count_out = (0 => (2**WIDTH)-1);}                             
        endgroup
        function new();
            check_notes = new();  
        endfunction
    endclass 
endpackage