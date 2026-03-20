`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: red_detector
//
// Strict color thresholding on RGB444 pixels to find red objects.
// A pixel is "red" only if:
//   - R channel is very strong (>= 12 out of 15)
//   - G and B channels are very low (<= 4)
//   - R dominates both G and B by a large margin
//
// Strict thresholds to avoid false positives from noise.
//////////////////////////////////////////////////////////////////////////////////

module red_detector (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        pixel_valid,
    input  wire [11:0] pixel,         // RGB444: {R[3:0], G[3:0], B[3:0]}
    
    output reg         is_red,
    output reg         out_valid
);

    wire [3:0] r = pixel[11:8];
    wire [3:0] g = pixel[7:4];
    wire [3:0] b = pixel[3:0];
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            is_red    <= 1'b0;
            out_valid <= 1'b0;
        end else begin
            out_valid <= pixel_valid;
            
            if (pixel_valid) begin
                // Strict red detection:
                //   R must be very strong (12+ out of 15)
                //   G and B must be weak (4 or less)
                //   R must exceed G and B by at least 6
                is_red <= (r >= 4'd8) && 
                          (g <= 4'd6)  && 
                          (b <= 4'd6)  &&
                          (r > g + 4'd4) &&
                          (r > b + 4'd4);
            end else begin
                is_red <= 1'b0;
            end
        end
    end

endmodule
