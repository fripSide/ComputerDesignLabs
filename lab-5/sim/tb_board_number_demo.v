`timescale 1ns / 1ps

module tb_board_number_demo;

reg clk;
reg rstn;
reg [15:0] sw_i;
wire [15:0] led_o;
wire [7:0] disp_seg_o;
wire [7:0] disp_an_o;
integer errors;

board_number_demo #(
    .SCAN_DIV_BITS(2)
) dut (
    .clk(clk),
    .rstn(rstn),
    .sw_i(sw_i),
    .led_o(led_o),
    .disp_seg_o(disp_seg_o),
    .disp_an_o(disp_an_o)
);

initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
end

task expect;
    input condition;
    input [255:0] message;
    begin
        if (!condition) begin
            $display("[FAIL] %0s", message);
            errors = errors + 1;
        end
    end
endtask

task step;
    begin
        @(posedge clk);
        #1;
    end
endtask

initial begin
    errors = 0;
    rstn = 1'b0;
    sw_i = 16'h1234;

    repeat (2) step();
    rstn = 1'b1;

    step();
    expect(led_o == 16'h1234, "LEDs must mirror switch value 0x1234");

    repeat (4) step();
    expect(disp_an_o == 8'b11111101, "scan should advance to digit 1 after the first tick");
    expect(disp_seg_o == 8'hB0, "digit 1 should display hex 3 for 0x1234");

    sw_i = 16'hABCD;
    step();
    expect(led_o == 16'hABCD, "LEDs must mirror switch value 0xABCD");

    repeat (4) step();
    expect(disp_an_o == 8'b11111011, "scan should advance to digit 2 after the second tick");
    expect(disp_seg_o == 8'h83, "digit 2 should display hex B for 0xABCD");

    repeat (4) step();
    expect(disp_an_o == 8'b11110111, "scan should advance to digit 3 after the third tick");
    expect(disp_seg_o == 8'h88, "digit 3 should display hex A for 0xABCD");

    repeat (4) step();
    expect(disp_an_o == 8'b11101111, "scan should advance to digit 4 after the fourth tick");
    expect(disp_seg_o == 8'hC0, "upper digit should display zero");

    if (errors == 0)
        $display("[PASS] lab-5 board number demo checks passed.");
    else
        $display("[FAIL] lab-5 board number demo checks failed with %0d error(s).", errors);

    $finish;
end

endmodule
