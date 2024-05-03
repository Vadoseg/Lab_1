`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/02/2024 07:32:41 PM
// Design Name: 
// Module Name: l4_tb_top
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


module l4_tb_top#(
        parameter int G_BYT = 1,
        parameter int G_BIT_WIDTH = 8 * G_BYT
    )(

    );
    
    bit i_clk = '0;
    bit i_rst_src  = '0;
    bit i_rst_fifo = '0;
    bit i_rst_sink = '0;
    localparam T_CLK = 1e-6;

    l4_top #(
        .G_BYT (G_BYT),
        .G_BIT_WIDTH (G_BIT_WIDTH)
    ) TOP (
        .i_rst_src  (i_rst_src ),
        .i_rst_fifo (i_rst_fifo),
        .i_rst_sink (i_rst_sink),
        .i_clk      (i_clk     )
    );
    
    always #(T_CLK * 20) i_clk = ~i_clk;


endmodule
