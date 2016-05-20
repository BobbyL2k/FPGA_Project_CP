module Waiter(
        busy,
        start,
        count_to,
        clock,
        reset
    );

    parameter COUNTER_SIZE = 8;


    output wire busy;

    input wire start;
    input wire [COUNTER_SIZE-1 : 0] count_to;
    input wire clock;
    input wire reset;

    reg [COUNTER_SIZE-1 : 0] counter;
    reg [COUNTER_SIZE-1 : 0] counter_to;
    reg ps;

    wire ns;
    wire[COUNTER_SIZE-1 : 0] next_counter;

    assign next_counter = (ps == 1) ? counter+1 : {{COUNTER_SIZE-1{1'b0}},{1'b1}};
    assign ns = ((ps==1'b1 && counter != counter_to) || (start && ps==1'b0))  ? 1'b1 : 1'b0;
    assign busy = ps || start;

    initial begin
        ps = 0;
        counter = 0;
        counter_to = 0;
    end

    always @(posedge clock or posedge reset) begin
        if(reset) begin
            ps <= 0;
            counter <= 0;
            counter_to <= 0;
        end
        else begin
            ps <= ns;
            counter <= next_counter;
            counter_to <= count_to;
        end
    end

endmodule
