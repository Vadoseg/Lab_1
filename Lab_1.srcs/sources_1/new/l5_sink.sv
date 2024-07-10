`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/27/2024 12:34:55 PM
// Design Name: 
// Module Name: l5_top
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


module l5_sink#(

    )(
        input bit i_clk,
        input bit i_rst_n,

        if_axil.s s_axil,

        input  [7:0] i_len,
        output [7:0] o_len,
        
        input bit i_err_crc,
        input bit i_err_unx,
        input bit i_err_mis
    );

    typedef enum{
        S0 = 0,     // Ready/Init
        S1 = 1,     // Header
        S2 = 2,     // Length
        S3 = 3,     // Payload
        S4 = 4,     // CRC_PAUSE
        S5 = 5      // CRC_DATA
    } t_fsm_states;
    
    t_fsm_states q_crnt_state = S0;

    always_ff@(posedge i_clk) begin
        case(q_crnt_state)
            S0: begin
                
            end
            S1: begin
                
            end
            S2: begin
                
            end
            S3: begin
                
            end
            S4: begin
                
            end
            S5: begin
                
            end

        endcase
    end
endmodule
