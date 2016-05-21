module serializer_tb();

    parameter DATA_WIDTH = 8;

    wire busy;
    wire data_out;
    reg [DATA_WIDTH-1:0] data_in;
    reg start;
    reg clock;
    reg reset;
    serializer s(busy,data_out,data_in,start,clock,reset);

    initial begin
        start = 0;
        clock = 0;
        data_in = 8'b1001_1110;

        $dumpfile("dump.vcd");
        $dumpvars(3);
        #50 reset = 1;
        #100 reset = 0;
        #50 start = 1;
        #100 start = 0;
        #5000 $finish;
    end

    always
        #50 clock = ~clock;

endmodule
