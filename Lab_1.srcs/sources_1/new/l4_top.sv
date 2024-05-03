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
	
	/*modport m (input tready, output tvalid, tlast, tdata);
	modport s (output tready, input tvalid, tlast, tdata);*/
endinterface : if_axis

module l4_top#(
    parameter int G_BYT = 1,
    parameter int G_BIT_WIDTH = 8 * G_BYT,
    parameter int G_LENGTH = 10 // LENGTH of data pack
)(
    
    input i_rst_src, //Maybe not in use because every module has its own reset
    input i_rst_sink,
    input i_rst_fifo,
    input i_clk,

    
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
        
        .o_src_tvalid (s_axis.tvalid),
        .o_src_tdata  (s_axis.tdata ),
        .o_src_tlast  (s_axis.tlast ),
        
        .i_src_tready (m_axis.tready),
        
        .i_length (G_LENGTH)
    );
    
    axis_data_fifo_0 AXIS (
        
        .s_axis_aresetn      (i_rst_fifo),
        .s_axis_aclk         (i_clk     ), //Maybe need its own clock
                                           
        .s_axis_tready      (s_axis.tready),    //sink-fifo
        .s_axis_tvalid      (s_axis.tvalid),    //src-fifo
        .s_axis_tlast       (s_axis.tlast ),    //src-fifo
        .s_axis_tdata       (s_axis.tdata ),    //src-fifo
                                           
        // .m_axis_tready      ('1),
        .m_axis_tready      (m_axis.tready),    //fifo-source
        .m_axis_tvalid      (m_axis.tvalid),    //fifo-sink
        .m_axis_tlast       (m_axis.tlast ),    //fifo-sink
        .m_axis_tdata       (m_axis.tdata ),    //fifo-sink
                                           
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
        
        .i_sink_tvalid (m_axis.tvalid),
        .i_sink_tdata  (m_axis.tdata ),
        .i_sink_tlast  (m_axis.tlast ),
        
        .o_sink_ready  (s_axis.tready   ),
        .o_sink_error  (o_top_error     ),
        .o_sink_good   (o_top_good      )
    );
endmodule
