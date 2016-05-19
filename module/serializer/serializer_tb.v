module serializer_tb();

    parameter DATA_WIDTH = 8;

    wire busy;
    wire data_out;
    reg [DATA_WIDTH-1:0] data_in;
    reg start;
    reg clock;
    serializer s(busy,data_out,data_in,start,clock);

    initial begin
        start = 0;
        clock = 0;
        data_in = 8'b1001_1110;
        $dumpfile("dump.vcd");
        #50 start = 1;
        #50 start = 0;
    end

    always
        #50 clock = ~clock;

endmodule
