/////////////////////////////////////////////////////////////////////////////
//����Ӳ��ƽ̨�� Xilinx Spartan 6 FPGA
//�����׼��ͺţ� SF-SP6 ��Ȩ����
//��   Ȩ  ��   ���� �������ɡ�����ǳ����תFPGA�����ߡ���Ȩͬѧ��ԭ����
//				����SF-SP6�����׼�ѧϰʹ�ã�лл֧��
//�ٷ��Ա����̣� http://myfpga.taobao.com/
//�����������أ� �ٶ����� http://pan.baidu.com/s/1jGjAhEm
//��                ˾�� �Ϻ�������ӿƼ����޹�˾
/////////////////////////////////////////////////////////////////////////////
//����LED��˸
module led_controller(
			input clk,		//ʱ���ź�
			input rst_n,	//��λ�źţ��͵�ƽ��Ч
			output sled		//LEDָʾ�ƽӿ�	
		);													
	
parameter CNT_HIGH = 24;	//���������λ
//-------------------------------------
reg[(CNT_HIGH-1):0] cnt;		//24λ������															

	//cnt����������ѭ������
always @ (posedge clk or negedge rst_n)									
	if(!rst_n) cnt <= 0;											
	else cnt <= cnt+1'b1;																		

assign sled = cnt[CNT_HIGH-1];			

endmodule
