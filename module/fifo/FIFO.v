`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/19/2016 01:29:36 PM
// Design Name: 
// Module Name: FIFO
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


`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:27:37 05/13/2016 
// Design Name: 
// Module Name:    fifo 
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

module fifo(
		data_count,
		data_out,
		empty,
		busy,
		full,
		data_in,
		push,
		pop,
		reset,
		clock
    );
	 
	 parameter DATA_WIDTH = 8;
	 parameter ADDR_WIDTH = 13;
	 parameter RAM_DEPTH = 5000;
	 
	 //output reg [DATA_WIDTH-1 : 0] data_out;
	 output wire [DATA_WIDTH-1 : 0] data_out;
	 output wire empty;
	 output wire busy; // pushing data;
	 output wire full;
	 output reg [ADDR_WIDTH-1 : 0]data_count;
	 
	 input wire [DATA_WIDTH-1 : 0] data_in;
	 input wire push;
	 input wire pop;
	 input wire reset;
	 input wire clock;
	 
	 reg [1:0]pushing;
	 reg poping;
	 reg [1:0]pushing_ns;
	 reg poping_ns;
	 
	 reg [DATA_WIDTH-1 : 0] mem [RAM_DEPTH-1 : 0];
	 reg [ADDR_WIDTH-1 : 0] front_addr;
	 reg [ADDR_WIDTH-1 : 0] rear_addr;
	 wire [ADDR_WIDTH-1 : 0] front_addr_in;
	 wire [ADDR_WIDTH-1 : 0] rear_addr_in;
	 wire [DATA_WIDTH-1 : 0] mem_in;
	 reg [ADDR_WIDTH-1 : 0] data_count_in;
     //wire [ADDR_WIDTH-1 : 0] next_rear_addr;
     //wire [ADDR_WIDTH-1 : 0] next_front_addr;
	 
	 assign data_out = mem[front_addr];
	 assign empty = (rear_addr == front_addr) ? 1'b1 : 1'b0;
	 assign full = (rear_addr+1 == front_addr) ? 1'b1 : 1'b0;
	 assign busy = (poping == 1'b0 && pushing == 2'b00) ? 1'b0 : 1'b1;
	 assign front_addr_in = (poping) ? front_addr + 1 : front_addr;
	 assign rear_addr_in = (pushing == 2'b10) ? rear_addr + 1: rear_addr ;
	 assign mem_in = (pushing == 2'b01) ? data_in : mem[rear_addr];
	//  wire ENA,ENB,WEA,WEB;
	//  assign ENA = 1'b1;
	//  assign ENB = 1'b0;
	//  assign WEA = 0;
	//  assign WEB = (pushing) ? 1'b1 : 1'b0;
	 	 
	//  assign pushing = (ps == 4'b1001 || ps == 4'b1000 || ps == 4'b1100 || ps == 4'b1101) ? 1'b1 : 1'b0;
	//  assign poping = (ps == 4'b0001 || ps == 4'b1100 ) ? 1'b1 : 1'b0;
	//  assign empty = (rear_addr == front_addr) ? 1'b1 : 1'b0;
	//  assign full = (next_rear_addr == front_addr) ? 1'b1 : 1'b0;
	//  assign busy = (pushing || poping) ? 1'b1 : 1'b0;
	//  assign rear_addr_in = (ps == 4'b1001 || ps == 4'b1101) ? next_rear_addr : rear_addr;
	//  assign front_addr_in = (ps == 4'b0001 || ps == 4'b1100) ? next_front_addr : front_addr; 
	//  assign next_rear_addr = (rear_addr == 4900) ? {DATA_WIDTH{1'b0}} :  rear_addr + 1;
	//  assign next_front_addr = (front_addr == 4900) ? {DATA_WIDTH{1'b0}} :  front_addr + 1;
	 
	 //DualPortRam #(.ADDR_WIDTH(ADDR_WIDTH)) ram(clock,front_addr,data_out,WEA,ENA,rear_addr,data_in,WEB,ENB);
	 
	initial begin
		poping = 0;
		pushing = 0;
		front_addr = 0;
		rear_addr = 0;
	end
	
	always @(posedge clock or posedge reset) begin
		if(reset) begin
			poping <= 1'b0;
			pushing <= 2'b00;
			front_addr <= {ADDR_WIDTH{1'b0}};
			rear_addr <= {ADDR_WIDTH{1'b0}};
			mem[rear_addr] <= 8'h00;
			data_count <= 13'b0_0000_0000_0000;
		end
		else begin
			poping <= poping_ns;
			pushing <= pushing_ns;
			front_addr <= front_addr_in;
			rear_addr <= rear_addr_in;
			mem[rear_addr] <= mem_in;
			data_count <= data_count_in;
		end
	end
	
	always @(*) begin
		case(pushing)
			2'b00 : begin
				if(push && !full) pushing_ns <= 2'b01;
				else pushing_ns <= 2'b00;
			end
			2'b01 : begin
				pushing_ns <= 2'b10;
			end
			2'b10 : begin
				pushing_ns <= 2'b00;
			end
			default : pushing_ns <= 2'b00;
		endcase
	end
	
	always @(*) begin
		case(poping)
			1'b0 : begin
				if(pop && !empty) poping_ns<=1'b1;
				else poping_ns<=1'b0;
			end
			1'b1 : begin
				poping_ns <= 1'b0;
			end
			default : poping_ns <= 1'b0;
		endcase
	end
	
	always @(*) begin
		if(pushing == 2'b01 && poping == 1'b1) data_count_in <= data_count;
		else if(pushing == 2'b01) data_count_in <= data_count + 1;
		else if(poping == 1'b1) data_count_in <= data_count - 1;
		else data_count_in <= data_count;
	end

endmodule


