/////////////////////////////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////////////////////////////
//8bit IIC读和写控制器
module iic_controller(
			input clk,			// 时钟
			input rst_n,		//低电平复位信号
			input[7:0] DEVICE_WRADD, 
			input[7:0] DEVICE_RDADD, 
			input[7:0] DEVICE_SDCMD, 
			input en,		//启动信号
			output reg[7:0] iic_rdms,	//IIC读出数据高八位寄存器
			output reg[7:0] iic_rdls,	//IIC读出数据低八位寄存器
			output iic_ack,		//IIC读写完成响应，高电平有效	
			inout scl,	//串行配置IIC时钟信号
			inout sda	//串行配置IIC数据信号
		);

//-------------------------------------------------
reg[3:0] dcstate,dnstate;
// wire en_signal;


//IIC读或写状态控制
parameter 	DIDLE	= 4'd0,	//idle
/*wr data*/	DSTAR	= 4'd1,	//start transfer
			DSABW	= 4'd2,	//slave addr (write cmd)
			D1ACK	= 4'd3,	//ACK1
			DRABW	= 4'd4,	//device addr write
			D2ACK	= 4'd5,	//ACK2
/*rd data*/	DRSTA	= 4'd6,	//restart transfer
			DSABR	= 4'd7,	//slave addr (read cmd)
			D3ACK	= 4'd8,//ACK4
			DRDMS	= 4'd9,//read lsb data
			D4ACK	= 4'd10,//ACK5
			DRDLS	= 4'd11,	//write msb data
			D5ACK	= 4'd12,	//ACK3
			DSTOP	= 4'd13;//stop transfer
			




//检测上升沿
//检测主机(soc)上升沿信号——————按键按下沿信号
// reg[1:0] ien;
// wire main_en_pos;
// always @(posedge clk or negedge rst_n)
// 	if(!rst_n) begin//主向应答信号
// 		ien <= 2'b00;
// 	end
// 	else ien <= {ien[0],en};

// assign main_en_pos = ien[0] & ~ien[1];//检测上升沿

reg hold_signal;
//使能信号启动scl的cnt计时器
always @(posedge clk or negedge rst_n)
	if(!rst_n) hold_signal <= 1'd0;
	else if(en) hold_signal <= 1'b1;
	// else if(dcstate == DSTOP && scl_ls) hold_signal <= 1'b0;//重新研究一个时序，在条件语句中，现在这个语句与最后STOP信号冲突
	else if(dcstate == DIDLE) hold_signal <= 1'b0;
	else ;


//-------------------------------------------------
//IIC时钟信号scl产生逻辑
reg[8:0] icnt;	//分频计数寄存器，25M/47.5K=512

always @(posedge clk or negedge rst_n)
	if(!rst_n) icnt <= 9'd0;
	else if(hold_signal) icnt <= icnt + 1'b1;
	else if(!hold_signal) icnt <= 9'd0;
	else ;

reg sclr;
always @(posedge clk or negedge rst_n)
	if(!rst_n) sclr <= 1'bz;
	else if(dcstate == DIDLE) sclr <= 1'bz;
	else if(scl_ls) sclr <= 1'b0;
	// else if(dcstate == DSTOP && scl_ls) sclr <= 1'bz;
	else if(scl_hs) sclr <= 1'bz;
	else ;

assign scl = sclr;

wire scl_hs = (icnt == 9'd1);	//scl high start
wire scl_hsm = (icnt == 9'd64);	//scl high start
wire scl_hc = (icnt == 9'd128);	//scl high center
wire scl_ls = (icnt == 9'd256);	//scl low start
wire scl_lc = (icnt == 9'd384);	//scl low center

//-------------------------------------------------	
	//IIC状态机控制信号				
reg[2:0] bcnt;	//数据位寄存器,bit0-7	
reg sdar;	//sda输出数据寄存器
reg sdalink;	//sda方向控制寄存器,0--input,1--output
	
	//当前和下一状态切换
always @(posedge clk or negedge rst_n)
	if(!rst_n) dnstate <= DIDLE;
	else dnstate <= dcstate;

always @(dnstate or scl_hc or bcnt or scl_ls or scl_hs or scl_lc or en) begin
	case(dnstate) 
		DIDLE: 	if(en) begin
					dcstate <= DSTAR;	//发出读或写IIC请求
				end
				else dcstate <= DIDLE;
		DSTAR:	if(scl_ls) dcstate <= DSABW;
				else dcstate <= DSTAR;
		DSABW:	if(scl_lc && (bcnt == 3'd0)) dcstate <= D1ACK;
				else dcstate <= DSABW;	//slave addr (write cmd)
		D1ACK:	if(scl_ls && (bcnt == 3'd7)) dcstate <= DRABW;	
				else dcstate <= D1ACK;
		DRABW:	if(scl_lc && (bcnt == 3'd0)) dcstate <= D2ACK;
				else dcstate <= DRABW;	//device addr write
		D2ACK:	if(scl_ls && (bcnt == 3'd7)) dcstate <= DRSTA;	//写数据
				// else if(scl_ls && (bcnt == 3'd7) && iicrd_req) dcstate <= DRSTA;	//读数据
				else dcstate <= D2ACK;
		DRSTA:	if(scl_ls) dcstate <= DSABR;
				else dcstate <= DRSTA;	
		DSABR:	if(scl_lc && (bcnt == 3'd0)) dcstate <= D3ACK;
				else dcstate <= DSABR;	//slave addr (read cmd)
		D3ACK:	if(scl_ls && (bcnt == 3'd7)) dcstate <= DRDMS;
				else dcstate <= D3ACK;
		DRDMS:	if(scl_hc && (bcnt == 3'd7) && (scl == 1'b1)) dcstate <= D4ACK;
				else dcstate <= DRDMS;	//read data
		D4ACK:	if(scl_ls && (bcnt == 3'd6)) dcstate <= DRDLS;
				else dcstate <= D4ACK;
		DRDLS:	if(scl_hc && (bcnt == 3'd6) && (scl == 1'b1)) dcstate <= D5ACK;
				else dcstate <= DRDLS;	//read data
		D5ACK:	if(scl_ls && (bcnt == 3'd5)) dcstate <= DSTOP;//DRDLS;	
				else dcstate <= D5ACK;
		DSTOP: 	if(scl_ls) dcstate <= DIDLE;
				else dcstate <= DSTOP;
		default: dcstate <= DIDLE;
		endcase
end

//-------------------------------------------------	
	//数据位寄存器控制
always @(posedge clk or negedge rst_n)
	if(!rst_n) bcnt <= 3'd0;
	else begin
		case(dnstate)
			DIDLE: bcnt <= 3'd7;
			DSABW,DRABW,DSABR: if(scl_hs) bcnt <= bcnt-1'b1;
			DRDMS,DRDLS: begin
					if(scl_hsm && scl == 1'b1) bcnt <= bcnt-1'b1;//
					else ;
				end
			D1ACK,D2ACK: if(scl_lc) bcnt <= 3'd7;
			D3ACK: if(scl_ls) bcnt <= 3'd7;
			D4ACK,D5ACK: if(scl_lc) bcnt <= bcnt-1'b1;
			default: ;
			endcase
	end

//-------------------------------------------------	
	//IIC数据输入输出控制
always @(posedge clk or negedge rst_n)
	if(!rst_n) begin
			sdar <= 1'b1;
			sdalink <= 1'b1;	//output
			iic_rdms <= 8'd0;
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
							sdar <= DEVICE_SDCMD[bcnt];
							sdalink <= 1'b1;
						end
				end	
			D2ACK: begin
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
			D3ACK: begin
					if(scl_lc && (bcnt == 3'd7)) sdalink <= 1'b0;	//input
				end
			DRDMS: begin
					sdar <= 1'bz;
					if(scl_hc && (scl == 1'b1)) iic_rdms[bcnt+1'b1] <= sda;//
				end	
			D4ACK:  begin
					if(scl_lc) begin 
							sdar <= 1'b0;
							sdalink <= 1'b1;
						end
					
				end

			DRDLS: begin
					sdalink <= 1'b0;//修改此处后，开始得到数据
					if(scl_hc && (scl == 1'b1)) iic_rdls[bcnt+2'd2] <= sda;//
					
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

					// else if(scl)
					// 这里想写一个结束信号，用于进行下一次的iic通信
				end
			default: ;
			endcase
	end

assign sda = sdalink ? sdar : 1'bz;

assign iic_ack = (dnstate == DSTOP);	//IIC读写完成响应，高电平有效	
		
endmodule

