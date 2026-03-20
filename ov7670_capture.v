`timescale 1ns / 1ps
module ov7670_capture(
    input clk, input pclk_raw, input vsync_raw, input href_raw,
    input [7:0] d_raw, output reg [16:0] addr,
    output reg [15:0] dout, output reg we
);
    reg pclk_1, pclk_2, href_1, href_2, vsync_1, vsync_2;
    always @(posedge clk) begin
        pclk_1 <= pclk_raw; pclk_2 <= pclk_1;
        href_1 <= href_raw;  href_2 <= href_1;
        vsync_1 <= vsync_raw; vsync_2 <= vsync_1;
    end
    reg [1:0] state = 0;
    reg [15:0] pixel;
    always @(posedge clk) begin
        we <= 0;
        case (state)
            0: if (vsync_1 == 0 && vsync_2 == 1) begin state <= 1; addr <= 0; end
            1: begin
                if (vsync_1 && vsync_2) state <= 0;
                else if (pclk_1 && !pclk_2 && href_1 && href_2) begin
                    pixel[15:8] <= d_raw;
                    state <= 2;
                end
            end
            2: begin
                if (vsync_1 && vsync_2) state <= 0;
                else if (pclk_1 && !pclk_2 && href_1 && href_2) begin
                    dout <= {pixel[15:8], d_raw};
                    we <= 1; if (addr < 76800) addr <= addr + 1; state <= 1;
                end
            end
            default: state <= 0;
        endcase
    end
endmodule
