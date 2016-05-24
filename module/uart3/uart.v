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
	 
	baudGenerator #(.bitDepth(bitDepth), .adder(adder))
		readBauder(clk,sub_baud);
	reg [3:0]ps;
	reg [3:0]ns;
	reg [2:0]rx_s;
	reg [8:0]baud_acc;
	reg [31:0]deb;
	wire rx_c = (rx_s[0]+rx_s[1]+rx_s[2])>=2; // Majority vote to prevent noise spike
  wire baud_8 = ~(baud_acc[3] | baud_acc[3] | baud_acc[3]);
  wire baud_16 = ~(baud_8 | baud_acc[3]);
	assign data_ready = ps == 4'b1111 && baud_acc >= 8;
	always @(posedge sub_baud)begin
	if(!nrst)begin
		ns = 0;
		baud_acc=0;
		rx_s = 3'b111;
		data = 8'b00000000;
		deb=0;
	end
	else begin
		rx_s = {rx_s[1:0],rx};
		case(ps[3])
			1'b0:begin
				if(baud_acc==16)begin
					baud_acc = 0;
					ns = 4'b1000;
				end
				else if(baud_acc!=0)begin
					baud_acc=baud_acc+1;
				end
				else if(!rx)begin
					baud_acc=1;
				end
			end
			1'b1:begin
				deb[30]=1;
				baud_acc=ns == 0 ? 0 : baud_acc+1;
				if(baud_acc==8)data[ps[2:0]] = rx;
				if(baud_acc==16)begin
					baud_acc=0;
					ns=ps+1;
				end
			end
		endcase
	end
	end
	always @(posedge sub_baud)begin
		ps = ns;
	end
endmodule
