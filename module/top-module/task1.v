`include "../uart/uart.v"
`include "../single_pulser/single_pulser.v"
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
  input wire reset,
  output reg tr_received,
  output wire m_data_ready,
  output wire m_ut_busy
);

  // Real World
  parameter IN_FREQ = 220052; // Expected internal clock frequncy
  parameter OUT_FREQ = 96;    // Baud Rate
  // For Simulation
  // parameter IN_FREQ = 20;
  // parameter OUT_FREQ = 1;
  
  wire tr_received_n;
  assign tr_received_n = ~tr_received;
  
  wire clock;
  assign clock = clk;
  
  wire [7:0] 
    data;     // data received from PC by uart_receive
  wire 
    db_reset,     // debounced reset signal
    // dummy_tx,  // dummy tx wire
    data_ready,   // data received and ready
    tr_send,      // trigger send signal from (uart_receive posedge data_ready) 
    ut_busy,      // uart transmitter being busy sending data to PC
    tr_reset_ready; // trigger send signal from (uart_transmitter posedge busy) 
    
  assign m_data_ready = data_ready;
  assign m_ut_busy = ut_busy;
  
  always @( posedge clock or posedge db_reset ) begin
    if( db_reset ) begin
      tr_received = 1;
    end else if( tr_send ) begin
      tr_received = tr_received_n;
    end
  end
  
  PushButton_Debouncer reset_db(
      .clk(clock),
      .PB(reset),
      .PB_state(db_reset)
	  );
    
  single_pulser send_sp(
    .signal_in(data_ready),
    .signal_out(tr_send),
    .clk(clock),
    .reset(db_reset)
  ),busy_sp(
    .signal_in(ut_busy),
    .signal_out(tr_reset_ready),
    .clk(clock),
    .reset(db_reset)
  );
	
  uart_receive #(
      .IN_FREQ(IN_FREQ),
      .OUT_FREQ(OUT_FREQ)) 
    uartr(
      .data(data),
      .ready(data_ready),
      .reset_ready(tr_reset_ready),
      .rx_i(rx),
      .reset(db_reset),
      .clk(clock)
    );
  
  uart_transmitter #(
      .IN_FREQ(IN_FREQ),
      .OUT_FREQ(OUT_FREQ)) 
    uartt(
      .data(data),
      .busy(ut_busy),
      .send(tr_send),
      .tx_o(tx),
      .reset(db_reset),
      .clk(clock)
    );

endmodule // uart_pc_2_pc