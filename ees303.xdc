##=============================================================================
## Nexys-4 FPGA Board — Pin Constraints
## Part: xc7a100tcsg324-3
## Source: Nexys-4 Reference Manual Table 6 (PMOD Pin Assignments)
##=============================================================================

##=============================================================================
## System Clock — 100MHz oscillator on pin E3
##=============================================================================
set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports sys_clk_pin]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} [get_ports sys_clk_pin]

##=============================================================================
## Reset Button — btnCpuReset (active-low)
##=============================================================================
set_property -dict {PACKAGE_PIN C12 IOSTANDARD LVCMOS33} [get_ports sys_rst_n_pin]

##=============================================================================
## LEDs [7:0]
##=============================================================================
set_property -dict {PACKAGE_PIN T8 IOSTANDARD LVCMOS33} [get_ports {led_pin[0]}]
set_property -dict {PACKAGE_PIN V9 IOSTANDARD LVCMOS33} [get_ports {led_pin[1]}]
set_property -dict {PACKAGE_PIN R8 IOSTANDARD LVCMOS33} [get_ports {led_pin[2]}]
set_property -dict {PACKAGE_PIN T6 IOSTANDARD LVCMOS33} [get_ports {led_pin[3]}]
set_property -dict {PACKAGE_PIN T5 IOSTANDARD LVCMOS33} [get_ports {led_pin[4]}]
set_property -dict {PACKAGE_PIN T4 IOSTANDARD LVCMOS33} [get_ports {led_pin[5]}]
set_property -dict {PACKAGE_PIN U7 IOSTANDARD LVCMOS33} [get_ports {led_pin[6]}]
set_property -dict {PACKAGE_PIN U6 IOSTANDARD LVCMOS33} [get_ports {led_pin[7]}]

##=============================================================================
## OV7670 Camera — PMOD JA: Data Bus D[7:0]
##
##  From Nexys-4 Reference Manual Table 6:
##    Top row:    JA1=B13  JA2=F14  JA3=D17  JA4=E17  (VCC)(GND)
##    Bottom row: JA7=G13  JA8=C17  JA9=D18  JA10=E18 (VCC)(GND)
##=============================================================================
set_property -dict {PACKAGE_PIN B13 IOSTANDARD LVCMOS33} [get_ports {data_pin[0]}]
set_property -dict {PACKAGE_PIN F14 IOSTANDARD LVCMOS33} [get_ports {data_pin[1]}]
set_property -dict {PACKAGE_PIN D17 IOSTANDARD LVCMOS33} [get_ports {data_pin[2]}]
set_property -dict {PACKAGE_PIN E17 IOSTANDARD LVCMOS33} [get_ports {data_pin[3]}]
set_property -dict {PACKAGE_PIN G13 IOSTANDARD LVCMOS33} [get_ports {data_pin[4]}]
set_property -dict {PACKAGE_PIN C17 IOSTANDARD LVCMOS33} [get_ports {data_pin[5]}]
set_property -dict {PACKAGE_PIN D18 IOSTANDARD LVCMOS33} [get_ports {data_pin[6]}]
set_property -dict {PACKAGE_PIN E18 IOSTANDARD LVCMOS33} [get_ports {data_pin[7]}]

##=============================================================================
## OV7670 Camera — PMOD JB: Control Signals
##
##  From Nexys-4 Reference Manual Table 6:
##    Top row:    JB1=G14  JB2=P15  JB3=V11  JB4=V15  (VCC)(GND)
##    Bottom row: JB7=K16  JB8=R16  JB9=T9   JB10=U11 (VCC)(GND)
##=============================================================================
# JB1 = G14 → pclk (used as data input, NOT a clock — CLK_100 oversampled)
set_property -dict {PACKAGE_PIN G14 IOSTANDARD LVCMOS33} [get_ports pclk]

# JB2 = P15 → href
set_property -dict {PACKAGE_PIN P15 IOSTANDARD LVCMOS33} [get_ports href]

# JB3 = V11 → vsync
set_property -dict {PACKAGE_PIN V11 IOSTANDARD LVCMOS33} [get_ports vsync]

# JB4 = V15 → xclk (25MHz output TO camera)
set_property -dict {PACKAGE_PIN V15 IOSTANDARD LVCMOS33} [get_ports xclk]

# JB7 = K16 → siod (I2C Data / SDA)
set_property -dict {PACKAGE_PIN K16 IOSTANDARD LVCMOS33} [get_ports siod]

# JB8 = R16 → sioc (I2C Clock / SCL)
set_property -dict {PACKAGE_PIN R16 IOSTANDARD LVCMOS33} [get_ports sioc]

# JB9 = T9 → reset_pin (active low, driven HIGH)
set_property -dict {PACKAGE_PIN T9 IOSTANDARD LVCMOS33} [get_ports reset_pin]

# JB10 = U11 → pwdn (active high, driven LOW)
set_property -dict {PACKAGE_PIN U11 IOSTANDARD LVCMOS33} [get_ports pwdn]

##=============================================================================
## VGA Output
##=============================================================================
set_property -dict {PACKAGE_PIN A3 IOSTANDARD LVCMOS33} [get_ports {R[0]}]
set_property -dict {PACKAGE_PIN B4 IOSTANDARD LVCMOS33} [get_ports {R[1]}]
set_property -dict {PACKAGE_PIN C5 IOSTANDARD LVCMOS33} [get_ports {R[2]}]
set_property -dict {PACKAGE_PIN A4 IOSTANDARD LVCMOS33} [get_ports {R[3]}]

set_property -dict {PACKAGE_PIN C6 IOSTANDARD LVCMOS33} [get_ports {G[0]}]
set_property -dict {PACKAGE_PIN A5 IOSTANDARD LVCMOS33} [get_ports {G[1]}]
set_property -dict {PACKAGE_PIN B6 IOSTANDARD LVCMOS33} [get_ports {G[2]}]
set_property -dict {PACKAGE_PIN A6 IOSTANDARD LVCMOS33} [get_ports {G[3]}]

set_property -dict {PACKAGE_PIN B7 IOSTANDARD LVCMOS33} [get_ports {B[0]}]
set_property -dict {PACKAGE_PIN C7 IOSTANDARD LVCMOS33} [get_ports {B[1]}]
set_property -dict {PACKAGE_PIN D7 IOSTANDARD LVCMOS33} [get_ports {B[2]}]
set_property -dict {PACKAGE_PIN D8 IOSTANDARD LVCMOS33} [get_ports {B[3]}]

set_property -dict {PACKAGE_PIN B11 IOSTANDARD LVCMOS33} [get_ports h_sync]
set_property -dict {PACKAGE_PIN B12 IOSTANDARD LVCMOS33} [get_ports v_sync]
