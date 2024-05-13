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

    (* keep_hierarchy="yes" *)   
    l4_if_source #(
        
        .G_BYT          (G_BYT      ),
        .G_BIT_WIDTH    (G_BIT_WIDTH)
    ) SOURCE (
        .i_rst      (i_rst[0] ),
        .i_clk      (i_clk    ),
        .m_axis     (mstr_axis),
        
        .i_length   (G_LENGTH )  // Need to change size of data pack
    );
    
    (* keep_hierarchy="yes" *) 
    axis_fifo #(
        .PACKET_MODE ("True"     ),     // Init packet_mode
        .RESET_SYNC  ("True"     ),     // Init reset_sync
        .FEATURES    (8'b01100111),     // Enable features from list: [ reserved, read count, prog. empty flag, almost empty, reserved, write count, prog. full flag, almost full flag ]
        .DEPTH       (256        ),     // Set Depth
        .PROG_FULL   (32         )      // Set prog. full
    ) AXIS_FIFO (
        .i_fifo_a_rst_n     (!i_rst[1]),

        .s_axis_a_clk_p     (i_clk),
        .s_axis_a_rst_n     ('1   ),

        .m_axis_a_clk_p     (i_clk),
        .m_axis_a_rst_n     ('1   ),
        
        .s_axis             (mstr_axis),
        .m_axis             (slav_axis),

        .o_fifo_a_tfull     (o_fifo_a_tfull),     // Almost full flag
        .o_fifo_p_tfull     (o_fifo_p_tfull),     // Programmable full flag
        .o_fifo_w_count     (o_fifo_w_count),     // Write data count

        .o_fifo_a_empty     (o_fifo_a_empty),     // Almost empty flag
        .o_fifo_p_empty     (o_fifo_p_empty),     // Programmable empty flag
        .o_fifo_r_count     (o_fifo_r_count)      // Read data count, if dual clock mode is false - output count is the same with write data count

    );

    (* keep_hierarchy="yes" *) 
    l4_if_sink #(
        .G_BYT          (G_BYT      ),
        .G_BIT_WIDTH    (G_BIT_WIDTH)
    ) SINK (
        .i_rst         (i_rst[2]   ),
        .i_clk         (i_clk      ),
        .s_axis        (slav_axis  ),

        .o_sink_error  (o_top_error),
        .o_sink_good   (o_top_good )
    );
endmodule