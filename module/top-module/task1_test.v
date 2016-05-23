`include "task1.v"

module task1_test();

  reg clk, rx, reset;
  wire tx;

  task1_t_test t1(
    .clk(clk),
    .rx(rx),
    .tx(tx),
    .reset(reset)
  );
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(3);
    
    reset = 0;
    rx = 0;
    #100
    reset = 1;
    rx = 1;
    #100
    reset = 0;
    #100
    
    #10000 $finish;
  end

  parameter PERIOD = 20;
  
  always begin
    clk = 1'b0;
    #(PERIOD/2)
    clk = 1'b1;
    #(PERIOD/2);
  end

endmodule // task1_test

module uart_pc_2_pc_test();

  reg [7:0] pc_data;
  wire _pc_busy, _pc_tx, _pc_rx;
  reg pc_send, pc_reset, pc_clk;
  
  reg reset_fpgas;
  reg fpga1_clk, fpga2_clk;

  uart_transmitter uartt_simulate_pc(
    .data(pc_data),
    .busy(_pc_busy),
    .send(pc_send),
    .tx_o(_pc_tx),
    .reset(pc_reset),
    .clk(pc_clk)
  );
  
  uart_pc_2_pc #(
    .IN_FREQ(20),
    .OUT_FREQ(1)
  )uartpc2pc(
    .clk(fpga1_clk),
    .rx(_pc_tx),
    .tx(_pc_rx),
    .reset(reset_fpgas)
  );
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0);
    
    reset_fpgas = 0;
    
    pc_send = 0;
    pc_reset = 0;
    pc_clk = 0;
    pc_data = 8'b0000_0000;
    
    #100
    reset_fpgas = 1;
    pc_reset = 1;
    #100
    reset_fpgas = 0;
    pc_reset = 0;
    #100
    
    pc_data = 8'b1111_1010;
    #20
    pc_send = 1;
    #4000
    pc_data = 8'b1111_0000;
    #400
    #4000
    pc_data = 8'b1111_1111;
    #400
    #4000
    pc_data = 8'b0000_0000;
    // pc_send = 0;
    #20000
    
    #10000 $finish;
    
  end
  
  parameter PERIOD = 20;
  parameter SHIFT1 = 5;
  parameter SHIFT2 = 5;

  always begin
    pc_clk = 1'b0;
    #(SHIFT1)
    fpga1_clk = 1'b1;
    #(SHIFT2)
    fpga2_clk = 1'b1;
    #(PERIOD/2 - SHIFT1 - SHIFT2)
    pc_clk = 1'b1;
    #(SHIFT1)
    fpga1_clk = 1'b0;
    #(SHIFT2)
    fpga2_clk = 1'b0;
    #(PERIOD/2 - SHIFT1 - SHIFT2);
  end

endmodule // uart_pc_2_pc_test