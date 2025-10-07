create_clock -period 8.000 -name refclk [get_ports gtx_refclk_n]

create_clock -period 4.000 -name gt_rxusrclk [get_pins -hier -filter {name =~ */rxoutclk_bufg/I }]
create_clock -period 8.000 -name gt_txusrclk [get_pins -hier -filter {name =~ */txoutclk_bufg/I }]

set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks -of_objects [get_ports gtx_refclk_n]] -group [get_clocks -include_generated_clocks gt_rxusrclk] -group [get_clocks -include_generated_clocks gt_txusrclk]

set_property LOC GTPE2_CHANNEL_X0Y0 [get_cells -hierarchical -filter {name =~ */gtpe2_i}]
set_property PACKAGE_PIN E4 [get_ports gtx_rxp]
set_property PACKAGE_PIN H2 [get_ports gtx_txp]

set_property PACKAGE_PIN B6 [get_ports gtx_refclk_p]
set_property PACKAGE_PIN B5 [get_ports gtx_refclk_n]

# Xillyusb GPIO LEDs ,K18 U10 is obLED

set_property PACKAGE_PIN K18 [get_ports {gpio_led[0]}]
set_property PACKAGE_PIN H17 [get_ports {gpio_led[1]}]

set_property PACKAGE_PIN B12 [get_ports {gpio_led[2]}]
set_property PACKAGE_PIN U10 [get_ports {gpio_led[3]}] 
set_property PACKAGE_PIN A12 [get_ports {gpio_led[4]}]
set_property PACKAGE_PIN A13 [get_ports {gpio_led[5]}]
set_property PACKAGE_PIN A14 [get_ports {gpio_led[6]}]
set_property PACKAGE_PIN C14 [get_ports {gpio_led[7]}]

set_property IOSTANDARD LVCMOS25 [get_ports {gpio_led[7]}]
set_property IOSTANDARD LVCMOS25 [get_ports {gpio_led[6]}]
set_property IOSTANDARD LVCMOS25 [get_ports {gpio_led[5]}]
set_property IOSTANDARD LVCMOS25 [get_ports {gpio_led[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpio_led[3]}]
set_property IOSTANDARD LVCMOS25 [get_ports {gpio_led[2]}]

set_property IOSTANDARD LVCMOS25 [get_ports {gpio_led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpio_led[0]}]
set_property DRIVE 4 [get_ports {gpio_led[7]}]
set_property DRIVE 4 [get_ports {gpio_led[6]}]
set_property DRIVE 4 [get_ports {gpio_led[5]}]
set_property DRIVE 4 [get_ports {gpio_led[4]}]
set_property DRIVE 4 [get_ports {gpio_led[3]}]
set_property DRIVE 4 [get_ports {gpio_led[2]}]

set_property DRIVE 4 [get_ports {gpio_led[1]}]
set_property DRIVE 4 [get_ports {gpio_led[0]}]
set_false_path -to [get_ports -filter NAME=~gpio_led*]


#  Bitstream settings
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 66 [current_design]
set_property CFGBVS VCCO [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]


