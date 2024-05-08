`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/08/2024 01:49:22 PM
// Design Name: 
// Module Name: l4_if_top
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
	
	modport m (input tready, output tvalid, tlast, tdata);
	modport s (output tready, input tvalid, tlast, tdata);
	
endinterface : if_axis

module l4_if_top#(
    parameter int G_BYT = 1,
    parameter int G_BIT_WIDTH = 8 * G_BYT,
    parameter int G_DATA_MAX = 10, // Size of data pack
    parameter int G_CNT_WIDTH = ($ceil($clog2(G_DATA_MAX+1))),
    parameter logic [G_CNT_WIDTH-1:0] G_LENGTH = G_DATA_MAX // LENGTH of data pack
)(
    input [2:0] i_rst,
    input i_clk,
    
// Output from Sink    
    output o_top_error,
    output o_top_good
    );
    
    if_axis #(.N(G_BYT)) mstr_axis ();
    if_axis #(.N(G_BYT)) slav_axis ();
    
    l4_if_source #(
        
        .G_BYT          (G_BYT      ),
        .G_BIT_WIDTH    (G_BIT_WIDTH)
    ) SOURCE (
        .i_rst      (i_rst[0] ),
        .i_clk      (i_clk    ),
        .m_axis     (mstr_axis),
        
        .i_length   (G_LENGTH )  // Need to change size of data pack
    );
    
    axis_data_fifo_0 AXIS (
        
        .s_axis_aresetn     (i_rst[1]  ),
        .s_axis_aclk        (i_clk     ), //Maybe need its own clock
                                           
        .s_axis_tvalid      (mstr_axis.tvalid),     // input wire s_axis_tvalid       
        .s_axis_tready      (mstr_axis.tready),     // output wire s_axis_tready      
        .s_axis_tdata       (mstr_axis.tdata ),     // input wire [7 : 0] s_axis_tdata
        .s_axis_tlast       (mstr_axis.tlast ),     // input wire s_axis_tlast                             
        
        .m_axis_tvalid      (slav_axis.tvalid),     // output wire m_axis_tvalid       
        .m_axis_tready      (slav_axis.tready),     // input wire m_axis_tready        
        .m_axis_tdata       (slav_axis.tdata ),     // output wire [7 : 0] m_axis_tdata 
        .m_axis_tlast       (slav_axis.tlast ),     // output wire m_axis_tlast        
                                           
        .axis_wr_data_count (axis_wr_data_count),   
        .axis_rd_data_count (axis_rd_data_count),   
        .prog_empty         (prog_empty        ),   
        .prog_full          (prog_full         )    
        
    );
    
    l4_if_sink #(
        .G_BYT          (G_BYT      ),
        .G_BIT_WIDTH    (G_BIT_WIDTH)
    ) SINK (
        .i_rst      (i_rst[2]  ),
        .i_clk      (i_clk     ),
        .s_axis     (slav_axis ),

        .o_sink_error  (o_top_error),
        .o_sink_good   (o_top_good )
    );
endmodule