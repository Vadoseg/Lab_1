`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/15/2024 10:55:31 AM
// Design Name: 
// Module Name: l3_sv_auto
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


module l3_sv_auto#(
    
        parameter G_NUM = 2, // Number of Sensors
        parameter G_WID = 2  // Number of Lights
    )
    
    (
    input [G_NUM-1:0] i_Sensor,
    output bit [G_WID-1:0] o_Light1,
    output bit [G_WID-1:0] o_Light2,
    input i_clk,
    input i_rst
    );
    
    typedef enum {
        S0_READY = 0,
        S1_BUSY  = 1,
        S2_PAUSE = 2,
        S3_DONE  = 3
} t_fsm_states;
    
    t_fsm_states w_next_state, q_crnt_state = S0_READY;
    
    always_comb begin
        w_next_state = q_crnt_state;
        case(q_crnt_state)
           S0_READY: 
                if (!i_Sensor[0]) w_next_state = S1_BUSY; // Change of state
                else w_next_state = S0_READY;
           S1_BUSY:
                w_next_state = S2_PAUSE;
           S2_PAUSE:
                if(!i_Sensor[1]) w_next_state = S3_DONE;
                else w_next_state = S2_PAUSE;
           S3_DONE:
                w_next_state = S0_READY;
           default:
                w_next_state = S0_READY;
           endcase;
    end
    
    always_ff@(posedge i_clk) begin
        if (i_rst) q_crnt_state <= S0_READY;
        else q_crnt_state <= w_next_state;
    end
    
    always_ff@(posedge i_clk) begin
       case(q_crnt_state)
            S0_READY:
                begin
                    o_Light1 = 2'b00; // Green
                    o_Light2 = 2'b10; // Red
                end
            S1_BUSY:
                o_Light1 = 2'b01; // Yellow
            S2_PAUSE:
                begin
                    o_Light1 = 2'b10; // Red
                    o_Light2 = 2'b00; // Green
                end
            S3_DONE:
                o_Light2 = 2'b01; // Yellow
            default:
                begin
                    o_Light1 = 2'b00; // Green
                    o_Light2 = 2'b10; // Red
                end
       endcase;
    end
    
endmodule
