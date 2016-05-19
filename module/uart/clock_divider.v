module clock_divider(
  input wire clock,
  output wire d_clock,
  input wire reset
);

parameter IN_FREQ = 10;
parameter OUT_FREQ = 1;

parameter COUNT_TO = IN_FREQ / OUT_FREQ / 4;
parameter COUNTER_SIZE = $clog2(COUNT_TO)+1;

reg [COUNTER_SIZE-1:0] counter;

reg c_d_clock, n_d_clock;
assign d_clock = c_d_clock;

always @( posedge clock or reset ) begin
  if(reset) begin
    counter = {COUNTER_SIZE{1'b0}};
  end else begin
    if(counter == COUNT_TO) begin
      counter = {COUNTER_SIZE{1'b0}};
    end else begin
      counter = counter + 1;
    end
  end
end

always @( posedge clock or reset ) begin
  if(reset) begin
    c_d_clock = 0;
  end else begin
    c_d_clock = n_d_clock;
  end
end

always @( * ) begin
  if( counter == COUNT_TO ) begin
    n_d_clock = ~c_d_clock;
  end else begin
    n_d_clock = c_d_clock;
  end
end

endmodule // clock_divider