`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/17/2024 02:36:30 PM
// Design Name: 
// Module Name: l4_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

interface if_axis #(parameter int N = 1) ();
	
	localparam W = 8 * N; // tdata bit width (N - number of BYTES)
	
	logic         tready;
	logic         tvalid;
	logic         tlast ;
	logic [W-1:0] tdata ;
endinterface

module l4_top#(
    int G_BYT = 1
)(
    
    input i_rst, //Maybe not in use because every module has its own reset
    input i_clk,
    
    output data
    );
    
    if_axis #(.N(G_BYT)) s_axis ();
    if_axis #(.N(G_BYT)) m_axis ();
    
    l4_source SOURCE(
        .i_reset    (i_rst),
        .i_clk      (i_clk),
        
        .src_tvalid (src_fifo_tvalid),
        .src_tdata  (src_fifo_tdata ),
        .src_tlast  (src_fifo_tlast )
    );
    
    axis_data_fifo_0 AXIS (
        
        .s_axis_aresetn      (i_aresetn),
        .s_axis_aclk         (i_aclk   ), 
                                           
        .s_axis_tready      (s_axis.tready),
        .s_axis_tvalid      (src_fifo_tvalid), // ПОМЕНЯТЬ
        .s_axis_tlast       (s_axis.tlast ),
        .s_axis_tdata       (s_axis.tdata ),
                                           
        .m_axis_tready      (m_axis.tready),
        .m_axis_tvalid      (m_axis.tvalid),
        .m_axis_tlast       (m_axis.tlast ),
        .m_axis_tdata       (m_axis.tdata ),
                                           
        .axis_wr_data_count (             ),
        .axis_rd_data_count (             ),
        .prog_empty         (             ),
        .prog_full          (             )
        
    );
    
    l4_sink SINK(
        .i_reset    (i_rst),
        .i_clk      (i_clk),
        
        .sink_tvalid (fifo_sink_tvalid),
        .sink_tdata  (fifo_sink_tdata ),
        .sink_tlast  (fifo_sink_tlast )
    
    );
endmodule
