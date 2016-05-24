`include "../PushButton_Debouncer/PushButton_Debouncer.v"
`include "../uart2/uart.v"
`include "../single_pulser/single_pulser.v"
`include "../fifo/RWFIFO.v"
`include "../FIFO/DualPortRam.v"
`include "../SDReader/SDCardInitializer.v"
`include "../SDReader/SDReader.v"
`include "../waiter/waiter.v"
`include "../deserializer_with_counter/DeserializerWithCounter.v"

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
	i_rx,
	debug,
	reset,
	clock,
	start,
	MISO,
	CS,
	SCLK,
	MOSI,
	busy,
	LED,
  dip_switch
    );
	 
		parameter sIDLE = 5'b00000;
		parameter sINNITIAL = 5'b00001;
		parameter sWAIT_INNITIAL = 5'b00010; 
		parameter sREADER = 5'b00011; 
		parameter sWAIT_READER = 5'b00100; 
		
		parameter sFINAL = 5'b11111;
	 
	 
		input wire reset;
		input wire clock;
		input wire start;
		input wire MISO;
		input wire debug;
    input wire[7:0] dip_switch;
		
		output wire tx_o;
		output wire CS;
		output wire SCLK;
		output wire MOSI;
		output wire busy;
		//output wire [7:0] fifo_data_in;
		//output wire fifo_push;
		output wire [7:0] LED;
		
		
		wire card_ready,initial_MOSI,initial_CS,initial_start,d_clock;
		wire reader_start,reader_CS,reader_MOSI,reader_busy;
		wire reset_module;
    wire start_module;
		wire [7:0] LED_WRITE;
		wire fifo_empty, fifo_available, uart_transmitter_busy;
		wire [7:0] fifo_data_in;
		wire [7:0] fifo_data_out;
		wire fifo_full;
		
		//wire [7:0] dummy;
		
		//assign dummy = 8'b1000_1110;
		//assign dummy = fifo_data_out;
		
		reg [4:0] ns;
		reg [4:0] ps;
		
		assign start_module = ( ps == sINNITIAL ) ? 1'b1 : 1'b0;
		assign CS = 1'b0;
		assign SCLK = d_clock;
		assign MOSI = (ps==sWAIT_INNITIAL && !card_ready)? initial_MOSI : (ps==sWAIT_READER && reader_busy)? reader_MOSI : 1'b1; // please fix
		assign busy = (ps == sIDLE)? 1'b0 : 1'b1;
		
		assign reset_module = (ps == sIDLE) ? 1'b1 : 1'b0;
		assign initial_start = (ps == sINNITIAL)? 1'b1 : 1'b0;
		assign reader_start = (ps == sREADER)? 1'b1 : 1'b0;
		
		assign uart_transmitter_send = (!fifo_empty && fifo_available) ? 1'b1 : 1'b0;
		assign fifo_pop = ~uart_transmitter_busy;
		
		//assign LED = (ps == sFINAL) ? {fifo_data_in} : {8'hA4};
		//assign LED = {card_ready,reader_busy,1'b1,ps};
		//assign LED = fifo_data_in;
		assign LED = (debug) ? LED_WRITER : {fifo_available,fifo_empty,fifo_full,ps} ;
		clock_divider #(.IN_FREQ(50),.OUT_FREQ(1))clkdiv(clock,d_clock,reset_PB_down);
		PushButton_Debouncer Debouncer_start(d_clock,start,start_PB_state,start_PB_down,start_PB_up);
		PushButton_Debouncer Debouncer_reset(clock,reset,reset_PB_state,reset_PB_down,reset_PB_up);
		
		// Real World
		parameter IN_FREQ = 220052; // Expected internal clock frequncy
		parameter OUT_FREQ = 96;    // Baud Rate

		single_pulser fifo_push_sp(uart_data_ready,sp_fifo_push,clock,reset_PB_down);
		single_pulser fifo_pop_sp(fifo_pop,sp_fifo_pop,clock,reset_PB_down);
		fifo ff(
				.data_count(fifo_data_count),
				.data_out(fifo_data_count),
				.empty(fifo_empty),
				.busy(fifo_busy),
				.full(fifo_full),
				.data_in(l_8_uart_data),
				.push(sp_fifo_push),
				.pop(sp_fifo_pop),
				.reset(reset_PB_down),
				.clock(clock)
    );
    /// UART
    wire [7:0] l_8_uart_data;
    wire uart_data_ready, sp_uart_data_ready;
		
    single_pulser 
      uart_data_ready_sp(
        .signal_in(uart_data_ready),
        .signal_out(sp_uart_data_ready),
        .clk(SCLK),
        .reset(reset)
      );
    
		uart_receiver
			uartR(
				.i_rx(i_rx),
				.o_8_data(l_8_uart_data),
				.o_data_ready(uart_data_ready),
				.i_clk(clock),
				.i_reset(reset)
			);
    /// END UART
		
		SDCardInitializer sdcardinitializer(card_ready,initial_MOSI,initial_CS,initial_start,reset_module,d_clock,MISO);
		SDWriter sdWriter(
      .i_reset(reset_module),
      .i_start(start_module),
      .i_s_clk(d_clock),
      .o_busy(sdWrite_busy),
      .MISO(MISO),
      .dip_switch(dip_switch),
      .MOSI(MOSI),
      .o_fifo_pop(fifo_pop),
      .i_8_fifo_data_out(fifo_data_out),
      .i_fifo_data_count(fifo_data_count), // number of data in FIDO
      .o_8_LED(LED_WRITER)
    );
    
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
					if(card_ready) ns <= sREADER;
					else ns <= sWAIT_INNITIAL;
				end
				
				sREADER : begin
					ns <= sWAIT_READER;
				end
        
				sWAIT_READER : begin
					if(reader_busy || !fifo_empty) ns <= sWAIT_READER;
					else ns <= sFINAL;
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
