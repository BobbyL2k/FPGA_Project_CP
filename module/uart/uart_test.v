`include "uart.v"

module uart_receive_test();

wire [7:0] data;
wire ready, tx;
reg reset_ready, rx, reset, clk;

initial begin
    $dumpfile("dump.vcd");
    $dumpvars(3);

    reset_ready = 0;
    rx = 0;
    
    reset = 0;
    #40
    reset = 1;
    rx = 1;
    #40
    reset = 0;
    #40
    
    #60
    
    rx = 0; // Start bit
    #400
    rx = 1; // 1
    #400
    rx = 0; // 2
    #400
    rx = 1; // 3
    #400
    rx = 1; // 4
    #400
    rx = 1; // 5
    #400
    rx = 0; // 6
    #400
     rx = 0; // 7
    #400
    rx = 0; // 8
    #400
    rx = 0; // parity
    #400
    rx = 1; // stop bit
    #400
    rx = 1; // stop bit
    
    
    // TX freq is 1/20 of clk
    // TX period is 400 ns
    
    #100 $finish;
end

parameter PERIOD = 20;

always begin
    clk = 1'b0;
    #(PERIOD/2)
    clk = 1'b1;
    #(PERIOD/2);
end

uart_receive ur(
    .data(data),
    .ready(ready),
    .reset_ready(reset_ready),
    .rx_i(rx),
    .tx_o(tx),
    .reset(reset),
    .clk(clk));

endmodule // uarthelper

module uart_transmitter_test();

  reg [8:0] data_in;
  reg send, rx_i, reset, clk;
  wire busy, tx_o;
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(3);

    reset = 0;
    #40
    reset = 1;
    rx_i = 1;
    #40
    reset = 0;
    #400
    
    data_in = 9'b1010_1011_1;
    #100
    send = 1;
    #20
    send = 0;
    #5000
    
    #100 $finish;
end
  
  parameter PERIOD = 20;
  
  always begin
    clk = 1'b0;
    #(PERIOD/2)
    clk = 1'b1;
    #(PERIOD/2);
  end
  
  uart_transmitter ut(
    .data(data_in),
    .busy(busy),
    .send(send),
    // .rx_i(rx_i),
    .tx_o(tx_o),
    .reset(reset),
    .clk(clk));

endmodule // uart_transmitter_test