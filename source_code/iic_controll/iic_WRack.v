module iic_WRack(
			input clk,			// 100M时钟
			input rst_n,		//低电平复位信号
			input en,
			input scl_hc,     //分频数字，分频后的的频率=clk频率/分频数字，注意分频后的iic频率应该在100kHZ~400kHZ之间
			input scl_ls,		//启动信号
            inout scl_lc,	//串行配置IIC时钟信号
            input sda,
			output reg sdalink,
			input state,
			input[3:0] state_code,
			output reg nack,//收到接收失败信号，状态变为停止状态
			output reg next_state_sig//状态保持信号
		);

reg bcnt;
reg nack_signal;
always @(posedge clk or negedge rst_n)
	if(!rst_n || en) begin
		bcnt <= 1'b0;
		next_state_sig <= 1'b0; 
		nack <= 1'b0;
		nack_signal <= 1'b0;
		sdalink <= 1'b0; 
	end
	else if(state && !next_state_sig) begin
		sdalink <= 1'b0; 
		if(scl_hc && sda == 1'b0 && bcnt == 1'b1) nack_signal <= 1'b0;//无nack
		else if(scl_hc && sda == 1'b1 && bcnt == 1'b1) nack_signal <= 1'b1;//有nack
		else if(scl_ls && (bcnt == 1'b1)) begin
			if(nack_signal) nack <= 1'b1;
			else next_state_sig <= 1'b1;
		end
		else if(scl_lc) begin
				bcnt <= 1'b1;
		end
	end
	else ;

endmodule