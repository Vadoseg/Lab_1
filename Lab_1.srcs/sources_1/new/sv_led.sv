`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/04/2024 10:29:22 AM
// Design Name: 
// Module Name: sv_led
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

module sv_led#(
    parameter CLK_FREQUENCY = 200.0e6, // Hz
    parameter BLINK_PERIOD = 1.0 // Seconds
)
(
    input i_clk,
    input i_rst,
    output logic [3:0] o_led = '0
);


//Constants
    localparam COUNTER_PERIOD = int'(BLINK_PERIOD * CLK_FREQUENCY);
    
    localparam COUNTER_WIDTH  = int'($ceil($clog2(COUNTER_PERIOD+1)));
    
//Counter & Comparator
    reg [COUNTER_WIDTH -1 : 0] counter_value ='0;
    logic led_on;
    
    always_ff@(posedge i_clk)begin
        if(i_rst || counter_value == COUNTER_PERIOD-1)
        begin
            counter_value <= 0;
        end
        
        else begin
            counter_value <= counter_value + 1;
        end;
    end
    
    always_ff@(posedge i_clk)begin
        if(counter_value < COUNTER_PERIOD/2)
        begin
            led_on <= 0;
        end
        else begin
            led_on <= 1;
        end;
        o_led[3:1]<={$size(o_led[3:1]){led_on}}; // 3 wires will be equal to led_on, except first
        
        //o_led[3:1]<=logic'(led_on);
        o_led[0]<=!led_on;  
    end
    
    
endmodule

module Led_top(
    input clk_ini_p,
    input clk_ini_n,
    input i_rst,
    output logic [3:0] o_led

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
    
    
    sv_led LED (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .o_led(o_led)
    );
endmodule


