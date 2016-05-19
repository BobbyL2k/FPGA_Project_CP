module uart_receive(
  output wire [7:0] data,
  output wire ready,
  input wire reset_ready,
  input wire rx_i,
  output wire tx_o,
  input wire reset,
  input wire clk,
  input wire d_clk
);

parameter rx_start_bit = 1'b0;
parameter rx_stop_bit  = 1'b1;

// leave tx at low (0)
assign tx_o = 1'b0;

// Module States
parameter sActiveCheck = 1'b0;
parameter sCountDown = 1'b0;

reg c_state, n_state;


reg [4:0] c_counter, n_counter;
 
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
      n_state = sCountDown;
    end else begin
      n_state = sActiveCheck;
    end
  end else begin
    if( c_state ==  )
  end
end

// always @( * ) begin
//   if( c_state == sIdle ) begin
//     if( rx_i == 1 ) begin
//       n_state = sIdle;
//     end else begin
//       n_state = sStart;
//     end
//   end else if( c_state == sStart ) begin
//     n_state = nData;
//   end else if( c_state == sData ) begin
//     if( c_counter[3] == 0 ) begin
//       n_state = nData;
//     end else begin
//       n_state = sEnd;
//     end
//   end
// end

always @( posedge d_clk or reset ) begin
  if( reset ) begin
    c_counter = 3'b000;
  end else begin
    c_counter = n_counter;
  end
end

always @( * ) begin
  if( c_state == sData ) begin
    n_counter = c_counter + 1;
  end else begin
    n_counter = 4'b0000;
  end
end

endmodule // uart_receive

module uart_receive_helper(
  input wire rx_i,
  output wire tx_o,
  input wire reset,
  input wire d_clk,
  data
);

parameter number_of_bits = 8+1;
output wire [number_of_bits-1:0] data

// Module states
parameter sIdle = 5'b11110;  // idle      state 11_000
parameter sStart= 5'b11111;  // start bit state 00_000
parameter sData = 5'b00000;  // data  bit state 01_XXX
                             // receive data for 8 clock
parameter sEnd  = sData + data;  // end   bit state 10_000

reg [4:0] c_state, n_state;

always @( d_clk or reset ) begin
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

endmodule // uart_receive_helper