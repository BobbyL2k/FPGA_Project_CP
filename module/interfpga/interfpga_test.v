`timescale 1ns/1ns
`include "interfpga.v"

module test_interfpga_send(
);

reg [7:0] data;
reg send;
wire busy;
wire [3:0] data_o;
wire ctrl_o;
reg reset;
reg clk;
wire clk_i;

initial begin
    $dumpfile("dump.vcd");
    $dumpvars;

    reset = 0;
    data = 8'b0000_0000;
    send = 0;
    #15
    reset = 1;
    #30
    reset = 0;
    data = 8'b0011_0101;
    #30
    
    send = 1;
    #20
    send = 0;
    #100
    
    data = 8'b1011_1010;
    #30
    
    send = 1;
    #20
    send = 0;
    
    #200 $finish;
end

parameter PERIOD = 20;

always begin
    clk = 1'b0;
    #(PERIOD/2) clk = 1'b1;
    #(PERIOD/2);
end
interfpga_send sender(
  .data(data),
  .send(send),
  .busy(busy),
  .data_o(data_o),
  .ctrl_o(ctrl_o),
  .reset(reset),
  .clk(clk)
);
// Prog1Tu prog(.clk(clk), .A(A), .B(B), .out(out));

endmodule // test_interfpga_send

module test_interfpga_sr();

reg [7:0] sender_data;
reg sender_send;
wire sender_busy;

wire [7:0] receiver_data;
wire receiver_ready;
reg receiver_reset_ready;

wire [3:0] data_io;
wire ctrl_io;

reg reset;
reg clk, clk_i;

initial begin
    $dumpfile("dump.vcd");
    $dumpvars(3);

    reset = 0;
    receiver_reset_ready = 0;
    sender_data = 8'b0000_0000;
    sender_send = 0;
    #15
    reset = 1;
    #30
    reset = 0;
    
    sender_data = 8'h12;
    #30
    sender_send = 1;
    #20
    sender_send = 0;
    #100
    
    sender_data = 8'h34;
    #30
    sender_send = 1;
    #20
    sender_send = 0;
    #45
	 receiver_reset_ready = 1;
	 #20
	 receiver_reset_ready = 0;
    #100
    
    sender_data = 8'h56;
    #30
    sender_send = 1;
    #20
    sender_send = 0;
    #100
    
    sender_data = 8'h78;
    #30
    sender_send = 1;
    #20
    sender_send = 0;
    #100
    
    sender_data = 8'h9A;
    #30
    sender_send = 1;
    #20
    sender_send = 0;
    #100
    
    sender_data = 8'hBC;
    #30
    sender_send = 1;
    #20
    sender_send = 0;
    #100
    
    sender_data = 8'hDE;
    #30
    sender_send = 1;
    #20
    sender_send = 0;
    #100
    
    #100 $finish;
end

parameter PERIOD = 20;
parameter SHIFT = 5;

always begin
    clk = 1'b0;
    #(SHIFT)
    clk_i = 1'b1;
    #(PERIOD/2 - SHIFT)
    clk = 1'b1;
    #(SHIFT)
    clk_i = 1'b0;
    #(PERIOD/2 - SHIFT);
end
interfpga_send sender(
  .data(sender_data),
  .send(sender_send),
  .busy(sender_busy),
  .data_o(data_io),
  .ctrl_o(ctrl_io),
  .reset(reset),
  .clk(clk)
);
interfpga_receive receiver(
  .data(receiver_data),
  .ready(receiver_ready),
  .reset_ready(receiver_reset_ready),
  .data_i(data_io),
  .ctrl_i(ctrl_io),
  .reset(reset),
  .clk(clk_i)
);

endmodule // test_interfpga_sr