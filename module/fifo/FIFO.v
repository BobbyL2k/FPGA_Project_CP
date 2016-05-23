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
	 
	 //output reg [DATA_WIDTH-1 : 0] data_out;
	 output wire [DATA_WIDTH-1 : 0] data_out;
	 output wire empty;
	 output wire busy; // pushing data;
	 output wire full;
	 
	 input wire [DATA_WIDTH-1 : 0] data_in;
	 input wire push;
	 input wire pop;
	 input wire reset;
	 input wire clock;
	 
	 reg [3:0] ps;
	 reg [3:0] ns;
	 reg [ADDR_WIDTH-1 : 0] front_addr;
	 reg [ADDR_WIDTH-1 : 0] rear_addr;
	 wire [ADDR_WIDTH-1 : 0] front_addr_in;
	 wire [ADDR_WIDTH-1 : 0] rear_addr_in;
     wire [ADDR_WIDTH-1 : 0]next_rear_addr;
     wire [ADDR_WIDTH-1 : 0]next_front_addr;
	 wire pushing;
	 
	 wire ENA,ENB,WEA,WEB;
	 assign ENA = 1'b1;
	 assign ENB = 1'b0;
	 assign WEA = 0;
	 assign WEB = (pushing) ? 1'b1 : 1'b0;
	 	 
	 assign pushing = (ps == 4'b1001 || ps == 4'b1000 || ps == 4'b1100 || ps == 4'b1101) ? 1'b1 : 1'b0;
	 assign poping = (ps == 4'b0001 || ps == 4'b1100 ) ? 1'b1 : 1'b0;
	 assign empty = (rear_addr == front_addr) ? 1'b1 : 1'b0;
	 assign full = (next_rear_addr == front_addr) ? 1'b1 : 1'b0;
	 assign busy = (pushing || poping) ? 1'b1 : 1'b0;
	 assign rear_addr_in = (ps == 4'b1001 || ps == 4'b1101) ? next_rear_addr : rear_addr;
	 assign front_addr_in = (ps == 4'b0001 || ps == 4'b1100) ? next_front_addr : front_addr; 
	 assign next_rear_addr = (rear_addr == 4900) ? {DATA_WIDTH{1'b0}} :  rear_addr + 1;
	 assign next_front_addr = (front_addr == 4900) ? {DATA_WIDTH{1'b0}} :  front_addr + 1;
	 
	 DualPortRam #(.ADDR_WIDTH(ADDR_WIDTH)) ram(clock,front_addr,data_out,WEA,ENA,rear_addr,data_in,WEB,ENB);
	 
	initial begin
		ps = 0;
		front_addr = 0;
		rear_addr = 0;
	end
	
	always @(posedge clock or posedge reset) begin
		if(reset) begin
			ps = 0;
			front_addr <= {ADDR_WIDTH{1'b0}};
			rear_addr <= {ADDR_WIDTH{1'b0}};
		end
		else begin
			ps = ns;
			front_addr <= front_addr_in; // TOEDIT
			rear_addr <= rear_addr_in; // TOEDIT
		end
	end
	
	always @(*) begin
		case(ps)
			// IDLE STATE
			4'b0000 : begin
				if(pop && !empty && push && !full) begin
					ns = 4'b1100;
				end
				else if(pop && !empty) begin
					ns = 4'b0001;
				end
				else if(push && !full) begin
					ns = 4'b1000;
				end
				else
					ns = 4'b0000;
			end
			//POP STATES
			4'b0001 : begin
				ns = 4'b0000; // LOL
			end
			//PUSH STATES
			4'b1000 : begin
				ns = 4'b1001;
			end
			4'b1001 : begin
				ns = 4'b0000;
			end
			//PUSH AND POP STATES
			4'b1100 : begin
				ns = 4'b1101;
			end
			
			4'b1101 : begin
				ns = 4'b0000;
			end
			
			default : begin
				ns = 4'b0000;
			end
			
		endcase
	end

endmodule


