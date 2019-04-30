//读取RTC芯片中的分、秒数据，显示到数码管上
module sp6(
			input ext_clk_25m,	//外部输入25MHz时钟信号
			input ext_rst_n,	//外部输入复位信号，低电平有效
			output[3:0] dtube_cs_n,	//7段数码管位选信号
			output[7:0] dtube_data,	//7段数码管段选信号（包括小数点为8段）
			inout rtc_iic_sck,	//RTC芯片的IIC时钟信号
			inout rtc_iic_sda,	//RTC芯片的IIC数据信号
			output uart_tx	// UART发送数据信号			
		);													

//-------------------------------------
//PLL例化
wire clk_12m5;	//PLL输出12.5MHz时钟
wire clk_25m;	//PLL输出25MHz时钟
wire clk_50m;	//PLL输出50MHz时钟
wire clk_100m;	//PLL输出100MHz时钟
wire sys_rst_n;	//PLL输出的locked信号，作为FPGA内部的复位信号，低电平复位，高电平正常工作
wire iic_ack;		//IIC读写完成响应，高电平有效
wire tx_enms;
wire tx_enls;
reg iic_en;

pll_controller uut_pll_controller(// Clock in ports
    .CLK_IN1(ext_clk_25m),      // IN
    // Clock out ports
    .CLK_OUT1(clk_12m5),     // OUT
    .CLK_OUT2(clk_25m),     // OUT
    .CLK_OUT3(clk_50m),     // OUT
    .CLK_OUT4(clk_100m),     // OUT
    // Status and control signals
    .RESET(~ext_rst_n),// IN
    .LOCKED(sys_rst_n));      // OUT	

//参数的设置
parameter	DEVICE_WRADD	= 8'h80,	//write device addr 
 			DEVICE_RDADD	= 8'h81,	//read device addr
			DEVICE_SDCMT  = 8'he3,
			DEVICE_SDCMH  = 8'he5;

wire timer_1s_en;
wire[7:0] DEVICE_SDCMD;
//时钟模块，每隔1s发出一个脉冲信号，启动iic读取数据，以及温湿度调度模块
iic_1s_counter			uut_iic_1s_counter(
							.clk(clk_25m), 
							.rst_n(sys_rst_n),
							.timer_1s_en(timer_1s_en),
							.DEVICE_SDCMT(DEVICE_SDCMT),
							.DEVICE_SDCMH(DEVICE_SDCMH),
							.DEVICE_SDCMD(DEVICE_SDCMD)
);




wire[7:0] iic_rdms;
wire[7:0] iic_rdls;
//iic通信模块用于测量温度
iic_controller 			uut_iic_tem_controller (
							.clk(clk_100m), 
							.rst_n(sys_rst_n), 
							.en(timer_1s_en),
							.DEVICE_WRADD(DEVICE_WRADD), 
							.DEVICE_RDADD(DEVICE_RDADD), 
							.DEVICE_SDCMD(DEVICE_SDCMD), 
							.iic_rdms(iic_rdms), 
							.iic_rdls(iic_rdls), 
							.iic_ack(iic_ack), 
							.scl(rtc_iic_sck), 
							.sda(rtc_iic_sda)
						);	

//-------------------------------------
wire bps_start;	//接收到数据后，波特率时钟启动信号置位
wire clk_bps;	// clk_bps_r高电平为接收数据位的中间采样点,同时也作为发送数据的数据改变点 
//UART发送信号波特率设置													
speed_setting		speed_tx(	
							.clk(clk_25m),	//波特率选择模块
							.rst_n(sys_rst_n),
							.bps_start(bps_start),
							.clk_bps(clk_bps)
						);
						
//UART发送温度高八位数据
my_uart_tx			tem_uart_txms(		
							.clk(clk_25m),	//发送数据模块
							.rst_n(sys_rst_n),
							.rx_data(iic_rdms),
							.rx_int(!iic_ack),
							.uart_tx(uart_tx),
							.tx_en(tx_enms),
							.clk_bps(clk_bps),
							.bps_start(bps_start)
						);

//UART发送温度低八位数据
my_uart_tx			tem_uart_txls(		
							.clk(clk_25m),	//发送数据模块
							.rst_n(sys_rst_n),
							.rx_data(iic_rdls),
							.rx_int(tx_enms),
							.uart_tx(uart_tx),
							.tx_en(tx_enls),
							.clk_bps(clk_bps),
							.bps_start(bps_start)
						);

//段数码管显示控制
seg7		uut_seg7(
				.clk(clk_25m),		//时钟信号
				.rst_n(sys_rst_n),	//复位信号，低电平有效
				.display_num({iic_rdms,iic_rdls}),		//LED指示灯接口	
				.dtube_cs_n(dtube_cs_n),	//7段数码管位选信号
				.dtube_data(dtube_data)		//7段数码管段选信号（包括小数点为8段）
		);

endmodule

