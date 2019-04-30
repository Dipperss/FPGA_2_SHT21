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
module iic_controller(
			input clk,			// ʱ��
			input rst_n,		//�͵�ƽ��λ�ź�
			input iicwr_req,	//IICд�����źţ��ߵ�ƽ��Ч
			input iicrd_req,	//IIC�������źţ��ߵ�ƽ��Ч
			input[7:0] iic_addr,	//IIC��д��ַ�Ĵ���
			input[7:0] iic_wrdb,	//IICд�����ݼĴ���
			output reg[7:0] iic_rddb,	//IIC�������ݼĴ���
			output iic_ack,		//IIC��д�����Ӧ���ߵ�ƽ��Ч	
			output reg scl,	//��������IICʱ���ź�
			inout sda	//��������IIC�����ź�
		);

//-------------------------------------------------
reg[3:0] dcstate,dnstate;

//IIC����д״̬����
parameter 	DIDLE	= 4'd0,	//idle
			DSTAR	= 4'd1,	//start transfer
			DSABW	= 4'd2,	//slave addr (write cmd)
			D1ACK	= 4'd3,	//ACK1
			DRABW	= 4'd4,	//device addr write
			D2ACK	= 4'd5,	//ACK2
/*wr data*/	DWRDB	= 4'd6,	//write data
			D3ACK	= 4'd7,	//ACK3
/*rd data*/		DRSTA	= 4'd8,	//restart transfer
			DSABR	= 4'd9,	//slave addr (read cmd)
			D4ACK	= 4'd10,//ACK4
			DRDDB	= 4'd11,//read data
			D5ACK	= 4'd12,//ACK5
			DSTOP	= 4'd13;//stop transfer
			
parameter	DEVICE_WRADD	= 8'ha2,	//write device addr 
 			DEVICE_RDADD	= 8'ha3;	//read device addr

//-------------------------------------------------
//IICʱ���ź�scl�����߼�
reg[8:0] icnt;	//��Ƶ�����Ĵ�����25M/47.5K=512

always @(posedge clk or negedge rst_n)
	if(!rst_n) icnt <= 9'd0;
	else icnt <= icnt+1'b1;
	
//assign scl = ~icnt[8] | (dcstate == DIDLE);	//0<=icnt<50ʱscl=1;50<=icnt<100ʱscl=0

always @(posedge clk or negedge rst_n)
	if(!rst_n) scl <= 1'b1;
	else if(dcstate == DIDLE) scl <= 1'b1;
	else scl <= ~icnt[8];

wire scl_hs = (icnt == 9'd1);	//scl high start
wire scl_hc = (icnt == 9'd128);	//scl high center
wire scl_ls = (icnt == 9'd256);	//scl low start
wire scl_lc = (icnt == 9'd384);	//scl low center

//-------------------------------------------------	
	//IIC״̬�������ź�				
reg[2:0] bcnt;	//����λ�Ĵ���,bit0-7	
reg sdar;	//sda������ݼĴ���
reg sdalink;	//sda������ƼĴ���,0--input,1--output
	
	//��ǰ����һ״̬�л�
always @(posedge clk or negedge rst_n)
	if(!rst_n) dnstate <= DIDLE;
	else dnstate <= dcstate;

	//״̬��Ǩ
always @(dnstate or iicwr_req or iicrd_req or scl_hc or bcnt or scl_ls or scl_hs or scl_lc) begin
	case(dnstate) 
		DIDLE: 	if((iicwr_req || iicrd_req) && scl_hs) dcstate <= DSTAR;	//��������дIIC����
				else dcstate <= DIDLE;
		DSTAR:	if(scl_ls) dcstate <= DSABW;
				else dcstate <= DSTAR;
		DSABW:	if(scl_lc && (bcnt == 3'd0)) dcstate <= D1ACK;
				else dcstate <= DSABW;	//slave addr (write cmd)
		D1ACK:	if(scl_ls && (bcnt == 3'd7)) dcstate <= DRABW;	
				else dcstate <= D1ACK;
		DRABW:	if(scl_lc && (bcnt == 3'd0)) dcstate <= D2ACK;
				else dcstate <= DRABW;	//device addr write
		D2ACK:	if(scl_ls && (bcnt == 3'd7) && iicwr_req) dcstate <= DWRDB;	//д����
				else if(scl_ls && (bcnt == 3'd7) && iicrd_req) dcstate <= DRSTA;	//������
				else dcstate <= D2ACK;
/*wr_db*/	DWRDB:	if(scl_lc && (bcnt == 3'd0)) dcstate <= D3ACK;
				else dcstate <= DWRDB;	//write data
		D3ACK:	if(scl_ls && (bcnt == 3'd7)) dcstate <= DSTOP;//DWRDB2;	
				else dcstate <= D3ACK;
/*rd_db*/DRSTA:	if(scl_ls) dcstate <= DSABR;
				else dcstate <= DRSTA;	
		DSABR:	if(scl_lc && (bcnt == 3'd0)) dcstate <= D4ACK;
				else dcstate <= DSABR;	//slave addr (read cmd)
		D4ACK:	if(scl_ls && (bcnt == 3'd7)) dcstate <= DRDDB;
				else dcstate <= D4ACK;
		DRDDB:	if(scl_hc && (bcnt == 3'd7)) dcstate <= D5ACK;
				else dcstate <= DRDDB;	//read data
		D5ACK:	if(scl_ls && (bcnt == 3'd6)) dcstate <= DSTOP;
				else dcstate <= D5ACK;
		DSTOP: 	if(scl_ls) dcstate <= DIDLE;
				else dcstate <= DSTOP;
		default: dcstate <= DIDLE;
		endcase
end

//-------------------------------------------------	
	//����λ�Ĵ�������
always @(posedge clk or negedge rst_n)
	if(!rst_n) bcnt <= 3'd0;
	else begin
		case(dnstate)
			DIDLE: bcnt <= 3'd7;
			DSABW,DRABW,DWRDB,DSABR: if(scl_hs) bcnt <= bcnt-1'b1;
			DRDDB: if(scl_hs) bcnt <= bcnt-1'b1;
			D1ACK,D2ACK,D3ACK: if(scl_lc) bcnt <= 3'd7;
			D4ACK: if(scl_ls) bcnt <= 3'd7;
			D5ACK: if(scl_lc) bcnt <= bcnt-1'b1;
			default: ;
			endcase
	end

//-------------------------------------------------	
	//IIC���������������
always @(posedge clk or negedge rst_n)
	if(!rst_n) begin
			sdar <= 1'b1;
			sdalink <= 1'b1;	//output
			iic_rddb <= 8'd0;
		end
	else begin
		case(dnstate) 
			DIDLE: begin
					sdar <= 1'b1;
					sdalink <= 1'b1;	//output
				end
			DSTAR: begin
					if(scl_hc) sdar <= 1'b0;				
				end
			DSABW: begin
					if(scl_lc) sdar <= DEVICE_WRADD[bcnt];
				end
			D1ACK: begin
					if(scl_lc) begin
							sdar <= 1'b1;
							sdalink <= 1'b0;
						end
				end
			DRABW: begin
					if(scl_lc) begin 
							sdar <= iic_addr[bcnt];
							sdalink <= 1'b1;
						end
				end	
			D2ACK: begin
					if(scl_lc) begin
							sdar <= 1'b1;
							sdalink <= 1'b0;
						end
				end
	/*wr_db*/DWRDB: begin
					if(scl_lc) begin
							sdar <= iic_wrdb[bcnt];
							sdalink <= 1'b1;
						end
				end
			D3ACK: begin
					if(scl_lc) begin
							sdar <= 1'b1;
							sdalink <= 1'b0;
						end
				end
	/*rd_db*/DRSTA:	begin
					if(scl_hc) sdar <= 1'b0;			
					else if(scl_lc) begin
							sdar <= 1'b1;	
							sdalink <= 1'b1;
						end
				end
			DSABR: begin
					if(scl_lc) sdar <= DEVICE_RDADD[bcnt];
				end 	
			D4ACK: begin
					if(scl_lc && (bcnt == 3'd7)) sdalink <= 1'b0;	//input
				end
			DRDDB: begin
					if(scl_hc) iic_rddb[bcnt+1'b1] <= sda;
					sdar <= 1'b1;
				end	
			D5ACK:  begin
					if(scl_lc) begin 
							sdar <= 1'b0;
							sdalink <= 1'b1;
						end
				end
			DSTOP: begin
					if(scl_lc) begin 
						sdalink <= 1'b1;	//output
						sdar <= 1'b0;
					end
					else if(scl_hc) sdar <= 1'b1;
				end
			default: ;
			endcase
	end

assign sda = sdalink ? sdar : 1'bz;

assign iic_ack = (dnstate == DSTOP) && scl_hs;	//IIC��д�����Ӧ���ߵ�ƽ��Ч	
		

endmodule

