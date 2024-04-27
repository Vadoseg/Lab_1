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

/*interface if_axis #(parameter int N = 1) ();
	
	localparam W = 8 * N; // tdata bit width (N - number of BYTES)
	
	logic         tready;
	logic         tvalid;
	logic         tlast ;
	logic [W-1:0] tdata ;
	
	modport m(input tready, output tvalid, tlast, tdata);
endinterface : if_axis*/

module l4_source#(

// CRC Generics    
    parameter int G_BYT = 1,
    parameter int G_BIT_WIDTH = 8 * G_BYT,
    parameter int G_DATA_MAX = 10,  // Size of data pack
    parameter int G_CNT_WIDTH = ($ceil($clog2(G_DATA_MAX+1)))
)(


//For CRC      
    input i_crc_s_ready,
 
//For Source
    input i_rst,
    input i_clk,
    
    input logic [G_CNT_WIDTH-1:0] i_length, // input for size of data pack
    
    /*if_axis.m m_axis,*/
           
    input i_src_tready,
    output logic o_src_tvalid = '0,
    output logic [G_BIT_WIDTH-1:0] o_src_tdata = '0,
    output logic o_src_tlast = '0
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
    
    t_fsm_states q_crnt_state = S0;
    
// Interface init

    // initial begin           // No m_axis.tready bcs its input
    //     m_axis.tvalid = '0;
    //     m_axis.tdata  = '0;
    //     m_axis.tlast  = '0;
    // end

// Local constants    
    localparam int C_PAUSE_MAX = 20;
    localparam int C_IDLE_MAX  = 50;
    
    logic [G_CNT_WIDTH-1:0] buf_length = '0; // Needed bcs we need to remember last input on i_length
    
    localparam int C_PAUSE_WIDTH = ($ceil($clog2(C_PAUSE_MAX+1)));
    localparam int C_IDLE_WIDTH  = ($ceil($clog2(C_IDLE_MAX+1)));
    
// Making counts for states of FSM-------------------------------------    
    
    logic [G_CNT_WIDTH-1:0]  q_data_cnt  = '0;  // How to make size dynamic (Or we can use size of int [31:0])
    logic [C_PAUSE_WIDTH-1:0] q_pause_cnt = '0;
    logic [C_IDLE_WIDTH-1:0]  q_idle_cnt  = '0;
 
    logic q_clear = '0;  // We can get rid of this bcs we can use (i_src_tready && o_src_tvalid) in crc
    logic m_crc_valid = '0;
    logic [G_BIT_WIDTH-1:0] m_crc_data = '0;
// FSM-----------------------------------------------------------------  
    always_ff @(posedge i_clk) begin
        
        if (i_length > 0) 
            buf_length = i_length;

// we can make tvalid <= '1 and make signal without spaces, it will not affect generation of datapack. We will still have HEADER and LENGTH, and PAYLOAD
        
        case(q_crnt_state)
            S0: begin
                q_idle_cnt <= '0;
                q_data_cnt <= 1;
            //  q_crnt_state <= (m_axis.tready) ? S1 : S0;
            //  m_axis.tvalid  <= '0; // HOW TO WRITE m.m_axis.tvalid or m.m_axis.tvalid(without m)
                q_crnt_state <= (i_src_tready) ? S1 : S0;
                o_src_tvalid <= '0;
            end
            S1: begin
            //  m_axis.tvalid  <= '1;
            //  m_axis.tdata <= 72;
                o_src_tvalid <= '1;
                o_src_tdata  <= 72;
                if (i_src_tready && o_src_tvalid) begin  // Change to m_axis.tready && m_axis.tvalid
                    q_crnt_state <= S2;
                    o_src_tvalid <= '0;
                    // m_axis.tvalid <= '0;    
                end
            end
            S2:begin
            //  m_axis.tvalid  <= '1;
            //  m_axis.tdata <= DATA_MAX;
                o_src_tvalid <= '1;
                o_src_tdata  <= buf_length;
                if (i_src_tready && o_src_tvalid) begin  // Change to m_axis.tready && m_axis.tvalid
                    q_crnt_state <= S3;
                    // m_axis.tvalid <= '0;   
                    o_src_tvalid <= '0;
                    o_src_tdata <= q_data_cnt;
                end          
            end
            S3: begin
            //  m_axis.tvalid  <= '1;
                o_src_tvalid <= '1;
                if (i_src_tready && o_src_tvalid) begin
                    // m_axis.tdata <= q_data_cnt;
                    o_src_tdata <= q_data_cnt + 1;
                    q_data_cnt <= q_data_cnt + 1; 
                    
                    if (q_data_cnt == buf_length) begin
                        q_crnt_state <= S4;
                        q_data_cnt <= 1;
                        // m_axis.tvalid <= '0; 
                        o_src_tvalid <= '0;
                    end
                end
            end    
            S4: begin
                q_crnt_state <= S5; // ADD pause cnt (If it needed)
            end
            S5: begin                
                q_clear <= (i_src_tready && o_src_tvalid);
                // m_axis.tvalid  <= '1;
                // m_axis.tlast <= '1;
                // m_axis.tdata <= m_crc_data;
                o_src_tvalid <= '1;
                o_src_tlast  <= '1;
                o_src_tdata <= m_crc_data;
                if (i_src_tready && o_src_tvalid) begin
                    q_crnt_state <= S6;
                    // m_axis.tvalid  <= '0;
                    // m_axis.tlast <= '0;
                    o_src_tvalid <= '0;
                    o_src_tlast  <= '0;
                end            
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

    /*always_comb begin
        case(q_crnt_state)
            S0:
                q_crnt_state = (i_src_tready) ? S1 : S0; 
            S1:
                q_crnt_state = (i_src_tready && o_src_tvalid) ? S2 : S1;
            S2:
                q_crnt_state = (i_src_tready && o_src_tvalid) ? S3 : S2;
            S3:
                q_crnt_state = (i_src_tready && o_src_tvalid && (q_data_cnt == DATA_MAX)) ? S4 : S3;
            S4:
                q_crnt_state = S5;
            S5:
                q_crnt_state = (i_src_tready && o_src_tvalid) ? S6 : S5; 
            S6:
                q_crnt_state = (q_idle_cnt == C_IDLE_MAX - 1) ? S0 : S6;
            default:
                q_crnt_state = S0;
        endcase;
        
        if (i_rst)
            q_crnt_state <= S0;
    end

    always_ff@(posedge i_clk) begin
        
        if (i_length > 0) 
            buf_length = i_length;

        case(q_crnt_state)
            S0: begin
                q_idle_cnt <= '0;
                q_data_cnt <= '1;
                o_src_tvalid <= '0;
                
                DATA_MAX <= buf_length;
            end
            S1: begin
                o_src_tvalid <= '1;
                o_src_tdata  <= 72;
                o_src_tvalid <= (i_src_tready && o_src_tvalid) ? '0 : '1;
            end
            S2: begin
                o_src_tvalid <= '1;
                o_src_tdata  <= DATA_MAX;
                o_src_tvalid <= (i_src_tready && o_src_tvalid) ? '0 : '1;
                o_src_tdata <= q_data_cnt;
            end
            S3: begin
                o_src_tvalid <= '1;
                if (i_src_tready && o_src_tvalid) begin
                    o_src_tdata <= q_data_cnt + 1 ;
                    q_data_cnt <= q_data_cnt + 1; 
                    
                    if (q_data_cnt == DATA_MAX) begin
                        q_data_cnt <= 1;
                        o_src_tvalid <= '0;
                    end
                end
            end
            S5: begin
                q_clear <= (i_src_tready && o_src_tvalid);
                o_src_tvalid <= '1;
                o_src_tlast  <= '1;
                o_src_tdata <= m_crc_data;
                if (i_src_tready && o_src_tvalid) begin
                    o_src_tvalid <= '0;
                    o_src_tlast  <= '0;
                end 
            end
            S6: begin
                q_idle_cnt <= q_idle_cnt+1;
                q_clear <= '0;
            end
            default: begin
                q_idle_cnt <= '0;
                q_data_cnt <= '1;
                o_src_tvalid <= '0;
                
                DATA_MAX <= buf_length;
            end
        endcase;
    end*/
    
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
		.i_crc_wrd_vld ((i_src_tready && o_src_tvalid /*m_axis.tready && m_axis.tvalid*/) && (q_crnt_state != S1) /* && (q_crnt_state == S3)*/), // Word Data Valid Flag 
		.o_crc_wrd_rdy (/* Nothing bcs source don't output ready*/), // Ready To Recieve Word Data
		.i_crc_wrd_dat (o_src_tdata /*m_axis.tdata*/), // Word Data
		.o_crc_res_vld (m_crc_valid), // Output Flag of Validity, Active High for Each WORD_COUNT Number
		.o_crc_res_dat (m_crc_data )  // Output CRC from Each Input Word
    );
    
endmodule


