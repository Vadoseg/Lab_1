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
    
    input i_reset,
    input i_clk,
    
    input i_sink_tvalid,
    input [G_BIT_WIDTH-1:0] i_sink_tdata,
    input i_sink_tlast, // WHERE TO CONNECT ????
    input i_sink_ready,
    
    output o_sink_good,
    output o_sink_error
    );
    

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
		.i_crc_s_rst_p (i_reset), // Sync Reset, Active High. Reset CRC To Initial Value.
		.i_crc_ini_vld ('0     ), // Input Initial Valid
		.i_crc_ini_dat ('0     ), // Input Initial Value
		.i_crc_wrd_vld (fifo_sink_tvalid), // Word Data Valid Flag 
		.o_crc_wrd_rdy (i_sink_ready    ), // Ready To Recieve Word Data
		.i_crc_wrd_dat (fifo_sink_tdata ), // Word Data
		.o_crc_res_vld (crc_m_valid), // Output Flag of Validity, Active High for Each WORD_COUNT Number
		.o_crc_res_dat (crc_m_data )  // Output CRC from Each Input Word
    );
    
endmodule
