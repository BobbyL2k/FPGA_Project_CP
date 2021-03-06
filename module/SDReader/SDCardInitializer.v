`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    03:49:30 05/23/2016 
// Design Name: 
// Module Name:    SDCardInitializer 
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
module SDCardInitializer(
		card_ready,
		MOSI,
		CS,
		start,
		reset,
		d_clock,
		MISO
    );
	 
	output wire card_ready;
	output wire MOSI;
	output wire CS;
	
	input wire start;
	input wire d_clock;
	input wire reset;
	input wire MISO;
	
	//---------------------- Define State ----------------------
		parameter sIDLE = 5'b00000;
		parameter sSET_SPI_MODE = 5'b00001;
		parameter sWAIT_SET_SPI_MODE = 5'b00010; 
	
		parameter sSEND_CMD0 = 5'b00011;
		parameter sRESPONSE_CMD0 = 5'b00100;
	
		parameter sSEND_CMD1 = 5'b00101;
		parameter sRESPONSE_CMD1 = 5'b00110;
	
		parameter sCHECK = 5'b00111;
		parameter sSEND_CMD17 = 5'b01000;
		parameter sRESPONSE_CMD17 = 5'b01001;
	
		parameter sWAIT_DATA = 5'b01010;
		parameter sGET_DATA = 5'b01011;
		parameter sWAIT_NEXT_CHECK = 5'b01100;
		
		parameter sSET_CS_HIGH_CMD0 = 5'b01101;
		parameter sSEND_CMD8 = 5'b01110;
		parameter sRESPONSE_CMD8 = 5'b01111;
		parameter sSET_CS_HIGH_CMD8 = 5'b10000;
		parameter sSET_CS_HIGH_CMD1 = 5'b10001;
		
		parameter sSEND_CMD55 = 5'b10010;
		parameter sRESPONSE_CMD55 = 5'b10011;
		parameter sSET_CS_HIGH_CMD55 = 5'b10100;
		
		parameter sSEND_CMD41 = 5'b10101;
		parameter sRESPONSE_CMD41 = 5'b10110;
		parameter sSET_CS_HIGH_CMD41 = 5'b10111;
		
		
		parameter sSEND_CMD58 = 5'b11000;
		parameter sRESPONSE_CMD58 = 5'b11001;
		parameter sSET_CS_HIGH_CMD58 = 5'b11010;

		parameter sFINAL = 5'b11111;

	//----------------------------------------------------------
	
	//----------------------------------------------------------

		parameter startAddress = 32'h0000_0000;		//32 bit
		parameter bitPerDataPacket = 16'b0001_0000_0000_0000;		//512*8 = 4096 bit per dataPacket

	wire reset_module;
	wire waiter_count_to;
	wire waiter_start;
	wire sendcmd_start;
	wire sendcmd_busy;
	wire sendcmd_data_out;
	wire [7:0] desedata_data_out;
	wire desedata_RCO;
	wire [7:0]deseres_data_out;
	wire deseres_busy;
	wire waiter_busy;
	
	wire [7:0]deseres7_data_out;
	wire deseres7_start;
	wire deseres7_data_in;
	
	reg [47:0] sendcmd_data_in;
	reg [4:0] ns;
	reg [4:0] ps;
	
	
	assign MOSI = (sendcmd_busy) ? sendcmd_data_out : 1'b1;
	assign CS = 1'b0;
	assign SCLK = d_clock;
	
	assign deseres_data_in = MISO;
	assign deseres_start = (ps == sSEND_CMD58 || ps == sSEND_CMD8 ||ps == sSEND_CMD0 || ps == sSEND_CMD1 || ps == sSEND_CMD55 || ps == sSEND_CMD41)? 1'b1 : 1'b0;
	assign deseres7_data_in = MISO;
	assign deseres7_start = (ps == sSEND_CMD8 || ps == sSEND_CMD58) ? 1'b1 : 1'b0;
	
	
	assign reset_module = (ps == sIDLE) ? 1'b1 : 1'b0;
	assign waiter_start = (ps == sSET_SPI_MODE || ps == sSEND_CMD1 || ps == sSEND_CMD55 || ps == sSEND_CMD41 || ps == sSEND_CMD0 || ps == sSEND_CMD58) ? 1'b1 : 1'b0;
	assign waiter_count_to = (ps == sSET_SPI_MODE) ? 8'hF0 : 8'h50;
	assign sendcmd_start = (ps == sSEND_CMD0 || ps == sSEND_CMD8 || ps == sSEND_CMD1 || ps == sSEND_CMD55 || ps == sSEND_CMD41 || ps == sSEND_CMD58) ? 1'b1 : 1'b0;
	
	assign card_ready = (ps == sFINAL) ? 1'b1 : 1'b0;
	assign LED =  (ps == sSET_CS_HIGH_CMD8 || ps == sFINAL) ? deseres7_data_out : deseres_data_out;
	//---------------------- Call Module -----------------------
		serializer #(.DATA_WIDTH(48)) sendcmd(sendcmd_busy,sendcmd_data_out,sendcmd_data_in,sendcmd_start,SCLK,reset_module);
		Waiter #(.COUNTER_SIZE(8)) waiter(waiter_busy,waiter_start,waiter_count_to,SCLK,reset_module);
		DeserializerWithCounter #(.DATA_LENGTH(7),.WORD_SIZE(8)) deseres(deseres_data_out,deseres_busy,deseres_RCO,deseres_start,deseres_data_in,SCLK,reset_module); //Deserializer for response1
		DeserializerWithCounter #(.DATA_LENGTH(39),.WORD_SIZE(8)) deseresr7(deseres7_data_out,deseres7_busy,deseres7_RCO,deseres7_start,deseres7_data_in,SCLK,reset_module); //Deserializer for response7

	//----------------------------------------------------------
	
	always @(posedge SCLK or posedge reset) begin
		if(reset) begin
			ps <= 0;
		end
		else begin
			ps <= ns;
		end
	end
	
	always @(*) begin
			case(ps)

				sIDLE : begin
					if(start) begin
						ns <= sSET_SPI_MODE;
					end
					else begin
						ns <= sIDLE;
					end
				end
				
				sSET_SPI_MODE : begin
					ns <= sWAIT_SET_SPI_MODE;
				end
				
				sWAIT_SET_SPI_MODE : begin
					if(waiter_busy) ns <= sWAIT_SET_SPI_MODE;
					else ns <= sSEND_CMD0;
				end
				
				sSEND_CMD0 : begin
					ns <= sRESPONSE_CMD0;
				end
				
				sRESPONSE_CMD0 : begin
					if(deseres_busy) ns <= sRESPONSE_CMD0;
					else ns <= sSET_CS_HIGH_CMD0;
				end
				
				sSET_CS_HIGH_CMD0 : begin
					//if(!deseres_busy)
					ns <= sSEND_CMD8;
				end
				
				sSEND_CMD8 : begin
					ns <= sRESPONSE_CMD8;
				end
				
				sRESPONSE_CMD8 : begin
					if(deseres7_busy) ns <= sRESPONSE_CMD8;
					else ns <= sSET_CS_HIGH_CMD8;
				end
				
				sSET_CS_HIGH_CMD8 : begin
						ns <= sSEND_CMD55;
				end
				
				sSEND_CMD1 : begin
					ns <= sRESPONSE_CMD1;
				end
				
				sRESPONSE_CMD1 : begin
					if(deseres_busy && waiter_busy) ns <= sRESPONSE_CMD1;
					else ns <= sSET_CS_HIGH_CMD1;
				end
				
				sSET_CS_HIGH_CMD1 : begin
					if(deseres_data_out[7] == 0 && !deseres_busy)
						ns <= sFINAL;
					else
						ns <= sSEND_CMD1;
				end
				
				sSEND_CMD55 : begin
					ns <= sRESPONSE_CMD55;
				end
				
				sRESPONSE_CMD55 : begin
					if(deseres_busy && waiter_busy) ns <= sRESPONSE_CMD55;
					else ns <= sSET_CS_HIGH_CMD55;
				end
				
				sSET_CS_HIGH_CMD55 : begin
					if(!deseres_busy)
						ns <= sSEND_CMD41;
					else
						ns <= sSEND_CMD55;
				end
				
				sSEND_CMD41 : begin
					ns <= sRESPONSE_CMD41;
				end
				
				sRESPONSE_CMD41 : begin
					if(deseres_busy && waiter_busy) ns <= sRESPONSE_CMD41;
					else ns <= sSET_CS_HIGH_CMD41;
				end
				
				sSET_CS_HIGH_CMD41 : begin
					if(!deseres_busy && (|deseres_data_out[7:1]) == 0)
						ns <= sSEND_CMD58;
					else 
						ns <= sSEND_CMD55;
				end
				
				sSEND_CMD58 : begin
					ns <= sRESPONSE_CMD58;
				end
				
				sRESPONSE_CMD58 : begin
					if(deseres7_busy) ns <= sRESPONSE_CMD58;
					else ns <= sSET_CS_HIGH_CMD58;
				end
				
				sSET_CS_HIGH_CMD58 : begin
					ns <= sFINAL;
				end
				
				sFINAL : begin
					ns <= sFINAL;
				end
				
				default : begin
					ns <= sIDLE;
				end
			endcase
	end
	always @(*) begin
		case(ps) 
			sSEND_CMD0  : sendcmd_data_in <= {1'b1,7'b010_1001,{32{1'b0}},6'b00_0000,2'b10};
			sSEND_CMD1  : sendcmd_data_in <= {48'b1000_0000_0000_0000_0000_0000_0000_0000_0000_0000_1000_0010};
			sSEND_CMD8  : sendcmd_data_in <= {48'b1110_0001_0101_0101_1000_0000_0000_0000_0000_0000_0001_0010};	
			sSEND_CMD55 : sendcmd_data_in <= {48'b1111_1111_0000_0000_0000_0000_0000_0000_0000_0000_1110_1110};
			sSEND_CMD41 : sendcmd_data_in <= {48'b1111_1111_0000_0000_0000_0000_0000_0000_0000_0010_1001_0110};
			sSEND_CMD58 : sendcmd_data_in <= {48'b1111_1111_0000_0000_0000_0000_0000_0000_0000_0000_0101_1110};
			default : sendcmd_data_in <= 48'hFFFF_FFFF_FFFF;
		endcase
	end
	

endmodule
