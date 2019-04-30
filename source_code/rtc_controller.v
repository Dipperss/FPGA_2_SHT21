/////////////////////////////////////////////////////////////////////////////
//����Ӳ��ƽ̨�� Xilinx Spartan 6 FPGA
//�����׼��ͺţ� SF-SP6 ��Ȩ����
//��   Ȩ  ��   ���� �������ɡ�����ǳ����תFPGA�����ߡ���Ȩͬѧ��ԭ����
//				����SF-SP6�����׼�ѧϰʹ�ã�лл֧��
//�ٷ��Ա����̣� http://myfpga.taobao.com/
//�����������أ� �ٶ����� http://pan.baidu.com/s/1jGjAhEm
//��                ˾�� �Ϻ�������ӿƼ����޹�˾
/////////////////////////////////////////////////////////////////////////////
//ÿ��10ms��ʱ��ȡRTCоƬ�е�ʱ���֡�������
module rtc_controller(
			input clk,			// ʱ��
			input rst_n,		//�͵�ƽ��λ�ź�
			output reg iicwr_req,	//IICд�����źţ��ߵ�ƽ��Ч
			output reg iicrd_req,	//IIC�������źţ��ߵ�ƽ��Ч
			output reg[7:0] iic_addr,	//IIC��д��ַ�Ĵ���
			output reg[7:0] iic_wrdb,	//IICд�����ݼĴ���
			input[7:0] iic_rddb,	//IIC�������ݼĴ���
			input iic_ack,		//IIC��д�����Ӧ���ߵ�ƽ��Ч	
			output reg[7:0] rtc_hour,	//RTCоƬ������ʱ���ݣ�BCD��ʽ
			output reg[7:0] rtc_mini,	//RTCоƬ�����ķ����ݣ�BCD��ʽ
			output reg[7:0] rtc_secd	//RTCоƬ�����������ݣ�BCD��ʽ
		);

//-------------------------------------------------
//10ms��ʱ��
reg[17:0] cnt;

always @(posedge clk or negedge rst_n) 
	if(!rst_n) cnt <= 18'd0;
	else if(cnt < 18'd249_999) cnt <= cnt+1'b1;
	else cnt <= 18'd0;

wire timer1_10ms = (cnt == 18'd49_999);		//10ms��ʱ��־λ���ߵ�ƽ��Чһ��ʱ������
wire timer2_10ms = (cnt == 18'd149_999);	//10ms��ʱ��־λ���ߵ�ƽ��Чһ��ʱ������
wire timer3_10ms = (cnt == 18'd249_999);	//10ms��ʱ��־λ���ߵ�ƽ��Чһ��ʱ������

//-------------------------------------------------
//��ȡRTC�Ĵ���״̬��
parameter 	RIDLE = 4'd0,	//����״̬
			RRDSE = 4'd1,	//����Ĵ���
			RWASE = 4'd2,	//�ȴ�
			RRDMI = 4'd3,	//���ּĴ���
			RWAMI = 4'd4,	//�ȴ�
			RRDHO = 4'd5;	//��ʱ�Ĵ���		

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
	
	//IIC��д���������ź����
always @(posedge clk or negedge rst_n) 
	if(!rst_n) begin
		iicwr_req <= 1'b0;	//IICд�����źţ��ߵ�ƽ��Ч
		iicrd_req <= 1'b0;	//IIC�������źţ��ߵ�ƽ��Ч
		iic_addr <= 8'h0;	//IIC��д��ַ�Ĵ���
		iic_wrdb <= 8'd0;	//IICд�����ݼĴ���		
	end
	else begin
		case(cstate)
			RRDSE: begin
				iicwr_req <= 1'b0;	//IICд�����źţ��ߵ�ƽ��Ч
				iicrd_req <= 1'b1;	//IIC�������źţ��ߵ�ƽ��Ч
				iic_addr <= 8'he3;	//IIC��д��ַ�Ĵ���
				iic_wrdb <= 8'd0;	//IICд�����ݼĴ���					
			end
			RRDMI: begin
				iicwr_req <= 1'b0;	//IICд�����źţ��ߵ�ƽ��Ч
				iicrd_req <= 1'b1;	//IIC�������źţ��ߵ�ƽ��Ч
				iic_addr <= 8'he3;	//IIC��д��ַ�Ĵ���
				iic_wrdb <= 8'd0;	//IICд�����ݼĴ���					
			end
			RRDHO: begin
				iicwr_req <= 1'b0;	//IICд�����źţ��ߵ�ƽ��Ч
				iicrd_req <= 1'b1;	//IIC�������źţ��ߵ�ƽ��Ч
				iic_addr <= 8'he3;	//IIC��д��ַ�Ĵ���
				iic_wrdb <= 8'd0;	//IICд�����ݼĴ���					
			end
			default: begin
				iicwr_req <= 1'b0;	//IICд�����źţ��ߵ�ƽ��Ч
				iicrd_req <= 1'b0;	//IIC�������źţ��ߵ�ƽ��Ч
				iic_addr <= 8'he3;	//IIC��д��ַ�Ĵ���
				iic_wrdb <= 8'd0;	//IICд�����ݼĴ���		
			end
		endcase
	end
	
	//��ȡIIC�Ĵ�������
always @(posedge clk or negedge rst_n) 
	if(!rst_n) begin
		rtc_hour <= 8'd0;	//RTCоƬ������ʱ���ݣ�BCD��ʽ
		rtc_mini <= 8'd0;	//RTCоƬ�����ķ����ݣ�BCD��ʽ
		rtc_secd <= 8'd0;	//RTCоƬ�����������ݣ�BCD��ʽ
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

