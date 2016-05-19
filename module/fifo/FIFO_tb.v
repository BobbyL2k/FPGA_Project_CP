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
    wire [7:0] data_out;
    wire empty;
    wire busy;
    wire full;
    wire [3:0] state;
    wire [9:0] rear;
    wire [9:0] front;
    fifo ff(front,rear,state,data_out,empty,busy,full,data_in,push,pop,reset,clock);
         
    initial begin
        data_in = 8'hF1;
        push = 0;
        pop = 0;
        reset = 0;
        clock = 0;
        #50 reset = 1;
        #50 reset = 0;
        #50 push = 1;
        #50 push = 0;
        #100 data_in = 8'hFA;
        #100 push = 1;
        #100 push =0;
        #100 pop = 1;
        #100 pop = 0;
        #100 pop = 1;
        #100 pop = 0;
        #50 $finish;
    end     
    always
        #20 clock = ~clock;
    always begin
        #100 push = 1;
        #100 push = 0;
    end
endmodule
