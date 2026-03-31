set_property SRC_FILE_INFO {cfile:/home/jsh-laptop/workspace_ondevice_2/fpga/self_study/OV7670_3/OV7670_3.srcs/constrs_1/imports/fpga/Basys-3-Master.xdc rfile:../../../OV7670_3.srcs/constrs_1/imports/fpga/Basys-3-Master.xdc id:1} [current_design]
set_property src_info {type:XDC file:1 line:7 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict { PACKAGE_PIN W5   IOSTANDARD LVCMOS33 } [get_ports wclk]
set_property src_info {type:XDC file:1 line:12 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict { PACKAGE_PIN V17   IOSTANDARD LVCMOS33 } [get_ports {rstn}]
set_property src_info {type:XDC file:1 line:13 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict { PACKAGE_PIN V16   IOSTANDARD LVCMOS33 } [get_ports {one_shot_top}]
set_property src_info {type:XDC file:1 line:31 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict { PACKAGE_PIN U16   IOSTANDARD LVCMOS33 } [get_ports {led_clk1}]
set_property src_info {type:XDC file:1 line:32 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict { PACKAGE_PIN E19   IOSTANDARD LVCMOS33 } [get_ports {led_clk2}]
set_property src_info {type:XDC file:1 line:33 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict { PACKAGE_PIN U19   IOSTANDARD LVCMOS33 } [get_ports {led_clk3}]
set_property src_info {type:XDC file:1 line:34 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict { PACKAGE_PIN V19   IOSTANDARD LVCMOS33 } [get_ports {led_clk4}]
set_property src_info {type:XDC file:1 line:85 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict { PACKAGE_PIN A14   IOSTANDARD LVCMOS33 } [get_ports {image_data[0]}];#Sch name = JB1
set_property src_info {type:XDC file:1 line:86 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict { PACKAGE_PIN A16   IOSTANDARD LVCMOS33 } [get_ports {image_data[1]}];#Sch name = JB2
set_property src_info {type:XDC file:1 line:87 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict { PACKAGE_PIN B15   IOSTANDARD LVCMOS33 } [get_ports {image_data[2]}];#Sch name = JB3
set_property src_info {type:XDC file:1 line:88 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict { PACKAGE_PIN B16   IOSTANDARD LVCMOS33 } [get_ports {image_data[3]}];#Sch name = JB4
set_property src_info {type:XDC file:1 line:89 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict { PACKAGE_PIN A15   IOSTANDARD LVCMOS33 } [get_ports {image_data[4]}];#Sch name = JB7
set_property src_info {type:XDC file:1 line:90 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict { PACKAGE_PIN A17   IOSTANDARD LVCMOS33 } [get_ports {image_data[5]}];#Sch name = JB8
set_property src_info {type:XDC file:1 line:91 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict { PACKAGE_PIN C15   IOSTANDARD LVCMOS33 } [get_ports {image_data[6]}];#Sch name = JB9
set_property src_info {type:XDC file:1 line:92 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict { PACKAGE_PIN C16   IOSTANDARD LVCMOS33 } [get_ports {image_data[7]}];#Sch name = JB10
set_property src_info {type:XDC file:1 line:95 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33 } [get_ports {PCLK}];#Sch name = JC1
set_property src_info {type:XDC file:1 line:99 export:INPUT save:INPUT read:READ} [current_design]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets PCLK_IBUF]
set_property src_info {type:XDC file:1 line:101 export:INPUT save:INPUT read:READ} [current_design]
set_clock_groups -asynchronous -group [get_clocks pclk_pin] -group [get_clocks clk_out2_clk_wiz_*]
set_property src_info {type:XDC file:1 line:102 export:INPUT save:INPUT read:READ} [current_design]
set_clock_groups -asynchronous -group [get_clocks pclk_pin] -group [get_clocks clk_out1_clk_wiz_*]
set_property src_info {type:XDC file:1 line:106 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict { PACKAGE_PIN N17   IOSTANDARD LVCMOS33 } [get_ports {Camera_Hs}];#Sch name = JC3
set_property src_info {type:XDC file:1 line:107 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict { PACKAGE_PIN P18   IOSTANDARD LVCMOS33 } [get_ports {Camera_Vs}];#Sch name = JC4
set_property src_info {type:XDC file:1 line:108 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict { PACKAGE_PIN L17   IOSTANDARD LVCMOS33 } [get_ports {MCLK}];#Sch name = JC7
set_property src_info {type:XDC file:1 line:110 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict { PACKAGE_PIN P17   IOSTANDARD LVCMOS33 } [get_ports {SIO_C}];#Sch name = JC9
set_property src_info {type:XDC file:1 line:111 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict { PACKAGE_PIN R18   IOSTANDARD LVCMOS33 } [get_ports {SIO_D}];#Sch name = JC10
set_property src_info {type:XDC file:1 line:113 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict { PACKAGE_PIN P17   IOSTANDARD LVCMOS33 PULLUP true } [get_ports {SIO_C}];
set_property src_info {type:XDC file:1 line:114 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict { PACKAGE_PIN R18   IOSTANDARD LVCMOS33 PULLUP true } [get_ports {SIO_D}];
set_property src_info {type:XDC file:1 line:128 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict { PACKAGE_PIN G19   IOSTANDARD LVCMOS33 } [get_ports {vgaRed[0]}]
set_property src_info {type:XDC file:1 line:129 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict { PACKAGE_PIN H19   IOSTANDARD LVCMOS33 } [get_ports {vgaRed[1]}]
set_property src_info {type:XDC file:1 line:130 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict { PACKAGE_PIN J19   IOSTANDARD LVCMOS33 } [get_ports {vgaRed[2]}]
set_property src_info {type:XDC file:1 line:131 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict { PACKAGE_PIN N19   IOSTANDARD LVCMOS33 } [get_ports {vgaRed[3]}]
set_property src_info {type:XDC file:1 line:132 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict { PACKAGE_PIN N18   IOSTANDARD LVCMOS33 } [get_ports {vgaBlue[0]}]
set_property src_info {type:XDC file:1 line:133 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict { PACKAGE_PIN L18   IOSTANDARD LVCMOS33 } [get_ports {vgaBlue[1]}]
set_property src_info {type:XDC file:1 line:134 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33 } [get_ports {vgaBlue[2]}]
set_property src_info {type:XDC file:1 line:135 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict { PACKAGE_PIN J18   IOSTANDARD LVCMOS33 } [get_ports {vgaBlue[3]}]
set_property src_info {type:XDC file:1 line:136 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict { PACKAGE_PIN J17   IOSTANDARD LVCMOS33 } [get_ports {vgaGreen[0]}]
set_property src_info {type:XDC file:1 line:137 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict { PACKAGE_PIN H17   IOSTANDARD LVCMOS33 } [get_ports {vgaGreen[1]}]
set_property src_info {type:XDC file:1 line:138 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict { PACKAGE_PIN G17   IOSTANDARD LVCMOS33 } [get_ports {vgaGreen[2]}]
set_property src_info {type:XDC file:1 line:139 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict { PACKAGE_PIN D17   IOSTANDARD LVCMOS33 } [get_ports {vgaGreen[3]}]
set_property src_info {type:XDC file:1 line:140 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict { PACKAGE_PIN P19   IOSTANDARD LVCMOS33 } [get_ports Hsync]
set_property src_info {type:XDC file:1 line:141 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict { PACKAGE_PIN R19   IOSTANDARD LVCMOS33 } [get_ports Vsync]
