module clock_divider(
  input wire clock,
  output wire d_clock,
  input wire reset
);

parameter IN_FREQ = 20;
parameter OUT_FREQ = 1;

parameter COUNT_TO = IN_FREQ / OUT_FREQ / 2 - 1;
parameter COUNTER_SIZE = clog2(COUNT_TO)+1;

function integer clog2;
input integer value;
begin 
value = value-1;
for (clog2=0; value>0; clog2=clog2+1)
value = value>>1;
end 
endfunction

reg [COUNTER_SIZE-1:0] counter;

reg c_d_clock, n_d_clock;
assign d_clock = c_d_clock;

always @( posedge clock or posedge reset ) begin
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

always @( posedge clock or posedge reset ) begin
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
