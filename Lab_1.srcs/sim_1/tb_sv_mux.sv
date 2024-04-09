`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/09/2024 11:58:44 PM
// Design Name: 
// Module Name: tb_sv_mux
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


module tb_sv_mux#(
    //parameter T_CLK = 20.0e-9
);
    localparam T_CLK = int'(1.0e9 / 50e6);    // 20 Nanoseconds
    bit [1:0] i_selector = '1;
    sv_mux#(
        .T_CLK(T_CLK)
    )
    UUT_2 (
        .i_selector(i_selector),
        .i_signal(i_signal),
        .o_func(o_func)
    );
    
    initial begin
        #(T_CLK) i_selector[1:0] = 2'b00; // With this periods i_signals will change 
        #(3*T_CLK/2) i_selector[1:0] = 2'b01;                                        
        #(T_CLK-(1.0e9/200e6)) i_selector[1:0] = 2'b10;                                   
        #((2**4)*T_CLK/20) i_selector[1:0] = 2'b11;                                  
    end
endmodule
