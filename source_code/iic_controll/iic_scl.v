module iic_scl(
			input clk,			// 100M时钟
			input rst_n,		//低电平复位信号
			input[9:0] sclDiv,     //分频数字，分频后的的频率=clk频率/分频数字，注意分频后的iic频率应该在100kHZ~400kHZ之间
			input en,		//启动信号
            inout scl,	//串行配置IIC时钟信号
			input[12:0] state_sig,//每出现这样的信号的下降沿，状态向前切换
            input state,
			input stop_code,
			input[3:0] state_code,
			output reg next_state_sig,
            output[9:0] icnt,//分频时钟
			// output up_en//en的上升沿信号
			input stp
		);

// //检测上升沿
// reg[1:0] ien;
// always @(posedge clk or negedge rst_n)
// 	if(!rst_n) begin//主向应答信号
// 		ien <= 2'b00;
// 	end
// 	else if(state && !next_state_sig) begin
// 		ien <= {ien[0],en};
// 	end
// 	else ;

// assign up_en = ien[0] & ~ien[1];//检测

reg hold_signal;
//使能信号启动scl的cnt计时器//state信号变换
always @(posedge clk or negedge rst_n)
	if(!rst_n || stp) begin 
		hold_signal <= 1'd0;
		next_state_sig 	<= 1'b0;
	end
	else if(state && !next_state_sig) begin 
		if(en) begin
			hold_signal <= 1'b1;
			next_state_sig <= 1'b1;
		end
		else begin
			hold_signal <= 1'b0;
			next_state_sig <= 1'b0;
		end

	end
	

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
	else if(state && !next_state_sig) sclr <= 1'bz;
	else if(icnt == {1'd0, sclDiv[9:1]}) sclr <= 1'b0;
	else if(icnt == 10'd1) sclr <= 1'bz;
	else ;

assign scl = sclr;
endmodule