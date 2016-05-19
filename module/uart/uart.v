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

// leave tx at low (0)
assign tx_o = 1'b0;

parameter sIdle = 2'b11;  // idle state 11_000
parameter sStart= 2'b01;  // start bit state 01_000
parameter sData = 2'b00;  // data  bit state 00_XXX
                          // receive data for 8 clock
parameter sEnd  = 2'b10;  // end   bit state 11_000

reg [1:0] c_state, n_state;

reg [3:0] c_counter, n_counter;
 
always @( posedge clk or reset ) begin
  if( reset ) begin
    c_state = sIdle;
  end else begin
    c_state = n_state;
  end
end

always @( * ) begin
  if( c_state == sIdle ) begin
    if( rx_i == 1 ) begin
      n_state = sIdle;
    end else begin
      n_state = sStart;
    end
  end else if( c_state == sStart ) begin
    n_state = nData;
  end else if( c_state == sData ) begin
    if( c_counter[3] == 0 ) begin
      n_state = nData;
    end else begin
      n_state = sEnd;
    end
  end
end

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