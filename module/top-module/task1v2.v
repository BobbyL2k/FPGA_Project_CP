`include "../uart2/uart.v"
`include "../single_pulser/single_pulser.v"
`include "../PushButton_Debouncer/PushButton_Debouncer.v"
`include "../7seg/7seg.v"

module uart_pc_2_pc(
  input wire clk,
  input wire rx,
  output wire tx,
  input wire reset,
  output reg tr_received,
  output wire m_data_ready,
  output wire m_ut_busy
);

  // Real World
  parameter IN_FREQ = 220052; // Expected internal clock frequncy
  parameter OUT_FREQ = 96;    // Baud Rate
  // For Simulation
  // parameter IN_FREQ = 20;
  // parameter OUT_FREQ = 1;
  
  wire tr_received_n;
  assign tr_received_n = ~tr_received;
  
  wire clock;
  assign clock = clk;
  
  wire [7:0] 
    data;     // data received from PC by uart_receive
  wire 
    db_reset,     // debounced reset signal
    // dummy_tx,  // dummy tx wire
    data_ready,   // data received and ready
    tr_send,      // trigger send signal from (uart_receive posedge data_ready) 
    ut_busy,      // uart transmitter being busy sending data to PC
    tr_reset_ready; // trigger send signal from (uart_transmitter posedge busy) 
    
  assign m_data_ready = data_ready;
  assign m_ut_busy = ut_busy;
  
  always @( posedge clock or posedge db_reset ) begin
    if( db_reset ) begin
      tr_received = 1;
    end else if( tr_send ) begin
      tr_received = tr_received_n;
    end
  end
  
  PushButton_Debouncer reset_db(
      .clk(clock),
      .PB(reset),
      .PB_state(db_reset)
	  );
    
  single_pulser send_sp(
    .signal_in(data_ready),
    .signal_out(tr_send),
    .clk(clock),
    .reset(db_reset)
  );/*,busy_sp(
    .signal_in(ut_busy),
    .signal_out(tr_reset_ready),
    .clk(clock),
    .reset(db_reset)
  );*/
	
  uart_receiver #(
      .HALF_buad(650),
      .FULL_buad(1302)) 
    uartr(
      .o_8_data(data),
      .o_ready(data_ready),
    //   .i_clear_ready(tr_reset_ready),
      .i_clear_ready(ut_busy),
      .i_rx(rx),
      .i_reset(db_reset),
      .i_clk(clock)
    );
  
  uart_transmitter #(
      .IN_FREQ(IN_FREQ),
      .OUT_FREQ(OUT_FREQ)) 
    uartt(
      .data(dataR),
      .busy(ut_busy),
      .send(tr_send),
      .tx_o(tx),
      .reset(db_reset),
      .clk(clock)
    );

endmodule // uart_pc_2_pc

module uart_pc_2_fpga_led(
  input wire clk,
  input wire rx,
  output wire tx,
  input wire reset,
  output wire [7:0] led,
  output wire [7:0] data_seg,
  output wire [3:0] segSelect
);

  wire data_ready, tr_busy, db_reset, ut_busy;
  reg data_tr;
  assign led = {data_ready, tr_busy, data_tr, ut_busy, 5'b1010};

  PushButton_Debouncer reset_db(
      .clk(clk),
      .PB(reset),
      .PB_state(db_reset)
	  );
    
  single_pulser busy_sp(
    .signal_in(ut_busy),
    .signal_out(tr_busy),
    .clk(clk),
    .reset(db_reset)
  ), ready_sp(
    .signal_in(data_ready),
    .signal_out(tr_ready),
    .clk(clk),
    .reset(db_reset)
  );
  
  always @( posedge clk or posedge db_reset ) begin
    if( db_reset ) begin
      data_tr = 1'b0;
    end else begin
      if( tr_busy )
        data_tr = ~data_tr;
      else
        data_tr = data_tr;
    end
  end
	
  wire [7:0] dataR;
  wire [7:0] data;
  assign dataR = {data[0],data[1],data[2],data[3],
						      data[4],data[5],data[6],data[0]};
  
  uart_receiver #(
      .HALF_buad(651),
      .FULL_buad(2603)) 
    uartr(
      .o_8_data(data),
      .o_ready(data_ready),
      .i_clear_ready(tr_ready),
      .i_rx(rx),
      .i_reset(db_reset),
      .i_clk(clk)
    );
	 
  
  parameter IN_FREQ = 220052; // Expected internal clock frequncy
  //parameter IN_FREQ = 250000; // Expected internal clock frequncy
  parameter OUT_FREQ = 96;    // Baud Rate
  
  //assign tx = 1'b1;
  uart_transmitter #(
      .IN_FREQ(IN_FREQ),
      .OUT_FREQ(OUT_FREQ)) 
    uartt(
      .data(dataR),
      .busy(ut_busy),
      .send(data_ready),
      .tx_o(tx),
      .reset(db_reset),
      .clk(clk)
    );
    	 
  reg [4:0] c_segSelect_msb;
	 
  /* debugging 7 seg
  reg [32:0] datam;

  always @( posedge clk ) begin
  datam = datam+1;
  end

  wire [7:0] datax;
  assign datax = datam[32:25];
  */
	 
  always @( posedge clk ) begin
    c_segSelect_msb = c_segSelect_msb+1;
  end

  assign segSelect = {~c_segSelect_msb[4],c_segSelect_msb[4],2'b11};
  reg [3:0] data_feed;

  always @( * ) begin
  if( c_segSelect_msb[4] ) begin
    data_feed = dataR[7:4];
  end else begin
    data_feed = dataR[3:0];
  end 
  end

  binary_to_7s ss(
    .num(data_feed),
    .ss(data_seg)
  );

endmodule // uart_pc_2_fpga_led