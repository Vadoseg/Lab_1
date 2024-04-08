set_property PACKAGE_PIN E15 [get_ports {o_led[0]}]
set_property PACKAGE_PIN D15 [get_ports {o_led[1]}]
set_property PACKAGE_PIN W17 [get_ports {o_led[2]}]
set_property PACKAGE_PIN W5  [get_ports {o_led[3]}]
set_property PACKAGE_PIN C19   [get_ports clk_ini_n]
set_property PACKAGE_PIN D18   [get_ports clk_ini_p]
set_property PACKAGE_PIN G19  [get_ports i_rst]
set_property IOSTANDARD LVCMOS25  [get_ports {o_led[3]}]
set_property IOSTANDARD LVCMOS25  [get_ports {o_led[2]}]
set_property IOSTANDARD LVCMOS25  [get_ports {o_led[1]}]
set_property IOSTANDARD LVCMOS25  [get_ports {o_led[0]}]
set_property -dict {IOSTANDARD LVDS_25 DIFF_TERM 1}   [get_ports clk_ini_n]
set_property -dict {IOSTANDARD LVDS_25 DIFF_TERM 1}   [get_ports clk_ini_p]
set_property IOSTANDARD LVCMOS25   [get_ports i_rst]