module iic_scl(
			input clk,			// 100M时钟
			input rst_n,		//低电平复位信号
			input[9:0] sclDiv,     //分频数字，分频后的的频率=clk频率/分频数字，注意分频后的iic频率应该在100kHZ~400kHZ之间
			input en,		//启动信号
            inout scl,	//串行配置IIC时钟信号
            inout[3:0] state,
			input[3:0] state_code,
            output[9:0] icnt//分频时钟
		);
reg[3:0] cstate;
reg hold_signal;
//使能信号启动scl的cnt计时器
always @(posedge clk or negedge rst_n)
	if(!rst_n) begin 
		hold_signal <= 1'd0;
		cstate <= state_code;
	end
	else if(state == state_code) begin 
		if(en) begin
			hold_signal <= 1'b1;
			cstate <= cstate + 1'b1;
		end
		else begin
			hold_signal <= 1'b0;
			cstate <= state_code;
		end
	end
	// else if(state == DSTOP && scl_ls) hold_signal <= 1'b0;//重新研究一个时序，在条件语句中，现在这个语句与最后STOP信号冲突
	// else if(state == state_code) hold_signal <= 1'b0;//0状态为IDLE状态
	else ;


//-------------------------------------------------
//IIC时钟信号scl产生逻辑

reg[9:0] cnt;
always @(posedge clk or negedge rst_n)
	if(!rst_n) cnt <= 10'd0;
	else if(cnt < sclDiv && hold_signal) cnt <= cnt + 1'b1;
	else cnt <= 10'd0;

assign icnt = cnt;
reg sclr;
always @(posedge clk or negedge rst_n)
	if(!rst_n) sclr <= 1'bz;
	else if(state == state_code) sclr <= 1'bz;
	else if(icnt == {1'd0, sclDiv[9:1]}) sclr <= 1'b0;
	else if(icnt == 10'd1) sclr <= 1'bz;
	else ;

assign state = ((!rst_n)||(state == state_code))?cstate:4'bzzzz;
assign scl = sclr;
endmodule