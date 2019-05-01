module iic_WRack(
			input clk,			// 100M时钟
			input rst_n,		//低电平复位信号
			input en,
			input scl_hc,     //分频数字，分频后的的频率=clk频率/分频数字，注意分频后的iic频率应该在100kHZ~400kHZ之间
			input scl_ls,		//启动信号
            inout scl_lc,	//串行配置IIC时钟信号
			input sda,
            inout[3:0] state,
			input[3:0] state_code,
			input[3:0] stop_code//收到接收失败信号，状态变为停止状态
		);

reg bcnt;
reg[3:0] cstate;
reg ack;
reg sdalink;
always @(posedge clk or negedge rst_n)
	if(!rst_n || en) begin
		bcnt <= 1'b0;
		cstate <= state_code;
		ack <= 1'b0;
		sdalink <= 1'b0;
	end
	else if(state == state_code) begin
		if(scl_hc && sda == 1'b0 && bcnt == 1'b1) ack <= 1'b0;
		else if(scl_hc && sda == 1'b1 && bcnt == 1'b1) ack <= 1'b1;
		else if(scl_ls && (bcnt == 1'b1))begin
			if(!ack) cstate <= cstate + 1'b1;
			else cstate <= stop_code;
		end

		else if(scl_lc) begin
				bcnt <= 1'b1;
		end
	end
	else ;

assign state = (state == state_code)?cstate:4'bzzzz;
assign sda = (state == state_code && sdalink)?1'bz:1'bz;
endmodule