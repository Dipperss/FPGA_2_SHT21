module iic_write8(
			input clk,			// 100M时钟
			input rst_n,		//低电平复位信号
            input en,
            input scl_hs,
            input scl_ls,
            input scl_lc,
            output reg sdar,
            output reg sdalink,
            input state,
            input[7:0] DEVICE_WRITE8,
            input[3:0] state_code,
            output reg next_state_sig//状态保持信号
		);

reg[2:0] bcnt;	//数据位寄存器,bit0-7
always @(posedge clk or negedge rst_n)
	if(!rst_n || en) begin
        bcnt <= 3'd7;
        next_state_sig <= 1'b0;
        sdalink <= 1'b0; 
        sdar <= 1'b0;
    end
    else if(state && !next_state_sig) begin
        sdalink <= 1'b1;
        if(scl_ls && (bcnt == 3'd7)) begin
            bcnt <= 3'd7;
            next_state_sig <= 1'b1;
            sdalink <= 1'b0;
            sdar <= 1'b0;
        end
        else if(scl_hs) bcnt <= bcnt-1'b1;
        else if(scl_lc) sdar <= DEVICE_WRITE8[bcnt];
        else ;
    end


endmodule
    