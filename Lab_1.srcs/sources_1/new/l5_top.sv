`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/27/2024 12:34:55 PM
// Design Name: 
// Module Name: l5_top
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


module l5_top#(

    )(
        input bit [2:0] i_rst,
        input bit i_reg_rst,
        input bit i_clk,

        if_axil.s s_axil
    );

    
    /*(* keep_hierarchy="yes" *)   
    axil_fifo #(

    )(

    );*/

    int length;

    (* keep_hierarchy="yes" *)  
    l4_if_top #(
        .G_DATA_MAX (length)    // Maybe need to change from "parameter" to "input"
    
    ) l4_top (
        
        .i_clk              (i_clk),
        .i_rst              (i_rst),

        .o_err_crc          (w_err_crc      ),
        .o_err_mis_tlast    (w_err_mis_tlast),
        .o_err_unx_tlast    (w_err_unx_tlast)

    );

    (* keep_hierarchy="yes" *)   
    l5_reg_map #(

    )(
        .i_clk              (i_clk    ),
        .i_rst              (i_reg_rst),

        .i_err_crc          (w_err_crc      ),
        .i_err_mis_tlast    (w_err_mis_tlast),
        .i_err_unx_tlast    (w_err_unx_tlast),

        .o_length           (length),
        .o_err              (o_err ),
        
        .s_axil             (s_axil)
    );


endmodule
