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
    parameter BLINK_PERIOD  = 1.0, // Seconds
    parameter G_CNT_LEDS    = 4,
    parameter G_LED_WIDTH   = int'($ceil($clog2(G_CNT_LEDS+1))) // output leds
)
(
    input i_clk,
    /*(* MARK_DEBUG="true" *)*/input i_rst,
    /*(* MARK_DEBUG="true" *)*/output logic [G_LED_WIDTH-1:0] o_led
);

//Constants
    localparam COUNTER_PERIOD = int'(BLINK_PERIOD * CLK_FREQUENCY);
    
    localparam COUNTER_WIDTH  = int'($ceil($clog2(COUNTER_PERIOD+1)));
    
//Counter & Comparator
    /*(* MARK_DEBUG="true" *)*/reg [COUNTER_WIDTH -1 : 0] counter_value ='0;
    /*(* MARK_DEBUG="true" *)*/logic led_on;
    
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
        o_led[G_LED_WIDTH-1:1]<={$size(o_led[G_LED_WIDTH-1:1]){led_on}}; // 3 wires will be equal to led_on, except first
        o_led[0]<=!led_on;
    end
    
    
endmodule


/*module sv_led_2#(
    parameter CLK_FREQUENCY = 200.0e6,
    parameter BLINK_PERIOD = 1.0
)
(
    input i_clk,
    input i_rst,
    output logic [7:4] o_led_2
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
        o_led_2[7:5]<={$size(o_led_2[7:5]){led_on}}; // 3 wires will be equal to led_on, except first
        o_led_2[4]<=!led_on;  
    end

endmodule*/


