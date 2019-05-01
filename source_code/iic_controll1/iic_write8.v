module iic_write8(
			input clk,			// 100M时钟
			input rst_n,		//低电平复位信号
            input en,
            input scl_hs,
            input scl_lc,
            inout sda,
            inout[3:0] state,
            input[7:0] DEVICE_WRITE8,
            input[3:0] state_code
		);

reg[3:0] cstate;
reg sdalink;
reg sdar;
reg[2:0] bcnt;	//数据位寄存器,bit0-7
always @(posedge clk or negedge rst_n)
	if(!rst_n || en) begin
        bcnt <= 3'd7;
        sdalink <= 1'b1;
        cstate <= state_code;
    end
    else if(state == state_code) begin
        if(scl_lc && (bcnt == 3'd0)) begin
            bcnt <= 3'd7;
            sdalink <= 1'b0;
            cstate <= cstate + 1'b1;
        end
        else if(scl_hs) bcnt <= bcnt-1'b1;
        else if(scl_lc) sdar <= DEVICE_WRITE8[bcnt];
        else ;
    end

assign state = (state == state_code)?cstate:4'bzzzz;
assign sda = (state == state_code && sdalink) ? sdar : 1'bz;
endmodule
    