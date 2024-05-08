`timescale 1ns / 1ps


module l4_tb_if_sink#(
        parameter int G_BYT = 1,
        parameter int G_BIT_WIDTH = 8 * G_BYT
    )(
    
    );
    
    if_axis s_axis();

    bit i_clk = '0;
    
    localparam T_CLK = 1;
    localparam C_PACK_LENGTH = 10;

    l4_if_sink#( 
        .G_BYT       (G_BYT      ),
        .G_BIT_WIDTH (G_BIT_WIDTH)
    ) SINK (
        .i_clk  (i_clk ),
        .i_rst  ('0    ), 
        .s_axis (s_axis)
    );
    
    always#(T_CLK * 10) i_clk = ~i_clk;


    initial
    begin
    // Interface init
    s_axis.tvalid = '0;
    s_axis.tlast  = '0;
    s_axis.tdata  = '0;
    // States:
    // S0: Init

    // S1
    s_axis.tvalid = '1;  // Header is not coming in
    s_axis.tdata  = 72;
    #(T_CLK * 20)
    s_axis.tvalid = '0;
    
    // S2
    #(T_CLK * 20)
    s_axis.tvalid = '1;
    s_axis.tdata  = C_PACK_LENGTH;
    #(T_CLK * 20)

    // S3
    #(T_CLK * 20)
    for (int i = 1; i < C_PACK_LENGTH + 1; i++) begin
        s_axis.tdata = i;
        #(T_CLK * 20);
    end
    s_axis.tvalid = '0;

    // S4: Pause

    // S5
    #(T_CLK * 20)
    s_axis.tvalid = '1;
    s_axis.tdata  = 'h5B;  // h6E( for 30)
    s_axis.tlast  = '1;
    #(T_CLK * 20)
    s_axis.tvalid = '0;
    s_axis.tlast  = '0;
    s_axis.tdata  = '0;
    end

endmodule