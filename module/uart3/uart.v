`include "../baudGenerator/baudGenerator.v"

module uart_receiver(
  output reg [7:0] o_8_data,
  output wire o_ready,
  input wire i_rx,
  input wire i_reset
  input wire i_clk,
);
  
  parameter bitDepth = 11;
	parameter adder = 170;
  
  parameter START_BIT = 1'b0;
  parameter sStartBit = 1'b0;
  parameter sDataBit  = 1'b1;
  
  // Vars 
	reg [3:0]ps;
	reg [3:0]ns;
	reg [4:0]baud_counter;
  
  // Module
  
	baudGenerator #(.bitDepth(bitDepth), .adder(adder))
    baudGen(i_clk, baud_clk);
    
	assign o_ready = (ps == {sDataBit,3'b111}) && baud_counter >= 8;
  
	always @( posedge baud_clk )begin
    if( i_reset ) begin
      ps = 3'b000;
    end else begin
		  ps = ns;
    end
	end
  
  always @( posedge baud_clk ) begin
    case(ps[3])
      sStartBit: begin
        if( baud_counter != 0 ) begin
          if( baud_counter == 16 ) begin
            baud_counter = 0;
          end else begin
            baud_counter = baud_counter+1;
          end
        end else begin
          if(i_rx == START_BIT)begin
            baud_counter = 1;
          end else begin
            baud_counter = 0; // Stuck at 0 if no start bit
          end
        end
      end
      sDataBit: begin
        if( baud_counter == 16 ) begin
          baud_counter = 0;
        end else begin
          baud_counter = baud_counter+1;
        end
      end
    endcase
  end
  
  always @( * ) begin
    case(ps[3])
      sStartBit: begin
        if(baud_counter==16)begin
          ns = {sDataBit,3'b000};
        end else begin
          ns = ps;
        end 
      end
      sDataBit: begin
        if(baud_counter==16)begin
          ns = ps+1;
        end else begin
          ns = ps;
        end
      end
    endcase
  end
  
  always @( posedge baud_clk or posedge nrst ) begin
    if( i_reset ) begin
      o_8_data = 8'b0000_0000;
    end else begin
      if( ps[3] == sDataBit && baud_counter == 8 ) begin
        o_8_data[ps[2:0]] = i_rx;
      end else begin
        o_8_data[ps[2:0]] = o_8_data[ps[2:0]];
      end
    end
  end
  
endmodule
