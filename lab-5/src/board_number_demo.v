`timescale 1ns / 1ps

module board_number_demo #(
    parameter SCAN_DIV_BITS = 15
)(
    input clk,
    input rstn,
    input [15:0] sw_i,
    output [15:0] led_o,
    output [7:0] disp_seg_o,
    output [7:0] disp_an_o
);

wire [31:0] display_data;

assign led_o = sw_i;
assign display_data = {16'h0000, sw_i};

scan_7seg #(
    .SCAN_DIV_BITS(SCAN_DIV_BITS)
) U_SCAN_7SEG (
    .clk(clk),
    .rstn(rstn),
    .data(display_data),
    .disp_seg_o(disp_seg_o),
    .disp_an_o(disp_an_o)
);

endmodule
