`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/09/2024 11:23:47 PM
// Design Name: 
// Module Name: sv_mux
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


module l1_sv_mux#(
    parameter int G_SIG_WIDTH = 4, // Bus input i_selector
    parameter int G_SEL_WIDTH = $ceil($clog2(G_SIG_WIDTH))
)
(
    input   wire    [G_SEL_WIDTH-1:0] i_selector, // We can make it with one selector, but use integer(or similar)
    input   wire    [G_SIG_WIDTH-1:0] i_signal,
    output  logic                     o_func      // Signal will be seen on LED's
    );

    always_comb 
        o_func = i_signal[i_selector];
        
endmodule