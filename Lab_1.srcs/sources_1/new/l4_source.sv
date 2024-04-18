`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/17/2024 02:24:23 PM
// Design Name: 
// Module Name: l4_source
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



module l4_source#(

// CRC Generics    
    parameter int G_BYT = 1,
    parameter int G_BIT_WIDTH = 8 * G_BYT
)(

//For Source    
    input i_reset,
    input i_clk,
    
    output src_tvalid,
    output [G_BIT_WIDTH-1:0] src_tdata,
    output src_tlast, // WHERE TO CONNECT ????

//For CRC   
    input i_crc_s_ready,
    input i_crc_s_valid,
    input [G_BIT_WIDTH-1:0] i_crc_s_data
    
    );
    
    typedef enum{
        S0 = 0,     // Ready/Init
        S1 = 1,     // Header
        S2 = 2,     // Length
        S3 = 3,     // Payload
        S4 = 4,     // CRC_PAUSE
        S5 = 5,     // CRC_DATA
        S6 = 6      // Idle
    } t_fsm_states;
    
    t_fsm_states w_next_state, q_crnt_state = S0;
    
    localparam C_DATA_MAX = 10;
    localparam C_WIDTH = int'($ceil($clog2(C_DATA_MAX)+1));

// Making counts for states of FSM-------------------------------------    
    
    logic [C_WIDTH-1:0] q_data_cnt  = '0;
    logic [C_WIDTH-1:0] q_pause_cnt = '0;
    logic [C_WIDTH-1:0] q_idle_cnt  = '0;
 
// FSM-----------------------------------------------------------------  
    always_comb begin
    
        w_next_state = q_crnt_state;
        
        case(q_crnt_state)
            S0: 
                w_next_state = (i_crc_s_ready) ? S1 : S0;
            S1:
                w_next_state = (i_crc_s_ready && i_crc_s_valid) ? S2 : S1;   
            S2:
                w_next_state = (i_crc_s_ready && i_crc_s_valid) ? S3 : S2;
            S3:
                w_next_state = ((q_data_cnt == C_DATA_MAX) && i_crc_s_ready && i_crc_s_valid) ? S4 : S3;
            S4:
                w_next_state = (q_pause_cnt == C_DATA_MAX) ? S5 : S4;
            S5:
                w_next_state = S6;
            S6:
                w_next_state = (q_idle_cnt == C_DATA_MAX) ? S1 : S6;
            default:
                w_next_state = S0;
        endcase;
    end

// Adding Data counter
    
    always_ff@(posedge i_crc_s_data) begin
        q_data_cnt = (q_data_cnt == C_DATA_MAX) ? '0 : q_data_cnt+1;
    end

// Adding 2 process for Pause and Idle counter

    always_comb begin
    
        if (q_crnt_state == S4) begin
            q_pause_cnt = (q_pause_cnt == C_DATA_MAX) ? '0 : q_pause_cnt+1;
        end
        
        if (q_crnt_state == S6) begin
            q_idle_cnt = (q_idle_cnt == C_DATA_MAX) ? '0 :  q_idle_cnt+1;
        end
    end
    
// Adding process to be able to reset FSM and FSM can stepping 
 
    always_ff@(posedge i_clk) begin
        
        if (i_reset)
            q_crnt_state <= S0;
        else 
            q_crnt_state <= w_next_state;
    end
    
// Connecting output from Source with output result from CRC
    
    assign src_tvalid = o_crc_m_valid;
    assign src_tdata = o_crc_m_data;

//Creating CRC-module inside Source
    crc#(
        .POLY_WIDTH (G_BIT_WIDTH   ), // Size of The Polynomial Vector
		.WORD_WIDTH (G_BIT_WIDTH   ), // Size of The Input Words Vector
		.WORD_COUNT (0   ), // Number of Words To Calculate CRC, 0 - Always Calculate CRC On Every Input Word
		.POLYNOMIAL ('hD5), // Polynomial Bit Vector
		.INIT_VALUE ('1  ), // Initial Value
		.CRC_REF_IN ('0  ), // Beginning and Direction of Calculations: 0 - Starting With MSB-First; 1 - Starting With LSB-First
		.CRC_REFOUT ('0  ), // Determines Whether The Inverted Order of The Bits of The Register at The Entrance to The Xor Element
		.BYTES_RVRS ('0  ), // Input Word Byte Reverse
		.XOR_VECTOR ('0  ), // CRC Final Xor Vector
		.NUM_STAGES (2   )  // Number of Register Stages, Equivalent Latency in Module. Minimum is 1, Maximum is 3.
    ) CRC (
        .i_crc_a_clk_p (i_clk  ), // Rising Edge Clock
		.i_crc_s_rst_p (i_reset), // Sync Reset, Active High. Reset CRC To Initial Value.
		.i_crc_ini_vld ('0     ), // Input Initial Valid
		.i_crc_ini_dat ('0     ), // Input Initial Value
		.i_crc_wrd_vld (i_crc_s_valid), // Word Data Valid Flag 
		.o_crc_wrd_rdy (i_crc_s_ready), // Ready To Recieve Word Data
		.i_crc_wrd_dat (i_crc_s_data ), // Word Data
		.o_crc_res_vld (o_crc_m_valid), // Output Flag of Validity, Active High for Each WORD_COUNT Number
		.o_crc_res_dat (o_crc_m_data )  // Output CRC from Each Input Word
    );
    
endmodule
