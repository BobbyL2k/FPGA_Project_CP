`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    22:07:46 05/20/2016 
// Design Name: 
// Module Name:    crc 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////


// ==========================================================================
// CRC Generation Unit - Linear Feedback Shift Register implementation
// (c) Kay Gorontzi, GHSi.de, distributed under the terms of LGPL
// ==========================================================================
//credit https://www.ghsi.de/CRC/
module crc(
	CRC,
	bitval,
	clock,
	reset
    );
	 
	input bitval;                          // Next input bit
   input clock;                           // Current bit valid (Clock)
   input reset;                           // Init CRC value
   output [7:0] CRC;                      // Current output CRC value

   reg [7:0] CRC;                         // We need output registers
   wire inv;
   
   assign inv = bitval ^ CRC[7];          // XOR required?
   
   always @(posedge clock or posedge reset) begin
      if (reset) begin
         CRC = 0;                         // Ini before calculation
         end
      else begin
         CRC[7] = CRC[6];
         CRC[6] = CRC[5];
         CRC[5] = CRC[4] ^ inv;
         CRC[4] = CRC[3] ^ inv;
         CRC[3] = CRC[2];
         CRC[2] = CRC[1];
         CRC[1] = CRC[0];
         CRC[0] = inv;
         end
      end

endmodule
