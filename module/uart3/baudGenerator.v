`timescale 1ns / 1ps

module baudGenerator(
    input clk,
    output subBaud
    );
	// 2048 / 151 :: 25000000/(16*115200)
	// 2048 / 170 :: 22XXXXXX/(16*115200)
	parameter bitDepth = 11;
	parameter adder = 170;
	
	reg [bitDepth:0]counter;
	assign subBaud = counter[bitDepth];
	always @(posedge clk)begin
		counter <= counter[bitDepth-1:0] + adder;
	end
endmodule
