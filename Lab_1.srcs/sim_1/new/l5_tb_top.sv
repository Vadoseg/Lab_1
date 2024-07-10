
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/30/2024 05:36:04 PM
// Design Name: 
// Module Name: l5_tb_top
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


module l5_tb_top#(

    int G_RM_ADDR_W = 4, 	// AXIL xADDR bit width
	int G_RM_DATA_B = 4, 	// AXIL xDATA number of bytes (B)
	real dt = 1.0 			// clock period ns
    )(

    );

    bit i_clk = '0;
    bit i_reg_rst = '0; 
    localparam T_CLK = 1.0; 
    localparam C_RM_DATA_W = 8 * G_RM_DATA_B;

    reg [7 : 0] 				length;
	reg [2 : 0]					i_rst = '0;
	reg [C_RM_DATA_W - 1 : 0]	w_err;


    typedef logic [G_RM_ADDR_W - 1 : 0] t_xaddr;
	typedef logic [C_RM_DATA_W - 1 : 0] t_xdata;

    if_axil #(.N(G_RM_DATA_B),  .A(G_RM_ADDR_W)) m_axil();

    l5_top TOP(
        .i_clk      (i_clk    ),
        .i_rst      (i_rst    ),
        .i_reg_rst  (i_reg_rst),

        .s_axil     (m_axil   )

    );

    always #(T_CLK) i_clk = ~i_clk;


    task t_axil_init; 
        begin
            m_axil.awvalid  <= '0;
            m_axil.awaddr   <= '0;
            m_axil.wvalid   <= '0;
            m_axil.wdata    <= '0;
            m_axil.wstrb    <= '0;
            m_axil.bready   <= '0;
            m_axil.arvalid  <= '0;
            m_axil.araddr   <= '0;
            m_axil.rready   <= '0;
            m_axil.rresp    <= '0;
            // m_axil.rdata    <= '0;

        end
    endtask : t_axil_init
    

    initial begin
        t_axil_init;
    end

     `define MACRO_AXIL_HSK(miso, mosi) \
		m_axil.``mosi``= '1; \
		do begin \
			#dt; \
		end while (!(m_axil.``miso`` && m_axil.``mosi``)); \
		m_axil.``mosi`` = '0; \


    task t_axil_wr;
		input t_xaddr ADDR;
		input t_xdata DATA;
		begin
		// write address
			m_axil.awaddr = ADDR;
			`MACRO_AXIL_HSK(awready, awvalid);
		// write data
			m_axil.wdata = DATA;
			m_axil.wstrb = '1;
			`MACRO_AXIL_HSK(wready, wvalid);
		// write response
			`MACRO_AXIL_HSK(bvalid, bready);
		end
	endtask : t_axil_wr   


    task t_axil_rd;
		input  t_xaddr ADDR;
		output t_xdata DATA;
		begin
		// read address
			m_axil.araddr = ADDR;
			`MACRO_AXIL_HSK(arready, arvalid);
		// read data
			m_axil.rresp = 2'b00;
			`MACRO_AXIL_HSK(rvalid, rready);
			DATA = m_axil.rdata;
		end
	endtask : t_axil_rd

    task t_axil_reset;
        begin
            
            #(dt*120)
            i_rst[0] = 1;
		    #2 i_rst = 0;

            #(dt*75)
            i_rst[1] = 1;
			#2 i_rst = 0;

            #(dt * 40)
            i_rst[2] = 1;
			#2 i_rst = 0;

        end
        
    endtask : t_axil_reset

    localparam t_xaddr LEN_ADDR		= 'h01; 
	// localparam t_xaddr LEN1_ADDR	= 'h02; 
	// localparam t_xaddr WRNG_ADDR 	= 'h03;  
	localparam t_xaddr ERR_ADDR	 	= 'h04;  

    always #(dt / 2) i_clk = ~i_clk;

    initial begin
        i_reg_rst   = 1; 
        #2;
        i_reg_rst   = 0;
	end


	// initial begin

	// 	#5 t_axil_rd(.ADDR(ERR_ADDR), .DATA(w_err));

	// end

    initial begin
		
        t_axil_init;

        #5;
        length = 5;
        t_axil_wr(.ADDR(LEN_ADDR), .DATA(length));
		t_axil_rd(.ADDR(ERR_ADDR), .DATA(w_err));
		#5;
		t_axil_wr(.ADDR(LEN_ADDR), .DATA(length + 1));
		t_axil_rd(.ADDR(ERR_ADDR), .DATA(w_err));
		#5;
		t_axil_wr(.ADDR(LEN_ADDR), .DATA(length + 2));
		t_axil_rd(.ADDR(ERR_ADDR), .DATA(w_err));
		#5;
		t_axil_wr(.ADDR(LEN_ADDR), .DATA(length + 3));
		t_axil_rd(.ADDR(ERR_ADDR), .DATA(w_err));

		// #10;
        // length = 8;
        // t_axil_wr(.ADDR(LEN1_ADDR), .DATA(length));
		t_axil_rd(.ADDR(ERR_ADDR), .DATA(w_err));

		length = 10;

		#10;
		t_axil_rd(.ADDR(LEN_ADDR), .DATA(length));

		// #10;
		// t_axil_rd(.ADDR(WRNG_ADDR), .DATA(w_err));

        t_axil_reset;
	end

    /* initial begin
        t_axil_init;

        #5;
        length = 5;
        // w_err  = 11;
        t_axil_wr(.ADDR(LEN_ADDR), .DATA(length));
        t_axil_rd(.ADDR(ERR_ADDR), .DATA(w_err));
        #5;
		t_axil_wr(.ADDR(LEN_ADDR), .DATA(length - 5));
		t_axil_rd(.ADDR(ERR_ADDR), .DATA(w_err));

        t_axil_reset;

        t_axil_wr(.ADDR(LEN_ADDR), .DATA(length));
        t_axil_rd(.ADDR(ERR_ADDR), .DATA(w_err));

    end

    always #(dt/2) t_axil_rd(.ADDR(ERR_ADDR), .DATA(w_err)); */
endmodule