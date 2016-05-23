`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:    16:26:38 05/22/2016
// Design Name:
// Module Name:    digit
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
module digit(
    input clk,
    input [15:0] data,
	 output [10:0] dgOut,
    input nrst
    );
	reg [3:0]dgOn;
	reg [6:0]fa;
	reg [20:0]counter;
	reg [3:0]c_data;
	assign dgOut = {fa,~dgOn};//11'b11111010101;
	always @(posedge clk)begin
		if(dgOn==4'b0000)dgOn = 1;
		else begin
			counter = counter[19:0]+30;
			if(counter[20])
			dgOn = {dgOn[2:0],dgOn[3]};
		end
	end
	always @(posedge clk)begin
		case(dgOn)
			4'b1000:c_data = data[15:12];
			4'b0100:c_data = data[11:8];
			4'b0010:c_data = data[7:4];
			4'b0001:c_data = data[3:0];
		endcase
	end
	always @(posedge clk)begin
		case(c_data)
			4'b0000:fa = 7'b0111111;//0
			4'b0001:fa = 7'b0000110;//1
			4'b0010:fa = 7'b1011011;//2
			4'b0011:fa = 7'b1001111;//3
			4'b0100:fa = 7'b1100110;//4
			4'b0101:fa = 7'b1101101;//5
			4'b0110:fa = 7'b1111101;//6
			4'b0111:fa = 7'b0000111;//7
			4'b1000:fa = 7'b1111111;//8
			4'b1001:fa = 7'b1101111;//9
			4'b1010:fa = 7'b1110111;//A
			4'b1011:fa = 7'b1111100;//b
			4'b1100:fa = 7'b0111001;//C
			4'b1101:fa = 7'b1011110;//d
			4'b1110:fa = 7'b1111001;//E
			4'b1111:fa = 7'b1110001;//F
		endcase
	end
endmodule
