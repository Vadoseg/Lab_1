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
        input [G_NUM-1:0] i_sensor,
        output bit [G_WID-1:0] o_light1,
        output bit [G_WID-1:0] o_light2,
        input i_clk,
        input i_rst
    );
    
    
    typedef enum {
        S0 = 0,
        S1 = 1,
        S2 = 2,
        S3 = 3
} t_fsm_states;
    
    t_fsm_states w_next_state, q_crnt_state = S0;
    
    localparam C_MAX = 10;
    localparam C_WIDTH = int'($ceil($clog2(C_MAX+1)));
    
    logic [C_WIDTH-1:0] q_cnt = '0;
    
    
    always_comb begin
    
        w_next_state = q_crnt_state;
        
        case(q_crnt_state)
           S0: 
                if (q_cnt >= C_MAX-1 && i_sensor[1]) w_next_state = S1; // Change of state
                else w_next_state = S0;
           S1:
                w_next_state = S2;
           S2:
                if(q_cnt >= C_MAX-1 && i_sensor[0])
                    w_next_state = S3;
                else
                    w_next_state = S2; // Equal to w_next_state = (q_cnt >= C_MAX-1 && i_sensor[0]) ? S3 : S2;  
           S3:
                w_next_state = S0;
           default:
                w_next_state = S0;
        endcase;
    end
    
    always_ff@(posedge i_clk) begin
        
        if (i_rst)
            q_crnt_state <= S0;
        else 
            q_crnt_state <= w_next_state;
    end
    
    
    always_ff@(posedge i_clk) begin
        
        case (q_crnt_state)
            S1, S3: 
                q_cnt <= '0;
            default:
                if (q_cnt < C_MAX-1)
                    q_cnt <= q_cnt + 1;
        endcase;
    end
    
    
    always_ff@(posedge i_clk) begin
       case(q_crnt_state)
            S0:
                begin
                    o_light1 = 2'b00; // Green
                    o_light2 = 2'b10; // Red
                end
            S2:
                begin
                    o_light1 = 2'b10; // Red
                    o_light2 = 2'b00; // Green
                end
            S1,S3:
                begin
                    o_light2 = 2'b01; //Yellow
                    o_light1 = 2'b01; //Yellow
                end
            default:
                begin
                    o_light1 = 2'b00; // Green
                    o_light2 = 2'b10; // Red
                end
       endcase;
    end

endmodule
