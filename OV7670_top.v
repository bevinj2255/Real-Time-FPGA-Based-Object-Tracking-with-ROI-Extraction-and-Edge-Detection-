`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: OV7670_top — RESCUE VERSION
// 
// *** CHANGE USE_TEST_PATTERN TO 1 TO VERIFY VGA PATH ***
// If test pattern shows clean bars → VGA+BRAM fine → problem is camera side
// If test pattern also broken → VGA or BRAM problem
//////////////////////////////////////////////////////////////////////////////////

module OV7670_top(
    input sys_clk_pin,
    input sys_rst_n_pin,

    output              sioc,
    inout               siod,

    input pclk,
    input vsync,
    input href,
    input [7:0] data_pin,
    
    output [7:0] led_pin,
    output xclk,
    output pwdn,
    output reset_pin,
    
    output h_sync, v_sync,  
    output [3:0] R, G, B
);
    
    // ==========================================================
    // >>>  SET TO 1 TO USE TEST PATTERN, 0 FOR CAMERA  <<<
    // ==========================================================
    parameter USE_TEST_PATTERN = 0;  // <<< COLOR BAR TEST MODE
    
    //==========================================================================
    // Clocks
    //==========================================================================
    wire clk_100, clk_25, pll_locked;
    
    clk_gen_wrapper u_clk_gen_wrapper (
        .clk_100 (clk_100),
        .clk_25  (clk_25),
        .clk_in1 (sys_clk_pin),
        .locked  (pll_locked),
        .reset   (~sys_rst_n_pin)
    );
    
    //==========================================================================
    // Startup Delay — 0.5s after PLL lock
    //==========================================================================
    reg [25:0] startup_cnt = 0;
    reg system_ready = 0;
    
    always @(posedge clk_100) begin
        if (!pll_locked) begin
            startup_cnt <= 0;
            system_ready <= 0;
        end else if (!system_ready) begin
            if (startup_cnt == 26'd50_000_000)
                system_ready <= 1;
            else
                startup_cnt <= startup_cnt + 1'b1;
        end
    end
    
    //==========================================================================
    // Camera Outputs
    //==========================================================================
    assign xclk      = clk_25;
    assign pwdn      = 1'b0;
    assign reset_pin = 1'b1;
    
    //==========================================================================
    // Camera I2C Initialization
    //==========================================================================
    wire config_done;
    
    ov7670_init u_ov7670_init (
        .iCLK       (clk_100),
        .iRST_N     (system_ready),
        .I2C_SCLK   (sioc),
        .I2C_SDAT   (siod),
        .Config_Done(config_done)
    );
    
    //==========================================================================
    // Camera Capture (always instantiated, just muxed out in test mode)
    //==========================================================================
    wire        cap_we;
    wire [16:0] cap_addr;
    wire [15:0] cap_pixel;
    
    ov7670_capture u_capture (
        .clk       (clk_100),
        .pclk_raw  (pclk),
        .vsync_raw (vsync),
        .href_raw  (href),
        .d_raw     (data_pin),
        .addr      (cap_addr),
        .dout      (cap_pixel),
        .we        (cap_we)
    );
    
    wire [11:0] cap_rgb444 = {cap_pixel[15:12], cap_pixel[10:7], cap_pixel[4:1]};
    
    //==========================================================================
    // Test Pattern Generator — 8 vertical color bars
    // Writes 320×240 pixels into BRAM once on startup
    //==========================================================================
    reg        tp_we   = 0;
    reg [16:0] tp_addr = 0;
    reg [11:0] tp_data = 0;
    reg        tp_done = 0;
    
    // Column calculation: col = addr mod 320
    wire [8:0] tp_col = tp_addr % 320;
    
    always @(posedge clk_25) begin
        if (!pll_locked) begin
            tp_addr <= 0;
            tp_we   <= 0;
            tp_done <= 0;
            tp_data <= 0;
        end else if (!tp_done) begin
            tp_we <= 1'b1;
            
            // 8 color bars (40 pixels each)
            if      (tp_col < 40)  tp_data <= 12'hFFF;  // White
            else if (tp_col < 80)  tp_data <= 12'hFF0;  // Yellow
            else if (tp_col < 120) tp_data <= 12'h0FF;  // Cyan
            else if (tp_col < 160) tp_data <= 12'h0F0;  // Green
            else if (tp_col < 200) tp_data <= 12'hF0F;  // Magenta
            else if (tp_col < 240) tp_data <= 12'hF00;  // Red
            else if (tp_col < 280) tp_data <= 12'h00F;  // Blue
            else                   tp_data <= 12'h000;  // Black
            
            if (tp_addr == 17'd76799) begin
                tp_done <= 1;
                tp_we   <= 0;
            end else begin
                tp_addr <= tp_addr + 1'b1;
            end
        end else begin
            tp_we <= 0;
        end
    end
    
    //==========================================================================
    // BRAM — mux between camera and test pattern
    //==========================================================================
    wire        bram_we    = USE_TEST_PATTERN ? tp_we    : cap_we;
    wire [16:0] bram_waddr = USE_TEST_PATTERN ? tp_addr  : cap_addr;
    wire [11:0] bram_wdata = USE_TEST_PATTERN ? tp_data  : cap_rgb444;
    wire        bram_wclk  = USE_TEST_PATTERN ? clk_25   : clk_100;
    
    wire [16:0] vga_addr;
    wire [11:0] vga_pixel;
    
    vram_wrapper u_vram (
        .BRAM_PORTA_addr (bram_waddr),
        .BRAM_PORTA_clk  (bram_wclk),
        .BRAM_PORTA_din  (bram_wdata),
        .BRAM_PORTA_en   (1'b1),
        .BRAM_PORTA_we   (bram_we),
        .BRAM_PORTB_addr (vga_addr),
        .BRAM_PORTB_clk  (clk_25),
        .BRAM_PORTB_dout (vga_pixel),
        .BRAM_PORTB_en   (1'b1)
    );
    
    //==========================================================================
    // VGA Display — get counters first
    //==========================================================================
    wire [9:0] vga_hcount, vga_vcount;
    //==========================================================================
    // Red Detection — runs on each pixel from BRAM (CLK_25 domain)
    //==========================================================================
    wire red_detected;
    wire red_valid;
    
    wire in_active_area = (vga_hcount >= 160 && vga_hcount < 480 &&
                           vga_vcount >= 120 && vga_vcount < 360);
    
    red_detector u_red_det (
        .clk         (clk_25),
        .rst_n       (pll_locked),
        .pixel_valid (in_active_area),
        .pixel       (vga_pixel),
        .is_red      (red_detected),
        .out_valid   (red_valid)
    );
    
    //==========================================================================
    // Pixel X/Y coordinates (in 320x240 camera space)
    // Derived from VGA counters with offsets
    //==========================================================================
    wire [8:0] pixel_x = vga_hcount - 10'd160;  // 0-319
    wire [7:0] pixel_y = vga_vcount - 10'd120;  // 0-239
    
    //==========================================================================
    // Frame sync — detect VGA VSYNC edges for frame_start/frame_done
    //==========================================================================
    reg vsync_vga_d1, vsync_vga_d2;
    always @(posedge clk_25) begin
        vsync_vga_d1 <= v_sync;
        vsync_vga_d2 <= vsync_vga_d1;
    end
    wire frame_start = vsync_vga_d1 && !vsync_vga_d2;  // VSYNC rising edge
    wire frame_done  = !vsync_vga_d1 && vsync_vga_d2;   // VSYNC falling edge
    
    //==========================================================================
    // Bounding Box Accumulator — single box tracking
    //==========================================================================
    wire [8:0] bbox_min_x, bbox_max_x;
    wire [7:0] bbox_min_y, bbox_max_y;
    wire       bbox_valid;
    
    bounding_box_accumulator u_bbox_acc (
        .clk         (clk_25),
        .rst_n       (pll_locked),
        .frame_start (frame_start),
        .frame_done  (frame_done),
        .edge_pixel  (red_detected),
        .in_valid    (in_active_area),
        .pixel_x     (pixel_x),
        .pixel_y     (pixel_y),
        .bbox_min_x  (bbox_min_x),
        .bbox_max_x  (bbox_max_x),
        .bbox_min_y  (bbox_min_y),
        .bbox_max_y  (bbox_max_y),
        .bbox_valid  (bbox_valid)
    );
    
    //==========================================================================
    // Bounding Box Overlay — draws red rectangle on VGA
    //==========================================================================
    wire [11:0] overlay_pixel;
    
    bbox_overlay u_bbox_overlay (
        .clk         (clk_25),
        .rst_n       (pll_locked),
        .vga_h       (vga_hcount),
        .vga_v       (vga_vcount),
        .frame_pixel (vga_pixel),
        .bbox_min_x  (bbox_min_x),
        .bbox_max_x  (bbox_max_x),
        .bbox_min_y  (bbox_min_y),
        .bbox_max_y  (bbox_max_y),
        .bbox_valid  (bbox_valid),
        .pixel_out   (overlay_pixel)
    );
    
    //==========================================================================
    // VGA Module
    //==========================================================================
    vga u_vga (
        .clk25       (clk_25),
        .vga_red     (R),
        .vga_green   (G),
        .vga_blue    (B),
        .vga_hsync   (h_sync),
        .vga_vsync   (v_sync),
        .frame_addr  (vga_addr),
        .frame_pixel (overlay_pixel),
        .hcount_out  (vga_hcount),
        .vcount_out  (vga_vcount)
    );
    
    //==========================================================================
    // LED Debug
    //==========================================================================
    assign led_pin[0] = config_done;
    assign led_pin[1] = system_ready;
    assign led_pin[2] = vsync;
    assign led_pin[3] = href;
    assign led_pin[4] = cap_we;
    assign led_pin[5] = pclk;
    assign led_pin[6] = bbox_valid;
    assign led_pin[7] = red_detected;
    
endmodule
