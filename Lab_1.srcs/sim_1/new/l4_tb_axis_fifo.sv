`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/17/2024 11:43:47 AM
// Design Name: 
// Module Name: l4_tb_axis_fifo
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

interface if_axis #(parameter int N = 1) ();
	
	localparam W = 8 * N; // tdata bit width (N - number of BYTES)
	
	logic         tready;
	logic         tvalid;
	logic         tlast ;
	logic [W-1:0] tdata ;
endinterface

module l4_tb_axis_fifo#(

    int G_BYT = 1,         // byte width
    //(Not in use)int G_WID = 8 * G_BYT, // bit width
    
    T_CLK = 1.0        //ns
);

    logic i_aresetn = '1; // asynchronous reset
    logic i_aclk   = '0; // clock
 
 
    if_axis #(.N(G_BYT)) s_axis ();
    if_axis #(.N(G_BYT)) m_axis ();
    
// Init AXIS
task axis_init;
    begin
        
        s_axis.tvalid <= 0; 
        s_axis.tlast  <= 0;
        s_axis.tdata  <= 0;
    end   
endtask
    
//Send packet to AXIS FIFO    
int i;    
task send_pkt;
    localparam P = 100; // Number of samples in packet
    begin
        for(i = 1; i <= P; i++) begin
            s_axis.tvalid   <= 1;
            s_axis.tlast    <= (i == P);
            s_axis.tdata    <= i;
            #(T_CLK);                       //delay(?)
            s_axis.tvalid   <= 0;
        end
    end
endtask   

int k;
initial begin
// init    
    i_aresetn = 1;
    axis_init;
    m_axis.tready = 1;
    #(10*T_CLK);
// reset FIFO (active-low)  
    i_aresetn = 0;
    #(10*T_CLK);
    i_aresetn = 1;
    #(10*T_CLK);
// send several packets
    for (k = 0; k < 8; k++) begin
        send_pkt;
    end
 // send 1st packet
    send_pkt;
 // send 2nd packet  
    send_pkt; 
end

 // simlate clock
always #(T_CLK/2.0) i_aclk = ~i_aclk;

 // UUT: AXIS FIFO IP
    axis_data_fifo_0 UUT(
    
        .s_axis_aresetn      (i_aresetn), // input wire s_axis_areset 
        .s_axis_aclk         (i_aclk   ), // input wire s_axis_aclk
        
        .s_axis_tready      (s_axis.tready), // output wire s_axis_tready
        .s_axis_tvalid      (s_axis.tvalid), // input wire s_axis_tvalid
        .s_axis_tlast       (s_axis.tlast ), // input wire s_axis_tlast 
        .s_axis_tdata       (s_axis.tdata ), // input wire [7:0] s_axis_tdata 
        
        .m_axis_tready      (m_axis.tready), // input wire  m_axis_tready
        .m_axis_tvalid      (m_axis.tvalid), // output wire m_axis_tvalid
        .m_axis_tlast       (m_axis.tlast ), // output wire m_axis_tlast 
        .m_axis_tdata       (m_axis.tdata ), // output wire [7:0] m_axis_tdata 
        
        .axis_wr_data_count (             ), // output wire [31:0] axis_wr_data_count
        .axis_rd_data_count (             ), // output wire [31:0] axis_rd_data_count
        .prog_empty         (             ), // output wire prog_empty
        .prog_full          (             )  // output wire prog_full 
        
    );
 
endmodule : l4_tb_axis_fifo
