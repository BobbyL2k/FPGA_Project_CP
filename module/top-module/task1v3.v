`include "../PushButton_Debouncer/PushButton_Debouncer.v"
`include "../single_pulser/single_pulser.v"
`include "../uart2/uart.v"
`include "../interfpga/interfpga.v"
`include "../crc8/crc8.v"
`include "../digi/digit.v"

module task1_pc_from_to_fpga_crcfpga(
  // System
  input wire clk,
  // interfpga
  input wire i_rx_fpga,
  output wire o_tx_fpga,
  // serial port
  input wire i_rx_pc,
  output wire o_tx_pc,
  // crc8
  output wire [7:0] o_8_led,
  // push button
  input wire pb_reset,
  input wire pb_start,
  input wire pb_debug,
  // 7seg
  output wire [10:0] dg
);

  assign o_tx_pc = i_rx_fpga;
  assign o_tx_fpga = i_rx_pc;

  // Vars
  
  wire 
    db_reset,
    db_start,
    db_debug,
    uart_data_ready,
    sp_uart_data_ready;
  wire [7:0]
    io_8_uart_data,
	 crc8;
  reg [7:0]
    data_counter;

  // Modules
  
  PushButton_Debouncer
    reset_db(
      .clk(clk),
      .PB(pb_reset),
      .PB_state(db_reset)
    ),
    start_db(
      .clk(clk),
      .PB(pb_start),
      .PB_state(db_start) // unpluged
    ),
    debug_db(
      .clk(clk),
      .PB(pb_debug),
      .PB_state(db_debug) // unpluged
    );
    
  single_pulser
    uart_data_ready_sp(
      .signal_in(uart_data_ready),
      .signal_out(sp_uart_data_ready),
      .clk(clk),
      .reset(db_reset)
    );

  uart_receiver #(
    .FULL_buad(2603),
	 .HALF_buad(200))
    uartR(
      .o_8_data(io_8_uart_data),
      .o_ready(uart_data_ready),
      .i_clear_ready(sp_uart_data_ready),
      .i_rx(i_rx_fpga),
      .i_reset(db_reset),
      .i_clk(clk)
    );

  crc 
    crc_module(
      .data_in(io_8_uart_data),
      .crc_en(sp_uart_data_ready),
      .crc_out(crc8),
      .rst(db_reset),
      .clk(clk)
    );
	 
  digit
    digit_module(
	   clk,
		{data_counter, crc8},
		dg,
		~db_reset
    );
	 
	 reg [7:0] l_data;
	 assign o_8_led = l_data;
	 
	 always @( posedge clk or posedge db_reset ) begin
		if( db_reset ) begin
		  l_data = 0;
	   end else begin
		  if( sp_uart_data_ready ) begin
		    l_data = io_8_uart_data;
		  end else begin
		    l_data = l_data;
		  end
		end
	 end
	 
	 always @( posedge clk or posedge db_reset ) begin
		if( db_reset ) begin
		  data_counter = 0;
		end else begin
		  if( sp_uart_data_ready ) begin
			 data_counter = data_counter + 1;
		  end else begin
			 data_counter = data_counter;
		  end
		end
	 end

endmodule // task1_pc_from_to_fpga

module task1_pc_from_to_fpga_crcpc(
  // System
  input wire clk,
  // interfpga
  input wire i_rx_fpga,
  output wire o_tx_fpga,
  // serial port
  input wire i_rx_pc,
  output wire o_tx_pc,
  // crc8
  output wire [7:0] o_8_led,
  // push button
  input wire pb_reset,
  input wire pb_start,
  input wire pb_debug,
  // 7seg
  output wire [10:0] dg
);

  assign o_tx_pc = i_rx_fpga;
  assign o_tx_fpga = i_rx_pc;

  // Vars
  
  wire 
    db_reset,
    db_start,
    db_debug,
    uart_data_ready,
    sp_uart_data_ready;
  wire [7:0]
    io_8_uart_data,
	 crc8;
  reg [7:0]
    data_counter;

  // Modules
  
  PushButton_Debouncer
    reset_db(
      .clk(clk),
      .PB(pb_reset),
      .PB_state(db_reset)
    ),
    start_db(
      .clk(clk),
      .PB(pb_start),
      .PB_state(db_start) // unpluged
    ),
    debug_db(
      .clk(clk),
      .PB(pb_debug),
      .PB_state(db_debug) // unpluged
    );
    
  single_pulser
    uart_data_ready_sp(
      .signal_in(uart_data_ready),
      .signal_out(sp_uart_data_ready),
      .clk(clk),
      .reset(db_reset)
    );

  uart_receiver  #(
    .FULL_buad(2603),
	 .HALF_buad(200))
    uartR(
      .o_8_data(io_8_uart_data),
      .o_ready(uart_data_ready),
      .i_clear_ready(sp_uart_data_ready),
      .i_rx(i_rx_pc),
      .i_reset(db_reset),
      .i_clk(clk)
    );

  crc 
    crc_module(
      .data_in(io_8_uart_data),
      .crc_en(sp_uart_data_ready),
      .crc_out(crc8),
      .rst(db_reset),
      .clk(clk)
    );

  digit
    digit_module(
	   clk,
		{data_counter, crc8},
		dg,
		~db_reset
    );
	 
	 reg [7:0] l_data;
	 assign o_8_led = l_data;
	 
	 always @( posedge clk or posedge db_reset ) begin
		if( db_reset ) begin
		  l_data = 0;
	   end else begin
		  if( sp_uart_data_ready ) begin
		    l_data = io_8_uart_data;
		  end else begin
		    l_data = l_data;
		  end
		end
	 end
	 
	 always @( posedge clk or posedge db_reset ) begin
		if( db_reset ) begin
		  data_counter = 0;
		end else begin
		  if( sp_uart_data_ready ) begin
			 data_counter = data_counter + 1;
		  end else begin
			 data_counter = data_counter;
		  end
		end
	 end

endmodule // task1_pc_from_to_fpga

module task1_pc2fpga(
  // System
  input wire clk,
  // interfpga
  output wire [3:0] o_data_line,
  output wire o_control_line,
  // serial port
  input wire i_rx,
  output wire o_tx,
  // crc8
  output wire [7:0] o_8_crc8,
  // push button
  input wire pb_reset,
  input wire pb_start,
  input wire pb_debug
);

  assign o_tx = 1'b1; // uart stop bit

  // Vars
  
  wire 
    db_reset,
    db_start,
    db_debug,
    uart_data_ready,
    sp_uart_data_ready,
    interfpga_send_busy,
    sp_interfpga_send_busy;
  wire [7:0]
    io_8_uart_data;


  // Modules
  
  PushButton_Debouncer
    reset_db(
      .clk(clk),
      .PB(pb_reset),
      .PB_state(db_reset)
    ),
    start_db(
      .clk(clk),
      .PB(pb_start),
      .PB_state(db_start) // unpluged
    ),
    debug_db(
      .clk(clk),
      .PB(pb_debug),
      .PB_state(db_debug) // unpluged
    );
    
  single_pulser
    uart_data_ready_sp(
      .signal_in(uart_data_ready),
      .signal_out(sp_uart_data_ready),
      .clk(clk),
      .reset(db_reset)
    ),
    interfpga_send_busy_sp(
      .signal_in(interfpga_send_busy),
      .signal_out(sp_interfpga_send_busy),
      .clk(clk),
      .reset(db_reset)
    );

  uart_receiver 
    uartR(
      .o_8_data(io_8_uart_data),
      .o_ready(uart_data_ready),
      .i_clear_ready(sp_interfpga_send_busy),
      .i_rx(i_rx),
      .i_reset(db_reset),
      .i_clk(clk)
    );
  
  interfpga_send
    interSend(
      .data(io_8_uart_data),
      .send(sp_uart_data_ready),
      .busy(interfpga_send_busy),
      .data_o(o_data_line),
      .ctrl_o(o_control_line),
      .reset(db_reset),
      .clk(clk)
    );

  crc 
    crc_module(
      .data_in(io_8_uart_data),
      .crc_en(sp_uart_data_ready),
      .crc_out(o_8_crc8),
      .rst(db_reset),
      .clk(clk)
    );

endmodule // task1_pc2fpga

module task1_fpga2pc(
  // System
  input wire clk,
  // interfpga
  input wire [3:0] i_data_line,
  input wire i_control_line,
  // serial port
  input wire i_rx, // unpluged
  output wire o_tx,
  // crc8
  output wire [7:0] o_8_crc8,
  // push button
  input wire pb_reset,
  input wire pb_start,
  input wire pb_debug
);

  // Vars
  
  wire 
    interfpga_data_ready,
    sp_interfpga_data_ready,
    uart_transmitter_busy,
    sp_uart_transmitter_busy,
    db_reset,
    db_start,
    db_debug;
  wire [7:0]
    io_8_interfpga_data;

  // Modules
  
  PushButton_Debouncer
    reset_db(
      .clk(clk),
      .PB(pb_reset),
      .PB_state(db_reset)
    ),
    start_db(
      .clk(clk),
      .PB(pb_start),
      .PB_state(db_start) // unpluged
    ),
    debug_db(
      .clk(clk),
      .PB(pb_debug),
      .PB_state(db_debug) // unpluged
    );
  
  single_pulser
    interfpga_data_ready_sp(
      .signal_in(interfpga_data_ready),
      .signal_out(sp_interfpga_data_ready),
      .clk(clk),
      .reset(db_reset)
    ),
    uart_transmitter_busy_sp(
      .signal_in(uart_transmitter_busy),
      .signal_out(sp_uart_transmitter_busy),
      .clk(clk),
      .reset(db_reset)
    );
  
  interfpga_receive
    interReceive(
      .data(io_8_interfpga_data),
      .ready(interfpga_data_ready),
      .reset_ready(sp_uart_transmitter_busy),
      .data_i(i_data_line),
      .ctrl_i(i_control_line),
      .reset(db_reset),
      .clk(clk)
    );
  
  uart_transmitter
    uartT(
      .data(io_8_interfpga_data),
      .busy(uart_transmitter_busy),
      .send(sp_interfpga_data_ready),
      .tx_o(o_tx),
      .reset(db_reset),
      .clk(clk)
    );

  crc 
    crc_module(
      .data_in(io_8_interfpga_data),
      .crc_en(sp_interfpga_data_ready),
      .crc_out(o_8_crc8),
      .rst(db_reset),
      .clk(clk)
    );
    
endmodule // task1_fpga2pc