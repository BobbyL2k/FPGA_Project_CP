module DeserializerWithCounter(
        data_out,
        busy,
        RCO,
        start,
        data_in,
        clock,
        reset
    );

    parameter DATA_LENGTH = 16; // length of serial input
    parameter DATA_COUNTER_SIZE = $clog2(DATA_LENGTH)+1;
    parameter WORD_SIZE = 8;    // size of data_out and RCO will assert 1 at the end of word
    parameter WORD_COUNTER_SIZE = $clog2(WORD_SIZE)+1;
    parameter START_BIT = 1'b0;
	 
		function integer clog2;
		input integer value;
		begin 
		value = value-1;
		for (clog2=0; value>0; clog2=clog2+1)
		value = value>>1;
		end 
		endfunction

    input wire data_in;
    input wire clock;
    input wire reset;
    input wire start;

    output wire [WORD_SIZE-1 : 0] data_out;
    output wire RCO;
    output wire busy;

    reg [WORD_SIZE-1 : 0]data;
    reg [WORD_COUNTER_SIZE-1:0]counter;
    reg [DATA_COUNTER_SIZE-1:0]data_counter;
    reg [3:0]ps;
    reg [3:0]ns;

    wire [WORD_COUNTER_SIZE-1:0]added_word_counter;
    wire [WORD_COUNTER_SIZE-1:0]next_counter;
    wire [DATA_COUNTER_SIZE-1:0]added_data_counter;
    wire [DATA_COUNTER_SIZE-1:0]next_data_counter;
    wire lastBitInWord;
    wire lastBitInData;
    wire [WORD_SIZE-1 : 0]next_data;

    assign added_word_counter = counter + 1;
    assign added_data_counter = data_counter + 1;
    assign next_counter = (ps == 2 && !lastBitInWord) ? added_word_counter : (ps == 2) ? {{WORD_COUNTER_SIZE-1{1'b0}},{1'b1}} : {WORD_COUNTER_SIZE{1'b0}};
    assign next_data_counter = (ps == 2) ? added_data_counter : {DATA_COUNTER_SIZE{1'b0}};
    assign next_data = (ps == 2 && ns != 1'b0) ? {data_in,data[WORD_SIZE-1 : 1]} : data;
    assign lastBitInWord = (counter == WORD_SIZE) ? 1'b1 : 1'b0;
    assign lastBitInData = (data_counter == DATA_LENGTH) ? 1'b1 : 1'b0;
    assign RCO = lastBitInWord;
    assign busy = (ps == 4'b0001 || ps == 4'b0010 || start) ? 1'b1 : 1'b0;
    assign data_out = data;

    initial begin
        ps <= 0;
        counter <= 0;
        data <= 0;
        data_counter <= 0;
    end

    always @(posedge clock or posedge reset) begin
        if(reset) begin
            ps <= 0;
            counter <= 0;
            data <= 0;
            data_counter <= 0;
        end
        else begin
            ps <= ns;
            counter <= next_counter;
            data <= next_data;
            data_counter <= next_data_counter;
        end
    end

    always @(*) begin
        case(ps)
            4'b0000 : begin
                    if(start) begin
                        ns <= 4'b0001;
                    end
                    else begin
                        ns <= 4'b0000;
                    end
            end

            4'b0001 : begin
                    if(data_in == START_BIT) begin
                        ns <= 4'b0010;
                    end
                    else begin
                        ns <= 4'b0001;
                    end
            end

            4'b0010 : begin
                    if(lastBitInData) begin
                        ns <= 4'b0000;
                    end
                    else begin
                        ns <= 4'b0010;
                    end
            end

            default : begin
                ns <= 4'b0000;
            end
        endcase
    end
endmodule
