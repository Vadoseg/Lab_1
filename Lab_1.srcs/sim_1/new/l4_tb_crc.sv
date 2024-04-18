`timescale 1ns / 1ps

// CRC TB
// v1.0, 17.04.2024
module tb_lab4_crc #(
// UUT generics
	int B = 1, // data byte width
	int W = 8 * B, // data bit width
	
// TB constants
	T_CLK = 1.0 // ns
);

logic i_clk   = '0; // clock
logic q_clear = '0; // clear (CRC soft reset, active-high)

logic         s_ready = '0;
logic         s_valid = '0;
logic [W-1:0] s_data  = '0;

logic         m_valid = '0;
logic [W-1:0] m_data  = '0;

// task: send test sequence
task send_pkt;
	input bit i_use_reset;
	localparam [W-1:0] C_DATA_ARR [0:8] = '{'h31, 'h32, 'h33, 'h34, 'h35, 'h36, 'h37, 'h38, 'h39};
	begin
		for (i = 0; i < $size(C_DATA_ARR); i++) begin
			s_valid = '1;
			s_data  = C_DATA_ARR[i];
			#(T_CLK);
			s_valid = '0;
		end
		#(4*T_CLK);
		q_clear = i_use_reset; // reset CRC (optional)
		#(T_CLK);
		q_clear = '0;
		#(5*T_CLK);
	end
endtask : send_pkt

// simulate input data
int i = 0;
initial begin : sim_proc
	q_clear = '0;
	s_valid = '0;
	s_data  = '0;
	#(10*T_CLK);
// send two packets w/o reset between them
	send_pkt(.i_use_reset('0));
	send_pkt(.i_use_reset('1));
// repeat w/ reset
	send_pkt(.i_use_reset('1));
	send_pkt(.i_use_reset('1));
end : sim_proc

// simulate clock
always #(T_CLK/2.0) i_clk = ~i_clk;

// unit under test: CRC
	crc #(
		.POLY_WIDTH (W   ), // Size of The Polynomial Vector
		.WORD_WIDTH (W   ), // Size of The Input Words Vector
		.WORD_COUNT (0   ), // Number of Words To Calculate CRC, 0 - Always Calculate CRC On Every Input Word
		.POLYNOMIAL ('hD5), // Polynomial Bit Vector
		.INIT_VALUE ('1  ), // Initial Value
		.CRC_REF_IN ('0  ), // Beginning and Direction of Calculations: 0 - Starting With MSB-First; 1 - Starting With LSB-First
		.CRC_REFOUT ('0  ), // Determines Whether The Inverted Order of The Bits of The Register at The Entrance to The Xor Element
		.BYTES_RVRS ('0  ), // Input Word Byte Reverse
		.XOR_VECTOR ('0  ), // CRC Final Xor Vector
		.NUM_STAGES (2   )  // Number of Register Stages, Equivalent Latency in Module. Minimum is 1, Maximum is 3.
	) u_uut (
		.i_crc_a_clk_p (i_clk  ), // Rising Edge Clock
		.i_crc_s_rst_p (q_clear), // Sync Reset, Active High. Reset CRC To Initial Value.
		.i_crc_ini_vld ('0     ), // Input Initial Valid
		.i_crc_ini_dat ('0     ), // Input Initial Value
		.i_crc_wrd_vld (s_valid), // Word Data Valid Flag 
		.o_crc_wrd_rdy (s_ready), // Ready To Recieve Word Data
		.i_crc_wrd_dat (s_data ), // Word Data
		.o_crc_res_vld (m_valid), // Output Flag of Validity, Active High for Each WORD_COUNT Number
		.o_crc_res_dat (m_data )  // Output CRC from Each Input Word
	);

endmodule : tb_lab4_crc