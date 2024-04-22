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
    parameter int G_BYT = 1,
    parameter int G_BIT_WIDTH = 8 * G_BYT
)(
    
    input i_rst_src, //Maybe not in use because every module has its own reset
    input i_rst_sink,
    input i_rst_fifo,
    input i_clk,

// Inputs for CRC in Source
/*    input crc_s_valid,
    input [G_BIT_WIDTH-1:0] crc_s_data,*/
    
// Output from Sink    
    output o_top_error,
    output o_top_good
    );
    
    if_axis #(.N(G_BYT)) s_axis ();
    if_axis #(.N(G_BYT)) m_axis ();
    
    l4_source #(
        
        .G_BYT       (G_BYT      ),
        .G_BIT_WIDTH (G_BIT_WIDTH)
    ) SOURCE (
        .i_rst      (i_rst_src),
        .i_clk      (i_clk    ),
        
        .o_src_tvalid (src_fifo_tvalid),
        .o_src_tdata  (src_fifo_tdata ),
        .o_src_tlast  (src_fifo_tlast ), // WHERE TO CONNECT ????
        
        .i_src_tready (fifo_source_tready)
    );
    
    axis_data_fifo_0 AXIS (
        
        .s_axis_aresetn      (i_rst_fifo),
        .s_axis_aclk         (i_clk     ), //Maybe need its own clock
                                           
        .s_axis_tready      (fifo_source_tready),
        .s_axis_tvalid      (src_fifo_tvalid   ),
        .s_axis_tlast       (src_fifo_tlast    ),
        .s_axis_tdata       (src_fifo_tdata    ),
                                           
        .m_axis_tready      ('1),
//        .m_axis_tready      (sink_fifo_tready),
        .m_axis_tvalid      (fifo_sink_tvalid),
        .m_axis_tlast       (fifo_sink_tlast ),
        .m_axis_tdata       (fifo_sink_tdata ),
                                           
        .axis_wr_data_count (             ),
        .axis_rd_data_count (             ),
        .prog_empty         (             ),
        .prog_full          (             )
        
    );
    
    l4_sink #(
        .G_BYT       (G_BYT      ),
        .G_BIT_WIDTH (G_BIT_WIDTH)
    ) SINK (
        .i_rst      (i_rst_sink),
        .i_clk      (i_clk     ),
        
        .o_sink_tvalid (fifo_sink_tvalid),
        .o_sink_tdata  (fifo_sink_tdata ),
        .i_sink_tlast  (fifo_sink_tlast ),
        
        .o_sink_ready  (sink_fifo_tready),
        .o_sink_error  (o_top_error     ),
        .o_sink_good   (o_top_good      )
    );
endmodule
