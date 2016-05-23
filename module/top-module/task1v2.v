`include "../uart2/uart.v"
`include "../single_pulser/single_pulser.v"
`include "../PushButton_Debouncer/PushButton_Debouncer.v"

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
  );/*,busy_sp(
    .signal_in(ut_busy),
    .signal_out(tr_reset_ready),
    .clk(clock),
    .reset(db_reset)
  );*/
	
  uart_receiver #(
      .HALF_buad(650),
      .FULL_buad(1302)) 
    uartr(
      .o_8_data(data),
      .o_ready(data_ready),
    //   .i_clear_ready(tr_reset_ready),
      .i_clear_ready(ut_busy),
      .i_rx(rx),
      .i_reset(db_reset),
      .i_clk(clock)
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

module uart_pc_2_fpga_led(
  input wire clk,
  input wire rx,
  output wire tx,
  input wire reset,
  output wire [7:0] led
);

  PushButton_Debouncer reset_db(
      .clk(clock),
      .PB(reset),
      .PB_state(db_reset)
	  );
    
  single_pulser reset_ready_sp(
    .signal_in(data_ready),
    .signal_out(tr_reset_ready),
    .clk(clock),
    .reset(db_reset)
  );
  
  reg [7:0] c_led_data, n_led_data;
  wire [7:0] data;
  
  always @( posedge clk or posedge db_reset ) begin
    if( db_reset ) begin
      c_led_data = 8'b0000_0000;
    end else begin
      c_led_data = n_led_data;
    end
  end
  
  always @( * ) begin
    if( data_ready ) begin
      n_led_data = data;
    end else begin
      n_led_data = c_led_data;
    end
  end
	
  uart_receiver #(
      .HALF_buad(650),
      .FULL_buad(1302)) 
    uartr(
      .o_8_data(data),
      .o_ready(data_ready),
      .i_clear_ready(tr_reset_ready),
      .i_rx(rx),
      .i_reset(db_reset),
      .i_clk(clock)
    );

endmodule // uart_pc_2_fpga_led