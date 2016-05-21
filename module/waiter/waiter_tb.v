module waiter_tb();

    parameter COUNTER_SIZE = 8;


    reg clock;
    reg start;
    reg reset;
    reg [COUNTER_SIZE-1:0] count_to;

    Waiter waiter(busy,start,count_to,clock,reset);

    initial begin
        clock = 0;
        start = 0;
        reset = 0;
        $dumpfile("dump.vcd");
        $dumpvars;
        count_to = 10;
        #50 reset = 1;
        #50 reset = 0;
        #50 start = 1;
        #50 start = 0;
        #1000 $finish;
    end

    always
        #10 clock = ~clock;

endmodule
