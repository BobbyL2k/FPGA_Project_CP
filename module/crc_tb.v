`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   22:24:31 05/20/2016
// Design Name:   crc
// Module Name:   C:/Users/jame/Documents/CRC/crc/crc_tb.v
// Project Name:  crc
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: crc
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module crc_tb;

	// Inputs
	reg bitval;
	reg clock;
	reg reset;

	// Outputs
	wire [7:0] CRC;

	// Instantiate the Unit Under Test (UUT)
	crc uut (
		.CRC(CRC), 
		.bitval(bitval), 
		.clock(clock), 
		.reset(reset)
	);

	initial begin
		// Initialize Inputs
		bitval = 0;
		clock = 0;
		reset = 1;
		#100 reset = 0;

		  #50 bitval = 0;
        #50 bitval = 1;
        #50 bitval = 0;
        #50 bitval = 1;
		  #50 bitval = 1;
		  #50 bitval = 1;
		  #50 bitval = 0;
		  #50 bitval = 1;
		  #50 reset = 1;
        #50 $finish;
    end     
    always
        #20 clock = ~clock;
      
endmodule

