`include "../counter/counter.v"

module uart_receiver(
  o_8_data,
  // o_error,
  o_ready,
  i_clear_ready,
  i_rx,
  i_reset,
  i_clk
);

  parameter FULL_buad = 1302;
  parameter HALF_buad =  652;

  input wire i_clk;
  input wire i_rx;
  parameter START_BIT = 1'b0;
  parameter STOP_BIT  = 1'b1;
  input wire i_reset;
  output wire [7:0] o_8_data;
  // output wire o_error;
  output wire o_ready;
  input wire i_clear_ready;
  
  wire [11:0] timer;
  reg reset_timer;
  
  // UART states
  parameter sStop   = 4'b1001;
  parameter sStart  = 4'b1010;
  parameter sData   = 1'b0; // 0XXX -> 0000 - 0111 ( 8 inner states )
  parameter sParity = 4'b1000;
  
  // assign reset_timer = c_state != n_state;
  
  // main state
  reg [3:0] c_state, n_state;
  always @( posedge i_clk or posedge i_reset ) begin
    if( i_reset )
      c_state = sStop;
    else
      c_state = n_state;
  end
  
  // data state
  reg [7:0] c_8_data, n_8_data;
  assign o_8_data = c_8_data;
  always @( posedge i_clk or posedge i_reset ) begin
    if( i_reset )
      c_8_data = 8'b0000_0000;
    else
      c_8_data = n_8_data;
  end
  
  // ready states
  parameter sReady     = 1'b1;
  parameter sNotReady  = 1'b0;
  
  reg c_ready, n_ready;
  assign o_ready = c_ready;
  wire clear_ready;
  assign clear_ready = i_reset || i_clear_ready;
  
  // ready state
  always @( posedge i_clk ) begin
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
    if( c_state == sStop && i_rx == START_BIT ) begin
      n_state = sStart;
      reset_timer = 1'b1;
    end else if( c_state == sStart && timer == HALF_buad ) begin
      n_state = sData;
      reset_timer = 1'b1;
    end else if( c_state[3] == sData && timer == FULL_buad ) begin
      n_state = c_state + 1;
      reset_timer = 1'b1;
    end else if( c_state == sParity && timer == FULL_buad ) begin
      n_state = sStop;
      reset_timer = 1'b1;
    end else begin
      n_state = c_state;
      reset_timer = 1'b0;
    end
  end
  
  counter_sync_reset counter(
    .i_clk(i_clk),
    .o_n_result(timer),
    .i_reset_sync(reset_timer)
  );

endmodule // uart_receiver

`include "../clock_divider/clock_divider.v"
`include "../serializer/serializer.v"

module uart_transmitter(
	data,
	busy,
	send,
	// rx_i,
	tx_o,
	reset,
	clk
);

  parameter number_of_bits = 8;
  parameter IN_FREQ = 20;
  parameter OUT_FREQ = 1;
  
  input wire [number_of_bits-1:0] data; // w/o parity
  output wire busy;
  input wire send;
  // input wire rx_i;
  output wire tx_o;
  input wire reset;
  input wire clk;
  
  parameter sInit = 2'b10;
  parameter sActiveCheck = 2'b00;
  parameter sPrepSend = 2'b01;
  parameter sSend = 2'b11;
  
  reg [1:0] c_state, n_state;
  
  wire d_clk, start, reset_d_clk;
  wire [number_of_bits+1:0] data_in;
  //reg reset_d_clk;
  
  assign start = c_state == sPrepSend;
  assign reset_d_clk = c_state == sInit;
  assign data_in = {^data, data, 1'b0}; // {parity, data, StartBit}
  
  always @( posedge clk or posedge reset ) begin
    if( reset ) begin
      c_state = sInit;
    end else begin
      c_state = n_state;
    end
  end
  
  always @( * ) begin
    if( c_state == sInit ) begin
      n_state = sActiveCheck;
    end else if( c_state == sActiveCheck ) begin
      if( send ) begin
        n_state = sPrepSend;
      end else begin
        n_state = sActiveCheck;
      end
    end else if( c_state == sPrepSend ) begin
      if( busy ) begin
        n_state = sSend;
      end else begin
        n_state = sPrepSend;    
      end
    end else begin // sPrepSend
      if( busy ) begin
        n_state = sSend;
      end else begin
        n_state = sActiveCheck;
      end
    end
  end
  
  // always @( posedge clk ) begin
  //   if( c_state == sSend && n_state == sActiveCheck ) begin
  //     reset_d_clk = 1;
  //   end else begin
  //     reset_d_clk = 0;
  //   end
  // end
  
  serializer #(
    .DATA_WIDTH(10)) ser(
    .busy(busy),
    .data_out(tx_o),
    .data_in(data_in),
    .start(start),
    .clock(d_clk),
    .reset(reset)
  );
  
  clock_divider #(
    .IN_FREQ(IN_FREQ),
    .OUT_FREQ(OUT_FREQ)) cd(
    .clock(clk),
    .d_clock(d_clk),
    .reset( reset_d_clk )
  );

endmodule // uart_transmitter