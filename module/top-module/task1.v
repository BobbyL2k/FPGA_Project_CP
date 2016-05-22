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

module uart_pc_2_pc(
  input wire clk,
  input wire rx,
  output wire tx,
  input wire reset
);

  // Real World
  parameter IN_FREQ = 220052; // Expected internal clock frequncy
  parameter OUT_FREQ = 96;    // Baud Rate
  // For Simulation
  // parameter IN_FREQ = 20;
  // parameter OUT_FREQ = 1;
  
  wire clock;
  assign clock = clk;
  
  wire [7:0] 
    data;     // data received from PC by uart_receive
  wire 
    db_reset, // debounced reset signal
    dummy_tx, // dummy tx wire
    tr_send,  // trigger send signal from (uart_transmitter posedge busy) 
    ut_busy;  // uart transmitter being busy sending data to PC
    
  
  PushButton_Debouncer reset_db(
      .clk(clock),
      .PB(reset),
      .PB_state(db_reset)
	  );
	
  uart_receive #(
      .IN_FREQ(IN_FREQ),
      .OUT_FREQ(OUT_FREQ)) 
    uartr(
      .data(data),
      .ready(data_ready),
      .reset_ready(tr_send),
      .rx_i(rx),
      .tx_o(dummy_tx),
      .reset(db_reset),
      .clk(clock)
    );
  
  uart_transmitter #(
      .IN_FREQ(IN_FREQ),
      .OUT_FREQ(OUT_FREQ)) 
    uartt(
      .data(data),
      .busy(busy),
      .send(tr_send),
      .tx_o(tx),
      .reset(db_reset),
      .clk(clock)
    );

endmodule // uart_pc_2_pc