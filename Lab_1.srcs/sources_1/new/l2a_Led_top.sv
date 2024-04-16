module l2a_Led_top#(
    parameter CLK_FREQUENCY = 200.0e6, // Hz
    parameter BLINK_PERIOD = 1.0 // Seconds
)

(
    input clk_ini_p,
    input clk_ini_n,
    input [1:0] i_rst,
    output logic [7:0] o_led
    //output logic [7:4] o_led_2
);


   IBUFDS #(
        .DIFF_TERM("TRUE"),
        .IBUF_LOW_PWR("FALSE"),
        .IOSTANDARD("LVDS")
   ) IBUFDS_inst (
        .O(clk_out1),
        .I(clk_ini_p),
        .IB(clk_ini_n)
   );

   BUFG BUFG_inst (
      .O(i_clk), // 1-bit output: Clock output
      .I(clk_out1)  // 1-bit input: Clock input
   );
    
    sv_led#(
        .CLK_FREQUENCY(CLK_FREQUENCY),
        .BLINK_PERIOD(BLINK_PERIOD)
    ) LED [1:0](
        .i_clk(i_clk),
        .i_rst(i_rst),
        .o_led(o_led)
    );
    
    /*sv_led_2 LED_2 (
        .i_clk(i_clk),
        .i_rst(i_rst[1]),
        .o_led_2(o_led_2)
    );*/
endmodule