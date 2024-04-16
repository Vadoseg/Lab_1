`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/15/2024 10:57:09 AM
// Design Name: 
// Module Name: l3_tb_sv_auto
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


module l3_tb_sv_auto#(
        
        parameter G_NUM = 2, // Number of Sensors
        parameter G_WID = 2  // Number of Lights
    );
    
    localparam BLINK = 5.0; // Seconds
    
    bit i_clk = '0; 
    bit i_rst = '0; // Use Later
    bit [G_NUM-1:0] i_Sensor = '0;
    
    l3_sv_auto#(
        .G_NUM(G_NUM),
        .G_WID(G_WID)
    )
    UUT(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_Sensor(i_Sensor)
    );
    
    always#(BLINK) i_clk = ~i_clk;
    always#(BLINK*31) i_Sensor[0] = ~i_Sensor[0];
    always#(BLINK*55) i_Sensor[1] = ~i_Sensor[1];
    
endmodule
