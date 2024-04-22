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


//For CRC      
    input i_crc_s_ready,
    
    /*input i_crc_s_valid,
    input [G_BIT_WIDTH-1:0] i_crc_s_data,*/ //Not needed

 
//For Source
    input i_rst,
    input i_clk,
           
    input i_src_tready,
    output logic o_src_tvalid = '0,
    output logic [G_BIT_WIDTH-1:0] o_src_tdata = '0,
    output logic o_src_tlast = '0 // WHERE TO CONNECT ????
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
    
    t_fsm_states /*w_next_state,*/ q_crnt_state = S0;
    
    localparam int C_DATA_MAX  = 10;
    localparam int C_PAUSE_MAX = 20;
    localparam int C_IDLE_MAX  = 50;
    
    localparam int C_DATA_WIDTH  = ($ceil($clog2(C_DATA_MAX+1)));
    localparam int C_PAUSE_WIDTH = ($ceil($clog2(C_PAUSE_MAX+1)));
    localparam int C_IDLE_WIDTH  = ($ceil($clog2(C_IDLE_MAX+1)));
// Making counts for states of FSM-------------------------------------    
    
    logic [C_DATA_WIDTH-1:0]  q_data_cnt  = '0;
    logic [C_PAUSE_WIDTH-1:0] q_pause_cnt = '0;
    logic [C_IDLE_WIDTH-1:0]  q_idle_cnt  = '0;
 
    logic q_clear = '0;
//// FSM-----------------------------------------------------------------  
//    always_comb begin
    
//        w_next_state = q_crnt_state;
        
//        case(q_crnt_state)
//            S0: 
//                w_next_state = (i_crc_s_ready) ? S1 : S0;
//            S1:
//                w_next_state = (i_crc_s_ready && i_crc_s_valid) ? S2 : S1;   
//            S2:
//                w_next_state = (i_crc_s_ready && i_crc_s_valid) ? S3 : S2;
//            S3:
//                w_next_state = ((q_data_cnt == C_DATA_MAX-1) && i_crc_s_ready && i_crc_s_valid) ? S4 : S3;
//            S4:
//                w_next_state = (q_pause_cnt == C_PAUSE_MAX-1) ? S5 : S4;
//            S5:
//                w_next_state = S6;
//            S6:
//                w_next_state = (q_idle_cnt == C_IDLE_MAX-1) ? S1 : S6;
//            default:
//                w_next_state = S0;
//        endcase;
//    end

// FSM-----------------------------------------------------------------  
    always_ff @(posedge i_clk) begin
    
//        w_next_state = q_crnt_state;
        
        case(q_crnt_state)
            S0: begin
                q_idle_cnt <= '0;
                q_data_cnt <= 1;
                q_crnt_state <= (i_src_tready) ? S1 : S0;
                o_src_tvalid <= '0;
                
            end
            S1: begin
                o_src_tvalid <= '1;
                o_src_tdata  <= 72;
                if (i_src_tready && o_src_tvalid) begin
                    q_crnt_state <= S2;
                    o_src_tvalid <= '0;
                end
            end
            S2:begin
                o_src_tvalid <= '1;
                o_src_tdata  <= C_DATA_MAX;
                if (i_src_tready && o_src_tvalid) begin
                    q_crnt_state <= S3;
                    o_src_tvalid <= '0;
                    o_src_tdata  <= '0;
                end          
            end
            S3: begin
                o_src_tvalid <= '1;
                if (i_src_tready && o_src_tvalid) begin
                    o_src_tdata <= q_data_cnt;
                    q_data_cnt <= q_data_cnt+1;
                    
                    if (q_data_cnt == C_DATA_MAX) begin
                        q_crnt_state <= S4;
                        q_data_cnt <= 1;
                        o_src_tvalid <= '0;
                    end
                end
            end    
            S4: begin
                q_crnt_state <= S5;
//                q_pause_cnt <= q_pause_cnt+1;
//                if (q_pause_cnt == C_PAUSE_MAX-1) begin
//                    q_crnt_state <= S5;
//                end
            end
            S5: begin
                /*o_src_tvalid <= '1;
                if (i_src_tready && o_src_tvalid) begin
                    q_data_cnt <= q_data_cnt+1;
                    if (q_data_cnt == C_DATA_MAX) begin
                        o_src_tdata <= m_crc_data;
                        q_clear <= '1;
                        q_data_cnt <= 1;
                        q_crnt_state <= S6;
                        o_src_tvalid <= '0;
                    end    
                end*/
                
                q_clear <= (i_src_tready && o_src_tvalid);
                
                o_src_tvalid <= '1;
                o_src_tlast  <= '1;
                o_src_tdata <= m_crc_data;
                if (i_src_tready && o_src_tvalid) begin
                    q_crnt_state <= S6;
                    o_src_tvalid <= '0;
                    o_src_tlast  <= '0;
                end     
//                if (q_data_cnt == C_DATA_MAX) begin
//                        q_clear <= '1;
//                        q_data_cnt <= 1;
//                        q_crnt_state <= S6;
//                end        
            end
            S6: begin
                q_crnt_state <= (q_idle_cnt == C_IDLE_MAX-1) ? S0 : S6;
                q_idle_cnt <= q_idle_cnt+1;
                q_clear <= '0;
            end
            default:
                q_crnt_state <= S0;
        endcase;
        
        if (i_rst)
            q_crnt_state <= S0;
    end

// Adding Data counter
    
    /*always_ff@(posedge i_crc_s_data) begin
        if (i_src_tready && o_src_tvalid && q_crnt_state == S3) begin
            q_data_cnt = (q_data_cnt == C_DATA_MAX-1) ? '0 : q_data_cnt+1;
        end
    end*/

// Adding 2 process for Pause and Idle counter

    /*always_comb begin
    
        if (q_crnt_state == S4) begin
            q_pause_cnt = (q_pause_cnt == C_PAUSE_MAX-1) ? '0 : q_pause_cnt+1;
        end
        
        if (q_crnt_state == S6) begin
            q_idle_cnt = (q_idle_cnt == C_IDLE_MAX-1) ? '0 :  q_idle_cnt+1;
        end
    end*/
    
// Adding process to be able to reset FSM and FSM can stepping 
 
//    always_ff@(posedge i_clk) begin
//        if (i_rst)
//            q_crnt_state <= S0;
//    end
    
// Connecting output from Source with output result from CRC
    
//    assign src_tvalid = o_crc_m_valid;
//    assign src_tdata = o_crc_m_data;


    logic m_crc_valid = '0;
    logic [G_BIT_WIDTH-1:0] m_crc_data = '0;

    
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
		.i_crc_s_rst_p (q_clear), // Sync Reset, Active High. Reset CRC To Initial Value.
		.i_crc_ini_vld ('0     ), // Input Initial Valid
		.i_crc_ini_dat ('0     ), // Input Initial Value
		.i_crc_wrd_vld (i_src_tready && o_src_tvalid), // Word Data Valid Flag 
		.o_crc_wrd_rdy (/* Nothing bcs source don't output ready*/), // Ready To Recieve Word Data
		.i_crc_wrd_dat (o_src_tdata ), // Word Data
		.o_crc_res_vld (m_crc_valid), // Output Flag of Validity, Active High for Each WORD_COUNT Number
		.o_crc_res_dat (m_crc_data )  // Output CRC from Each Input Word
    );
    
endmodule
