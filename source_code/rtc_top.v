/////////////////////////////////////////////////////////////////////////////
//����Ӳ��ƽ̨�� Xilinx Spartan 6 FPGA
//�����׼��ͺţ� SF-SP6 ��Ȩ����
//��   Ȩ  ��   ���� �������ɡ�����ǳ����תFPGA�����ߡ���Ȩͬѧ��ԭ����
//				����SF-SP6�����׼�ѧϰʹ�ã�лл֧��
//�ٷ��Ա����̣� http://myfpga.taobao.com/
//�����������أ� �ٶ����� http://pan.baidu.com/s/1jGjAhEm
//��                ˾�� �Ϻ�������ӿƼ����޹�˾
/////////////////////////////////////////////////////////////////////////////
//8bit IIC����д������
module rtc_top(
			input clk,			// ʱ��
			input rst_n,		//�͵�ƽ��λ�ź�
			output rtc_iic_sck,	//RTCоƬ��IICʱ���ź�
			inout rtc_iic_sda,	//RTCоƬ��IIC�����ź�
			output[7:0] rtc_hour,	//RTCоƬ������ʱ���ݣ�BCD��ʽ
			output[7:0] rtc_mini,	//RTCоƬ�����ķ����ݣ�BCD��ʽ
			output[7:0] rtc_secd	//RTCоƬ�����������ݣ�BCD��ʽ			
		);
			
//-------------------------------------------------		
//ÿ��10ms��ʱ��ȡRTCоƬ�е�ʱ���֡�������		
wire iicwr_req;	//IICд�����źţ��ߵ�ƽ��Ч
wire iicrd_req;	//IIC�������źţ��ߵ�ƽ��Ч
wire[7:0] iic_addr;	//IIC��д��ַ�Ĵ���
wire[7:0] iic_wrdb;	//IICд�����ݼĴ���
wire[7:0] iic_rddb;	//IIC�������ݼĴ���
wire iic_ack;		//IIC��д�����Ӧ���ߵ�ƽ��Ч	
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
						.rtc_hour(rtc_hour),	//RTCоƬ������ʱ���ݣ�BCD��ʽ
						.rtc_mini(rtc_mini),	//RTCоƬ�����ķ����ݣ�BCD��ʽ
						.rtc_secd(rtc_secd)	//RTCоƬ�����������ݣ�BCD��ʽ
					);		
					
		
		
//-------------------------------------------------
//IIC��дʱ������߼�

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

