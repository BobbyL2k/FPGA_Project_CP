`include "uart.v"

module uart_receiver_test();

  reg clk;
  reg rx, reset, clear_ready;
  wire ready;
  wire [7:0] data;

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(3);

    reset = 0;
    rx = 0;
    clear_ready = 0;
    #25
    reset = 1;
    rx = 1;
    #56
    reset = 0;
    #37
    
    rx = 1;
    #100
    rx = 0; // start bit
    #100
    rx = 1; // data bit 1
    #100
    rx = 0; // data bit 2
    #100
    rx = 1; // data bit 3
    #100
    rx = 0; // data bit 4
    #100
    rx = 1; // data bit 5
    #100
    rx = 0; // data bit 6
    #100
    rx = 1; // data bit 7
    #100
    rx = 0; // data bit 8
    #100
    rx = 0; // parity bit
    #100
    rx = 1; // stop bit
    
    #100 $finish;
  end
  
  uart_receiver #(
    .FULL_buad(9),
    .HALF_buad(3)) 
    uartr(
      .i_clk(clk),
      .i_rx(rx),
      .i_reset(reset),
      .o_8_data(data),
      .o_ready(ready),
      .i_clear_ready(clear_ready)
    );

  parameter PERIOD = 10;

  always begin
    clk = 1'b0;
    #(PERIOD/2)
    clk = 1'b1;
    #(PERIOD/2);
  end

endmodule // uart_receiver_test