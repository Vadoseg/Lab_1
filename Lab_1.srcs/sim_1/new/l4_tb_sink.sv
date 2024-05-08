`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/03/2024 11:08:57 AM
// Design Name: 
// Module Name: l4_tb_sink
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


module l4_tb_sink#(
        parameter int G_BYT = 1,
        parameter int G_BIT_WIDTH = 8 * G_BYT
    )(
    
    );
    
    bit i_clk = '0;
    bit i_sink_tvalid  = '0;
    bit i_sink_tlast = '0;
    logic [G_BIT_WIDTH-1:0] i_sink_tdata = '0;
    
    localparam T_CLK = 1;
    localparam C_PACK_LENGTH = 10;

    l4_sink#( 
        .G_BYT       (G_BYT      ),
        .G_BIT_WIDTH (G_BIT_WIDTH)
    ) SINK (
        .i_clk (i_clk),
        .i_rst ('0   ), 
        .i_sink_tvalid  (i_sink_tvalid),
        .i_sink_tdata   (i_sink_tdata ),
        .i_sink_tlast   (i_sink_tlast )
    );
    
    always#(T_CLK * 10) i_clk = ~i_clk;


    initial
    begin
    // States:
    // S0: Init

    // S1
    i_sink_tvalid = '1;  // Header is not coming in
    i_sink_tdata  = 72;
    #(T_CLK * 20)
    i_sink_tvalid = '0;
    
    // S2
    #(T_CLK * 20)
    i_sink_tvalid = '1;
    i_sink_tdata = C_PACK_LENGTH;
    #(T_CLK * 20)

    // S3
    #(T_CLK * 20)
    for (int i = 1; i < C_PACK_LENGTH + 1; i++) begin
        i_sink_tdata = i;
        #(T_CLK * 20);
    end
    i_sink_tvalid = '0;

    // S4: Pause

    // S5
    #(T_CLK * 20)
    i_sink_tvalid = '1;
    i_sink_tdata  = 'h5B;  // h6E( for 30)
    i_sink_tlast  = '1;
    #(T_CLK * 20)
    i_sink_tvalid = '0;
    i_sink_tlast  = '0;
    i_sink_tdata  = '0;
    end

endmodule
