`timescale 1ns / 1ps

module scan_7seg #(
    parameter SCAN_DIV_BITS = 15
)(
    input clk,
    input rstn,
    input [31:0] data,
    output [7:0] disp_seg_o,
    output reg [7:0] disp_an_o
);

reg [SCAN_DIV_BITS-1:0] scan_cnt;
reg [2:0] digit_sel;
reg [3:0] digit_data;
wire scan_tick;

assign scan_tick = &scan_cnt;

always @(posedge clk or negedge rstn) begin
    if (!rstn)
        scan_cnt <= {SCAN_DIV_BITS{1'b0}};
    else
        scan_cnt <= scan_cnt + 1'b1;
end

always @(posedge clk or negedge rstn) begin
    if (!rstn)
        digit_sel <= 3'b000;
    else if (scan_tick)
        digit_sel <= digit_sel + 1'b1;
end

always @(*) begin
    case (digit_sel)
        3'd0: begin disp_an_o = 8'b11111110; digit_data = data[3:0]; end
        3'd1: begin disp_an_o = 8'b11111101; digit_data = data[7:4]; end
        3'd2: begin disp_an_o = 8'b11111011; digit_data = data[11:8]; end
        3'd3: begin disp_an_o = 8'b11110111; digit_data = data[15:12]; end
        3'd4: begin disp_an_o = 8'b11101111; digit_data = data[19:16]; end
        3'd5: begin disp_an_o = 8'b11011111; digit_data = data[23:20]; end
        3'd6: begin disp_an_o = 8'b10111111; digit_data = data[27:24]; end
        3'd7: begin disp_an_o = 8'b01111111; digit_data = data[31:28]; end
        default: begin disp_an_o = 8'b11111111; digit_data = 4'h0; end
    endcase
end

hex_to_7seg U_HEX_TO_7SEG(
    .hex(digit_data),
    .seg(disp_seg_o)
);

endmodule
