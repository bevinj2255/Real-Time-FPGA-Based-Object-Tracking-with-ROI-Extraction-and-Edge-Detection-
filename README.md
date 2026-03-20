# Real-Time-FPGA-Based-Object-Tracking-with-ROI-Extraction-and-Edge-Detection-

Real-time color-based object tracking using an OV7670 camera and Nexys-4 FPGA board. The system captures live video, detects red objects using RGB thresholding, and draws a bounding box around the detected object on a VGA display.

## Hardware

- FPGA Board: Digilent Nexys-4 (Xilinx Artix-7 XC7A100T-CSG324-3)
- Camera: OV7670 (CMOS, no FIFO)
- Display: VGA monitor (640x480 @ 60Hz)
- Development Tool: Xilinx Vivado

## Modules

- OV7670_top.v — Top-level module. Wires all components, generates startup delay, handles clock and reset.
- ov7670_capture.v — Captures 8-bit camera data on PCLK rising edges using 100MHz oversampling. Assembles two bytes into one RGB565 pixel.
- ov7670_init.v — I2C master that sends configuration registers to the OV7670 camera on startup.
- I2C_Controller2.v — Low-level I2C (SCCB) bus driver used by ov7670_init.
- I2C_OV7670_RGB565_Config2.v — Lookup table containing 165 camera register configurations (QVGA, RGB565, timing).
- vram_wrapper.v — Dual-port BRAM wrapper (Vivado IP). Port A writes from camera, Port B reads for VGA.
- clk_gen_wrapper.v — Clocking Wizard IP wrapper. Takes 100MHz board clock, outputs 100MHz and 25MHz.
- VGA.v — VGA timing generator (640x480 @ 60Hz, 25MHz pixel clock). Displays a 320x240 image centered on screen.
- red_detector.v — RGB444 color thresholding. A pixel is "red" if R>=8, G<=6, B<=6, and R dominates G and B by at least 4.
- bounding_box_accumulator.v — Tracks the min/max x and y coordinates of all detected red pixels during each frame. Outputs bounding box coordinates.
- bbox_overlay.v — Draws a red rectangle on the VGA output at the bounding box coordinates.

## How It Works

1. The PLL generates 100MHz (for capture and I2C) and 25MHz (for VGA and camera XCLK).
2. After PLL lock and a 0.5s startup delay, I2C configures the OV7670 for QVGA RGB565 mode.
3. Camera pixel data is captured on PCLK rising edges using 100MHz oversampling and stored as RGB444 in dual-port BRAM.
4. On the VGA read side, each pixel is tested against red color thresholds.
5. The bounding box accumulator tracks the min/max coordinates of all red pixels across the frame.
6. At the end of each frame, a red rectangle is drawn around the detected region on the VGA output.

## Test Pattern

Set USE_TEST_PATTERN = 1 in OV7670_top.v to display 8 SMPTE color bars without a camera connected. This verifies the VGA and BRAM pipeline independently.

## Constraints

- System clock: 100MHz on pin E3
- Camera data bus: PMOD JA (pins B13, F14, D17, E17, G13, C17, D18, E18)
- Camera control: PMOD JB (PCLK=G14, HREF=P15, VSYNC=V11, XCLK=V15, SIOD=K16, SIOC=R16, RESET=T9, PWDN=U11)
- VGA output: Standard Nexys-4 VGA pins
