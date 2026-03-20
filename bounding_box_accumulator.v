`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: bounding_box_accumulator
//
// Tracks the bounding box of all detected red pixels during a frame scan.
// Maintains min_x, max_x, min_y, max_y registers.
//
// On frame_start: resets to extremes (min=MAX, max=0).
// On frame_done:  latches if bbox meets minimum size requirement.
//
// Minimum size filter: rejects bounding boxes smaller than MIN_SIZE pixels
// in both width and height. This prevents noise from triggering false positives.
//////////////////////////////////////////////////////////////////////////////////

module bounding_box_accumulator (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        frame_start,
    input  wire        frame_done,
    
    input  wire        edge_pixel,     // Detection flag (red pixel)
    input  wire        in_valid,
    input  wire [8:0]  pixel_x,        // 0-319
    input  wire [7:0]  pixel_y,        // 0-239
    
    output reg  [8:0]  bbox_min_x,
    output reg  [8:0]  bbox_max_x,
    output reg  [7:0]  bbox_min_y,
    output reg  [7:0]  bbox_max_y,
    output reg         bbox_valid
);

    // Minimum bounding box size (in pixels) to count as valid detection
    localparam MIN_WIDTH  = 10;
    localparam MIN_HEIGHT = 10;

    // Working registers
    reg [8:0] work_min_x, work_max_x;
    reg [7:0] work_min_y, work_max_y;
    reg       work_found;
    reg [15:0] pixel_count;  // Count of detected pixels this frame
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            work_min_x  <= 9'd319;
            work_max_x  <= 9'd0;
            work_min_y  <= 8'd239;
            work_max_y  <= 8'd0;
            work_found  <= 1'b0;
            pixel_count <= 16'd0;
            
            bbox_min_x <= 9'd0;
            bbox_max_x <= 9'd0;
            bbox_min_y <= 8'd0;
            bbox_max_y <= 8'd0;
            bbox_valid <= 1'b0;
        end else begin
            // Reset at start of new frame
            if (frame_start) begin
                work_min_x  <= 9'd319;
                work_max_x  <= 9'd0;
                work_min_y  <= 8'd239;
                work_max_y  <= 8'd0;
                work_found  <= 1'b0;
                pixel_count <= 16'd0;
            end
            
            // Accumulate bounding box
            if (in_valid && edge_pixel) begin
                work_found <= 1'b1;
                pixel_count <= pixel_count + 1'b1;
                
                if (pixel_x < work_min_x) work_min_x <= pixel_x;
                if (pixel_x > work_max_x) work_max_x <= pixel_x;
                if (pixel_y < work_min_y) work_min_y <= pixel_y;
                if (pixel_y > work_max_y) work_max_y <= pixel_y;
            end
            
            // Latch at end of frame, with size filter
            if (frame_done) begin
                if (work_found &&
                    (work_max_x - work_min_x) >= MIN_WIDTH &&
                    (work_max_y - work_min_y) >= MIN_HEIGHT &&
                    pixel_count >= 16'd100) begin
                    // Valid detection: meets minimum size and pixel count
                    bbox_min_x <= work_min_x;
                    bbox_max_x <= work_max_x;
                    bbox_min_y <= work_min_y;
                    bbox_max_y <= work_max_y;
                    bbox_valid <= 1'b1;
                end else begin
                    // Too small or no detection — clear bbox
                    bbox_valid <= 1'b0;
                end
            end
        end
    end

endmodule
