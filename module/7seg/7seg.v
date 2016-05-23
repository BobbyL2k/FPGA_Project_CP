module binary_to_7s(
    input [3:0] num,
    output [7:0] ss
    );
    reg [7:0]SevenSeg;
    assign ss=SevenSeg;
    always@(*)
    begin
        case(num)
        4'h0: SevenSeg = 8'b11111100;
        4'h1: SevenSeg = 8'b01100000;
        4'h2: SevenSeg = 8'b11011010;
        4'h3: SevenSeg = 8'b11110010;
        4'h4: SevenSeg = 8'b01100110;
        4'h5: SevenSeg = 8'b10110110;
        4'h6: SevenSeg = 8'b10111110;
        4'h7: SevenSeg = 8'b11100000;
        4'h8: SevenSeg = 8'b11111110;
        4'h9: SevenSeg = 8'b11110110;
        4'hA: SevenSeg = 8'b11101110;
        4'hB: SevenSeg = 8'b00111110;
        4'hC: SevenSeg = 8'b10011100;
        4'hD: SevenSeg = 8'b01111010;
        4'hE: SevenSeg = 8'b10011110;
        4'hF: SevenSeg = 8'b10001110;
        default: SevenSeg = 8'b00000000;
        endcase
    end
endmodule
