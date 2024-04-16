`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/11/2024 03:09:33 PM
// Design Name: 
// Module Name: tb_sv_led_no_comarator
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


module tb_sv_led_no_comarator#(
    parameter CLK_FREQUENCY = 200.0e6,
    parameter BLINK_PERIOD = 1.0e-6
);
//-- Constants
    localparam T_CLK = 1.0e9 / CLK_FREQUENCY; // ns
    localparam NEW_CLK = 1.0e9 / /*400.0e6*/  2**28;
//-- Signals
    bit i_clk = 1'b0; bit i_rst = 1'b0; logic [3:0] o_led = 4'b0001;
//-- 
    sv_led_no_comparator# ( 
        .CLK_FREQUENCY(CLK_FREQUENCY),
        .BLINK_PERIOD (BLINK_PERIOD)
   ) 
    UUT_2 (
        .i_clk (i_clk),
        .i_rst(i_rst),
        .o_led(o_led)
    );
//--
    always #(T_CLK/2) i_clk = ~i_clk;
    //always #(NEW_CLK) o_led[0] = ~o_led[0];
    //always #(NEW_CLK*10000) i_rst = ~i_rst;


endmodule
