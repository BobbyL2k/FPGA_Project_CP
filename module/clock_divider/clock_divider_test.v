`include "clock_divider.v"

module clock_divider_test();

reg clk;
wire d_clk;
reg reset;

initial begin
    $dumpfile("dump.vcd");
    $dumpvars(3);

    reset = 0;
    #25
    reset = 1;
    #100
    reset = 0;
    
    #1000
    
    #100 $finish;
end

parameter PERIOD = 20;

always begin
    clk = 1'b0;
    #(PERIOD/2)
    clk = 1'b1;
    #(PERIOD/2);
end

clock_divider cd(
    .clock(clk),
    .d_clock(d_clk),
    .reset(reset)
);

endmodule // clock_divider_test