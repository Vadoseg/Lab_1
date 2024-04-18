`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Vadim Hvatov
// 
// Create Date: 04/18/2024 02:18:44 PM
// Design Name: 
// Module Name: l2b_tb_Led_top
// Project Name: Testbench for l2b_Led_top
// Target Devices: zc702
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Revision 1.01 - Completed
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module l2b_tb_Led_top ();

//Adding UUT Generics------------------------------------------------------------------------------
    
    localparam       G_CLK_FREQUENCY    = 1e9; // Hz = 1 GHz
    localparam  real G_BLINK_PERIOD [0:3] = '{1e-6, 2e-6, 3e-6, 4e-6}; // Milliseconds
    localparam  int  G_LEDS             = $size(G_BLINK_PERIOD);
    localparam  int  G_SEL_WIDTH        = $ceil($clog2(G_LEDS));
    localparam  int  G_LED_WIDTH        = 8;

// Adding TestBench Constants
    localparam       T_CLK = 1e9 / G_CLK_FREQUENCY; // 1 Nanosecond
    
    
    /*bit clk_ini_p =  '1;
    bit clk_ini_n =  '1;*/ //Instead of this, we can use 1 i_clk for negative and positive
    
    
// UUT I/O signals    
    logic                   i_clk      = '0;
    logic [G_SEL_WIDTH-1:0] i_selector = '0;  //  MUX selector
    logic [G_LED_WIDTH-1:0] o_led      = '0;  //  LED Output

    l2b_Led_top #(
        .G_CLK_FREQUENCY    (G_CLK_FREQUENCY ),
        .G_LED_WIDTH        (G_LED_WIDTH     ),
        .G_LEDS             (G_LEDS          ),
        .G_SEL_WIDTH        (G_SEL_WIDTH     ),
        .G_BLINK_PERIOD     (G_BLINK_PERIOD  )
    ) LED_TOP_2B (
        .clk_ini_p  (i_clk     ),     //  Positive with i_clk
        .clk_ini_n  (~i_clk    ),     //  Negative with i_clk
        .i_selector (i_selector),     //  MUX selector
        .o_led      (o_led     )      //  LED Output
    );
    
    always #(T_CLK/2) i_clk = ~i_clk; //  Simulate clock
    always #(1e4) i_selector += 1;    //  Overflowing a selector to simulate its work (1e4 = 10 Microseconds) 
                                      //  Selector need to switch faster then LED's BLINK_PERIOD, so we use 1e4 which faster then 1e-6
                                      //  Millisecond = 1000 Microseconds
endmodule
