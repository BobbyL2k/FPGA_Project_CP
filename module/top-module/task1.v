`include "../uart/uart.v"

module task1(
  input wire clk,
  input wire rx,
  output wire tx,
  input wire reset
);

  wire [7:0] data;
  wire busy, send, l_reset;
  
  assign data = 8'b1100_1001;
  assign send = 1'b1;
  assign l_reset = reset;

  uart_transmitter uartt(
    .data(data),
    .busy(busy),
    .send(send),
    .tx_o(tx),
    .reset(l_reset),
    .clk(clk)
  );

endmodule // task1