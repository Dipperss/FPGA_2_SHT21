/////////////////////////////////////////////////////////////////////////////
//工程硬件平台： Xilinx Spartan 6 FPGA
//开发套件型号： SF-SP6 特权打造
//版   权  申   明： 本例程由《深入浅出玩转FPGA》作者“特权同学”原创，
//				仅供SF-SP6开发套件学习使用，谢谢支持
//官方淘宝店铺： http://myfpga.taobao.com/
//最新资料下载： 百度网盘 http://pan.baidu.com/s/1jGjAhEm
//公                司： 上海或与电子科技有限公司
/////////////////////////////////////////////////////////////////////////////
//8bit IIC读和写控制器
module rtc_top(
			input clk,			// 时钟
			input rst_n,		//低电平复位信号
			output rtc_iic_sck,	//RTC芯片的IIC时钟信号
			inout rtc_iic_sda,	//RTC芯片的IIC数据信号
			output[7:0] rtc_hour,	//RTC芯片读出的时数据，BCD格式
			output[7:0] rtc_mini,	//RTC芯片读出的分数据，BCD格式
			output[7:0] rtc_secd	//RTC芯片读出的秒数据，BCD格式			
		);
			
//-------------------------------------------------		
//每隔10ms定时读取RTC芯片中的时、分、秒数据		
wire iicwr_req;	//IIC写请求信号，高电平有效
wire iicrd_req;	//IIC读请求信号，高电平有效
wire[7:0] iic_addr;	//IIC读写地址寄存器
wire[7:0] iic_wrdb;	//IIC写入数据寄存器
wire[7:0] iic_rddb;	//IIC读出数据寄存器
wire iic_ack;		//IIC读写完成响应，高电平有效	
reg  iic_en;

rtc_controller		uut_rtc_controller(
						.clk(clk), 
						.rst_n(rst_n), 
						.iicwr_req(iicwr_req), 
						.iicrd_req(iicrd_req), 
						.iic_addr(iic_addr), 
						.iic_wrdb(iic_wrdb), 
						.iic_rddb(iic_rddb), 
						.iic_ack(iic_ack), 
						.rtc_hour(rtc_hour),	//RTC芯片读出的时数据，BCD格式
						.rtc_mini(rtc_mini),	//RTC芯片读出的分数据，BCD格式
						.rtc_secd(rtc_secd)	//RTC芯片读出的秒数据，BCD格式
					);		
					
		
		
//-------------------------------------------------
//IIC读写时序控制逻辑

iic_controller 			uut_iic_controller (
							.clk(clk), 
							.rst_n(rst_n), 
							.en(iic_en),
							// .iicwr_req(iicwr_req), 
							// .iicrd_req(iicrd_req), 
							.iic_addr(iic_addr), 
							.iic_wrdb(iic_wrdb), 
							.iic_rddb(iic_rddb), 
							.iic_ack(iic_ack), 
							.scl(rtc_iic_sck), 
							.sda(rtc_iic_sda)
						);				


initial
begin
// Initialize Inputs
    
    //master
    iic_en = 1'b0;
    
// Wait 100 ns for global reset to finish

    #10000
	iic_en = 1'b1;

	#10000
    iic_en = 1'b0;
end
endmodule

