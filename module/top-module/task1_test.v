`include "task1.v"

module task1_test(
);

  reg clk, rx, reset;
  wire tx;

  task1 t1(
    .clk(clk),
    .rx(rx),
    .tx(tx),
    .reset(reset)
  );
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(3);
    
    reset = 0;
    rx = 0;
    #100
    reset = 1;
    rx = 1;
    #100
    reset = 0;
    #100
    
    #10000 $finish;
  end

  parameter PERIOD = 20;
  
  always begin
    clk = 1'b0;
    #(PERIOD/2)
    clk = 1'b1;
    #(PERIOD/2);
  end

endmodule // task1_test