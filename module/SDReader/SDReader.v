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
	count_to,
	fifo_data_in,
	fifo_push,
	fifo_empty,
	fifo_available,
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
		input wire [7:0]count_to;
		
		output wire fifo_available;
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
	//wire [7:0]count_to; // TOEDIT
	
	wire [7:0]deseres7_data_out;
	wire deseres7_start;
	wire deseres7_data_in;
	wire [31:0] next_address;
	wire [7:0] next_counter;
	wire next_gotDATA_TOKEN;
	
	reg [47:0] sendcmd_data_in;
	reg [5:0] ns;
	reg [5:0] ps;
	reg [31:0] address;
	reg [7:0] counter;
	reg gotDATA_TOKEN;
	
	assign next_gotDATA_TOKEN = (ps == sDATA_CMD17 && desedata_data_out == 8'hFE) ? 1'b1 : 1'b0 ;
	//assign count_to = 10;
	
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
	
	assign next_address = (ps == sWAIT_CRC) ?  address + 32'h0000_0200 : address ;
	assign next_counter = (ps == sWAIT_CRC) ?  counter + 1 : counter;
	
	//assign fifo_data_in = 8'b0110_1010;
	assign fifo_data_in = desedata_data_out;
	assign fifo_push = desedata_RCO;
	assign fifo_available = (ps==sSEND_CMD17 ||ps==sRESPONSE_CMD17||ps==sCHECK_RES_CMD17||ps==sSTART_DESE_DATA_CMD17||ps==sDATA_CMD17||ps==sWAIT_CRC) ? 1'b0 : 1'b1;
	
	assign reset_module = (ps == sIDLE) ? 1'b1 : 1'b0;
	assign waiter_start = (ps == sWAIT_CRC || ps == sSEND_CMD17) ? 1'b1 : 1'b0;
	assign waiter_count_to = 8'h50;
	assign sendcmd_start = (ps == sSEND_CMD17) ? 1'b1 : 1'b0;
	
	//assign LED =  (ps == sFINAL) ? deseres7_data_out : deseres_data_out;
	//assign LED =  (ps == sFINAL) ? deseres7_data_out : {2'b11,ps};
	assign LED = desedata_data_out;
	//assign LED = desedata_data_out;
	//assign LED =  {fifo_empty,waiter_busy,ps};
	//assign LED = (ps == sFINAL) ? deseres_data_out : (ps == sRESPONSE_CMD0)? 8'hAA : 8'h66;
	//assign LED = {deseres_busy,waiter_busy,deseres_data_out[7],ps};
	//---------------------- Call Module -----------------------
		serializer #(.DATA_WIDTH(48)) sendcmd(sendcmd_busy,sendcmd_data_out,sendcmd_data_in,sendcmd_start,SCLK,reset_module);
		Waiter #(.COUNTER_SIZE(8)) waiter(waiter_busy,waiter_start,waiter_count_to,SCLK,reset_module);
		DeserializerWithCounter #(.DATA_LENGTH(7),.WORD_SIZE(8)) deseres(deseres_data_out,deseres_busy,deseres_RCO,deseres_start,MISO,SCLK,reset_module); //Deserializer for response1
		//DeserializerWithCounter #(.DATA_LENGTH(39),.WORD_SIZE(8)) deseresr7(deseres7_data_out,deseres7_busy,deseres7_RCO,deseres7_start,deseres7_data_in,SCLK,reset_module);
		DeserializerWithCounter #(.DATA_LENGTH(4096),.WORD_SIZE(8)) desedata(desedata_data_out,desedata_busy,desedata_RCO,desedata_start,MISO,SCLK,reset_module); //Deserializer for data block
	
	//----------------------------------------------------------
	
	always @(posedge SCLK or posedge reset) begin
		if(reset) begin
			counter <= 8'h00;
			address <= 32'h00_F0_00_00;
			ps <= sIDLE;
			gotDATA_TOKEN = 0;
		end
		else begin
			counter <= next_counter;
			address <= next_address;
			ps <= ns;
			gotDATA_TOKEN = next_gotDATA_TOKEN;
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
					ns <= sFINAL;
				end
			endcase
	end
	wire [47:0]aaa;
	assign aaa = {8'b01_010001,address,8'b1111_1111};
	always @(*) begin
		case(ps) 
			
			//01 010001 address 1111 1111
			sSEND_CMD17  : begin
				sendcmd_data_in[47] <= aaa[0];
sendcmd_data_in[46] <= aaa[1];
sendcmd_data_in[45] <= aaa[2];
sendcmd_data_in[44] <= aaa[3];
sendcmd_data_in[43] <= aaa[4];
sendcmd_data_in[42] <= aaa[5];
sendcmd_data_in[41] <= aaa[6];
sendcmd_data_in[40] <= aaa[7];
sendcmd_data_in[39] <= aaa[8];
sendcmd_data_in[38] <= aaa[9];
sendcmd_data_in[37] <= aaa[10];
sendcmd_data_in[36] <= aaa[11];
sendcmd_data_in[35] <= aaa[12];
sendcmd_data_in[34] <= aaa[13];
sendcmd_data_in[33] <= aaa[14];
sendcmd_data_in[32] <= aaa[15];
sendcmd_data_in[31] <= aaa[16];
sendcmd_data_in[30] <= aaa[17];
sendcmd_data_in[29] <= aaa[18];
sendcmd_data_in[28] <= aaa[19];
sendcmd_data_in[27] <= aaa[20];
sendcmd_data_in[26] <= aaa[21];
sendcmd_data_in[25] <= aaa[22];
sendcmd_data_in[24] <= aaa[23];
sendcmd_data_in[23] <= aaa[24];
sendcmd_data_in[22] <= aaa[25];
sendcmd_data_in[21] <= aaa[26];
sendcmd_data_in[20] <= aaa[27];
sendcmd_data_in[19] <= aaa[28];
sendcmd_data_in[18] <= aaa[29];
sendcmd_data_in[17] <= aaa[30];
sendcmd_data_in[16] <= aaa[31];
sendcmd_data_in[15] <= aaa[32];
sendcmd_data_in[14] <= aaa[33];
sendcmd_data_in[13] <= aaa[34];
sendcmd_data_in[12] <= aaa[35];
sendcmd_data_in[11] <= aaa[36];
sendcmd_data_in[10] <= aaa[37];
sendcmd_data_in[9] <= aaa[38];
sendcmd_data_in[8] <= aaa[39];
sendcmd_data_in[7] <= aaa[40];
sendcmd_data_in[6] <= aaa[41];
sendcmd_data_in[5] <= aaa[42];
sendcmd_data_in[4] <= aaa[43];
sendcmd_data_in[3] <= aaa[44];
sendcmd_data_in[2] <= aaa[45];
sendcmd_data_in[1] <= aaa[46];
sendcmd_data_in[0] <= aaa[47];
			end
			
			
			//sendcmd_data_in = rev_cmd17;
			//{8'b1111_1111,address[31:0],8'b100010_10};
			default : sendcmd_data_in <= 48'hFFFF_FFFF_FFFF;
		endcase
	end
endmodule