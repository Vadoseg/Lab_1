`timescale 1ns / 1ps


module l4_if_source#(
// CRC Generics    
    parameter int G_BYT = 1,
    parameter int G_BIT_WIDTH = 8 * G_BYT,
    parameter int G_DATA_MAX = 10,  // Size of data pack
    parameter int G_CNT_WIDTH = ($ceil($clog2(G_DATA_MAX+1)))
)(

//For Source
    input wire i_rst,
    input wire i_clk,
    
    input logic [G_CNT_WIDTH-1:0] i_length, // input for size of data pack
    
    if_axis.m m_axis      
    );
    
    typedef enum{
        S0 = 0,     // Length && Header
        S1 = 1,     // Payload
        S2 = 2,     // Pause
        S3 = 3      // CRC_DATA
    } t_fsm_states;
    
    t_fsm_states q_crnt_state = S0;
    
// Interface init
    initial begin           // No m_axis.tready bcs its input
        m_axis.tvalid = '0;
        m_axis.tdata  = '0;
        m_axis.tlast  = '0;
    end

// Local length buffer   
    logic [G_CNT_WIDTH-1:0] buf_length = '0; // Needed bcs we need to remember last input on i_length
    
// Making counts for FSM  
    logic [G_CNT_WIDTH-1:0]  q_data_cnt = 1;

// For CRC 
    logic m_crc_valid;
    logic [G_BIT_WIDTH-1:0] m_crc_data ;
// FSM-----------------------------------------------------------------  
    always_ff @(posedge i_clk) begin
        
        if (i_length > 0) 
            buf_length = i_length;
        
        case(q_crnt_state)
            S0: begin
                m_axis.tvalid  <= '1;
                m_axis.tdata <= 72;
                m_axis.tvalid  <= '1;

                if (m_axis.tready && m_axis.tdata == 72) begin
                    m_axis.tdata <= buf_length;
<<<<<<< Updated upstream
                end

                if (m_axis.tready && m_axis.tvalid && m_axis.tdata <= buf_length) begin
=======
                
                end

                if (m_axis.tready && m_axis.tvalid && m_axis.tdata == buf_length) begin
>>>>>>> Stashed changes
                    q_crnt_state  <= S1;
                    m_axis.tvalid <= '0;
                    m_axis.tdata  <= q_data_cnt;
                    q_data_cnt    <= q_data_cnt + 1;
                end
            end
            S1: begin
                m_axis.tvalid  <= '1;
                if (m_axis.tready && m_axis.tvalid) begin
                    m_axis.tdata <= q_data_cnt;
                    q_data_cnt   <= q_data_cnt + 1; 
                    
                    if (q_data_cnt == buf_length + 1) begin
                        q_crnt_state <= S2;
                        q_data_cnt   <= 1;
                        m_axis.tvalid <= '0; 
                    end
                end
            end  
            S2: begin
                q_crnt_state = S3;  // Need bcs m_crc_data will be still equal to 0xC2 instead of 0x5B  (Found a way to optimizate this)
            end  
            S3: begin            
                m_axis.tvalid  <= '1;
                m_axis.tlast   <= '1;
                m_axis.tdata   <= m_crc_data;
                if (m_axis.tready && m_axis.tvalid) begin
                    m_axis.tlast    <= '0;
                    q_crnt_state    <= S0;
                    m_axis.tvalid   <= '0;
                end            
            end
            
            default:
                q_crnt_state <= S0;
        endcase;
        
        if (i_rst) begin
            q_crnt_state    <= S0;
            m_axis.tvalid   <= '0;
            m_axis.tlast    <= '0;
            m_axis.tdata    <= '0;
            q_data_cnt      <=  1;
        end
    end

//Creating CRC-module inside Source
    crc#(
        .POLY_WIDTH (G_BIT_WIDTH   ),   // Size of The Polynomial Vector
		.WORD_WIDTH (G_BIT_WIDTH   ),   // Size of The Input Words Vector
		.WORD_COUNT (0   ),             // Number of Words To Calculate CRC, 0 - Always Calculate CRC On Every Input Word
		.POLYNOMIAL ('hD5),             // Polynomial Bit Vector
		.INIT_VALUE ('1  ),             // Initial Value
		.CRC_REF_IN ('0  ),             // Beginning and Direction of Calculations: 0 - Starting With MSB-First; 1 - Starting With LSB-First
		.CRC_REFOUT ('0  ),             // Determines Whether The Inverted Order of The Bits of The Register at The Entrance to The Xor Element
		.BYTES_RVRS ('0  ),             // Input Word Byte Reverse
		.XOR_VECTOR ('0  ),             // CRC Final Xor Vector
		.NUM_STAGES (2   )              // Number of Register Stages, Equivalent Latency in Module. Minimum is 1, Maximum is 3.
    ) CRC (
        .i_crc_a_clk_p (i_clk  ),       // Rising Edge Clock
		.i_crc_s_rst_p (m_axis.tready && m_axis.tvalid && q_crnt_state == S3),  // Sync Reset, Active High. Reset CRC To Initial Value.
		.i_crc_ini_vld ('0     ),       // Input Initial Valid
		.i_crc_ini_dat ('0     ),       // Input Initial Value
		.i_crc_wrd_vld ((m_axis.tready && m_axis.tvalid) && m_axis.tdata != 72),  // Word Data Valid Flag 
		.o_crc_wrd_rdy (/* Nothing bcs source don't output ready*/),    // Ready To Recieve Word Data
		.i_crc_wrd_dat (m_axis.tdata),  // Word Data
		.o_crc_res_vld (m_crc_valid),   // Output Flag of Validity, Active High for Each WORD_COUNT Number
		.o_crc_res_dat (m_crc_data )    // Output CRC from Each Input Word
    );
    
endmodule
