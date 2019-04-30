/////////////////////////////////////////////////////////////////////////////
//工程硬件平台： Xilinx Spartan 6 FPGA
//开发套件型号： SF-SP6 特权打造
//版   权  申   明： 本例程由《深入浅出玩转FPGA》作者“特权同学”原创，
//				仅供SF-SP6开发套件学习使用，谢谢支持
//官方淘宝店铺： http://myfpga.taobao.com/
//最新资料下载： 百度网盘 http://pan.baidu.com/s/1jGjAhEm
//公                司： 上海或与电子科技有限公司
/////////////////////////////////////////////////////////////////////////////
//单个LED闪烁
module led_controller(
			input clk,		//时钟信号
			input rst_n,	//复位信号，低电平有效
			output sled		//LED指示灯接口	
		);													
	
parameter CNT_HIGH = 24;	//计数器最高位
//-------------------------------------
reg[(CNT_HIGH-1):0] cnt;		//24位计数器															

	//cnt计数器进行循环计数
always @ (posedge clk or negedge rst_n)									
	if(!rst_n) cnt <= 0;											
	else cnt <= cnt+1'b1;																		

assign sled = cnt[CNT_HIGH-1];			

endmodule
