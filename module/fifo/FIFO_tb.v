`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/19/2016 01:31:49 PM
// Design Name: 
// Module Name: FIFO_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module FIFO_tb(
    
    );
    reg [7:0] data_in;
    reg push;
    reg pop;
    reg reset;
    reg clock;
    wire [9:0] data_count;
    wire [7:0] data_out;
    wire empty;
    wire busy;
    wire full;
    fifo ff(data_count,data_out,empty,busy,full,data_in,push,pop,reset,clock);
         
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;
        data_in = 8'hF1;
        push = 0;
        pop = 0;
        reset = 0;
        clock = 0;
        #50 reset = 1;
        #50 reset = 0;
        #50 push = 1;
        #40 push = 0;
        #100 data_in = 8'hFA;
        #100 push = 1;
        #40 push =0;
        #100 data_in = 8'h91;
        #20 push = 1;
            pop = 1;
        #40 push = 0;
            pop = 0;
        #100 pop = 1;
        #40 pop = 0;
        #100 pop = 1;
        #1000 pop = 0;
        #50 $finish;
    end     
    always
        #20 clock = ~clock;
endmodule
