`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/11/2024 02:54:01 PM
// Design Name: 
// Module Name: sv_led_no_comparator
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


module sv_led_no_comparator#(
    parameter CLK_FREQUENCY = 200.0e6, // Hz
    parameter BLINK_PERIOD = 1.0 // Seconds
)
(
    input i_clk,
    input i_rst,
    output logic [3:0] o_led
);

//Constants
    localparam COUNTER_PERIOD = int'(BLINK_PERIOD * CLK_FREQUENCY);
    
    localparam COUNTER_WIDTH  = int'($ceil($clog2(COUNTER_PERIOD+1)));
    
//Counter & Comparator
    reg [COUNTER_WIDTH -1 : 0] counter_value ='0;
    
    always_ff@(posedge i_clk)begin
        if(i_rst || counter_value == COUNTER_PERIOD-1)
        begin
            counter_value <= 0;
        end
        
        else begin
            counter_value <= counter_value + 1;
        end;
    end
    
    /*always_ff@(posedge i_clk)begin
        if(counter_value < COUNTER_PERIOD/2)
        begin
            led_on <= 0;
        end
        else begin
            led_on <= 1;
        end;
        o_led[3:1]<={$size(o_led[3:1]){led_on}}; // 3 wires will be equal to led_on, except first
        o_led[0]<=!led_on;
    end*/
    
    assign o_led[0] = counter_value[7];
    always_comb begin
        o_led[3:1] <={$size(o_led[3:1]){~o_led[0]}};
        /*if(i_rst) begin
            o_led[0] <= 0;
        end*/
       
    end
    //000 <= {3 0}
    //2^28
endmodule

