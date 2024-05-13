if { [llength [get_cells -quiet packet_fifo.u_axis_reset/with_sync.*]] > 0 } {
  set areset_ss "async_cdc.q_sync_stages_reg*/PRE"
  set_false_path -to [get_pins packet_fifo.u_axis_reset/with_sync.u_rclk_w_rst_p/$areset_ss]
  set_false_path -to [get_pins packet_fifo.u_axis_reset/with_sync.u_wclk_w_rst_p/$areset_ss]
  set_false_path -to [get_pins packet_fifo.u_axis_reset/with_sync.u_wclk_r_rst_p/$areset_ss]
  set_false_path -to [get_pins packet_fifo.u_axis_reset/with_sync.u_rclk_r_rst_p/$areset_ss]
}

set s_clock [get_clocks -quiet -of [get_ports s_axis_fifo\\.a_clk_p]]
set m_clock [get_clocks -quiet -of [get_ports m_axis_fifo\\.a_clk_p]]

set s_clock_period [get_property -quiet -min PERIOD $s_clock]
set m_clock_period [get_property -quiet -min PERIOD $m_clock]

if { $s_clock == "" } {
  set s_clock_period 1.125
}

if { $m_clock == "" } {
  set m_clock_period 1.375
}

if { ($s_clock != $m_clock) || ($s_clock == "" && $m_clock == "") } { 
  
  if { [llength [get_cells -quiet packet_fifo.dual_axis_pack.*]] > 0 } {

    set src_reg "src_with_reg.q_src_cdc_sig_reg[*]"
    set gray_ss "gray_cdc.q_sync_stages_reg[0][*]"

    set cdc_wr_counter "packet_fifo.dual_axis_pack.u_cdc_wr_counter"
    set_max_delay -from [get_cells $cdc_wr_counter/$src_reg] -to [get_cells $cdc_wr_counter/$gray_ss] $s_clock_period -datapath_only
    set_bus_skew  -from [get_cells $cdc_wr_counter/$src_reg] -to [get_cells $cdc_wr_counter/$gray_ss] [expr min($s_clock_period, $m_clock_period)]

    set_false_path -to [get_pins packet_fifo.dual_axis_pack.u_cdc_a_tfull/other_cdc.q_sync_stages_reg[0][*]/D]

  }
} 