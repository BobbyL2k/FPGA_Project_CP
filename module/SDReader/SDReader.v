`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    23:32:43 05/20/2016 
// Design Name: 
// Module Name:    SDReader
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

	parameter sFINAL = 5'b11111;
//----------------------------------------------------------


	parameter startAddress = 32'h0000_0000;		//32 bit
	parameter bitPerDataPacket = 16'b0001_0000_0000_0000;		//512*8 = 4096 bit per dataPacket

//---------------------- Input/Output ----------------------
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
//----------------------------------------------------------

//-------------------------- Wire --------------------------
	wire d_clock;
	wire sendcmd_busy;
	wire sendcmd_data_out;
	wire waiter_busy;
	
	wire [7:0] deseres_data_out;
	wire deseres_busy,deseres_RCO;
	wire [7:0] desedata_data_out;
	wire desedata_busy,desedata_RCO;
	wire deseres_data_in;
	wire desedata_data_in;
	
	wire [19:0] num_DataPacket;
//----------------------------------------------------------

//-------------------------- Reg ---------------------------
	reg [4:0] ps;
	reg [4:0] ns;
	
	reg [19:0] count_DataPacket;
	reg [47:0] sendcmd_data_in;		//CMD Command frame 48bit
	reg sendcmd_start;
	reg waiter_start;
	reg [7:0] waiter_count_to;		   //number of d_clock for wait (max 8 bit)
	reg [31:0] address;					//address 32bit of SDCard for read
	
	reg deseres_start;
	reg desedata_start;
//----------------------------------------------------------

//------------------------ Assign --------------------------
	assign MOSI = (sendcmd_busy)? sendcmd_data_out : 1'b1;
	assign CS = (ps == sSET_SPI_MODE)? 1'b1 : 1'b0;
	assign SCLK = d_clock;
	assign busy = (ps == sIDLE)? 1'b0 : 1'b1;
	
	assign deseres_data_in = MISO;
	assign desedata_data_in = MISO;
	
	assign fifo_data_in = desedata_data_out;
	assign fifo_push = desedata_RCO;
	
	//LED
	assign LED = {3'b000,ps};
	
	assign num_DataPacket = 16'b0000_0000_0000_1000; // round = Mbyte(from DPSwitch) / 512 Byte //8
	//assign num_data = 24'b0100_0000_0000_0000;// 0 to 512 * 8 =  4096
//----------------------------------------------------------

//---------------------- Call Module -----------------------
	clock_divider #(.IN_FREQ(250),.OUT_FREQ(2))clkdiv(clock,d_clock,reset);
	serializer #(.DATA_WIDTH(48)) sendcmd(sendcmd_busy,sendcmd_data_out,sendcmd_data_in,sendcmd_start,d_clock,reset);
	Waiter #(.COUNTER_SIZE(8)) waiter(waiter_busy,waiter_start,waiter_count_to,d_clock,reset);
	DeserializerWithCounter #(.DATA_LENGTH(7),.WORD_SIZE(8)) deseres(deseres_data_out,deseres_busy,deseres_RCO,deseres_start,deseres_data_in,d_clock,reset); //Deserializer for response1
	DeserializerWithCounter #(.DATA_LENGTH(4096),.WORD_SIZE(8)) desedata(desedata_data_out,desedata_busy,desedata_RCO,desedata_start,desedata_data_in,d_clock,reset); //Deserializer for data block
	//fifo Fifo(fifo_front,fifo_rear,fifo_state,fifo_data_out,fifo_empty,fifo_busy,fifo_full,fifo_data_in,fifo_push,fifo_pop,reset,clock);
//----------------------------------------------------------

	initial begin
		ps <= 0;
		ns <= 0;
		count_DataPacket <= {20{1'b0}};
		sendcmd_data_in <= {48{1'b0}};		
		sendcmd_start <= 1'b0;
		waiter_start <= 1'b0;
		waiter_count_to <= {8{1'b0}};
		address <= {32{1'b0}};
		deseres_start <= 1'b0;
		desedata_start <= 1'b0;
	end
	
	
	always @ (posedge clock or posedge reset) begin
		if(reset) ps <= 0;
		else ps <= ns;
	end

	always @( * ) begin
		case(ps)
			sIDLE : begin
			//---------- Reset Value -----------
				count_DataPacket <= {20{1'b0}};
				sendcmd_data_in <= {48{1'b0}};		
				sendcmd_start <= 1'b0;
				waiter_start <= 1'b0;
				waiter_count_to <= {8{1'b0}};
				address <= {32{1'b0}};
				deseres_start <= 1'b0;
				desedata_start <= 1'b0;
			//-----------------------------------
				if(start) ns <= sSET_SPI_MODE;
				else ns <= ps;			
			end
			sSET_SPI_MODE : begin
				//use module waiter 74+ d_clock
				waiter_count_to <= 8'b0101_0000; //80 d_clock
				waiter_start <= 1'b1;
				
				ns <= sWAIT_SET_SPI_MODE;
			end
			sWAIT_SET_SPI_MODE : begin
				waiter_start <= 1'b0;
				
				if(waiter_busy) ns <= ps;
				else ns <= sSEND_CMD0;
			end
			sSEND_CMD0 : begin
				sendcmd_start <= 1'b1;
				sendcmd_data_in <= {2'b01,6'b00_0000,{32{1'b0}},7'b000_0000,1'b1}; //CMD0
				deseres_start <= 1'b1;
				
				ns <= sRESPONSE_CMD0;
			end
			sRESPONSE_CMD0 : begin
				sendcmd_start <= 1'b0;
				deseres_start <= 1'b0;
				
				if(deseres_busy) ns <= ps;
				else ns <= 	sSEND_CMD1;
			end
			sSEND_CMD1 : begin
				sendcmd_start <= 1'b1;
				sendcmd_data_in <= {2'b01,6'b00_0001,{32{1'b0}},7'b000_0000,1'b1}; //CMD1
				deseres_start <= 1'b1;
				
				ns <= sRESPONSE_CMD1;
			end
			sRESPONSE_CMD1 : begin
				sendcmd_start <= 1'b0;
				deseres_start <= 1'b0;
				
				if(deseres_busy) ns <= ps;
				else ns <= 	sCHECK;
			end
			sCHECK : begin
				
				if(count_DataPacket == num_DataPacket) ns <= sIDLE;
				else ns <= sSEND_CMD17;
			end
			sSEND_CMD17 : begin
				sendcmd_start <= 1'b1;
				sendcmd_data_in <= {2'b01,6'b01_0001,address,7'b000_0000,1'b1}; //CMD1
				deseres_start <= 1'b1;
				
				ns <= sRESPONSE_CMD17;
			end
			sRESPONSE_CMD17 : begin
				sendcmd_start <= 1'b0;
				deseres_start <= 1'b0;
				
				if(deseres_busy) ns <= ps;
				else ns <= 	sWAIT_DATA;
			end
			sWAIT_DATA : begin
				desedata_start <= 1'b1;
				ns <= sGET_DATA;
			end
			sGET_DATA : begin
				desedata_start <= 1'b0;
				
				//if(desedata_RCO) push(desedata_data_out) to FIFO //8bit
				
				if(desedata_busy) begin
					ns <= ps;
					waiter_start <= waiter_start;
					waiter_count_to <= waiter_count_to;
				end
				else begin
					ns <= sWAIT_NEXT_CHECK;
					//use module waiter 16+ d_clock for CRC
					waiter_count_to <= 8'b0001_1000; //24 d_clock
					waiter_start <= 1'b1;
				end
			end
			sWAIT_NEXT_CHECK : begin
				waiter_start <= 1'b0;
				
				if(waiter_busy) begin
					ns <= ps;
				end
				else begin
					ns <= sCHECK;
					count_DataPacket <= count_DataPacket + 1;
					address <= address + 32'b0000_0000_0000_0010_0000_0000_0000; //512
				end
			end
			sFINAL : begin
				ns <= sIDLE;
			end
			default : begin
				ns <= sIDLE;
			end
		endcase
	end
endmodule