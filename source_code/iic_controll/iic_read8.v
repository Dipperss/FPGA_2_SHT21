module iic_read8(
			input clk,			// 100M时钟
			input rst_n,		//低电平复位信号
            input en,
            input scl_hsm,
            input scl_hc,
            input scl,
            input sda,
            output reg sdalink,
            input state,
            input[3:0] state_code,
            output reg[7:0] DEVICE_READ8,
            output reg next_state_sig//状态保持信号
		);


reg[2:0] bcnt;	//数据位寄存器,bit0-7
always @(posedge clk or negedge rst_n)
	if(!rst_n || en) begin
        bcnt <= 3'd7;
        next_state_sig <= 1'b0;
        sdalink <= 1'b0; 
    end
    else if(state && !next_state_sig) begin
        sdalink <= 1'b0;
        if(scl_hsm && scl == 1'b1) bcnt <= bcnt-1'b1;
        else if(scl_hc  && (scl == 1'b1)) begin
                 DEVICE_READ8[bcnt+1'b1] <= sda;
                 if (bcnt == 3'd7) begin
                     next_state_sig <= 1'b1;
                    //  sdalink  <= 1'b1;
                 end      
        end
    else ;
    end           
endmodule

    