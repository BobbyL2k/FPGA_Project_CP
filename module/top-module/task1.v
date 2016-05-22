`include "../uart/uart.v"
`include "../PushButton_Debouncer/PushButton_Debouncer.v"

module task1_t_test(
  input wire clk,
  input wire rx,
  output wire tx,
  input wire reset
);

  parameter IN_FREQ = 25000000;
  parameter OUT_FREQ = 9600;
  // parameter IN_FREQ = 20;
  // parameter OUT_FREQ = 1;
  
  wire [7:0] data;
  wire busy, send, l_reset;
  
  assign data = 8'b1100_1001;
  assign send = 1'b1;
  //assign l_reset = reset;

  PushButton_Debouncer_dummy reset_db(
    .clk(clk),
	 .PB(reset),
	 .PB_state(l_reset)
	 );
	
	//assign tx = rx;
	
  uart_transmitter #(
    .IN_FREQ(IN_FREQ),
    .OUT_FREQ(OUT_FREQ)) uartt(
    .data(data),
    .busy(busy),
    .send(send),
    .tx_o(tx),
    .reset(l_reset),
    .clk(clk)
  );
  
  

endmodule // task1_t_test