`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/08/2024 02:25:51 PM
// Design Name: 
// Module Name: l4_tb_if_top
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


module l4_tb_if_top#(
        parameter int G_BYT = 1,
        parameter int G_BIT_WIDTH = 8 * G_BYT,
        parameter G_DATA_MAX = 10 // Size of pack
    )(

    );
    
    bit i_clk = '0;
    bit [2:0] i_rst  = '0;
    localparam T_CLK = 1;

    l4_if_top #(
        .G_BYT (G_BYT),
        .G_BIT_WIDTH (G_BIT_WIDTH),
        .G_DATA_MAX (G_DATA_MAX)
    ) TOP (
        .i_rst  (i_rst),
        .i_clk  (i_clk)
    );
    
    always #(T_CLK * 20) i_clk = ~i_clk;
    



endmodule