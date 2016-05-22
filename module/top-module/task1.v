`include "../uart/uart.v"
`include "../PushButton_Debouncer/PushButton_Debouncer.v"

module task1_t_test(
  input wire clk,
  input wire rx,
  output wire tx,
  input wire reset,
  input wire send,
  output wire busy
);

  parameter IN_FREQ = 220052;
  parameter OUT_FREQ = 96;
  // parameter IN_FREQ = 20;
  // parameter OUT_FREQ = 1;
  
  wire [7:0] data;
  wire db_reset, tr_send;
  wire clock;
  
  assign clock = clk;
  
  assign data = 8'b1000_1110;
  //assign send = 1'b1;
  //assign l_reset = reset;

  PushButton_Debouncer reset_db(
    .clk(clock),
	 .PB(reset),
	 .PB_state(db_reset)
	 ),
	 send_db(
    .clk(clock),
	 .PB(send),
	 .PB_down(tr_send)
	 );
	
	//assign tx = rx;
	
  uart_transmitter #(
    .IN_FREQ(IN_FREQ),
    .OUT_FREQ(OUT_FREQ)) uartt(
    .data(data),
    .busy(busy),
    .send(tr_send),
    .tx_o(tx),
    .reset(db_reset),
    .clk(clock)
  );
  
  

endmodule // task1_t_test