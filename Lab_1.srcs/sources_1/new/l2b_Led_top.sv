`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/16/2024 02:55:29 PM
// Design Name: 
// Module Name: l2b_Led_top
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


module l2b_Led_top#(
    parameter CLK_FREQUENCY    = 200.0e6, // Hz,
    parameter int G_LED_WIDTH  = 8,
    parameter int G_LEDS       = 4,
    parameter int G_SEL_WIDTH  = $ceil($clog2(G_LEDS)),
    parameter real G_BLINK_PERIOD [0:G_LEDS-1] = '{1: 2, 2: 3, 3: 4, default:1}
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
    
    wire [G_LEDS-1:0] w_led;
    
    genvar i;
   
    generate for (i = 0; i < G_LEDS; i+=1) begin : gen_led
        l2b_sv_led#(
            .CLK_FREQUENCY (CLK_FREQUENCY    ),
            .BLINK_PERIOD  (G_BLINK_PERIOD[i]),
            .G_CNT_LEDS    (1                )
        ) LED (
            .i_clk  (w_clk   ),
            .i_rst  ('0      ),
            .o_led  (w_led[i])
        );
    end : gen_led endgenerate
    
        sv_mux#(
            .G_SIG_WIDTH(G_LEDS)
            
        ) MUX (
            .i_selector (i_selector),
            .i_signal   (w_led     ),
            .o_func     (o_func    )
        );
        
        always @(posedge w_clk)
		  o_led <= '{default: o_func};
endmodule
