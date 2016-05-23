`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    04:07:44 05/23/2016 
// Design Name: 
// Module Name:    TopModule_SDCardInitailizer 
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

module TopModule_SDCardInitailizer(
	reset,
	clock,
	start,
	MISO,
	CS,
	SCLK,
	MOSI,
	busy,
	fifo_data_in,
	fifo_push,
	LED
    );
	 
		parameter sIDLE = 5'b00000;
		parameter sINNITIAL = 5'b00001;
		parameter sWAIT_INNITIAL = 5'b00010; 
		
		parameter sFINAL = 5'b11111;
	 
	 
		input wire reset;
		input wire clock;
		input wire start;
		input wire MISO;
		output wire CS;
		output wire SCLK;
		output wire MOSI;
		output wire busy;
		output wire [7:0] fifo_data_in;
		output wire fifo_push;
		output wire [7:0]LED;
		
		
		wire card_ready,initial_MOSI,initial_CS,initial_start,d_clock;
		wire reset_module;
		
		
		reg [4:0] ns;
		reg [4:0] ps;
		
		
		assign CS = 1'b0;
		assign SCLK = d_clock;
		assign MOSI = (!card_ready)? initial_MOSI : 1'b1; // please fix
		assign busy = (ps == sIDLE)? 1'b0 : 1'b1;
		
		assign reset_module = (ps == sIDLE) ? 1'b1 : 1'b0;
		assign initial_start = (ps == sINNITIAL)? 1'b1 : 1'b0;

		assign LED = (ps == sFINAL) ? {7'b000_0000,card_ready} : {7'b011_0011,card_ready};
		
		
		clock_divider #(.IN_FREQ(50),.OUT_FREQ(1))clkdiv(clock,d_clock,reset_PB_down);
		PushButton_Debouncer Debouncer_start(d_clock,start,start_PB_state,start_PB_down,start_PB_up);
		PushButton_Debouncer Debouncer_reset(clock,reset,reset_PB_state,reset_PB_down,reset_PB_up);

		SDCardInitializer sdcardinitializer(card_ready,initial_MOSI,initial_CS,initial_start,reset_module,d_clock,MISO);


		always @(posedge d_clock or posedge reset_PB_down) begin
			if(reset_PB_down) begin
				ps <= 0;
			end
			else begin
				ps <= ns;
			end
		end
	
		always @(*) begin
			case(ps)

				sIDLE : begin
					if(start_PB_down) begin
						ns <= sINNITIAL;
					end
					else begin
						ns <= sIDLE;
					end
				end
				sINNITIAL : begin
					ns <= sWAIT_INNITIAL;
				end
				sWAIT_INNITIAL : begin
					if(card_ready) ns <= sFINAL;
					else ns <= sWAIT_INNITIAL;
				end
				sFINAL : begin
					ns <= sFINAL;
				end
				default : begin
					ns <= sIDLE;
				end
			endcase
		end
endmodule
