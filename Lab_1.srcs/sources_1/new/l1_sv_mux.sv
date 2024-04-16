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


module sv_mux#(
    parameter G_SIG_WIDTH = 4, // Bus input i_selector
    parameter G_SEL_WIDTH = int'($ceil($clog2(G_SIG_WIDTH)))
)
(
    input bit [G_SEL_WIDTH-1:0] i_selector, // We can make it with one selector, but use integer(or similar)
    input bit [G_SIG_WIDTH-1:0] i_signal,
    output bit o_func // Signal will be seen on LED's
    );
    
    //localparam COUNTER_WIDTH  = int'($ceil($clog2(COUNTER_PERIOD+1)));
    /*always_ff@(posedge i_selector[1:0] or negedge i_selector[1:0])begin
        i_signal[3:0] <= '0;
        if(i_selector[1:0] == 2'b00)
        begin
            i_signal[0] <= '1;
        end
        
        if(i_selector[1:0] == 2'b01)
        begin
            i_signal[1] <= '1;
        end
        
        if(i_selector[1:0] == 2'b10)
        begin
            i_signal[2] <= '1;
        end
        
        if(i_selector[1:0] == 2'b11) begin
            i_signal[3] <= '1;
        end
    end;*/
    
    
    always_comb 
        o_func = i_signal[i_selector];
        
endmodule