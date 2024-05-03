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



module l4_sink#(
    
// CRC Generics    
    parameter int G_BYT = 1,
    parameter int G_BIT_WIDTH = 8 * G_BYT
    )(
    
    input i_rst,
    input i_clk,
    
    input logic i_sink_tvalid,
    input logic [G_BIT_WIDTH-1:0] i_sink_tdata,
    input logic i_sink_tlast,
    
    output logic o_sink_good,
    output logic o_sink_error,
    output o_sink_ready
    );
    
    logic q_clear = '0; 
    logic /*[]*/ q_data_cnt = '0;
    logic [G_BIT_WIDTH-1:0] q_crc_tdata = '0;
    logic Length = '0;

    logic m_crc_valid ;
    logic [G_BIT_WIDTH-1:0] m_crc_data ;

    typedef enum{
        S0 = 0,     // Ready/Init
        S1 = 1,     // Header
        S2 = 2,     // Length
        S3 = 3,     // Payload
        S4 = 4,     // CRC_PAUSE
        S5 = 5,     // CRC_DATA
        S6 = 6      // Idle
    } t_fsm_states;

    t_fsm_states q_crnt_state = S0;
    
    always_ff@(posedge i_clk) begin
        //o_sink_tdata 
        case(q_crnt_state)
            S0: begin
                q_crnt_state <= S1;
                q_data_cnt <= 1;
            end
            S1: begin 
                if(i_sink_tvalid) begin
                    q_crc_tdata <= i_sink_tdata;   // Header
                    q_crnt_state <= S2;
                end
            end
            S2: begin 
                if(i_sink_tvalid) begin
                    Length <= i_sink_tdata;   // Length
                    q_crnt_state <= S3;
                end
            end
            S3: begin
                if(i_sink_tvalid) begin
                    q_crc_tdata <= i_sink_tdata;
                    q_data_cnt <= q_data_cnt + 1;   // Length
                    
                    if (q_data_cnt == Length + 1) begin
                        q_crnt_state <= S4;
                        q_data_cnt <= 1;
                    end
                end
            end
            S4: begin
                q_crnt_state <= S5;
            end
            S5: begin
                q_clear <= (i_sink_tvalid);
                if(i_sink_tvalid) begin
                    if(i_sink_tlast && (m_crc_data == i_sink_tdata)) begin
                        o_sink_good <= '1;
                    end
                    else if (i_sink_tlast && (m_crc_data != i_sink_tdata)) begin
                        o_sink_error <= '1;
                    end
                    o_sink_good <= '0;
                    o_sink_error <= '0;
                end
            end
        endcase
        
        if (i_rst)
            q_crnt_state <= S0;
    end
    
    
//Creating CRC inside Sink    
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
		.i_crc_wrd_vld (i_sink_tvalid && (q_crnt_state != S1)), // Word Data Valid Flag 
		.o_crc_wrd_rdy (o_sink_ready ), // Ready To Recieve Word Data
		.i_crc_wrd_dat (q_crc_tdata ), // Word Data
		.o_crc_res_vld (m_crc_valid), // Output Flag of Validity, Active High for Each WORD_COUNT Number
		.o_crc_res_dat (m_crc_data )  // Output CRC from Each Input Word
    );
    
endmodule
