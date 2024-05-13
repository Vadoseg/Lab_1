`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Nickolay A. Sysoev
// 
// Create Date: 02/02/2019 16:54:27 PM
// Module Name: axis_fifo
// Tool Versions: SV 2012, Vivado 2018.3
// Description: AXI4-Stream FIFO
// 
// Dependencies: axi.sv, fifo.sv
// 
// Revision:
// Revision 1.1.0 - new fix with fifo.sv version 1.0.2
// Additional Comments: 
// 
//////////////////////////////////////////////////////////////////////////////////

(* KEEP_HIERARCHY = "Yes" *)
module axis_fifo #(
    parameter   int       DEPTH = 16, // Depth of fifo, minimum is 16, actual depth will be displayed in the information of module
    parameter             PACKET_MODE = "False", // Packet mode, when true the FIFO outputs data only when a tlast is received or the FIFO has filled
    parameter             MEM_STYLE = "Distributed", // Memory style: "Distributed" or "Block"
    parameter             DUAL_CLOCK = "False", // Dual clock fifo: "True" or "False"
    parameter   int       SYNC_STAGES = 2, // Number of synchronization stages in dual clock mode: [2, 3, 4]
    parameter             RESET_SYNC = "False", // Asynchronous reset synchronization: "True" or "False"
    parameter   bit [7:0] FEATURES = '0, // Advanced features: [ reserved, read count, prog. empty flag, almost empty, reserved, write count, prog. full flag, almost full flag ] 
    parameter   int       PROG_FULL = 12, // Programmable full threshold
    parameter   int       PROG_EMPTY = 4, // Programmable empty threshold
    localparam  int       CW = $clog2(DEPTH)+1 // Count width
  )  (
    input   wire            i_fifo_a_rst_n, // Asynchronous reset, connect only when reset synchronization is true, active low, must be asserted at least 2 slowest clock cycles

    input   wire            s_axis_a_clk_p, // Rising edge slave clock
    input   wire            s_axis_a_rst_n, // Reset synchronous to slave clock, connect only when reset synchronization is false, active low

    if_axis.s               s_axis, // AXI4-Stream slave interface

    input   wire            m_axis_a_clk_p, // Rising edge master clock
    input   wire            m_axis_a_rst_n, // Reset synchronous to master clock, connect only when reset synchronization is false, active low

    if_axis.m               m_axis, // AXI4-Stream master interface

    output  wire            o_fifo_a_tfull, // Almost full flag
    output  wire            o_fifo_p_tfull, // Programmable full flag
    output  wire  [CW-1:0]  o_fifo_w_count, // Write data count

    output  wire            o_fifo_a_empty, // Almost empty flag
    output  wire            o_fifo_p_empty, // Programmable empty flag
    output  wire  [CW-1:0]  o_fifo_r_count  // Read data count, if dual clock mode is false - output count is the same with write data count
  );

  localparam int S_PAYLOAD = s_axis.PAYLOAD;
  localparam int M_PAYLOAD = m_axis.PAYLOAD;

// Parameters check & information
  initial begin : check_param
    
    if ( S_PAYLOAD != M_PAYLOAD )
      $error("[%s %0d-%0d] Payload width between slave (%d) and master (%d) interfaces are different. %m", "AXIS_FIFO", 1, 1, S_PAYLOAD, M_PAYLOAD);
    
    if ( !(PACKET_MODE inside { "True", "False" }) )
      $error("[%s %0d-%0d] Parameter PACKET_MODE (%0s) must be 'True' or 'False'. %m", "AXIS_FIFO", 1, 2, PACKET_MODE);
      
  end : check_param

  localparam int DW = M_PAYLOAD;

// AXI-Stream payload masking
  logic [DW-1:0] s_axis_payload;
  always_comb
    s_axis_payload = s_axis.payload();

  logic [DW-1:0] m_axis_payload;
  always_comb
    m_axis.paymask(m_axis_payload);

  if ( PACKET_MODE == "True" ) begin : packet_fifo

    typedef logic [CW-1:0] t_cnt; // Type for counter

    typedef struct packed { bit R_RSRVD, R_COUNT, P_EMPTY, A_EMPTY, W_RSRVD, W_COUNT, P_TFULL, A_TFULL; } t_fts;

    localparam t_fts FEATURE = FEATURES;

    wire s_axis_s_rst_p;
    wire m_axis_s_rst_p;

    fifo_reset #(
      .SYNC_STAGES ( SYNC_STAGES ),
      .RESET_SYNC  ( RESET_SYNC )
    ) u_axis_reset (
      .i_fifo_a_rst_p (!i_fifo_a_rst_n ),
      .i_fifo_w_rst_p (!s_axis_a_rst_n ),
      .i_fifo_w_clk_p ( s_axis_a_clk_p ),
      .i_fifo_r_rst_p (!m_axis_a_rst_n ),
      .i_fifo_r_clk_p ( m_axis_a_clk_p ),
      .o_fifo_w_rst_p ( s_axis_s_rst_p ),
      .o_fifo_r_rst_p ( m_axis_s_rst_p )
    );

    wire w_axis_tvalid;
    wire w_axis_tready;
    wire w_fifo_a_tfull;

    fifo #(
      .DW ( DW ),
      .DEPTH ( DEPTH ),
      .FWFT ( "True" ),
      .MEM_STYLE ( MEM_STYLE ),
      .DUAL_CLOCK ( DUAL_CLOCK ),
      .SYNC_STAGES ( SYNC_STAGES ),
      .RESET_SYNC ( "False" ),
      .PROG_FULL ( PROG_FULL ),
      .PROG_EMPTY ( PROG_EMPTY ),
      .FEATURES ( { 1'b1, FEATURES[6:4], 1'b1, FEATURES[2:1], 1'b1 } )
    ) u_fifo (
      .i_fifo_a_rst_p ( '0 ),
      .i_fifo_w_rst_p ( s_axis_s_rst_p ),
      .i_fifo_w_clk_p ( s_axis_a_clk_p ),
      .i_fifo_w_valid ( s_axis.tvalid ),
      .i_fifo_w_value ( s_axis_payload ),
      .o_fifo_w_tfull ( s_axis.tready ),
      .o_fifo_a_tfull ( w_fifo_a_tfull ),
      .o_fifo_p_tfull ( o_fifo_p_tfull ),
      .o_fifo_w_count ( o_fifo_w_count ),
      .i_fifo_r_rst_p ( m_axis_s_rst_p ),
      .i_fifo_r_clk_p ( m_axis_a_clk_p ),
      .i_fifo_r_query ( w_axis_tready ),
      .o_fifo_r_valid (  ),
      .o_fifo_r_value ( m_axis_payload ),
      .o_fifo_r_empty ( w_axis_tvalid ),
      .o_fifo_a_empty ( o_fifo_a_empty ),
      .o_fifo_p_empty ( o_fifo_p_empty ),
      .o_fifo_r_count ( o_fifo_r_count ) 
    );

    logic q_pack_r_valid = '0;

    if ( DUAL_CLOCK == "True" ) begin : double_clock

      t_cnt s_pack_w_count = '0;
      always_ff @(posedge s_axis_a_clk_p)
        if ( s_axis_s_rst_p )
          s_pack_w_count <= '0;
        else if ( s_axis.tvalid && s_axis.tready && s_axis.tlast )
          s_pack_w_count <= s_pack_w_count + 1;

      wire t_cnt s_mclk_w_count;

      fifo_cdc #(
        .SW ( CW ),
        .CDC_CONFIG ( "GRAY" ),
        .SYNC_STAGES ( SYNC_STAGES ),
        .SOURCE_REG ( '1 ),
        .OUTPUT_REG ( '1 )
      ) u_cdc_wr_counter (
        .i_src_s_rst_p ( '0 ),
        .i_src_a_clk_p ( s_axis_a_clk_p ),
        .i_src_cdc_sig ( s_pack_w_count ),

        .i_dst_s_rst_p ( '0 ),
        .i_dst_a_clk_p ( m_axis_a_clk_p ),
        .o_dst_cdc_sig ( s_mclk_w_count )
      );

      wire m_fifo_a_tfull;

      fifo_cdc #(
        .SW ( 1 ),
        .CDC_CONFIG ( "BUS" ),
        .SYNC_STAGES ( SYNC_STAGES ),
        .SOURCE_REG ( '0 ),
        .OUTPUT_REG ( '0 )
      ) u_cdc_a_tfull (
        .i_src_s_rst_p ( '0 ),
        .i_src_a_clk_p ( s_axis_a_clk_p ),
        .i_src_cdc_sig ( w_fifo_a_tfull ),

        .i_dst_s_rst_p ( '0 ),
        .i_dst_a_clk_p ( m_axis_a_clk_p ),
        .o_dst_cdc_sig ( m_fifo_a_tfull )
      );

      t_cnt q_mclk_r_count = '0;

      wire  m_pack_r_valid = w_axis_tvalid && m_axis.tready && m_axis.tlast;

      always_ff @(posedge m_axis_a_clk_p)
        if ( m_axis_s_rst_p )
          q_mclk_r_count <= '0;
        else if ( m_pack_r_valid )
          q_mclk_r_count <= q_mclk_r_count + 1;

      t_cnt q_pack_counter = '0;
      always_ff @(posedge m_axis_a_clk_p)
        if ( m_axis_s_rst_p )
          q_pack_counter <= '0;
        else if ( m_pack_r_valid )
          q_pack_counter <= q_pack_counter - 1;
        else
          q_pack_counter <= s_mclk_w_count - q_mclk_r_count;

      always_ff @(posedge m_axis_a_clk_p)
        if ( m_axis_s_rst_p )
          q_pack_r_valid <= '0;
        else if ( m_pack_r_valid && q_pack_counter == 1 )
          q_pack_r_valid <= '0;
        else if ( q_pack_counter != 0 || m_fifo_a_tfull )
          q_pack_r_valid <= '1;
        else if ( !m_fifo_a_tfull )
          q_pack_r_valid <= '0;

    end : double_clock else begin : single_clock

      logic s_pack_w_valid = '0;
      always_ff @(posedge s_axis_a_clk_p)
        if ( s_axis_s_rst_p )
          s_pack_w_valid <= '0;
        else
          s_pack_w_valid <= s_axis.tvalid && s_axis.tready && s_axis.tlast;

      wire m_pack_r_valid = w_axis_tvalid && m_axis.tready && m_axis.tlast;

      t_cnt q_pack_counter = '0;
      always_ff @(posedge m_axis_a_clk_p)
        if ( m_axis_s_rst_p )
          q_pack_counter <= '0;
        else if ( s_pack_w_valid && !m_pack_r_valid )
          q_pack_counter <= q_pack_counter + 1;
        else if ( m_pack_r_valid && !s_pack_w_valid )
          q_pack_counter <= q_pack_counter - 1;
      
      always_ff @(posedge m_axis_a_clk_p)
        if ( m_axis_s_rst_p )
          q_pack_r_valid <= '0;
        else if ( !s_pack_w_valid && m_pack_r_valid && q_pack_counter == 1 )
          q_pack_r_valid <= '0;
        else if ( q_pack_counter != 0 || w_fifo_a_tfull )
          q_pack_r_valid <= '1;
        else if ( !w_fifo_a_tfull )
          q_pack_r_valid <= '0;

    end : single_clock

    assign w_axis_tready = q_pack_r_valid && w_axis_tvalid && m_axis.tready;
    assign m_axis.tvalid = q_pack_r_valid && w_axis_tvalid;
    assign o_fifo_a_tfull = ( FEATURE.A_TFULL ) ? w_fifo_a_tfull : '0;

  end : packet_fifo else begin : stream_fifo

    fifo #(
      .DW ( DW ),
      .DEPTH ( DEPTH ),
      .FWFT ( "True" ),
      .MEM_STYLE ( MEM_STYLE ),
      .DUAL_CLOCK ( DUAL_CLOCK ),
      .SYNC_STAGES ( SYNC_STAGES ),
      .RESET_SYNC ( RESET_SYNC ),
      .PROG_FULL ( PROG_FULL ),
      .PROG_EMPTY ( PROG_EMPTY ),
      .FEATURES ( { 1'b1, FEATURES[6:4], 1'b1, FEATURES[2:0] } )
    ) u_fifo (
      .i_fifo_a_rst_p (!i_fifo_a_rst_n ),
      .i_fifo_w_rst_p (!s_axis_a_rst_n ),
      .i_fifo_w_clk_p ( s_axis_a_clk_p ),
      .i_fifo_w_valid ( s_axis.tvalid ),
      .i_fifo_w_value ( s_axis_payload ),
      .o_fifo_w_tfull ( s_axis.tready ),
      .o_fifo_a_tfull ( o_fifo_a_tfull ),
      .o_fifo_p_tfull ( o_fifo_p_tfull ),
      .o_fifo_w_count ( o_fifo_w_count ),
      .i_fifo_r_rst_p (!m_axis_a_rst_n ),
      .i_fifo_r_clk_p ( m_axis_a_clk_p ),
      .i_fifo_r_query ( m_axis.tready ),
      .o_fifo_r_valid (  ),
      .o_fifo_r_value ( m_axis_payload ),
      .o_fifo_r_empty ( m_axis.tvalid ),
      .o_fifo_a_empty ( o_fifo_a_empty ),
      .o_fifo_p_empty ( o_fifo_p_empty ),
      .o_fifo_r_count ( o_fifo_r_count ) 
    );
    
  end : stream_fifo

endmodule : axis_fifo
