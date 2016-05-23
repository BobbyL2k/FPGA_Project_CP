`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/19/2016 03:42:17 PM
// Design Name: 
// Module Name: DualPortRam
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


module DualPortRam  (clk,
  address_0,
  data_0,
  we_0,
  oe_0,
  address_1,
  data_1,
  we_1,
  oe_1);
  parameter DATA_WIDTH = 8;
  parameter ADDR_WIDTH = 13;
  parameter RAM_DEPTH = 1 << ADDR_WIDTH;

  input clk;
  input [ADDR_WIDTH-1 : 0] address_0;
  input we_0 ;
  input oe_0 ;
  input [ADDR_WIDTH-1 : 0] address_1;
  input we_1;
  input oe_1;

  input [DATA_WIDTH-1 : 0] data_1;
  output [DATA_WIDTH-1 : 0] data_0;

  reg [DATA_WIDTH-1 : 0] mem [RAM_DEPTH-1 : 0];

  always @(posedge clk)
    begin
      //if(we_0)
       // mem[address_0] = data_0;
      if(we_1)
        mem[address_1] = data_1;
    end 
    assign data_0  =  mem[address_0];
    //assign data_1  = oe_1 ? mem[address_1] : {DATA_WIDTH{1'bZ}};
endmodule
