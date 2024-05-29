`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/29/2024 01:53:57 PM
// Design Name: 
// Module Name: l5_reg_map
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


module l5_reg_map#(
        int G_RM_ADDR_W = 8, // AXIL xADDR bit width
	    int G_RM_DATA_B = 8 // AXIL xDATA number of bytes (B)
    )(
        input bit i_err_crc,
        input bit i_err_mis_tlast,
        input bit i_err_unx_tlast,

        input bit i_clk,
        input bit i_rst,

        output reg [(G_RM_DATA_B * 8) - 1 : 0]  o_length,
        output reg [(G_RM_DATA_B * 8) - 1 : 0]  o_err,

        if_axil.s s_axil
    );

    localparam C_RM_DATA_W = 8 * G_RM_DATA_B;

    typedef logic [G_RM_ADDR_W - 1 : 0] t_xaddr;
	typedef logic [C_RM_DATA_W - 1 : 0] t_xdata;

    localparam t_xaddr C_LEN_ADDR	    = 'h00; 

	localparam t_xaddr C_ERR_ADDR     = 'h04;

    t_xaddr ADDR;

    task t_axil_init; 
        begin
            s_axil.awready = 0;
            s_axil.wready  = 0;
            s_axil.bvalid  = 0;
            s_axil.arready = 0;
            s_axil.rvalid  = 0;
            s_axil.bvalid  = 0;
            s_axil.bresp   = 0;

        end
    endtask : t_axil_init
    
endmodule
