`include "single_pulser.v"

module single_pulser_test();

reg signal_in;
wire signal_out;
reg reset;
reg clk;

initial begin
    $dumpfile("dump.vcd");
    $dumpvars(3);

    reset = 0;
    signal_in = 0;
    #25
    reset = 1;
    #56
    reset = 0;
    #37
    signal_in = 1;
    #200
    signal_in = 0;
    #100
    signal_in = 1;
    #300
    signal_in = 0;
    #100
    signal_in = 1;
    #500
    signal_in = 0;
    #100
    signal_in = 1;
    #100
    signal_in = 0;
    #100
    
    #100 $finish;
end

parameter PERIOD = 20;

always begin
    clk = 1'b0;
    #(PERIOD/2)
    clk = 1'b1;
    #(PERIOD/2);
end

single_pulser sp(
  .signal_in(signal_in),
  .signal_out(signal_out),
  .clk(clk),
  .reset(reset));

endmodule // single_pulser_test