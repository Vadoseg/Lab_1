`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Nickolay A. Sysoev
// 
// Create Date: 02/02/2019 16:54:27 PM
// Module Name: fifo
// Tool Versions: SV 2012, Vivado 2018.3
// Description: FIFO
// 
// Dependencies: -
// 
// Revision:
// Revision 1.0.2 - some code optimization
// Additional Comments:
//  1) Inverse flags are used primarily to indicate readiness for writing and read validity.
//
////////////////////////////////////////////////////////////////////////////////// 

(* KEEP_HIERARCHY = "Yes" *)
module fifo #(
    parameter  int          DW = 16, // Data write width
    parameter  int          DR = DW, // Data read width, aspect ratio must be 1:1, 1:2, 1:4, 1:8, 8:1, 4:1 or 2:1 of data write width
    parameter  int          DEPTH = 16, // Write depth of fifo, minimum is 16, actual depth will be displayed in the information of module
    parameter               FWFT = "False", // First Word Fall Through: "True" ( FWFT Mode ) or "False" ( Normal Mode )
    parameter               MEM_STYLE = "Distributed", // Memory style: "Distributed" or "Block"
    parameter               EXTRA_REG = "False", // Adds an extra register to the memory output in Normal Mode, latency increased by 2
    parameter               DUAL_CLOCK = "False", // Dual clock fifo: "True" or "False"
    parameter  int          SYNC_STAGES = 2, // Number of synchronization stages: [2, 3, 4]
    parameter               RESET_SYNC = "False", // Asynchronous reset synchronization: "True" or "False"
    parameter  int          PROG_FULL = 8, // Programmable full threshold
    parameter  int          PROG_EMPTY = 8, // Programmable empty threshold
    parameter  bit [DR-1:0] RESET_VALUE = '0, // Output data value when reset is asserted
    parameter  bit [   7:0] FEATURES = '0, // Use advanced features: { inverse full and empty flags, read count, prog. empty flag, almost empty, full flag reset, write count, prog. full flag, almost full flag }
    localparam int          CW = $clog2(DEPTH)+1, // Write count width
    localparam int          CR = $clog2(DEPTH*DW/DR)+1 // Read count width
  )  (
    input   wire            i_fifo_a_rst_p, // Asynchronous reset, connect only when reset synchronization is true, active high, must be asserted at least 2 slowest clock cycles

    input   wire            i_fifo_w_rst_p, // Reset synchronous to write clock, connect only when reset synchronization is false, active high
    input   wire            i_fifo_w_clk_p, // Rising edge write clock

    input   wire            i_fifo_w_valid, // Write valid
    input   wire  [DW-1:0]  i_fifo_w_value, // Write value
    output  wire            o_fifo_w_tfull, // Write full flag

    output  wire            o_fifo_a_tfull, // Almost full flag
    output  wire            o_fifo_p_tfull, // Programmable full flag
    output  wire  [CW-1:0]  o_fifo_w_count, // Write data count

    input   wire            i_fifo_r_rst_p, // Reset synchronous to read clock, connect only when reset synchronization is false, active high
    input   wire            i_fifo_r_clk_p, // Rising edge read clock, if dual clock mode is false - connect the same clock as in i_fifo_w_clk_p

    input   wire            i_fifo_r_query, // Read query
    output  wire            o_fifo_r_valid, // Read valid
    output  wire  [DR-1:0]  o_fifo_r_value, // Read value
    output  wire            o_fifo_r_empty, // Read empty flag

    output  wire            o_fifo_a_empty, // Almost empty flag
    output  wire            o_fifo_p_empty, // Programmable empty flag
    output  wire  [CR-1:0]  o_fifo_r_count // Read data count, if dual clock mode is false - output count is the same with write data count
  );

  typedef struct packed { bit INVERSE, R_COUNT, P_EMPTY, A_EMPTY, W_RESET, W_COUNT, P_TFULL, A_TFULL; } t_fts;

  localparam t_fts FEATURE = FEATURES;

  localparam int AW = ( DEPTH < 16 ) ? $clog2(16) : $clog2(DEPTH);
  localparam int AR = $clog2(2**AW*DW/DR);
  localparam int RE = ( FWFT == "True" || EXTRA_REG == "True" ) ? 2 : 1; // Read enable max width
  localparam int N = ( FEATURE.A_TFULL || FEATURE.A_EMPTY ) ? 3 : 2; // Number of output addresses 2 or 3

  localparam int PW = ( DUAL_CLOCK == "True" ) ? AW+1 : AW;
  localparam int PR = ( DUAL_CLOCK == "True" ) ? AR+1 : AR;
  
  // Parameters check & information
  initial begin : param_check

    localparam int FIFO_DEPTH = ( FWFT == "True" ) ? 2**AW+2 : 2**AW;
    localparam int READ_DEPTH = ( FWFT == "True" ) ? 2**AR+2 : 2**AR;
    
    if ( !(FWFT == "True" || FWFT == "False") )
      $error("[%s %0d-%0d] Parameter FWFT (%0s) must be 'True' or 'False'. %m", "FIFO", 1, 1, FWFT);
    if ( !(MEM_STYLE == "Block" || MEM_STYLE == "Distributed") )
      $error("[%s %0d-%0d] Parameter MEM_STYLE (%0s) must be 'Block' or 'Distributed'. %m", "FIFO", 1, 2, MEM_STYLE);
    if ( !(EXTRA_REG == "True" || EXTRA_REG == "False") )
      $error("[%s %0d-%0d] Parameter EXTRA_REG (%0s) must be 'True' or 'False'. %m", "FIFO", 1, 3, EXTRA_REG);
    if ( !(DUAL_CLOCK == "True" || DUAL_CLOCK == "False") )
      $error("[%s %0d-%0d] Parameter DUAL_CLOCK (%0s) must be 'True' or 'False'. %m", "FIFO", 1, 4, DUAL_CLOCK);
    if ( !(SYNC_STAGES inside {[2:4]}) )
      $error("[%s %0d-%0d] Parameter SYNC_STAGES (%0d) must be 2, 3 or 4. %m", "FIFO", 1, 5, SYNC_STAGES);
    if ( !(RESET_SYNC == "True" || RESET_SYNC == "False") )
      $error("[%s %0d-%0d] Parameter RESET_SYNC (%0s) must be 'True' or 'False'. %m", "FIFO", 1, 6, RESET_SYNC);
    if ( !(PROG_FULL inside {[2:FIFO_DEPTH-2]}) )
      $error("[%s %0d-%0d] Parameter PROG_FULL (%0d) must be between 2 and %0d. %m", "FIFO", 1, 7, PROG_FULL, FIFO_DEPTH-2);
    if ( AR == AW && !(PROG_EMPTY inside {[2:FIFO_DEPTH-2]}) )
      $error("[%s %0d-%0d] Parameter PROG_EMPTY (%0d) must be between 2 and %0d. %m", "FIFO", 1, 8, PROG_EMPTY, FIFO_DEPTH-2);
    else if ( AW > AR && !(PROG_EMPTY inside {[2:READ_DEPTH-2]}) )
      $error("[%s %0d-%0d] Parameter PROG_EMPTY (%0d) must be between 2 and %0d. %m", "FIFO", 1, 9, PROG_EMPTY, READ_DEPTH-2);
    else if ( AR > AW && !(PROG_EMPTY inside {[2**(AR-AW):READ_DEPTH-2]}) )
      $error("[%s %0d-%0d] Parameter PROG_EMPTY (%0d) must be between %0d and %0d. %m", "FIFO", 1, 10, PROG_EMPTY, 2**(AR-AW), READ_DEPTH-2);
    if ( DW != DR && MEM_STYLE != "Block" )
      $error("[%s %0d-%0d] Data write and read width must be equal in memory style (%0s). %m", "FIFO", 1, 11, MEM_STYLE);
    if ( DW != DR && DW != 2*DR && DW != 4*DR && DW != 8*DR && DR != 2*DW && DR != 4*DW && DR != 8*DW )
      $error("[%s %0d-%0d] Write (%0d) and read (%0d) width aspect ratio must be 1:1, 1:2, 1:4, 1:8, 8:1, 4:1 or 2:1. %m", "FIFO", 1, 12, DW, DR);
    if ( AR < 4 )
      $error("[%s %0d-%0d] Read depth (%0d) must be greater than 16. %m", "FIFO", 1, 13, 2**AR);

    if ( AW == AR ) begin
      $info("[%s %0d-%0d] Actual fifo depth is %0d. %m", "FIFO", 2, 1, FIFO_DEPTH);
    end else begin
      $info("[%s %0d-%0d] Actual write depth is %0d. %m", "FIFO", 2, 2, FIFO_DEPTH);
      $info("[%s %0d-%0d] Actual read depth is %0d. %m", "FIFO", 2, 3, READ_DEPTH);
    end

  end : param_check

  wire m_fifo_w_rst_p;
  wire m_fifo_r_rst_p;

  fifo_reset #(
    .SYNC_STAGES ( SYNC_STAGES ),
    .DUAL_CLOCK ( DUAL_CLOCK ),
    .RESET_SYNC ( RESET_SYNC )
  ) u_reset (
    .i_fifo_a_rst_p ( i_fifo_a_rst_p ),

    .i_fifo_w_rst_p ( i_fifo_w_rst_p ),
    .i_fifo_w_clk_p ( i_fifo_w_clk_p ),

    .i_fifo_r_rst_p ( i_fifo_r_rst_p ),
    .i_fifo_r_clk_p ( i_fifo_r_clk_p ),

    .o_fifo_w_rst_p ( m_fifo_w_rst_p ),
    .o_fifo_r_rst_p ( m_fifo_r_rst_p )
  );

  wire m_fifo_w_allow;
  wire [N-1:0][PW-1:0] m_fifo_wr_addr;

  fifo_wr_addr #(
    .AW ( PW ),
    .N ( N )
  ) u_wr_addr (
    .i_fifo_w_rst_p ( m_fifo_w_rst_p ),
    .i_fifo_w_clk_p ( i_fifo_w_clk_p ),
    .i_fifo_w_allow ( m_fifo_w_allow ),
    .o_fifo_wr_addr ( m_fifo_wr_addr )
  );

  wire m_fifo_r_allow;
  wire [N-1:0][PR-1:0] m_fifo_rd_addr;

  fifo_rd_addr #(
    .AR ( PR ),
    .N ( N )
  ) u_rd_addr (
    .i_fifo_r_rst_p ( m_fifo_r_rst_p ),
    .i_fifo_r_clk_p ( i_fifo_r_clk_p ),
    .i_fifo_r_allow ( m_fifo_r_allow ),
    .o_fifo_rd_addr ( m_fifo_rd_addr )
  );

  wire m_fifo_ram_wen;
  wire [RE-1:0] m_fifo_ram_ren;

  fifo_control #(
    .AW ( PW ),
    .AR ( PR ),
    .FWFT ( FWFT ),
    .EXTRA_REG ( EXTRA_REG ),
    .DUAL_CLOCK ( DUAL_CLOCK ),
    .SYNC_STAGES ( SYNC_STAGES ),
    .PROG_FULL ( PROG_FULL ),
    .PROG_EMPTY ( PROG_EMPTY ),
    .FEATURES ( FEATURES ),
    .N ( N ),
    .RE ( RE )
  ) u_control (
    .i_fifo_w_rst_p ( m_fifo_w_rst_p ),
    .i_fifo_w_clk_p ( i_fifo_w_clk_p ),

    .i_fifo_w_valid ( i_fifo_w_valid ),
    .i_fifo_wr_addr ( m_fifo_wr_addr ),
    .o_fifo_w_allow ( m_fifo_w_allow ),
    .o_fifo_ram_wen ( m_fifo_ram_wen ),
    .o_fifo_w_tfull ( o_fifo_w_tfull ),

    .o_fifo_a_tfull ( o_fifo_a_tfull ),
    .o_fifo_p_tfull ( o_fifo_p_tfull ),
    .o_fifo_w_count ( o_fifo_w_count ),

    .i_fifo_r_rst_p ( m_fifo_r_rst_p ),
    .i_fifo_r_clk_p ( i_fifo_r_clk_p ),

    .i_fifo_r_query ( i_fifo_r_query ),
    .i_fifo_rd_addr ( m_fifo_rd_addr ),
    .o_fifo_r_allow ( m_fifo_r_allow ),
    .o_fifo_ram_ren ( m_fifo_ram_ren ),
    .o_fifo_r_empty ( o_fifo_r_empty ),

    .o_fifo_a_empty ( o_fifo_a_empty ),
    .o_fifo_p_empty ( o_fifo_p_empty ),
    .o_fifo_r_count ( o_fifo_r_count ),

    .o_fifo_r_valid ( o_fifo_r_valid )
  );

  fifo_ram #(
    .DW ( DW ),
    .DR ( DR ),
    .AW ( AW ),
    .AR ( AR ),
    .FWFT ( FWFT ),
    .MEM_STYLE ( MEM_STYLE ),
    .EXTRA_REG ( EXTRA_REG ),
    .RESET_VALUE ( RESET_VALUE ),
    .RE ( RE )
  ) u_ram (
    .i_fifo_r_rst_p ( m_fifo_r_rst_p ),

    .i_fifo_w_clk_p ( i_fifo_w_clk_p ),

    .i_fifo_wr_addr ( m_fifo_wr_addr[N-1][AW-1:0] ),
    .i_fifo_ram_wen ( m_fifo_ram_wen ),
    .i_fifo_w_value ( i_fifo_w_value ),

    .i_fifo_r_clk_p ( i_fifo_r_clk_p ),

    .i_fifo_rd_addr ( m_fifo_rd_addr[N-1][AR-1:0] ),
    .i_fifo_ram_ren ( m_fifo_ram_ren ),
    .o_fifo_r_value ( o_fifo_r_value )
  );

endmodule : fifo

(* KEEP_HIERARCHY = "Soft" *)
module fifo_reset #( 
    parameter int SYNC_STAGES = 2, // Number of synchronization stages: [2, 3, 4]
    parameter     DUAL_CLOCK = "False", // Dual clock fifo: "True" or "False"
    parameter     RESET_SYNC = "False" // Asynchronous reset synchronization: "True" or "False"
  )  (
    input   wire  i_fifo_a_rst_p, // Async reset, active high, must be asserted at least 2 slowest clock cycles

    input   wire  i_fifo_w_rst_p, // Reset synchronous to write clock, active high
    input   wire  i_fifo_w_clk_p, // Rising edge write clock

    input   wire  i_fifo_r_rst_p, // Reset synchronous to read clock, active high
    input   wire  i_fifo_r_clk_p, // Rising edge read clock

    output  wire  o_fifo_w_rst_p, // Reset synchronous to write clock, active high
    output  wire  o_fifo_r_rst_p // Reset synchronous to read clock, active high
  );

  if ( RESET_SYNC == "True" ) begin : with_sync

    // Write reset synchronization
    wire m_rclk_w_rst_p;

    fifo_cdc #(
      .SW ( 1 ),
      .CDC_CONFIG ( "ASYNC_RESET" ),
      .SYNC_STAGES ( SYNC_STAGES ),
      .SOURCE_REG ( '0 ),
      .OUTPUT_REG ( '0 ),
      .RESET_POLARITY ( '1 )
    ) u_rclk_w_rst_p (
      .i_src_s_rst_p ( '0 ),
      .i_src_a_clk_p ( '0 ),
      .i_src_cdc_sig ( i_fifo_a_rst_p ),

      .i_dst_s_rst_p ( '0 ),
      .i_dst_a_clk_p ( i_fifo_r_clk_p ),
      .o_dst_cdc_sig ( m_rclk_w_rst_p )
    );

    wire m_wclk_w_rst_p;

    fifo_cdc #(
      .SW ( 1 ),
      .CDC_CONFIG ( "ASYNC_RESET" ),
      .SYNC_STAGES ( SYNC_STAGES ),
      .SOURCE_REG ( '0 ),
      .OUTPUT_REG ( '0 ),
      .RESET_POLARITY ( '1 )
    ) u_wclk_w_rst_p (
      .i_src_s_rst_p ( '0 ),
      .i_src_a_clk_p ( '0 ),
      .i_src_cdc_sig ( m_rclk_w_rst_p ),

      .i_dst_s_rst_p ( '0 ),
      .i_dst_a_clk_p ( i_fifo_w_clk_p ),
      .o_dst_cdc_sig ( m_wclk_w_rst_p )
    );

    logic q_wclk_w_rst_p = '1;
    always_ff @(posedge i_fifo_w_clk_p)
      q_wclk_w_rst_p <= m_wclk_w_rst_p;

    logic q_fifo_w_rst_p = '1;
    always_ff @(posedge i_fifo_w_clk_p)
      if ( m_wclk_w_rst_p && !q_wclk_w_rst_p )
        q_fifo_w_rst_p <= '1;
      else if ( q_wclk_w_rst_p && !m_wclk_w_rst_p )
        q_fifo_w_rst_p <= '0;

    assign o_fifo_w_rst_p = q_fifo_w_rst_p;

    // Read reset synchronization
    wire m_wclk_r_rst_p;

    fifo_cdc #(
      .SW ( 1 ),
      .CDC_CONFIG ( "ASYNC_RESET" ),
      .SYNC_STAGES ( SYNC_STAGES ),
      .SOURCE_REG ( '0 ),
      .OUTPUT_REG ( '0 ),
      .RESET_POLARITY ( '1 )
    ) u_wclk_r_rst_p (
      .i_src_s_rst_p ( '0 ),
      .i_src_a_clk_p ( '0 ),
      .i_src_cdc_sig ( i_fifo_a_rst_p ),

      .i_dst_s_rst_p ( '0 ),
      .i_dst_a_clk_p ( i_fifo_w_clk_p ),
      .o_dst_cdc_sig ( m_wclk_r_rst_p )
    );

    wire m_rclk_r_rst_p;

    fifo_cdc #(
      .SW ( 1 ),
      .CDC_CONFIG ( "ASYNC_RESET" ),
      .SYNC_STAGES ( SYNC_STAGES ),
      .SOURCE_REG ( '0 ),
      .OUTPUT_REG ( '0 ),
      .RESET_POLARITY ( '1 )
    ) u_rclk_r_rst_p (
      .i_src_s_rst_p ( '0 ),
      .i_src_a_clk_p ( '0 ),
      .i_src_cdc_sig ( m_wclk_r_rst_p ),

      .i_dst_s_rst_p ( '0 ),
      .i_dst_a_clk_p ( i_fifo_r_clk_p ),
      .o_dst_cdc_sig ( m_rclk_r_rst_p )
    );

    logic q_rclk_r_rst_p = '1;
    always_ff @(posedge i_fifo_r_clk_p)
      q_rclk_r_rst_p <= m_rclk_r_rst_p;

    logic q_fifo_r_rst_p = '1;
    always_ff @(posedge i_fifo_r_clk_p)
      if ( m_rclk_r_rst_p && !q_rclk_r_rst_p )
        q_fifo_r_rst_p <= '1;
      else if ( q_rclk_r_rst_p && !m_rclk_r_rst_p )
        q_fifo_r_rst_p <= '0;

    assign o_fifo_r_rst_p = q_fifo_r_rst_p;

  end : with_sync else begin : wout_sync

    wire w_power_on_rst;

    if ( DUAL_CLOCK == "False" ) begin : sync_clock

      logic q_power_on_rst [2] = '{default:'1};
      always_ff @(posedge i_fifo_w_clk_p)
        q_power_on_rst[0] <= '0;
      always_ff @(posedge i_fifo_w_clk_p)
        q_power_on_rst[1] <= q_power_on_rst[0];

      assign w_power_on_rst = q_power_on_rst[1];

    end : sync_clock else begin : dual_clock

      assign w_power_on_rst = '0;

    end : dual_clock

    assign o_fifo_w_rst_p = i_fifo_w_rst_p || w_power_on_rst;
    assign o_fifo_r_rst_p = i_fifo_r_rst_p || w_power_on_rst;

  end : wout_sync

endmodule : fifo_reset

(* KEEP_HIERARCHY = "Soft" *)
module fifo_wr_addr #(
    parameter   int AW = 4, // Depth of write fifo = 2^AW, AW > 3
    parameter   int N = 2, // Number of output addresses 2 or 3
    localparam  int WA = N*AW // Write address max width
  )  (
    input   wire            i_fifo_w_rst_p, // Write reset, active high
    input   wire            i_fifo_w_clk_p, // Rising edge write clock
    input   wire            i_fifo_w_allow, // Allow write address increment
    output  wire  [WA-1:0]  o_fifo_wr_addr // Output write address
  );

  (* SHREG_EXTRACT = "No" *) logic [N-1:0][AW-1:0] q_fifo_wr_addr = ( N == 3 ) ? { AW'(0), AW'(1), AW'(2) } : { AW'(0), AW'(1) };

  always_ff @(posedge i_fifo_w_clk_p)
    if ( i_fifo_w_rst_p )
      q_fifo_wr_addr[0] <= AW'(N-1);
    else if ( i_fifo_w_allow )
      q_fifo_wr_addr[0] <= q_fifo_wr_addr[0] + 1;

  always_ff @(posedge i_fifo_w_clk_p)
    if ( i_fifo_w_rst_p )
      q_fifo_wr_addr[1] <= AW'(N-2);
    else if ( i_fifo_w_allow )
      q_fifo_wr_addr[1] <= q_fifo_wr_addr[0];

  if ( N == 3 ) begin : a_tfull

    always_ff @(posedge i_fifo_w_clk_p)
      if ( i_fifo_w_rst_p )
        q_fifo_wr_addr[2] <= AW'(N-3);
      else if ( i_fifo_w_allow )
        q_fifo_wr_addr[2] <= q_fifo_wr_addr[1];
  
  end : a_tfull

  assign o_fifo_wr_addr = q_fifo_wr_addr;

endmodule : fifo_wr_addr

(* KEEP_HIERARCHY = "Soft" *)
module fifo_rd_addr #(
    parameter   int AR = 4, // Depth of read fifo = 2^AR, AR > 3
    parameter   int N = 2, // Number of output addresses 2 or 3
    localparam  int RA = N*AR // Read address max width
  )  (
    input   wire            i_fifo_r_rst_p, // Read reset, active high    
    input   wire            i_fifo_r_clk_p, // Rising edge read clock
    input   wire            i_fifo_r_allow, // Allow read address increment
    output  wire  [RA-1:0]  o_fifo_rd_addr  // Output read address
  );

  (* SHREG_EXTRACT = "No" *) logic [N-1:0][AR-1:0] q_fifo_rd_addr = ( N == 3 ) ? { AR'(0), AR'(1), AR'(2) } : { AR'(0), AR'(1) };
  
  always_ff @(posedge i_fifo_r_clk_p)
    if ( i_fifo_r_rst_p )
      q_fifo_rd_addr[0] <= AR'(N-1);
    else if ( i_fifo_r_allow )
      q_fifo_rd_addr[0] <= q_fifo_rd_addr[0] + 1;

  always_ff @(posedge i_fifo_r_clk_p)
    if ( i_fifo_r_rst_p )
      q_fifo_rd_addr[1] <= AR'(N-2);
    else if ( i_fifo_r_allow )
      q_fifo_rd_addr[1] <= q_fifo_rd_addr[0];

  if ( N == 3 ) begin : a_empty

    always_ff @(posedge i_fifo_r_clk_p)
      if ( i_fifo_r_rst_p )
        q_fifo_rd_addr[2] <= AR'(N-3);
      else if ( i_fifo_r_allow )
        q_fifo_rd_addr[2] <= q_fifo_rd_addr[1];

  end : a_empty

  assign o_fifo_rd_addr = q_fifo_rd_addr;

endmodule : fifo_rd_addr

(* KEEP_HIERARCHY = "Soft" *)
module fifo_control #(
    parameter   int       AW = 4, // Address write width = 2^AW, AW > 3
    parameter   int       AR = AW, // Address read width = 2^AR, AR > 3
    parameter             FWFT = "False", // First Word Fall Through: "True" or "False"
    parameter             EXTRA_REG = "False", // Adds an extra register to the memory output in normal mode, latency increased by 2
    parameter             DUAL_CLOCK = "False", // Dual clock fifo: "True" or "False"
    parameter   int       SYNC_STAGES = 2, // Number of synchronization stages in dual clock mode: [2, 3, 4]
    parameter   int       PROG_FULL = 12, // Programmable full threshold
    parameter   int       PROG_EMPTY = 4, // Programmable empty threshold
    parameter   bit [7:0] FEATURES = '0, // Use advanced features: [ 7 - inverse full and empty flags | 6 - read count | 5 - prog. empty flag | 4 - almost empty | 3 - full flag reset | 2 - write count | 1 - prog. full flag | 0 - almost full flag ]
    parameter   int       N = 2, // Number of output addresses 2 or 3 
    parameter   int       RE = ( FWFT == "True" || EXTRA_REG == "True" ) ? 2 : 1, // Read enable max width
    localparam  int       WA = N*AW, // Write address max width
    localparam  int       RA = N*AR, // Read address max width
    localparam  int       CW = ( DUAL_CLOCK == "True" ) ? AW : AW+1, // Write counter width
    localparam  int       CR = ( DUAL_CLOCK == "True" ) ? AR : AR+1 // Read counter width
  )  (
    input   wire            i_fifo_w_rst_p, // Write reset, active high
    input   wire            i_fifo_w_clk_p, // Rising edge write clock

    input   wire            i_fifo_w_valid, // Write valid
    input   wire  [WA-1:0]  i_fifo_wr_addr, // Write address
    output  wire            o_fifo_w_allow, // Allow write address increment
    output  wire            o_fifo_ram_wen, // RAM write enable
    output  wire            o_fifo_w_tfull, // Write full flag
    
    output  wire            o_fifo_a_tfull, // Almost full flag
    output  wire            o_fifo_p_tfull, // Programmable full flag
    output  wire  [CW-1:0]  o_fifo_w_count, // Write data count
    
    input   wire            i_fifo_r_rst_p, // Read reset, active high
    input   wire            i_fifo_r_clk_p, // Rising edge read clock

    input   wire            i_fifo_r_query, // Read query
    input   wire  [RA-1:0]  i_fifo_rd_addr, // Read address
    output  wire            o_fifo_r_allow, // Allow read address increment
    output  wire  [RE-1:0]  o_fifo_ram_ren, // RAM read enable 
    output  wire            o_fifo_r_empty, // Read empty flag 
    
    output  wire            o_fifo_a_empty, // Almost empty flag
    output  wire            o_fifo_p_empty, // Programmable empty flag
    output  wire  [CR-1:0]  o_fifo_r_count, // Read data count, if dual clock mode is false - output count is the same with write data count

    output  wire            o_fifo_r_valid // Read valid
  );

  localparam int M = ( AR > AW ) ? AR - AW : ( AW > AR ) ? AW - AR : 0;

  typedef struct packed { bit INVERSE, R_COUNT, P_EMPTY, A_EMPTY, W_RESET, W_COUNT, P_TFULL, A_TFULL; } t_fts;

  localparam t_fts FEATURE = FEATURES;

  localparam bit FULL_FLAG_RESET = !FEATURE.INVERSE && FEATURE.W_RESET || FEATURE.INVERSE && !FEATURE.W_RESET;

  wire [N-1:0][AW-1:0] w_fifo_wr_addr = i_fifo_wr_addr;
  wire [N-1:0][AR-1:0] w_fifo_rd_addr = i_fifo_rd_addr;

  logic q_fifo_w_tfull = ( FEATURE.INVERSE ) ? '0 : '1;
  logic q_fifo_a_tfull = '0;

  logic q_fifo_r_empty = ( FEATURE.INVERSE ) ? '0 : '1;
  logic q_fifo_a_empty = '1;
  logic q_fwft_r_empty = ( FEATURE.INVERSE ) ? '0 : '1;
  logic q_fwft_a_empty = '1;

  wire w_fifo_ram_wen = ( FEATURE.INVERSE ) ? i_fifo_w_valid && q_fifo_w_tfull : i_fifo_w_valid && !q_fifo_w_tfull;

  wire w_fifo_r_valid = ( FEATURE.INVERSE ) ? q_fifo_r_empty : !q_fifo_r_empty;
  
  wire w_fifo_ram_ren;

  if ( FWFT == "True" ) begin : fwft_mode

    logic [1:0] q_fwft_c_state = '0; // fwft current state
    always_ff @(posedge i_fifo_r_clk_p)
      if ( i_fifo_r_rst_p )
        q_fwft_c_state[0] <= '0;
      else if ( w_fifo_r_valid || !i_fifo_r_query && q_fwft_c_state[0] && q_fwft_c_state[1] )
        q_fwft_c_state[0] <= '1;
      else
        q_fwft_c_state[0] <= '0;

    always_ff @(posedge i_fifo_r_clk_p)
      if ( i_fifo_r_rst_p )
        q_fwft_c_state[1] <= '0;
      else if ( q_fwft_c_state[0] || !i_fifo_r_query && q_fwft_c_state[1] )
        q_fwft_c_state[1] <= '1;
      else
        q_fwft_c_state[1] <= '0;

    wire [1:0] w_fwft_ram_ren = { q_fwft_c_state[0] && ( !q_fwft_c_state[1] || i_fifo_r_query ), 
                                  w_fifo_r_valid && ( !q_fwft_c_state[0] || !q_fwft_c_state[1] || q_fwft_c_state[1] && i_fifo_r_query ) };

    always_ff @(posedge i_fifo_r_clk_p)
      if ( i_fifo_r_rst_p )
        q_fwft_r_empty <= ( FEATURE.INVERSE ) ? '0 : '1;
      else if ( q_fwft_c_state[0] && !q_fwft_c_state[1] )
        q_fwft_r_empty <= ( FEATURE.INVERSE ) ? '1 : '0;
      else if ( i_fifo_r_query && !q_fwft_c_state[0] && q_fwft_c_state[1] )
        q_fwft_r_empty <= ( FEATURE.INVERSE ) ? '0 : '1;

    if ( FEATURE.A_EMPTY ) begin : a_empty

      always_ff @(posedge i_fifo_r_clk_p)
        if ( i_fifo_r_rst_p )
          q_fwft_a_empty <= '1;
        else if ( w_fifo_r_valid && ( !i_fifo_r_query && ( ^ q_fwft_c_state ) || i_fifo_r_query && q_fwft_c_state[0] && !q_fwft_c_state[1] ) ) 
          q_fwft_a_empty <= '0;
        else if ( !w_fifo_r_valid && i_fifo_r_query && ( & q_fwft_c_state ) )
          q_fwft_a_empty <= '1;

    end : a_empty

    assign w_fifo_ram_ren = w_fifo_r_valid && ( !q_fwft_c_state[0] || !q_fwft_c_state[1] || q_fwft_c_state[0] && i_fifo_r_query );

    assign o_fifo_ram_ren = w_fwft_ram_ren;

    logic q_fifo_r_valid = '0;
    always_ff @(posedge i_fifo_r_clk_p)
      if ( i_fifo_r_rst_p )
        q_fifo_r_valid <= '0;
      else if ( i_fifo_r_query && q_fwft_c_state[0] || !i_fifo_r_query && ( | q_fwft_c_state ) )
        q_fifo_r_valid <= '1;
      else
        q_fifo_r_valid <= '0;

    assign o_fifo_r_valid = q_fifo_r_valid;

  end : fwft_mode else begin : norm_mode

    assign w_fifo_ram_ren = i_fifo_r_query && w_fifo_r_valid;

    logic q_fifo_r_valid = '0;
    if ( EXTRA_REG == "True" ) begin : extra_reg
      
      logic q_fifo_ram_ren = '0;
      always_ff @(posedge i_fifo_r_clk_p)
        q_fifo_ram_ren <= w_fifo_ram_ren;

      always_ff @(posedge i_fifo_r_clk_p)
        if ( i_fifo_r_rst_p )
          q_fifo_r_valid <= '0;
        else
          q_fifo_r_valid <= q_fifo_ram_ren;

      assign o_fifo_ram_ren = { q_fifo_ram_ren, w_fifo_ram_ren };

    end : extra_reg else begin : basic_reg

      always_ff @(posedge i_fifo_r_clk_p)
        if ( i_fifo_r_rst_p )
          q_fifo_r_valid <= '0;
        else
          q_fifo_r_valid <= w_fifo_ram_ren;

      assign o_fifo_ram_ren = w_fifo_ram_ren;

    end : basic_reg

    assign o_fifo_r_valid = q_fifo_r_valid;

  end : norm_mode

  wire w_full_w_reset;
  if ( FEATURE.W_RESET ) begin : with_w_reset

    logic q_fifo_w_rst_p = '0;
    always_ff @(posedge i_fifo_w_clk_p)
      q_fifo_w_rst_p <= i_fifo_w_rst_p;

    assign w_full_w_reset = q_fifo_w_rst_p && !i_fifo_w_rst_p;

  end : with_w_reset else begin : wout_w_reset

    assign w_full_w_reset = '0;

  end : wout_w_reset

  wire [AR-1:0] w_rclk_wr_addr;
  wire [AW-1:0] w_wclk_rd_addr;

  if ( DUAL_CLOCK == "True" ) begin : dual_clock

    wire [AW-1:0] m_rclk_wr_addr;
    wire [AR-1:0] m_wclk_rd_addr;

    fifo_cdc #(
      .SW ( AW ),
      .CDC_CONFIG ( "GRAY" ),
      .SYNC_STAGES ( SYNC_STAGES ),
      .SOURCE_REG ( '1 ),
      .OUTPUT_REG ( '1 )
    ) u_cdc_wr_addr (
      .i_src_s_rst_p ( '0 ),
      .i_src_a_clk_p ( i_fifo_w_clk_p ),
      .i_src_cdc_sig ( w_fifo_wr_addr[N-1] ),

      .i_dst_s_rst_p ( '0 ),
      .i_dst_a_clk_p ( i_fifo_r_clk_p ),
      .o_dst_cdc_sig ( m_rclk_wr_addr )
    );

    fifo_cdc #(
      .SW ( AR ),
      .CDC_CONFIG ( "GRAY" ),
      .SYNC_STAGES ( SYNC_STAGES ),
      .SOURCE_REG ( '1 ),
      .OUTPUT_REG ( '1 )
    ) u_cdc_rd_addr (
      .i_src_s_rst_p ( '0 ),
      .i_src_a_clk_p ( i_fifo_r_clk_p ),
      .i_src_cdc_sig ( w_fifo_rd_addr[N-1] ),

      .i_dst_s_rst_p ( '0 ),
      .i_dst_a_clk_p ( i_fifo_w_clk_p ),
      .o_dst_cdc_sig ( m_wclk_rd_addr )
    );

    assign w_rclk_wr_addr = ( AR > AW ) ? m_rclk_wr_addr << M : ( AW > AR ) ? m_rclk_wr_addr >> M : m_rclk_wr_addr;
    assign w_wclk_rd_addr = ( AR > AW ) ? m_wclk_rd_addr >> M : ( AW > AR ) ? m_wclk_rd_addr << M : m_wclk_rd_addr;

    wire v_fifo_w_tfull = ( FEATURE.INVERSE ) ? !q_fifo_w_tfull : q_fifo_w_tfull;

    // Dual clock fifo full flag
    always_ff @(posedge i_fifo_w_clk_p)
      if ( i_fifo_w_rst_p )
        q_fifo_w_tfull <= ( FULL_FLAG_RESET ) ? '1 : '0;
      else if ( v_fifo_w_tfull && ( w_fifo_wr_addr[N-1] ^ (1'b1 << AW-1) ) != w_wclk_rd_addr || w_full_w_reset )
        q_fifo_w_tfull <= ( FEATURE.INVERSE ) ? '1 : '0;
      else if ( w_fifo_ram_wen && ( w_fifo_wr_addr[N-2] ^ (1'b1 << AW-1) ) == w_wclk_rd_addr )
        q_fifo_w_tfull <= ( FEATURE.INVERSE ) ? '0 : '1;

    // Dual clock fifo empty flag
    wire v_fifo_r_empty = ( FEATURE.INVERSE ) ? !q_fifo_r_empty : q_fifo_r_empty;

    always_ff @(posedge i_fifo_r_clk_p)
      if ( i_fifo_r_rst_p )
        q_fifo_r_empty <= ( FEATURE.INVERSE ) ? '0 : '1;
      else if ( v_fifo_r_empty && w_fifo_rd_addr[N-1] != w_rclk_wr_addr )
        q_fifo_r_empty <= ( FEATURE.INVERSE ) ? '1 : '0;
      else if ( w_fifo_ram_ren && w_fifo_rd_addr[N-2] == w_rclk_wr_addr )
        q_fifo_r_empty <= ( FEATURE.INVERSE ) ? '0 : '1;

    // Dual clock fifo almost full flag
    if ( FEATURE.A_TFULL ) begin : a_tfull

      always_ff @(posedge i_fifo_w_clk_p)
        if ( i_fifo_w_rst_p )
          q_fifo_a_tfull <= ( FEATURE.W_RESET ) ? '1 : '0;
        else if ( w_fifo_ram_wen && ( w_fifo_wr_addr[N-3] ^ (1'b1 << AW-1) ) == w_wclk_rd_addr )
          q_fifo_a_tfull <= '1;
        else if ( !v_fifo_w_tfull && ( w_fifo_wr_addr[N-2] ^ (1'b1 << AW-1) ) != w_wclk_rd_addr || w_full_w_reset )
          q_fifo_a_tfull <= '0;

    end : a_tfull

    // Dual clock fifo almost empty flag
    if ( FEATURE.A_EMPTY && FWFT != "True" ) begin : a_empty

      always_ff @(posedge i_fifo_r_clk_p)
        if ( i_fifo_r_rst_p )
          q_fifo_a_empty <= '1;
        else if ( w_fifo_ram_ren && w_fifo_rd_addr[N-3] == w_rclk_wr_addr )
          q_fifo_a_empty <= '1;
        else if ( !v_fifo_r_empty && w_fifo_rd_addr[N-2] != w_rclk_wr_addr )
          q_fifo_a_empty <= '0;

    end : a_empty

  end : dual_clock else begin : sync_clock

    // Sync fifo full flag
    wire w_fall_w_tfull, w_rise_w_tfull;
    if ( AR > AW ) begin : w_tfull_wr_wide
      assign w_fall_w_tfull = w_fifo_ram_ren && w_fifo_rd_addr[N-1][AR-AW-1:0] == '1 || w_full_w_reset;
      assign w_rise_w_tfull = w_fifo_ram_wen && w_fifo_wr_addr[N-2] == w_fifo_rd_addr[N-1] >> M;
    end : w_tfull_wr_wide else if ( AW > AR ) begin : w_tfull_rd_wide
      assign w_fall_w_tfull = w_fifo_ram_ren || w_full_w_reset;
      assign w_rise_w_tfull = w_fifo_ram_wen && w_fifo_wr_addr[N-2] == w_fifo_rd_addr[N-1] << M;
    end : w_tfull_rd_wide else begin : w_tfull_no_wide
      assign w_fall_w_tfull = w_fifo_ram_ren || w_full_w_reset;
      assign w_rise_w_tfull = w_fifo_ram_wen && w_fifo_wr_addr[N-2] == w_fifo_rd_addr[N-1];
    end : w_tfull_no_wide

    always_ff @(posedge i_fifo_w_clk_p)
      if ( i_fifo_w_rst_p )
        q_fifo_w_tfull <= ( FULL_FLAG_RESET ) ? '1 : '0;
      else if ( w_fall_w_tfull )
        q_fifo_w_tfull <= ( FEATURE.INVERSE ) ? '1 : '0;
      else if ( w_rise_w_tfull )
        q_fifo_w_tfull <= ( FEATURE.INVERSE ) ? '0 : '1;

    // Sync fifo empty flag
    wire w_fall_r_empty, w_rise_r_empty;
    if ( AR > AW ) begin : r_empty_wr_wide
      assign w_fall_r_empty = w_fifo_ram_wen;
      assign w_rise_r_empty = w_fifo_ram_ren && w_fifo_rd_addr[N-2] == w_fifo_wr_addr[N-1] << M;
    end : r_empty_wr_wide else if ( AW > AR ) begin : r_empty_rd_wide
      assign w_fall_r_empty = w_fifo_ram_wen && w_fifo_wr_addr[N-1][AW-AR-1:0] == '1;
      assign w_rise_r_empty = w_fifo_ram_ren && w_fifo_rd_addr[N-2] == w_fifo_wr_addr[N-1] >> M;
    end : r_empty_rd_wide else begin : r_empty_no_wide
      assign w_fall_r_empty = w_fifo_ram_wen;
      assign w_rise_r_empty = w_fifo_ram_ren && w_fifo_rd_addr[N-2] == w_fifo_wr_addr[N-1];
    end : r_empty_no_wide

    always_ff @(posedge i_fifo_r_clk_p)
      if ( i_fifo_r_rst_p )
        q_fifo_r_empty <= ( FEATURE.INVERSE ) ? '0 : '1;
      else if ( w_fall_r_empty )
        q_fifo_r_empty <= ( FEATURE.INVERSE ) ? '1 : '0;
      else if ( w_rise_r_empty )
        q_fifo_r_empty <= ( FEATURE.INVERSE ) ? '0 : '1;

    // Sync fifo almost full flag
    if ( FEATURE.A_TFULL ) begin : a_tfull

      wire w_fall_a_tfull, w_rise_a_tfull;
      if ( AR > AW ) begin : a_tfull_wr_wide
        assign w_fall_a_tfull = w_fifo_ram_ren && !w_fifo_ram_wen && w_fifo_wr_addr[N-3] == w_fifo_rd_addr[N-2] >> M || w_full_w_reset;
        assign w_rise_a_tfull = w_fifo_ram_wen && !(w_fifo_ram_ren && w_fifo_rd_addr[N-1][AR-AW-1:0] == '1) && w_fifo_wr_addr[N-3] == w_fifo_rd_addr[N-1] >> M;
      end : a_tfull_wr_wide else if ( AW > AR ) begin : a_tfull_rd_wide
        assign w_fall_a_tfull = w_fifo_ram_ren && w_fifo_wr_addr[N-2] != w_fifo_rd_addr[N-2] << M || w_full_w_reset;
        assign w_rise_a_tfull = w_fifo_ram_wen && !w_fifo_ram_ren && w_fifo_wr_addr[N-3] == w_fifo_rd_addr[N-1] << M;
      end : a_tfull_rd_wide else begin : a_tfull_no_wide
        assign w_fall_a_tfull = w_fifo_ram_ren && !w_fifo_ram_wen && w_fifo_wr_addr[N-2] != w_fifo_rd_addr[N-2] || w_full_w_reset;
        assign w_rise_a_tfull = w_fifo_ram_wen && !w_fifo_ram_ren && w_fifo_wr_addr[N-3] == w_fifo_rd_addr[N-1];
      end : a_tfull_no_wide

      always_ff @(posedge i_fifo_w_clk_p)
        if ( i_fifo_w_rst_p )
          q_fifo_a_tfull <= ( FEATURE.W_RESET ) ? '1 : '0;
        else if ( w_fall_a_tfull )
          q_fifo_a_tfull <= '0;
        else if ( w_rise_a_tfull )
          q_fifo_a_tfull <= '1;

    end : a_tfull

    // Sync fifo almost empty flag
    if ( FEATURE.A_EMPTY && FWFT != "True" ) begin : a_empty

      wire w_fall_a_empty, w_rise_a_empty;
      if ( AR > AW ) begin : a_empty_wr_wide
        assign w_fall_a_empty = w_fifo_ram_wen && w_fifo_rd_addr[N-2] != w_fifo_wr_addr[N-2] << M;
        assign w_rise_a_empty = w_fifo_ram_ren && !w_fifo_ram_wen && w_fifo_rd_addr[N-3] == w_fifo_wr_addr[N-1] << M;
      end : a_empty_wr_wide else if ( AW > AR ) begin : a_empty_rd_wide
        assign w_fall_a_empty = w_fifo_ram_wen && !w_fifo_ram_ren && w_fifo_wr_addr[N-2] >> M == w_fifo_rd_addr[N-3];
        assign w_rise_a_empty = w_fifo_ram_ren && !(w_fifo_ram_wen && w_fifo_wr_addr[N-1][AW-AR-1:0] == '1) && w_fifo_wr_addr[N-1] >> M == w_fifo_rd_addr[N-3];
      end : a_empty_rd_wide else begin : a_empty_no_wide
        assign w_fall_a_empty = w_fifo_ram_wen && !w_fifo_ram_ren && w_fifo_rd_addr[N-2] != w_fifo_wr_addr[N-2];
        assign w_rise_a_empty = w_fifo_ram_ren && !w_fifo_ram_wen && w_fifo_rd_addr[N-3] == w_fifo_wr_addr[N-1];
      end : a_empty_no_wide

      always_ff @(posedge i_fifo_r_clk_p)
        if ( i_fifo_r_rst_p )
          q_fifo_a_empty <= '1;
        else if ( w_fall_a_empty )
          q_fifo_a_empty <= '0;
        else if ( w_rise_a_empty )
          q_fifo_a_empty <= '1;
          
    end : a_empty
  
  end : sync_clock

  wire w_fifo_r_empty = ( FWFT == "True" ) ? q_fwft_r_empty : q_fifo_r_empty;
  wire w_fifo_a_empty = ( FWFT == "True" ) ? q_fwft_a_empty : q_fifo_a_empty;

  if ( FEATURE.P_EMPTY || FEATURE.R_COUNT || FEATURE.P_TFULL || FEATURE.W_COUNT ) begin : features_on

    fifo_program #(
      .AW ( AW ),
      .AR ( AR ),
      .FWFT ( FWFT ),
      .DUAL_CLOCK ( DUAL_CLOCK ),
      .SYNC_STAGES ( SYNC_STAGES ),
      .PROG_FULL ( PROG_FULL ),
      .PROG_EMPTY ( PROG_EMPTY ),
      .FEATURES ( FEATURES )
    ) u_program (
      .i_full_w_reset ( w_full_w_reset ),
      .i_fifo_w_rst_p ( i_fifo_w_rst_p ),
      .i_fifo_w_clk_p ( i_fifo_w_clk_p ),
      .i_fifo_w_valid ( i_fifo_w_valid ),
      .i_fifo_w_tfull ( q_fifo_w_tfull ),
      .i_fifo_w_count ( { w_wclk_rd_addr, w_fifo_wr_addr[N-1] } ),
      .o_fifo_w_count ( o_fifo_w_count ),
      .o_fifo_p_tfull ( o_fifo_p_tfull ),
      .i_fifo_r_rst_p ( i_fifo_r_rst_p ),
      .i_fifo_r_clk_p ( i_fifo_r_clk_p ),
      .i_fifo_r_query ( i_fifo_r_query ),
      .i_fifo_r_empty ( w_fifo_r_empty ),
      .i_fifo_r_count ( { w_rclk_wr_addr, w_fifo_rd_addr[N-1] } ),
      .o_fifo_r_count ( o_fifo_r_count ), // In the FWFT mode, can bind to an empty flag
      .o_fifo_p_empty ( o_fifo_p_empty )
    );

  end : features_on else begin : no_features
    
    assign o_fifo_p_tfull = '0;
    assign o_fifo_w_count = '0;
    assign o_fifo_p_empty = '0;
    assign o_fifo_r_count = '0;

  end : no_features

  assign o_fifo_w_allow = w_fifo_ram_wen;
  assign o_fifo_ram_wen = w_fifo_ram_wen;

  assign o_fifo_w_tfull = q_fifo_w_tfull;
  assign o_fifo_a_tfull = q_fifo_a_tfull;

  assign o_fifo_r_allow = w_fifo_ram_ren;

  assign o_fifo_r_empty = w_fifo_r_empty;
  assign o_fifo_a_empty = w_fifo_a_empty;

endmodule : fifo_control

(* KEEP_HIERARCHY = "Soft" *)
module fifo_ram #(
    parameter int           DW = 16, // Data write width
    parameter int           DR = DW, // Data read width
    parameter int           AW = 4, // Address write width
    parameter int           AR = AW, // Address read width
    parameter               FWFT = "False", // First Word Fall Through: "True" or "False"
    parameter               MEM_STYLE = "Distributed", // "Distributed" or "Block"
    parameter               EXTRA_REG = "False", // Adds an extra register to the memory output in normal mode, latency increased by 2
    parameter bit [DR-1:0]  RESET_VALUE = '0, // Output data value when reset is asserted
    parameter int           RE = ( FWFT == "True" || EXTRA_REG == "True" ) ? 2 : 1 // Read enable max width
  )  (
    input   wire            i_fifo_r_rst_p, // Read reset, active high

    input   wire            i_fifo_w_clk_p, // Rising edge write clock

    input   wire  [AW-1:0]  i_fifo_wr_addr, // Write address
    input   wire            i_fifo_ram_wen, // RAM write enable
    input   wire  [DW-1:0]  i_fifo_w_value, // Input fifo data
    
    input   wire            i_fifo_r_clk_p, // Rising edge read clock

    input   wire  [AR-1:0]  i_fifo_rd_addr, // Read address
    input   wire  [RE-1:0]  i_fifo_ram_ren, // RAM read enable 
    output  wire  [DR-1:0]  o_fifo_r_value // Output fifo data
  );

  localparam int W = ( DW > DR ) ? DR : DW;
  localparam int A = ( AR > AW ) ? AR : AW;

  (* RAM_STYLE = MEM_STYLE *) bit [W-1:0] q_fifo_ram_mem [2**A] = '{default:'0};

  // Write to RAM
  if ( AR > AW ) begin : wr_wide
    
    always_ff @(posedge i_fifo_w_clk_p)
      for ( int i = 0; i < 2**(AR-AW); i++ )
        if ( i_fifo_ram_wen )
          q_fifo_ram_mem[{i_fifo_wr_addr, i[AR-AW-1:0]}] <= i_fifo_w_value[(i+1)*W-1-:W];

  end : wr_wide else begin : wr_norm

    always_ff @(posedge i_fifo_w_clk_p)
      if ( i_fifo_ram_wen )
        q_fifo_ram_mem[i_fifo_wr_addr] <= i_fifo_w_value;

  end : wr_norm

  logic [DR-1:0] q_fifo_r_value [RE] = '{default:RESET_VALUE};

  wire w_fifo_ram_ren = i_fifo_ram_ren[0];

  // Read from RAM
  if ( AW > AR ) begin : rd_wide

    always_ff @(posedge i_fifo_r_clk_p)
      for ( int i = 0; i < 2**(AW-AR); i++ )
        if ( i_fifo_r_rst_p )
          q_fifo_r_value[0][(i+1)*W-1-:W] <= ( MEM_STYLE == "Block" && (FWFT == "True" || EXTRA_REG == "True") ) ? 'X : RESET_VALUE[(i+1)*W-1-:W];
        else if ( w_fifo_ram_ren )
          q_fifo_r_value[0][(i+1)*W-1-:W] <= q_fifo_ram_mem[{i_fifo_rd_addr, i[AW-AR-1:0]}];

  end : rd_wide else begin : rd_norm

    always_ff @(posedge i_fifo_r_clk_p)
      if ( i_fifo_r_rst_p )
        q_fifo_r_value[0] <= ( MEM_STYLE == "Block" && (FWFT == "True" || EXTRA_REG == "True") ) ? 'X : RESET_VALUE;
      else if ( w_fifo_ram_ren )
        q_fifo_r_value[0] <= q_fifo_ram_mem[i_fifo_rd_addr];

  end : rd_norm

  if ( FWFT == "True" || EXTRA_REG == "True" ) begin : extra_reg

    always_ff @(posedge i_fifo_r_clk_p)
      if ( i_fifo_r_rst_p )
        q_fifo_r_value[1] <= RESET_VALUE;
      else if ( i_fifo_ram_ren[1] )
        q_fifo_r_value[1] <= q_fifo_r_value[0];

    assign o_fifo_r_value = q_fifo_r_value[1];

  end : extra_reg else begin : basic_reg

    assign o_fifo_r_value = q_fifo_r_value[0];

  end : basic_reg

endmodule : fifo_ram

(* KEEP_HIERARCHY = "Soft" *)
module fifo_program #(
    parameter   int       AW = 4, // Address write width = 2^AW, AW > 3
    parameter   int       AR = AW, // Address read width = 2^AR, AR > 3
    parameter             FWFT = "False", // First Word Fall Through: "True" or "False"
    parameter             DUAL_CLOCK = "False", // Dual clock fifo: "True" or "False"
    parameter   int       SYNC_STAGES = 2, // Number of synchronization stages in dual clock mode: [2, 3, 4]
    parameter   int       PROG_FULL = 12, // Programmable full threshold
    parameter   int       PROG_EMPTY = 4, // Programmable empty threshold
    parameter   bit [7:0] FEATURES = '0, // Use advanced features: [ 7 - inverse full and empty flags | 6 - read count | 5 - prog. empty flag | 4 - almost empty | 3 - full flag reset | 2 - write count | 1 - prog. full flag | 0 - almost full flag ]
    localparam  int       WA = 2*AW, // Write address max width
    localparam  int       RA = 2*AR, // Read address max width
    localparam  int       CW = ( DUAL_CLOCK == "True" ) ? AW : AW+1, // Write counter width
    localparam  int       CR = ( DUAL_CLOCK == "True" ) ? AR : AR+1 // Read counter width
  )  (
    input   wire            i_full_w_reset, // Delay reset, active high

    input   wire            i_fifo_w_rst_p, // Write reset, active high
    input   wire            i_fifo_w_clk_p, // Rising edge write clock

    input   wire            i_fifo_w_valid, // Write valid
    input   wire            i_fifo_w_tfull, // Write full flag
    input   wire  [WA-1:0]  i_fifo_w_count, // Write side data counter { rd, wr } clock domain
    output  wire  [CW-1:0]  o_fifo_w_count, // Write data count
    output  wire            o_fifo_p_tfull, // Programmable full flag
    
    input   wire            i_fifo_r_rst_p, // Read reset, active high
    input   wire            i_fifo_r_clk_p, // Rising edge read clock

    input   wire            i_fifo_r_query, // Read query
    input   wire            i_fifo_r_empty, // Read empty flag 
    input   wire  [RA-1:0]  i_fifo_r_count, // Read side data counter { wr, rd } clock domain
    output  wire  [CR-1:0]  o_fifo_r_count, // Read data count, if dual clock mode is false - output count is the same with write data count
    output  wire            o_fifo_p_empty  // Programmable empty flag
  );

  localparam int CM = ( CR > CW ) ? CR : CW;

  localparam int M = ( AR > AW ) ? AR - AW : ( AW > AR ) ? AW - AR : 0;

  typedef logic [CM-1:0] t_cnt;

  typedef struct packed { bit INVERSE, R_COUNT, P_EMPTY, A_EMPTY, W_RESET, W_COUNT, P_TFULL, A_TFULL; } t_fts;

  localparam t_fts FEATURE = FEATURES;

  wire w_fifo_dat_wen = ( FEATURE.INVERSE ) ? i_fifo_w_valid && i_fifo_w_tfull : i_fifo_w_valid && !i_fifo_w_tfull;
  wire w_fifo_dat_ren = ( FEATURE.INVERSE ) ? i_fifo_r_query && i_fifo_r_empty : i_fifo_r_query && !i_fifo_r_empty;

  if ( DUAL_CLOCK == "True" ) begin : dual_clock

    wire [CW-1:0] w_wclk_r_count, w_wclk_w_count;
    wire [CR-1:0] w_rclk_w_count, w_rclk_r_count;

    if ( FWFT == "True" ) begin : fwft_mode

      // Dual clock fifo write clock counter
      logic [CW-1:0] q_wclk_w_count = '0;
      always_ff @(posedge i_fifo_w_clk_p)
        if ( i_fifo_w_rst_p )
          q_wclk_w_count <= 0;
        else if ( w_fifo_dat_wen )
          q_wclk_w_count <= q_wclk_w_count + 1;

      assign w_wclk_w_count = q_wclk_w_count;

      // Dual clock fifo read clock counter
      logic [CR-1:0] q_rclk_r_count = '0;
      always_ff @(posedge i_fifo_r_clk_p)
        if ( i_fifo_r_rst_p )
          q_rclk_r_count <= 0;
        else if ( w_fifo_dat_ren )
          q_rclk_r_count <= q_rclk_r_count + 1;

      assign w_rclk_r_count = q_rclk_r_count;

      wire [CW-1:0] m_rclk_w_count;
      wire [CR-1:0] m_wclk_r_count;

      fifo_cdc #(
        .SW ( CW ),
        .CDC_CONFIG ( "GRAY" ),
        .SYNC_STAGES ( SYNC_STAGES ),
        .SOURCE_REG ( '1 ),
        .OUTPUT_REG ( '1 )
      ) u_cdc_w_count (
        .i_src_s_rst_p ( '0 ),
        .i_src_a_clk_p ( i_fifo_w_clk_p ),
        .i_src_cdc_sig ( q_wclk_w_count ),

        .i_dst_s_rst_p ( '0 ),
        .i_dst_a_clk_p ( i_fifo_r_clk_p ),
        .o_dst_cdc_sig ( m_rclk_w_count )
      );

      fifo_cdc #(
        .SW ( CR ),
        .CDC_CONFIG ( "GRAY" ),
        .SYNC_STAGES ( SYNC_STAGES ),
        .SOURCE_REG ( '1 ),
        .OUTPUT_REG ( '1 )
      ) u_cdc_r_count (
        .i_src_s_rst_p ( '0 ),
        .i_src_a_clk_p ( i_fifo_r_clk_p ),
        .i_src_cdc_sig ( q_rclk_r_count ),
        
        .i_dst_s_rst_p ( '0 ),
        .i_dst_a_clk_p ( i_fifo_w_clk_p ),
        .o_dst_cdc_sig ( m_wclk_r_count )
      );

      assign w_rclk_w_count = ( CR > CW ) ? m_rclk_w_count << M : ( CW > CR ) ? m_rclk_w_count >> M : m_rclk_w_count;
      assign w_wclk_r_count = ( CR > CW ) ? m_wclk_r_count >> M : ( CW > CR ) ? m_wclk_r_count << M : m_wclk_r_count;

    end : fwft_mode else begin : norm_mode      
    
      assign { w_wclk_r_count, w_wclk_w_count } = i_fifo_w_count;
      assign { w_rclk_w_count, w_rclk_r_count } = i_fifo_r_count;

    end : norm_mode

    // Dual clock fifo write count
    if ( FEATURE.W_COUNT ) begin : with_w_count

      logic [AW-1:0] q_fifo_w_count = '0;
      always_ff @(posedge i_fifo_w_clk_p)
        if ( i_fifo_w_rst_p )
          q_fifo_w_count <= '0;
        else
          q_fifo_w_count <= w_wclk_w_count - w_wclk_r_count;

      assign o_fifo_w_count = q_fifo_w_count;

    end : with_w_count else begin : wout_w_count

      assign o_fifo_w_count = '0;

    end : wout_w_count

    // Dual clock fifo read count
    if ( FEATURE.R_COUNT ) begin : with_r_count

      logic [AR-1:0] q_fifo_r_count = '0;
      always_ff @(posedge i_fifo_r_clk_p)
        if ( i_fifo_r_rst_p )
          q_fifo_r_count <= '0;
        else
          q_fifo_r_count <= w_rclk_w_count - w_rclk_r_count;

      assign o_fifo_r_count = q_fifo_r_count;

    end : with_r_count else begin : wout_r_count

      assign o_fifo_r_count = '0;

    end : wout_r_count

    // Dual clock fifo programmable full flag
    if ( FEATURE.P_TFULL ) begin : with_p_tfull

      wire [AW-1:0] w_diff_w_count = w_wclk_w_count - w_wclk_r_count;

      logic q_fifo_p_tfull = '0;
      always_ff @(posedge i_fifo_w_clk_p)
        if ( i_fifo_w_rst_p )
          q_fifo_p_tfull <= ( FEATURE.W_RESET ) ? '1 : '0;
        else if ( w_diff_w_count >= PROG_FULL )
          q_fifo_p_tfull <= '1;
        else
          q_fifo_p_tfull <= '0;

      assign o_fifo_p_tfull = q_fifo_p_tfull;

    end : with_p_tfull else begin : wout_p_tfull

      assign o_fifo_p_tfull = '0;

    end : wout_p_tfull

    // Dual clock fifo programmable empty flag
    if ( FEATURE.P_EMPTY ) begin : with_p_empty

      wire [AR-1:0] w_diff_r_count = w_rclk_w_count - w_rclk_r_count;

      logic q_fifo_p_empty = '1;
      always_ff @(posedge i_fifo_r_clk_p)
        if ( i_fifo_r_rst_p )
          q_fifo_p_empty <= '1;
        else if ( w_diff_r_count <= PROG_EMPTY )
          q_fifo_p_empty <= '1;
        else 
          q_fifo_p_empty <= '0;

      assign o_fifo_p_empty = q_fifo_p_empty;

    end : with_p_empty else begin : wout_p_empty

      assign o_fifo_p_empty = '0;

    end : wout_p_empty

  end : dual_clock else begin : sync_clock

    localparam int unsigned INIT = ( AR > AW ) ? 2**(AR-AW) - 1 : '0;
    localparam int unsigned BOTH = ( AR > AW ) ? 2**(AR-AW) - 1 : ( AW > AR ) ? -(2**(AW-AR)) + 1 : '0;
    localparam int unsigned INCR = ( AR > AW ) ? 2**(AR-AW) : 1;
    localparam int unsigned DECR = ( AW > AR ) ? 2**(AW-AR) : 1;

    // Sync clock fifo write count
    if ( FEATURE.W_COUNT || FEATURE.P_TFULL ) begin : with_w_count

      t_cnt q_fifo_w_count = INIT;
      always_ff @(posedge i_fifo_w_clk_p)
        if ( i_fifo_w_rst_p )
          q_fifo_w_count <= INIT;
        else if ( w_fifo_dat_wen && w_fifo_dat_ren )
          q_fifo_w_count <= q_fifo_w_count + BOTH;
        else if ( w_fifo_dat_wen )
          q_fifo_w_count <= q_fifo_w_count + INCR;
        else if ( w_fifo_dat_ren )
          q_fifo_w_count <= q_fifo_w_count - DECR;

      // Sync clock fifo programmable full flag
      if ( FEATURE.P_TFULL ) begin : with_p_tfull

        wire w_fall_p_tfull, w_rise_p_tfull;
        if ( AR > AW ) begin : p_tfull_wr_wide
          assign w_fall_p_tfull = w_fifo_dat_ren && !w_fifo_dat_wen && q_fifo_w_count == 2**(AR-AW)*PROG_FULL || i_full_w_reset;
          assign w_rise_p_tfull = w_fifo_dat_wen && (w_fifo_dat_ren && q_fifo_w_count > 2**(AR-AW)*PROG_FULL-2**(AR-AW) || !w_fifo_dat_ren && q_fifo_w_count > 2**(AR-AW)*PROG_FULL-2**(AR-AW)-1);
        end : p_tfull_wr_wide else if ( AW > AR ) begin : p_tfull_rd_wide
          assign w_fall_p_tfull = w_fifo_dat_ren && (w_fifo_dat_wen && q_fifo_w_count < PROG_FULL+2**(AW-AR)-1 || !w_fifo_dat_wen && q_fifo_w_count < PROG_FULL+2**(AW-AR)) || i_full_w_reset;
          assign w_rise_p_tfull = w_fifo_dat_wen && q_fifo_w_count == PROG_FULL-1;
        end : p_tfull_rd_wide else begin : p_tfull_no_wide
          assign w_fall_p_tfull = w_fifo_dat_ren && !w_fifo_dat_wen && q_fifo_w_count == PROG_FULL || i_full_w_reset;
          assign w_rise_p_tfull = w_fifo_dat_wen && !w_fifo_dat_ren && q_fifo_w_count == PROG_FULL-1;
        end : p_tfull_no_wide

        logic q_fifo_p_tfull = '0;
        always_ff @(posedge i_fifo_w_clk_p)
          if ( i_fifo_w_rst_p )
            q_fifo_p_tfull <= ( FEATURE.W_RESET ) ? '1 : '0;
          else if ( w_fall_p_tfull )
            q_fifo_p_tfull <= '0;
          else if ( w_rise_p_tfull )
            q_fifo_p_tfull <= '1;

        assign o_fifo_p_tfull = q_fifo_p_tfull;

      end : with_p_tfull else begin : wout_p_tfull

        assign o_fifo_p_tfull = '0;

      end : wout_p_tfull

      assign o_fifo_w_count = ( AR > AW ) ? q_fifo_w_count >> M : q_fifo_w_count;

    end : with_w_count else begin : wout_w_count

      assign o_fifo_w_count = '0;

    end : wout_w_count

    // Sync clock fifo read count 
    if ( FEATURE.R_COUNT || FEATURE.P_EMPTY ) begin : with_r_count

      t_cnt q_fifo_r_count = '0;
      always_ff @(posedge i_fifo_r_clk_p)
        if ( i_fifo_r_rst_p )
          q_fifo_r_count <= '0;
        else if ( w_fifo_dat_wen && w_fifo_dat_ren )
          q_fifo_r_count <= q_fifo_r_count + BOTH;
        else if ( w_fifo_dat_wen )
          q_fifo_r_count <= q_fifo_r_count + INCR;
        else if ( w_fifo_dat_ren )
          q_fifo_r_count <= q_fifo_r_count - DECR;

      // Sync clock fifo programmable empty flag
      if ( FEATURE.P_EMPTY ) begin : with_p_empty

        wire w_fall_p_empty, w_rise_p_empty;
        if ( AR > AW ) begin : p_empty_wr_wide
          assign w_fall_p_empty = w_fifo_dat_wen && (w_fifo_dat_ren && q_fifo_r_count > PROG_EMPTY-2**(AR-AW)+1 || !w_fifo_dat_ren && q_fifo_r_count > PROG_EMPTY-2**(AR-AW));
          assign w_rise_p_empty = w_fifo_dat_ren && q_fifo_r_count == PROG_EMPTY+1;
        end : p_empty_wr_wide else if ( AW > AR ) begin : p_empty_rd_wide
          assign w_fall_p_empty = w_fifo_dat_wen && !w_fifo_dat_ren && q_fifo_r_count == 2**(AW-AR)*PROG_EMPTY+2**(AW-AR)-1;
          assign w_rise_p_empty = w_fifo_dat_ren && (w_fifo_dat_wen && q_fifo_r_count < 2**(AW-AR)*PROG_EMPTY+2*2**(AW-AR)-1 || !w_fifo_dat_wen && q_fifo_r_count < 2**(AW-AR)*PROG_EMPTY+2*2**(AW-AR));
        end : p_empty_rd_wide else begin : p_empty_no_wide
          assign w_fall_p_empty = w_fifo_dat_wen && !w_fifo_dat_ren && q_fifo_r_count == PROG_EMPTY;
          assign w_rise_p_empty = w_fifo_dat_ren && !w_fifo_dat_wen && q_fifo_r_count == PROG_EMPTY+1;
        end : p_empty_no_wide

        logic q_fifo_p_empty = '1;
        always_ff @(posedge i_fifo_r_clk_p)
          if ( i_fifo_r_rst_p )
            q_fifo_p_empty <= '1;
          else if ( w_fall_p_empty )
            q_fifo_p_empty <= '0;
          else if ( w_rise_p_empty )
            q_fifo_p_empty <= '1;

        assign o_fifo_p_empty = q_fifo_p_empty;

      end : with_p_empty else begin : wout_p_empty

        assign o_fifo_p_empty = '0;

      end : wout_p_empty

      assign o_fifo_r_count = ( AW > AR ) ? q_fifo_r_count >> M : q_fifo_r_count;

    end : with_r_count else begin : wout_r_count

      assign o_fifo_r_count = '0;

    end : wout_r_count

  end : sync_clock

endmodule : fifo_program

(* KEEP_HIERARCHY = "Soft" *)
module fifo_cdc #(
    parameter int SW = 1, // Signal width
    parameter     CDC_CONFIG = "BUS", // CDC configuration for cdc data: ["BUS" - bus domain crossing | "PULSE" - pulse domain crossing | "GRAY" - gray encoding/decoding domain crossing | "SYNC_RESET" - synchronous reset domain crossing | "ASYNC_RESET" - asynchronous reset synchronization]
    parameter int SYNC_STAGES = 3, // Number of synchronization stages from 2 to 8
    parameter bit SOURCE_REG = '1, // Use register on source input, always enabled in "PULSE" and "GRAY" configuration, and always disabled in "ASYNC_RESET" configuration
    parameter bit OUTPUT_REG = '1, // Additional register on destination output
    parameter bit INIT_STATE = '1, // Initial state for registers in "SYNC_RESET" CDC configuration
    parameter bit RESET_POLARITY = '1 // Reset polarity in "ASYNC_RESET" configuration: ['0 - active low | '1 - active high]
  )  (
    input   wire            i_src_s_rst_p, // Reset source registers, only for "PULSE" configuration and optional, active high
    input   wire            i_src_a_clk_p, // Source rising edge clock
    input   wire  [SW-1:0]  i_src_cdc_sig, // Source CDC input bus, pulse, reset or gray counter data

    input   wire            i_dst_s_rst_p, // Reset destination registers, only for "PULSE" configuration and optional, active high
    input   wire            i_dst_a_clk_p, // Destination rising edge clock
    output  wire  [SW-1:0]  o_dst_cdc_sig // Destination CDC output bus, pulse, reset or gray counter data
  );

  typedef logic [SW-1:0] t_sig;

  initial begin : check_param
    if ( !(CDC_CONFIG inside {"BUS", "PULSE", "GRAY", "ASYNC_RESET", "SYNC_RESET"}) )
      $error("[%s %0d-%0d] Configuration for CDC (%0s) must be 'BUS', 'PULSE', 'GRAY', 'ASYNC_RESET' or 'SYNC_RESET'. %m", "FIFO-CDC", 1, 1, CDC_CONFIG);
    if ( !(SYNC_STAGES inside {[2:8]}) )
      $error("[%s %0d-%0d] Synchronization stages (%0d) must be between 2 and 8. %m", "FIFO-CDC", 1, 2, SYNC_STAGES);
    if ( CDC_CONFIG inside {"PULSE", "ASYNC_RESET", "SYNC_RESET"} && SW != 1 )
      $error("[%s %0d-%0d] Signal width (%0d) in pulse and any reset configuration should be 1'. %m", "FIFO-CDC", 1, 3, SW);
    if ( CDC_CONFIG == "PULSE" && !SOURCE_REG )
      $warning("[%s %0d-%0d] Pulse configuration must contain an input register. Source register enabled automatically. %m", "FIFO-CDC", 2, 1);
    if ( CDC_CONFIG == "GRAY" && !SOURCE_REG )
      $warning("[%s %0d-%0d] Gray configuration must contain an input register. Source register enabled automatically. %m", "FIFO-CDC", 2, 2);
    if ( CDC_CONFIG == "ASYNC_RESET" && SOURCE_REG )
      $warning("[%s %0d-%0d] Asynchronous reset synchronization should not contain an input register. Source register disabled automatically. %m", "FIFO-CDC", 2, 3);
  end : check_param

  // Gray encoding/decoding
  function t_sig Binary2Gray(t_sig B);
    return B ^ (B >> 1);
  endfunction : Binary2Gray

  function t_sig Gray2Binary(t_sig G);
    t_sig B;
    for ( int i = 0; i < $size(G); i++ )
      B[i] = ^ (G >> i);

    return B;
  endfunction : Gray2Binary

  // Source register
  wire t_sig w_src_cdc_sig;
  if ( SOURCE_REG && CDC_CONFIG != "ASYNC_RESET" || CDC_CONFIG inside { "PULSE", "GRAY" } ) begin : src_with_reg

    t_sig q_src_cdc_sig = ( CDC_CONFIG == "SYNC_RESET" ) ? INIT_STATE : '0;

    if ( CDC_CONFIG == "PULSE" ) begin : pulse_cfg

      always_ff @(posedge i_src_a_clk_p)
        if ( i_src_s_rst_p )
          q_src_cdc_sig <= '0;
        else
          q_src_cdc_sig <= ~ i_src_cdc_sig & q_src_cdc_sig | i_src_cdc_sig & ~ q_src_cdc_sig;

    end : pulse_cfg else begin : other_cfg

      always_ff @(posedge i_src_a_clk_p)
        q_src_cdc_sig <= ( CDC_CONFIG == "GRAY" ) ? Binary2Gray(i_src_cdc_sig) : i_src_cdc_sig;

    end : other_cfg

    assign w_src_cdc_sig = q_src_cdc_sig;

  end : src_with_reg else begin : src_wout_reg

    assign w_src_cdc_sig = i_src_cdc_sig;

  end : src_wout_reg

  // Clock domain crossing
  (* ASYNC_REG = "True", SHREG_EXTRACT = "No" *) t_sig [SYNC_STAGES-1:0] q_sync_stages = ( CDC_CONFIG == "SYNC_RESET" ) ? {SYNC_STAGES{INIT_STATE}} : ( CDC_CONFIG == "ASYNC_RESET" ) ? {SYNC_STAGES{RESET_POLARITY}} : '0;

  if ( CDC_CONFIG == "PULSE" ) begin : pulse_cdc

    always_ff @(posedge i_dst_a_clk_p)
      if ( i_dst_s_rst_p )
        q_sync_stages <= '0;
      else
        q_sync_stages <= { q_sync_stages[$high(q_sync_stages)-1:0], w_src_cdc_sig };

  end : pulse_cdc else if ( CDC_CONFIG == "GRAY" ) begin : gray_cdc

    always_ff @(posedge i_dst_a_clk_p)
      q_sync_stages <= { q_sync_stages[$high(q_sync_stages)-1:0], w_src_cdc_sig };

  end : gray_cdc else if ( CDC_CONFIG == "ASYNC_RESET" ) begin : async_cdc

    wire w_src_cdc_rst = ( RESET_POLARITY ) ? w_src_cdc_sig : ~ w_src_cdc_sig;

    always_ff @(posedge i_dst_a_clk_p or posedge w_src_cdc_rst)
      if ( w_src_cdc_rst )
        q_sync_stages <= {SYNC_STAGES{RESET_POLARITY}};
      else
        q_sync_stages <= { q_sync_stages[$high(q_sync_stages)-1:0], !RESET_POLARITY };

  end : async_cdc else begin : other_cdc

    always_ff @(posedge i_dst_a_clk_p)
      q_sync_stages <= { q_sync_stages[$high(q_sync_stages)-1:0], w_src_cdc_sig };

  end : other_cdc

  wire t_sig w_dst_hgh_sig = q_sync_stages[$high(q_sync_stages)];

  // Output logic
  wire t_sig w_dst_cdc_sig;
  if ( CDC_CONFIG == "PULSE" ) begin : pulse_out

    t_sig q_pls_cdc_sig = '0;
    always_ff @(posedge i_dst_a_clk_p)
      if ( i_dst_s_rst_p )
        q_pls_cdc_sig <= '0;
      else
        q_pls_cdc_sig <= w_dst_hgh_sig;

    assign w_dst_cdc_sig = q_pls_cdc_sig ^ w_dst_hgh_sig;

  end : pulse_out else begin : other_out

    assign w_dst_cdc_sig = w_dst_hgh_sig;

  end : other_out

  // Output register
  if ( OUTPUT_REG ) begin : out_with_reg

    t_sig q_out_cdc_sig = ( CDC_CONFIG == "SYNC_RESET" ) ? INIT_STATE : ( CDC_CONFIG == "ASYNC_RESET" ) ? RESET_POLARITY : '0;

    if ( CDC_CONFIG == "PULSE" ) begin : pulse_cfg

      always_ff @(posedge i_dst_a_clk_p)
        if ( i_dst_s_rst_p )
          q_out_cdc_sig <= '0;
        else
          q_out_cdc_sig <= w_dst_cdc_sig;

    end : pulse_cfg else begin : other_cfg

      always_ff @(posedge i_dst_a_clk_p)
        q_out_cdc_sig <= ( CDC_CONFIG == "GRAY" ) ? Gray2Binary(w_dst_cdc_sig) : w_dst_cdc_sig;

    end : other_cfg

    assign o_dst_cdc_sig = q_out_cdc_sig;

  end : out_with_reg else begin : out_wout_reg

    assign o_dst_cdc_sig = ( CDC_CONFIG == "GRAY" ) ? Gray2Binary(w_dst_cdc_sig) : w_dst_cdc_sig;

  end : out_wout_reg

endmodule : fifo_cdc