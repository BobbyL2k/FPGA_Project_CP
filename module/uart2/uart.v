`include "../counter/counter.v"

module uart_receiver(
  i_rx,
  i_reset,
  o_8_data,
  // o_error,
  o_ready,
  i_clear_ready
);

  parameter FULL_buad = 1302;
  parameter HALF_buad =  652;

  input wire i_rx;
  parameter START_BIT = 1'b0;
  parameter STOP_BIT  = 1'b1;
  input wire i_reset;
  output wire [7:0] o_8_data;
  // output wire o_error;
  output wire o_ready;
  input wire i_clear_ready;
  
  wire [11:0] timer;
  wire reset_timer;
  
  // UART states
  parameter sStop   = 4'b1001;
  parameter sStart  = 4'b1010;
  parameter sData   = 1'b0; // 0XXX -> 0000 - 0111 ( 8 inner states )
  parameter sParity = 4'b1000;
  
  // main state
  reg [3:0] c_state, n_state;
  always @( posedge clk or posedge i_reset ) begin
    if( i_reset )
      c_state = sStop;
    else
      c_state = n_state;
  end
  
  assign reset_timer = c_state == n_state;
  
  // data state
  reg [7:0] c_8_data, n_8_data;
  assign o_8_data = c_8_data;
  always @( posedge clk or posedge i_reset ) begin
    if( i_reset )
      c_8_data = 8'b0000_0000;
    else
      c_8_data = n_8_data;
  end
  
  // ready states
  parameter sReady     = 1'b1;
  parameter sNotReady  = 1'b0;
  
  reg c_ready, n_ready;
  wire clear_ready;
  assign clear_ready = i_reset || i_clear_ready;
  
  // ready state
  always @( posedge clk ) begin
    if( clear_ready )
      c_ready = sNotReady;
    else
      c_ready = n_ready;
  end
  
  always @( * ) begin
    if( c_state == sParity && timer == FULL_buad )
      n_ready = sReady;
    else
      n_ready = c_ready;
  end
  
  // next state data
  always @( * ) begin
    if( c_state[3] == sData && timer == FULL_buad ) begin
      n_8_data[0] = i_rx;
      n_8_data[7:1] = c_8_data[6:0];
    end else begin
      n_8_data = c_8_data;
    end
  end
  
  // next state main state
  always @( * ) begin
    if( c_state == sStop && i_rx == START_BIT )
      n_state = sStart;
    else if( c_state == sStart && timer == HALF_buad )
      n_state = sData;
    else if( c_state[3] == sData && timer == FULL_buad )
      n_state = c_state + 1;
    else if( c_state == sParity && timer == FULL_buad )
      n_state = sStop;
    else
      n_state = c_state;
  end
  
  counter_sync_reset counter(
    .i_clk(clk),
    .o_n_result(timer),
    .i_reset_sync(reset_timer)
  );

endmodule // uart_receiver