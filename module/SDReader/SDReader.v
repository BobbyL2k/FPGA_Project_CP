`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:25:11 05/22/2016 
// Design Name: 
// Module Name:    SDReader_new 
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
module SDReader(
	reset,
	start,
	MISO,
	CS,
	SCLK,
	MOSI,
	busy,
	//count_to,
	fifo_data_in,
	fifo_push,
	fifo_empty,
	LED
    );
	 
	 //---------------------- Define State ----------------------
		parameter sIDLE = 6'b000000;
		
		parameter sWAIT_FIFO_EMPTY_CMD17 = 6'b00_0001;
		parameter sSEND_CMD17 = 6'b00_0010;
		parameter sRESPONSE_CMD17 = 6'b00_0011;
		parameter sDATA_CMD17 = 6'b00_0100;
		parameter sEND_CMD17 = 6'b00_0101;
		parameter sWAIT_CRC = 6'b00_0110;
		parameter sSTART_DESE_DATA_CMD17 = 6'b00_0111;
		parameter sCHECK_RES_CMD17 = 6'b00_1000;
		
		parameter sFINAL = 6'b11_1111;
	//----------------------------------------------------------

		parameter startAddress = 32'h0000_0000;		//32 bit
		parameter bitPerDataPacket = 16'b0001_0000_0000_0000;		//512*8 = 4096 bit per dataPacket

	//---------------------- Input/Output ----------------------
		input wire reset;
		input wire start;
		input wire MISO;
		input wire fifo_empty;
		input wire SCLK;
		//input wire count_to;
		
		output wire CS;
		output wire MOSI;
		output wire busy;
		output wire [7:0] fifo_data_in;
		output wire fifo_push;
	
		output wire [7:0]LED;
	//----------------------------------------------------------

	wire reset_module;
	wire waiter_count_to;
	wire waiter_start;
	wire sendcmd_start;
	wire sendcmd_busy;
	wire sendcmd_data_out;
	wire d_clock;
	wire [7:0] desedata_data_out;
	wire desedata_RCO;
	wire [7:0]deseres_data_out;
	wire deseres_busy;
	wire waiter_busy;
	wire [7:0]count_to; // TOEDIT
	
	wire [7:0]deseres7_data_out;
	wire deseres7_start;
	wire deseres7_data_in;
	wire [31:0] next_address;
	wire [7:0] next_counter;
	
	reg [47:0] sendcmd_data_in;
	reg [5:0] ns;
	reg [5:0] ps;
	reg [31:0] address;
	reg [7:0] counter;
	
	assign count_to = 1;
	
	assign MOSI = (sendcmd_busy) ? sendcmd_data_out : 1'b1;
	//assign CS = (ps == sSET_SPI_MODE || ps == sWAIT_SET_SPI_MODE || ps == sSET_CS_HIGH_CMD0 
	//				|| ps == sSET_CS_HIGH_CMD8 || ps == sSET_CS_HIGH_CMD1 || ps == sSET_CS_HIGH_CMD55 || ps == sSET_CS_HIGH_CMD55) ? 1'b1 : 1'b0;
	assign CS = 1'b0;
	assign busy = (ps == sIDLE) ? 1'b0 : 1'b1;
	
	assign deseres_data_in = MISO;
	assign desdata_data_in = MISO;
	//assign deseres7_data_in = MISO;
	
	assign deseres_start = (ps == sSEND_CMD17)? 1'b1 : 1'b0;
	//assign deseres7_start = (ps == sSEND_CMD8 || ps == sSEND_CMD58) ? 1'b1 : 1'b0;
	assign desedata_start = (ps == sSTART_DESE_DATA_CMD17)? 1'b1 : 1'b0;
	
	assign next_address = (sWAIT_CRC) ?  address + 32'h0000_0200 : address ;
	assign next_counter = (sWAIT_CRC) ?  counter + 1 : counter;
	
	assign fifo_data_in = desedata_data_out;
	assign fifo_push = desedata_RCO;
	
	assign reset_module = (ps == sIDLE) ? 1'b1 : 1'b0;
	assign waiter_start = (ps == sWAIT_CRC || ps == sSEND_CMD17) ? 1'b1 : 1'b0;
	assign waiter_count_to = 8'h50;
	assign sendcmd_start = (ps == sSEND_CMD17) ? 1'b1 : 1'b0;
	
	//assign LED =  (ps == sFINAL) ? deseres7_data_out : deseres_data_out;
	//assign LED =  (ps == sFINAL) ? deseres7_data_out : {2'b11,ps};
	assign LED =  {start,reset,ps};
	//assign LED = (ps == sFINAL) ? deseres_data_out : (ps == sRESPONSE_CMD0)? 8'hAA : 8'h66;
	//assign LED = {deseres_busy,waiter_busy,deseres_data_out[7],ps};
	//---------------------- Call Module -----------------------
		serializer #(.DATA_WIDTH(48)) sendcmd(sendcmd_busy,sendcmd_data_out,sendcmd_data_in,sendcmd_start,SCLK,reset_module);
		Waiter #(.COUNTER_SIZE(8)) waiter(waiter_busy,waiter_start,waiter_count_to,SCLK,reset_module);
		DeserializerWithCounter #(.DATA_LENGTH(7),.WORD_SIZE(8)) deseres(deseres_data_out,deseres_busy,deseres_RCO,deseres_start,deseres_data_in,SCLK,reset_module); //Deserializer for response1
		//DeserializerWithCounter #(.DATA_LENGTH(39),.WORD_SIZE(8)) deseresr7(deseres7_data_out,deseres7_busy,deseres7_RCO,deseres7_start,deseres7_data_in,SCLK,reset_module);
		DeserializerWithCounter #(.DATA_LENGTH(4096),.WORD_SIZE(8)) desedata(desedata_data_out,desedata_busy,desedata_RCO,desedata_start,desedata_data_in,SCLK,reset_module); //Deserializer for data block
	
	//----------------------------------------------------------
	
	always @(posedge SCLK or posedge reset) begin
		if(reset) begin
			counter <= 8'h00;
			address <= 32'h00_00_00_00;
			ps <= sIDLE;
		end
		else begin
			counter <= next_counter;
			address <= next_address;
			ps <= ns;
		end
	end
	
	always @(*) begin
			case(ps)
			
				sIDLE : begin
					if(start) begin
						ns <= sWAIT_FIFO_EMPTY_CMD17;
						//ns <= sFINAL;
					end
					else begin
						ns <= sIDLE;
					end
				end
				
				sWAIT_FIFO_EMPTY_CMD17 : begin
					if(counter == count_to) 
						ns <= sFINAL;
					else if(fifo_empty && !waiter_busy)
						ns <= sSEND_CMD17;
					else 
						ns <= sWAIT_FIFO_EMPTY_CMD17;
				end
				
				sSEND_CMD17 : begin
					ns <= sRESPONSE_CMD17;
				end
				
				sRESPONSE_CMD17 : begin
					if(deseres_busy && waiter_busy) ns <=  sRESPONSE_CMD17;
					else ns <= sCHECK_RES_CMD17;
				end
				
				sCHECK_RES_CMD17 : begin
					if(deseres_busy) ns <= sSEND_CMD17;
					else ns <= sSTART_DESE_DATA_CMD17;
				end
				
				sSTART_DESE_DATA_CMD17 : begin
					ns <= sDATA_CMD17;
				end
				
				sDATA_CMD17 : begin
					if(desedata_busy) ns <= sDATA_CMD17;
					else ns <= sWAIT_CRC;
				end
				
				sWAIT_CRC : begin
					ns <= sWAIT_FIFO_EMPTY_CMD17;
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
			sSEND_CMD17  : sendcmd_data_in <= {48'b1000_0000_0000_0000_0000_0000_0000_0000_0000_0000_1000_0010};
			default : sendcmd_data_in <= 48'hFFFF_FFFF_FFFF;
		endcase
	end
endmodule