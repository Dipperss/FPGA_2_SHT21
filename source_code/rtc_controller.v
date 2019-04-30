/////////////////////////////////////////////////////////////////////////////
//工程硬件平台： Xilinx Spartan 6 FPGA
//开发套件型号： SF-SP6 特权打造
//版   权  申   明： 本例程由《深入浅出玩转FPGA》作者“特权同学”原创，
//				仅供SF-SP6开发套件学习使用，谢谢支持
//官方淘宝店铺： http://myfpga.taobao.com/
//最新资料下载： 百度网盘 http://pan.baidu.com/s/1jGjAhEm
//公                司： 上海或与电子科技有限公司
/////////////////////////////////////////////////////////////////////////////
//每隔10ms定时读取RTC芯片中的时、分、秒数据
module rtc_controller(
			input clk,			// 时钟
			input rst_n,		//低电平复位信号
			output reg iicwr_req,	//IIC写请求信号，高电平有效
			output reg iicrd_req,	//IIC读请求信号，高电平有效
			output reg[7:0] iic_addr,	//IIC读写地址寄存器
			output reg[7:0] iic_wrdb,	//IIC写入数据寄存器
			input[7:0] iic_rddb,	//IIC读出数据寄存器
			input iic_ack,		//IIC读写完成响应，高电平有效	
			output reg[7:0] rtc_hour,	//RTC芯片读出的时数据，BCD格式
			output reg[7:0] rtc_mini,	//RTC芯片读出的分数据，BCD格式
			output reg[7:0] rtc_secd	//RTC芯片读出的秒数据，BCD格式
		);

//-------------------------------------------------
//10ms定时器
reg[17:0] cnt;

always @(posedge clk or negedge rst_n) 
	if(!rst_n) cnt <= 18'd0;
	else if(cnt < 18'd249_999) cnt <= cnt+1'b1;
	else cnt <= 18'd0;

wire timer1_10ms = (cnt == 18'd49_999);		//10ms定时标志位，高电平有效一个时钟周期
wire timer2_10ms = (cnt == 18'd149_999);	//10ms定时标志位，高电平有效一个时钟周期
wire timer3_10ms = (cnt == 18'd249_999);	//10ms定时标志位，高电平有效一个时钟周期

//-------------------------------------------------
//读取RTC寄存器状态机
parameter 	RIDLE = 4'd0,	//空闲状态
			RRDSE = 4'd1,	//读秒寄存器
			RWASE = 4'd2,	//等待
			RRDMI = 4'd3,	//读分寄存器
			RWAMI = 4'd4,	//等待
			RRDHO = 4'd5;	//读时寄存器		

reg[3:0] cstate,nstate;			
			
always @(posedge clk or negedge rst_n) 
	if(!rst_n) cstate <= RIDLE;
	else cstate <= nstate;
			
always @(cstate or timer1_10ms or timer2_10ms or timer3_10ms or iic_ack) begin 
	case(cstate)
		RIDLE: begin
			if(timer1_10ms) nstate <= RRDSE;
			else nstate <= RIDLE;
		end
		RRDSE: begin
			if(iic_ack) nstate <= RWASE;
			else nstate <= RRDSE;		
		end
		RWASE: begin
			if(timer2_10ms) nstate <= RRDMI;
			else nstate <= RWASE;		
		end
		RRDMI: begin
			if(iic_ack) nstate <= RWAMI;
			else nstate <= RRDMI;		
		end
		RWAMI: begin
			if(timer3_10ms) nstate <= RRDHO;
			else nstate <= RWAMI;		
		end
		RRDHO: begin
			if(iic_ack) nstate <= RIDLE;
			else nstate <= RRDHO;		
		end
		default: nstate <= RIDLE;
	endcase
end			
	
	//IIC读写操作控制信号输出
always @(posedge clk or negedge rst_n) 
	if(!rst_n) begin
		iicwr_req <= 1'b0;	//IIC写请求信号，高电平有效
		iicrd_req <= 1'b0;	//IIC读请求信号，高电平有效
		iic_addr <= 8'h0;	//IIC读写地址寄存器
		iic_wrdb <= 8'd0;	//IIC写入数据寄存器		
	end
	else begin
		case(cstate)
			RRDSE: begin
				iicwr_req <= 1'b0;	//IIC写请求信号，高电平有效
				iicrd_req <= 1'b1;	//IIC读请求信号，高电平有效
				iic_addr <= 8'he3;	//IIC读写地址寄存器
				iic_wrdb <= 8'd0;	//IIC写入数据寄存器					
			end
			RRDMI: begin
				iicwr_req <= 1'b0;	//IIC写请求信号，高电平有效
				iicrd_req <= 1'b1;	//IIC读请求信号，高电平有效
				iic_addr <= 8'he3;	//IIC读写地址寄存器
				iic_wrdb <= 8'd0;	//IIC写入数据寄存器					
			end
			RRDHO: begin
				iicwr_req <= 1'b0;	//IIC写请求信号，高电平有效
				iicrd_req <= 1'b1;	//IIC读请求信号，高电平有效
				iic_addr <= 8'he3;	//IIC读写地址寄存器
				iic_wrdb <= 8'd0;	//IIC写入数据寄存器					
			end
			default: begin
				iicwr_req <= 1'b0;	//IIC写请求信号，高电平有效
				iicrd_req <= 1'b0;	//IIC读请求信号，高电平有效
				iic_addr <= 8'he3;	//IIC读写地址寄存器
				iic_wrdb <= 8'd0;	//IIC写入数据寄存器		
			end
		endcase
	end
	
	//读取IIC寄存器数据
always @(posedge clk or negedge rst_n) 
	if(!rst_n) begin
		rtc_hour <= 8'd0;	//RTC芯片读出的时数据，BCD格式
		rtc_mini <= 8'd0;	//RTC芯片读出的分数据，BCD格式
		rtc_secd <= 8'd0;	//RTC芯片读出的秒数据，BCD格式
	end
	else begin
		case(cstate)
			RRDSE: if(iic_ack) rtc_secd <= {1'b0,iic_rddb[6:0]};
					else ;
			RRDMI: if(iic_ack) rtc_mini <= {1'b0,iic_rddb[6:0]};
					else ;
			RRDHO: if(iic_ack) rtc_hour <= {1'b0,iic_rddb[6:0]};
					else ;
		default: ;
		endcase
	end

	
			
endmodule

