//��ȡRTCоƬ�еķ֡������ݣ���ʾ���������
module sp6(
			input ext_clk_25m,	//�ⲿ����25MHzʱ���ź�
			input ext_rst_n,	//�ⲿ���븴λ�źţ��͵�ƽ��Ч
			output[3:0] dtube_cs_n,	//7�������λѡ�ź�
			output[7:0] dtube_data,	//7������ܶ�ѡ�źţ�����С����Ϊ8�Σ�
			inout rtc_iic_sck,	//RTCоƬ��IICʱ���ź�
			inout rtc_iic_sda,	//RTCоƬ��IIC�����ź�
			output uart_tx	// UART���������ź�			
		);													

//-------------------------------------
//PLL����
wire clk_12m5;	//PLL���12.5MHzʱ��
wire clk_25m;	//PLL���25MHzʱ��
wire clk_50m;	//PLL���50MHzʱ��
wire clk_100m;	//PLL���100MHzʱ��
wire sys_rst_n;	//PLL�����locked�źţ���ΪFPGA�ڲ��ĸ�λ�źţ��͵�ƽ��λ���ߵ�ƽ��������
wire iic_ack;		//IIC��д�����Ӧ���ߵ�ƽ��Ч
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

//����������
parameter	DEVICE_WRADD	= 8'h80,	//write device addr 
 			DEVICE_RDADD	= 8'h81,	//read device addr
			DEVICE_SDCMT  = 8'he3,
			DEVICE_SDCMH  = 8'he5;

wire timer_1s_en;
wire[7:0] DEVICE_SDCMD;
//ʱ��ģ�飬ÿ��1s����һ�������źţ�����iic��ȡ���ݣ��Լ���ʪ�ȵ���ģ��
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
//iicͨ��ģ�����ڲ����¶�
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
wire bps_start;	//���յ����ݺ󣬲�����ʱ�������ź���λ
wire clk_bps;	// clk_bps_r�ߵ�ƽΪ��������λ���м������,ͬʱҲ��Ϊ�������ݵ����ݸı�� 
//UART�����źŲ���������													
speed_setting		speed_tx(	
							.clk(clk_25m),	//������ѡ��ģ��
							.rst_n(sys_rst_n),
							.bps_start(bps_start),
							.clk_bps(clk_bps)
						);
						
//UART�����¶ȸ߰�λ����
my_uart_tx			tem_uart_txms(		
							.clk(clk_25m),	//��������ģ��
							.rst_n(sys_rst_n),
							.rx_data(iic_rdms),
							.rx_int(!iic_ack),
							.uart_tx(uart_tx),
							.tx_en(tx_enms),
							.clk_bps(clk_bps),
							.bps_start(bps_start)
						);

//UART�����¶ȵͰ�λ����
my_uart_tx			tem_uart_txls(		
							.clk(clk_25m),	//��������ģ��
							.rst_n(sys_rst_n),
							.rx_data(iic_rdls),
							.rx_int(tx_enms),
							.uart_tx(uart_tx),
							.tx_en(tx_enls),
							.clk_bps(clk_bps),
							.bps_start(bps_start)
						);

//���������ʾ����
seg7		uut_seg7(
				.clk(clk_25m),		//ʱ���ź�
				.rst_n(sys_rst_n),	//��λ�źţ��͵�ƽ��Ч
				.display_num({iic_rdms,iic_rdls}),		//LEDָʾ�ƽӿ�	
				.dtube_cs_n(dtube_cs_n),	//7�������λѡ�ź�
				.dtube_data(dtube_data)		//7������ܶ�ѡ�źţ�����С����Ϊ8�Σ�
		);

endmodule

