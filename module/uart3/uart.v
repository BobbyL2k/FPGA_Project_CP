`include "../uart3/baudGenerator.v"

module uart_receiver(
  input rx,
  output reg [7:0] data,
  output data_ready,
  input clk,
  input nrst
);
     
  parameter bitDepth = 11;
  parameter adder = 170;
  
  parameter sActiveCheck = 1'b0;
  parameter sDataRead    = 1'b1;
  
  parameter START_BIT = 1'b0;
  
  parameter half_baud = 8;
  parameter full_baud = 16;

  baudGenerator #(.bitDepth(bitDepth), .adder(adder))
    readBauder(clk, d_clk);
    
  wire d_clk;
    
  reg [3:0] c_state, n_state;
  reg [4:0] sub_baud_counter;
  
  assign data_ready = c_state == {sDataRead, 3'b111} && sub_baud_counter >= half_baud;
  
  always @( posedge d_clk )begin
    if(!nrst)begin
      n_state = {sActiveCheck, 3'b000};
      sub_baud_counter = 5'b0_0000;
      data = 8'b00000000;
    end else begin
      case(c_state[3])
        sActiveCheck : begin
          if( sub_baud_counter == full_baud )begin
            sub_baud_counter = 5'b0_0000;
            n_state = {sDataRead, 3'b000};
          end
          else if( sub_baud_counter != 0 )begin
            sub_baud_counter = sub_baud_counter+1;
          end
          else if( rx == START_BIT )begin
            sub_baud_counter = = 5'b0_0001;
          end
        end
        sDataRead : begin
          sub_baud_counter= n_state == 0 ? 0 : sub_baud_counter+1;
          if( sub_baud_counter == half_baud )
            data[c_state[2:0]] = rx;
          if( sub_baud_counter == full_baud )begin
            sub_baud_counter = 5'b0_0000;
            n_state = c_state + 1;
          end
        end
      endcase
    end
  end
  
  always @(posedge d_clk)begin
    c_state = n_state;
  end
endmodule
