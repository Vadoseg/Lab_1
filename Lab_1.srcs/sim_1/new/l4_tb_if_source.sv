`timescale 1ns / 1ps
/*interface if_axis #(parameter int N = 1) ();
	
	localparam W = 8 * N; // tdata bit width (N - number of BYTES)
	
	logic         tready;
	logic         tvalid;
	logic         tlast ;
	logic [W-1:0] tdata ;
	
	modport m (input tready, output tvalid, tlast, tdata);
	modport s (output tready, input tvalid, tlast, tdata);
	
endinterface : if_axis*/
module l4_tb_if_source#(
    parameter int G_BYT = 1,             
    parameter int G_BIT_WIDTH = 8 * G_BYT,
    parameter int G_DATA_MAX = 10, //Size of data pack
    parameter int G_CNT_WIDTH = ($ceil($clog2(G_DATA_MAX+1)))
    );
    
    localparam T_CLK = 1;
    
    bit i_clk = '0;
    bit i_rst = '0;
    logic w_tready = '0;
    if_axis m_axis();
    logic [G_CNT_WIDTH-1:0] i_length = '0;
    
    l4_if_source #(
        .G_DATA_MAX (G_DATA_MAX)
    ) UUT_1 (
        .i_clk  (i_clk),
        .i_rst  (i_rst  ),
        .i_length (i_length),
        .m_axis   (m_axis  )
    );
    
    always#(T_CLK) i_clk = ~i_clk;
    always#(T_CLK*10) w_tready = ~w_tready; // Problem? check if work

//      always#(T_CLK*10) m_axis.tready = ~m_axis.tready;

    always_ff @(posedge i_clk)
        m_axis.tready <= w_tready;
        // i_src_tready <= w_tready;

    initial begin
        m_axis.tready <= '0;
        #(T_CLK * 5)
        i_length <= G_DATA_MAX; // G_DATA_MAX need to be equal or bigger than i_length
        
        /*#(T_CLK * 20)
        i_length <= 0;
        
        #(T_CLK * 20)
        i_length <= 30;
        
        #(T_CLK * 20)
        i_length <= 0;
        
        #(T_CLK * 20)
        i_length <= 10;
        
        #(T_CLK * 20)
        i_length <= 0;*/
    end

endmodule
