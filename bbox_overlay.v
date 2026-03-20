`timescale 1ns / 1ps
module bbox_overlay (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [9:0]  vga_h,
    input  wire [9:0]  vga_v,
    input  wire [11:0] frame_pixel,
    input  wire [8:0]  bbox_min_x, bbox_max_x,
    input  wire [7:0]  bbox_min_y, bbox_max_y,
    input  wire        bbox_valid,
    output wire [11:0] pixel_out
);
    localparam H_OFFSET = 10'd160;
    localparam V_OFFSET = 10'd120;
    localparam [3:0] BORDER = 4'd3;

    wire [10:0] box_left   = {2'b0, bbox_min_x} + {1'b0, H_OFFSET};
    wire [10:0] box_right  = {2'b0, bbox_max_x} + {1'b0, H_OFFSET};
    wire [10:0] box_top    = {3'b0, bbox_min_y} + {1'b0, V_OFFSET};
    wire [10:0] box_bottom = {3'b0, bbox_max_y} + {1'b0, V_OFFSET};

    wire [10:0] h = {1'b0, vga_h};
    wire [10:0] v = {1'b0, vga_v};

    wire on_top    = (v >= box_top)    && (v < box_top + BORDER)    && (h >= box_left) && (h <= box_right);
    wire on_bottom = (v <= box_bottom) && (v > box_bottom - BORDER) && (h >= box_left) && (h <= box_right);
    wire on_left   = (h >= box_left)   && (h < box_left + BORDER)   && (v >= box_top)  && (v <= box_bottom);
    wire on_right  = (h <= box_right)  && (h > box_right - BORDER)  && (v >= box_top)  && (v <= box_bottom);
    wire on_border = on_top || on_bottom || on_left || on_right;

    assign pixel_out = (bbox_valid && on_border) ? 12'hF00 : frame_pixel;
endmodule
