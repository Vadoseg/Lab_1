`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Vadim Hvatov
// 
// Create Date: 04/16/2024 02:55:29 PM
// Design Name: 
// Module Name: l2b_Led_top
// Project Name: LAB Work #2b
// Target Devices: zc702
// Tool Versions: Vivado 2021.1
// Description: Top-Module
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Revision 1.01 - Top-module was made
// Revision 0.03 - Added Comments
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module l2b_Led_top#(
    parameter CLK_FREQUENCY    = 200.0e6, // Hz,
    parameter int G_LED_WIDTH  = 8,
    parameter int G_LEDS       = 4,
    parameter int G_SEL_WIDTH  = $ceil($clog2(G_LEDS)),
    parameter real G_BLINK_PERIOD [0:G_LEDS-1] = '{1: 2, 2: 3, 3: 4, default:1} //Seconds
)
(
    input  wire                    clk_ini_p, clk_ini_n,
    input  wire  [G_SEL_WIDTH-1:0] i_selector,
    output logic [G_LED_WIDTH-1:0] o_led
    );
    
      IBUFDS #(
        .DIFF_TERM      ("TRUE"),
        .IBUF_LOW_PWR   ("FALSE"),
        .IOSTANDARD     ("LVDS")
    ) IBUFDS_inst (
        .I  (clk_ini_p ),
        .IB (clk_ini_n ),
        .O  (w_clk     )
    );
    
    wire [G_LEDS-1:0] w_led; // Making a bus which connect o_led of all LEDS together
  
//Generate LEDs------------------------------------------------------------------------------------
    genvar i;
   
    generate for (i = 0; i < G_LEDS; i+=1) begin : gen_led
        l2b_sv_led#(
            .CLK_FREQUENCY (CLK_FREQUENCY    ),
            .BLINK_PERIOD  (G_BLINK_PERIOD[i]),
            .G_CNT_LEDS    (1                ) //Number of output from LEDs
        ) LED (
            .i_clk  (w_clk   ), //Giving to i_clk value of w_clk(Output from Diff.Clock/IBUFDS)
            .i_rst  ('0      ), // i_rst = '0 because we don't need this now
            .o_led  (w_led[i])  //Connecting o_led with each other
        );
    end : gen_led endgenerate

//Adding MUX---------------------------------------------------------------------------------------
        sv_mux#(
            .G_SIG_WIDTH(G_LEDS) //This will change bit number of signals and bit number of selector
            
        ) MUX (
            .i_selector (i_selector),
            .i_signal   (w_led     ),
            .o_func     (o_func    )
        );

//Making a process which connect o_led(Led_top) and o_func(MUX)------------------------------------   
        always @(posedge w_clk)
		  o_led <= '{default: o_func};
endmodule
