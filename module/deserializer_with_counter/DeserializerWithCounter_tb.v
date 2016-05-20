module DeserializerWithCounter_tb();

    parameter DATA_LENGTH = 16;
    parameter WORD_SIZE = 8;

    wire [WORD_SIZE-1 : 0]data_out;
    wire busy;
    wire RCO;

    reg start;
    reg data_in;
    reg clock;
    reg reset;

    DeserializerWithCounter deserializerWithCounter(data_out,busy,RCO,start,data_in,clock,reset);

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;
        start = 0;
        data_in = 1;
        clock = 0;
        reset = 0;
        #20 reset = 1;
        #20 reset = 0;
        #20 start = 1;
        #20 start = 0;
        #40 data_in = 0;
        #20 data_in = 1;
        #20 data_in = 0;
        #20 data_in = 0;
        #20 data_in = 0;
        #20 data_in = 1;
        #20 data_in = 0;
        #20 data_in = 1;
        #20 data_in = 0;//01010001 51
        #20 data_in = 1;
        #20 data_in = 0;
        #20 data_in = 0;
        #20 data_in = 0;
        #20 data_in = 1;
        #20 data_in = 1;
        #20 data_in = 0;
        #20 data_in = 1;//10110001 B1
        #200 $finish;
    end

    always
        #10 clock = !clock;

endmodule
