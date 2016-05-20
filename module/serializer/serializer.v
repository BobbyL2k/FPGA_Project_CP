module serializer(
    busy,
    data_out,
    data_in,
    start,
    clock,
    reset
    );

    parameter DATA_WIDTH = 8;
    parameter COUNTER_SIZE = clog2(DATA_WIDTH)+1;
	 
	 function integer clog2;
		input integer value;
		begin 
		value = value-1;
		for (clog2=0; value>0; clog2=clog2+1)
		value = value>>1;
		end 
		endfunction

    output wire busy;
    output wire data_out;

    input [DATA_WIDTH-1:0]data_in;
    input wire start;
    input wire clock;
    input wire reset;

    reg ps;
    reg [DATA_WIDTH-1:0]data;
    reg [COUNTER_SIZE-1:0]counter;

    wire ns;
    wire [COUNTER_SIZE-1:0]next_counter;

    assign next_counter = (ps==1) ? counter + 1 : {COUNTER_SIZE{1'b0}};
    assign ns = (counter == DATA_WIDTH && ps == 1'b1) ? 1'b0 : 1'b1;
    assign data_out = (ps == 1) ? data[0] : 1'b1;
    assign busy = ps;

    always @(posedge clock or reset) begin
        if(reset) begin
            ps <= 0;
            counter <= {{COUNTER_SIZE-1{1'b0}},1'b1};
            data <= data_in;
        end
        else if(start && ps == 1'b0) begin
            ps <= 1'b1;
            counter <= {{COUNTER_SIZE-1{1'b0}},1'b1};
            data <= data;
        end
        else if(ps == 1'b1) begin
            ps <= ns;
            counter <= next_counter;
            data <= {data[0],data[DATA_WIDTH-1:1]};
        end
        else begin
            ps <= 1'b0;
            data <= data_in;
            counter <= {{COUNTER_SIZE-1{1'b0}},1'b1};
        end
    end

endmodule
