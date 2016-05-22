module uart_receiver_test();

  reg clk;
  reg rx, reset, clear_ready;

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

  parameter PERIOD = 10;

  always begin
    clk = 1'b0;
    #(PERIOD/2)
    clk = 1'b1;
    #(PERIOD/2);
  end

endmodule // uart_receiver_test