`include "clock_divider.v"

module uart_receive(
  output wire [7:0] data,
  output reg ready,
  input wire reset_ready,
  input wire rx_i,
  output wire tx_o,
  input wire reset,
  input wire clk
);

parameter rx_start_bit = 1'b0;
parameter rx_stop_bit  = 1'b1;

// leave tx at low (0)
assign tx_o = 1'b0;

// Module States
parameter sActiveCheck = 1'b0;
parameter sCollect = 1'b1;

reg c_state, n_state;

reg resetHelper;
wire collectDone, d_clk;
wire [8:0]data_wP;

assign data = data_wP[7:0];

always @( posedge clk or reset or reset_ready ) begin
  if( reset || reset_ready ) begin
    ready = 0;
  end else begin
    if( collectDone ) begin
      ready = 1;
    end else begin
      ready = ready;
    end
  end 
end
 
always @( posedge clk or reset ) begin
  if( reset ) begin
    c_state = sActiveCheck;
  end else begin
    c_state = n_state;
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

always @( * ) begin
  if( c_state == sActiveCheck && n_state == sCollect ) begin
    resetHelper = 1'b1;
  end else begin
    resetHelper = 1'b0;
  end
end

clock_divider cd(
  .clock(clk),
  .d_clock(d_clk),
  .reset(resetHelper)
);

uart_receive_helper urh(
  .rx_i(rx_i),
  // .tx_o(tx_o),
  .reset(resetHelper),
  .d_clk(d_clk),
  .data(data_wP),
  .done(collectDone));

endmodule // uart_receive

module uart_receive_helper(
  input wire rx_i,
  // output wire tx_o,
  input wire reset,
  input wire d_clk,
  output wire [number_of_bits-1:0] data,
  // data,
  output reg done
);

parameter number_of_bits = 8+1;

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

always @( posedge d_clk or reset ) begin
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

always @( posedge d_clk or reset ) begin
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