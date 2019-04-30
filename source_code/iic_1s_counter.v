/////////////////////////////////////////////////////////////////////////////
//����Ӳ��ƽ̨�� Xilinx Spartan 6 FPGA
//�����׼��ͺţ� SF-SP6 ��Ȩ����
//��   Ȩ  ��   ���� �������ɡ�����ǳ����תFPGA�����ߡ���Ȩͬѧ��ԭ����
//				����SF-SP6�����׼�ѧϰʹ�ã�лл֧��
//�ٷ��Ա����̣� http://myfpga.taobao.com/
//�����������أ� �ٶ����� http://pan.baidu.com/s/1jGjAhEm
//��                ˾�� �Ϻ�������ӿƼ����޹�˾
/////////////////////////////////////////////////////////////////////////////
module iic_1s_counter(
			input clk,		//ʱ���źţ�25MHz
			input rst_n,	//��λ�źţ��͵�ƽ��Ч
			input[7:0] DEVICE_SDCMT,
			input[7:0] DEVICE_SDCMH,
			output[7:0] DEVICE_SDCMD,
			output timer_1s_en	//�������ʾ���ݣ�[15:12]--�����ǧλ��[11:8]--����ܰ�λ��[7:4]--�����ʮλ��[3:0]--����ܸ�λ
		);

//-------------------------------------------------
//1s��ʱ�����߼�
reg[24:0] timer_cnt;	//1s��������0-24999999

	//1s��ʱ����
always @(posedge clk or negedge rst_n)
	if(!rst_n) timer_cnt <= 25'd0;
	else if(timer_cnt < 25'd24_999_999) timer_cnt <= timer_cnt+1'b1;
	else timer_cnt <= 25'd0;

assign timer_1s_en = (timer_cnt == 25'd24_999_999);		//1s��ʱ����־λ������Чһ��ʱ������

// //-------------------------------------------------
// //�������ݲ����߼�

// 	//��ʾ����ÿ�����
reg opt_num;
always @(posedge clk or negedge rst_n)
	if(!rst_n) opt_num <= 1'd0;
	else if(timer_cnt == 25'd12_499_999) opt_num <= opt_num+1'b1;

// always @(posedge clk or negedge rst_n)
// 	if(!rst_n) DEVICE_SDCMD <= DEVICE_SDCMT;
// 	else if(opt_num) DEVICE_SDCMD <= DEVICE_SDCMH;
// 	else if(!opt_num)DEVICE_SDCMD <= DEVICE_SDCMT;
assign DEVICE_SDCMD = opt_num?DEVICE_SDCMH:DEVICE_SDCMT;
endmodule

