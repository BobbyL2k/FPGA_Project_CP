`include "../clock_divider/clock_divider.v"

module uart_receive(
  output wire [7:0] data,
  output reg ready,
  input wire reset_ready,
  input wire rx_i,
  output wire tx_o,
  input wire reset,
  input wire clk
);

  parameter IN_FREQ = 20;
  parameter OUT_FREQ = 1;

  parameter rx_start_bit = 1'b0;
  parameter rx_stop_bit  = 1'b1;

  // leave tx at high (1)
  assign tx_o = 1'b1;

  // Module States
  parameter sActiveCheck = 1'b0;
  parameter sCollect = 1'b1;

  reg c_state, n_state;

  reg resetHelper;
  wire collectDone, d_clk;
  wire [8:0]data_wP;

  reg [7:0] buffer [1:0];
  wire [7:0] l_buffer0, l_buffer1;
  
  reg buffer_sel, n_buffer_sel;
  
  assign data = buffer[~buffer_sel];
  
  assign l_buffer0 = (buffer_sel) ? buffer[0] : data_wP[7:0];
  assign l_buffer1 = (buffer_sel) ? data_wP[7:0] : buffer[1];
  
  wire l_ready_reset;

  assign l_ready_reset = reset | reset_ready;

  always @( posedge clk or posedge l_ready_reset ) begin
    if( l_ready_reset ) begin
      ready = 0;
    end else begin
      if( collectDone ) begin
        ready = 1;
      end else begin
        ready = ready;
      end
    end 
  end
  
  always @( posedge clk or posedge reset ) begin
    if( reset ) begin
      c_state = sActiveCheck;
    end else begin
      c_state = n_state;
    end
  end
  
  always @( posedge clk or posedge reset ) begin
    if( reset ) begin
      buffer[0] = 8'b0000_0000;
      buffer[1] = 8'b0000_0000;
    end else begin
      buffer[0] = l_buffer0;
      buffer[1] = l_buffer1;
    end
  end
  
  always @( posedge clk or posedge reset ) begin
    if( reset ) begin
      buffer_sel = 1'b0;
    end else begin
      buffer_sel = n_buffer_sel;
    end
  end

  always @( * ) begin
    if( c_state == sActiveCheck ) begin
      if( rx_i == rx_start_bit ) begin
        n_state = sCollect;
      end else begin
        n_state = sActiveCheck;
      end
    end else begin // sCollect
      if( collectDone == 1 ) begin
        n_state = sActiveCheck;
      end else begin
        n_state = sCollect;
      end
    end
  end
  
  // always @( * ) begin
  //   if( buffer_sel ) begin
  //     l_buffer0 = buffer[0];
  //     l_buffer1 = data_wP[7:0];
  //   end else begin
  //     l_buffer0 = data_wP[7:0];
  //     l_buffer1 = buffer[1];
  //   end
  // end
  
  always @( * ) begin
    if( c_state == sCollect && n_state == sActiveCheck ) begin
      n_buffer_sel = ~buffer_sel;
    end else begin
      n_buffer_sel = buffer_sel;
    end
  end

  always @( * ) begin
    if( c_state == sActiveCheck && n_state == sCollect ) begin
      resetHelper = 1'b1;
    end else begin
      resetHelper = 1'b0;
    end
  end

  clock_divider #(
    .IN_FREQ(IN_FREQ),
    .OUT_FREQ(OUT_FREQ)) cd(
    .clock(clk),
    .d_clock(d_clk),
    .reset(resetHelper)
  );

  uart_receive_helper urh(
    .rx_i(rx_i),
    // .tx_o(tx_o),
    .reset(resetHelper),
    .d_clk(d_clk),
    .data(data_wP), // with parity
    .done(collectDone));

endmodule // uart_receive

module uart_receive_helper(
  rx_i,
  reset,
  d_clk,
  data,
  done
);

  parameter number_of_bits = 8+1;
  
  input wire rx_i;
  // output wire tx_o;
  input wire reset;
  input wire d_clk;
  output [number_of_bits-1:0] data;
  output reg done;

  // Module states
  parameter sIdle = 5'b11110;  // idle      state 11_000
  parameter sStart= 5'b11111;  // start bit state 00_000
  parameter sData = 5'b00000;  // data  bit state 01_XXX
                              // receive data for 8 clock
  parameter sEnd  = sData + number_of_bits;  
                              // end   bit state 10_000
                              
  reg [number_of_bits-1:0] buffer;

  assign data = buffer;

  reg [4:0] c_state, n_state;

  always @( posedge d_clk or posedge reset ) begin
    if(reset) begin
      buffer = {number_of_bits{1'b0}};
    end else begin
      buffer = buffer;
      buffer[c_state] = rx_i;
    end
  end

  always @( negedge d_clk or posedge reset ) begin
    if(reset) begin
      c_state = sStart;
    end else begin
      c_state = n_state;
    end
  end

  always @( * ) begin
    if( c_state == sStart ) begin
      n_state = sData;
    end else if( c_state == sEnd || c_state == sIdle ) begin
      n_state = sIdle;
    end else begin
      n_state = c_state + 1;
    end
  end

  always @( posedge d_clk or posedge reset ) begin
    if( reset ) begin
      done = 0;
    end else begin
      if( c_state == sEnd ) begin
        done = 1;
      end else begin
        done = 0;
      end
    end
  end

endmodule // uart_receive_helper

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
