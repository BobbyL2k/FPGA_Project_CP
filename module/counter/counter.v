module counter_sync_reset(
  i_clk,
  o_n_result,
  i_reset_sync
);

  parameter WIDTH = 12;
  // max value of 1303 will need at least 11 bits

  input wire i_clk;
  output reg [WIDTH-1:0] o_n_result;
  input wire i_reset_sync;

  always @( posedge i_clk ) begin
    if( i_reset_sync ) begin
      o_n_result = {WIDTH{1'b0}};
    end else begin
      o_n_result = o_n_result + 1;
    end
  end

endmodule // counter_sync_reset