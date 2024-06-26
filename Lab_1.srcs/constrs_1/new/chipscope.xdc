#create_debug_core u_ila_0 ila
#set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
#set_property ALL_PROBE_SAME_MU_CNT 4 [get_debug_cores u_ila_0]
#set_property C_ADV_TRIGGER true [get_debug_cores u_ila_0]
#set_property C_DATA_DEPTH 2048 [get_debug_cores u_ila_0]
#set_property C_EN_STRG_QUAL true [get_debug_cores u_ila_0]
#set_property C_INPUT_PIPE_STAGES 6 [get_debug_cores u_ila_0]
#set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
#set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
#set_property port_width 1 [get_debug_ports u_ila_0/clk]
#connect_debug_port u_ila_0/clk [get_nets [list i_clk]]
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
#set_property port_width 28 [get_debug_ports u_ila_0/probe0]
#connect_debug_port u_ila_0/probe0 [get_nets [list {LED[1]/counter_value[0]} {LED[1]/counter_value[1]} {LED[1]/counter_value[2]} {LED[1]/counter_value[3]} {LED[1]/counter_value[4]} {LED[1]/counter_value[5]} {LED[1]/counter_value[6]} {LED[1]/counter_value[7]} {LED[1]/counter_value[8]} {LED[1]/counter_value[9]} {LED[1]/counter_value[10]} {LED[1]/counter_value[11]} {LED[1]/counter_value[12]} {LED[1]/counter_value[13]} {LED[1]/counter_value[14]} {LED[1]/counter_value[15]} {LED[1]/counter_value[16]} {LED[1]/counter_value[17]} {LED[1]/counter_value[18]} {LED[1]/counter_value[19]} {LED[1]/counter_value[20]} {LED[1]/counter_value[21]} {LED[1]/counter_value[22]} {LED[1]/counter_value[23]} {LED[1]/counter_value[24]} {LED[1]/counter_value[25]} {LED[1]/counter_value[26]} {LED[1]/counter_value[27]}]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
#set_property port_width 28 [get_debug_ports u_ila_0/probe1]
#connect_debug_port u_ila_0/probe1 [get_nets [list {LED[0]/counter_value[0]} {LED[0]/counter_value[1]} {LED[0]/counter_value[2]} {LED[0]/counter_value[3]} {LED[0]/counter_value[4]} {LED[0]/counter_value[5]} {LED[0]/counter_value[6]} {LED[0]/counter_value[7]} {LED[0]/counter_value[8]} {LED[0]/counter_value[9]} {LED[0]/counter_value[10]} {LED[0]/counter_value[11]} {LED[0]/counter_value[12]} {LED[0]/counter_value[13]} {LED[0]/counter_value[14]} {LED[0]/counter_value[15]} {LED[0]/counter_value[16]} {LED[0]/counter_value[17]} {LED[0]/counter_value[18]} {LED[0]/counter_value[19]} {LED[0]/counter_value[20]} {LED[0]/counter_value[21]} {LED[0]/counter_value[22]} {LED[0]/counter_value[23]} {LED[0]/counter_value[24]} {LED[0]/counter_value[25]} {LED[0]/counter_value[26]} {LED[0]/counter_value[27]}]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
#set_property port_width 4 [get_debug_ports u_ila_0/probe2]
#connect_debug_port u_ila_0/probe2 [get_nets [list {LED[1]/o_led[0]} {LED[1]/o_led[1]} {LED[1]/o_led[2]} {LED[1]/o_led[3]}]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
#set_property port_width 4 [get_debug_ports u_ila_0/probe3]
#connect_debug_port u_ila_0/probe3 [get_nets [list {LED[0]/o_led[0]} {LED[0]/o_led[1]} {LED[0]/o_led[2]} {LED[0]/o_led[3]}]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
#set_property port_width 1 [get_debug_ports u_ila_0/probe4]
#connect_debug_port u_ila_0/probe4 [get_nets [list {LED[1]/i_rst}]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
#set_property port_width 1 [get_debug_ports u_ila_0/probe5]
#connect_debug_port u_ila_0/probe5 [get_nets [list {LED[0]/i_rst}]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
#set_property port_width 1 [get_debug_ports u_ila_0/probe6]
#connect_debug_port u_ila_0/probe6 [get_nets [list {LED[0]/led_on}]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
#set_property port_width 1 [get_debug_ports u_ila_0/probe7]
#connect_debug_port u_ila_0/probe7 [get_nets [list {LED[1]/led_on}]]
#set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
#set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
#set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
#connect_debug_port dbg_hub/clk [get_nets i_clk]
