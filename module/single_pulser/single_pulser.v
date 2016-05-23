// active high single pulser
module single_pulser(
  input wire signal_in,
  output wire signal_out,
  input wire clk,
  input wire reset
);

parameter sLow = 2'b00;
parameter sFHigh = 2'b01;
parameter sHigh = 2'b10;

reg [1:0] c_state, n_state;

assign signal_out = c_state[0];

always @( posedge clk or posedge reset ) begin
  if( reset ) begin
    c_state = sLow;
  end else begin
    c_state = n_state;
  end
end

always @( * ) begin
  if( c_state == sLow ) begin
    if( signal_in == 1 ) begin
      n_state = sFHigh;
    end else begin
      n_state = sLow;
    end
  end else begin
    if( signal_in == 1 ) begin
      n_state = sHigh;
    end else begin
      n_state = sLow;
    end
  end
end

endmodule // single_pulser