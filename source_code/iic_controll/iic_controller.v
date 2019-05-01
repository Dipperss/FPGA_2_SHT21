//8bit IIC读和写控制器
// 带"***"的需要在编写其他IIC通信时，根据自己需要作出改变
module iic_controller(
			input clk,			// 时钟
			input rst_n,		//低电平复位信号
			input[9:0] sclDiv,     //分频数字，分频后的的频率=clk频率/分频数字，注意分频后的iic频率应该在100kHZ~400kHZ之间
			input[7:0] DEVICE_WRADD, 
			input[7:0] DEVICE_RDADD, 
			input[7:0] DEVICE_SDCMD, 
			input en,		//启动信号
			output[7:0] iic_rdms,	//IIC读出数据高八位寄存器
			output[7:0] iic_rdls,	//IIC读出数据低八位寄存器
			output iic_ack,		//IIC读写完成响应，高电平有效	
			inout scl,	//串行配置IIC时钟信号
			inout sda	//串行配置IIC数据信号
		);	


//***IIC读或写状态控制这个是为SHT21编写的状态机，在写其他的IIC时，需要修改
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

wire[7:0] sdar;
wire[12:0] sdalink;
wire[13:0] state_sig;//***根据状态数量设计位数
wire[2:0] nack;//***根据WRack数量设计位数
//iic的scl时钟生成模块
wire[9:0] icnt;	//分频计数寄存器，100M/512=195.31k

wire stp;	
iic_scl uut_iic_scl(//IDLE模块//其中还有状态转换模块
			.clk(clk), 
			.rst_n(rst_n),
			.sclDiv(sclDiv),  
			.en(en),
			.scl(scl), 
			.state(state_sig[DIDLE]), 
			.state_code(DIDLE),
			.next_state_sig(state_sig[DIDLE+1]),
			.icnt(icnt),
			// .up_en(up_en),
			.stp(stp)//stop模块结束	
);

//scl各部分的使能信号
wire scl_hs = (icnt == 10'd1);	//scl high start
wire scl_hsm = (icnt == {3'd0, sclDiv[9:3]});	//scl high start
wire scl_hc = (icnt == {2'd0, sclDiv[9:2]});	//scl high center
wire scl_ls = (icnt == {1'd0, sclDiv[9:1]});	//scl low start
wire scl_lc = (icnt == {1'd0, sclDiv[9:1]}+{2'd0, sclDiv[9:2]});	//scl low center

//产生开始信号模块
iic_start uut_iic_start(
			.clk(clk), 
			.rst_n(rst_n),
			.en(en),
			.scl_hc(scl_hc),  
			.scl_ls(scl_ls),
			.scl_lc(scl_lc),
			.sdar(sdar[0]),//***根据sdar出现次序确定序号
			.sdalink(sdalink[DSTAR-1]),//***根据sdalink出现次序确定序号
			.state(state_sig[DSTAR]),//***当前状态启动信号
			.state_code(DSTAR),//设置当前模块状态码,
			.next_state_sig(state_sig[DSTAR+1]),//***下一状态启动信号
			.stp(stp)//stop模块结束	
);

//向从机发送地址模块和写指令模块
iic_write8 uut_iic_sdaddw ( 
			.clk(clk), 
			.rst_n(rst_n),
			.en(en), 
			.scl_hs(scl_hs), 
			.scl_ls(scl_ls),
			.scl_lc(scl_lc),
			.sdar(sdar[1]),
			.sdalink(sdalink[DSABW-1]),
			.state(state_sig[DSABW]),
			.DEVICE_WRITE8(DEVICE_WRADD), 
			.state_code(DSABW),
			.next_state_sig(state_sig[DSABW+1])//当前状态位-1
);

//ACK1,发送地址后的ACK信号
iic_WRack uut_iic_add_w_ack(
			.clk(clk), 
			.rst_n(rst_n),
			.en(en), 
			.scl_hc(scl_hc),  
			.scl_ls(scl_ls),
			.scl_lc(scl_lc),
			.sda(sda),
			.sdalink(sdalink[D1ACK-1]),
			.state(state_sig[D1ACK]),
			.state_code(D1ACK),
			.nack(nack[0]),
			.next_state_sig(state_sig[D1ACK+1])//当前状态位-1
);

//向从机发送命令模块
iic_write8 uut_iic_sd_cmd(
			.clk(clk), 
			.rst_n(rst_n),
			.en(en), 
			.scl_hs(scl_hs), 
			.scl_ls(scl_ls), 
			.scl_lc(scl_lc),
			.sdar(sdar[2]),
			.sdalink(sdalink[DRABW-1]),
			.state(state_sig[DRABW]),
			.DEVICE_WRITE8(DEVICE_SDCMD), 
			.state_code(DRABW),
			.next_state_sig(state_sig[DRABW+1])//当前状态位-1
);

//ACK2,向从机发送命令后发送ack
iic_WRack uut_iic_sd_cmd_ack(
			.clk(clk), 
			.rst_n(rst_n),
			.en(en), 
			.scl_hc(scl_hc),  
			.scl_ls(scl_ls),
			.scl_lc(scl_lc),
			.sda(sda),
			.sdalink(sdalink[D2ACK-1]),
			.state(state_sig[D2ACK]),
			.state_code(D2ACK),
			.nack(nack[1]),//***根据WRack模块次序编写nack序号
			.next_state_sig(state_sig[D2ACK+1])//当前状态位-1
);

//restart模块
iic_start uut_iic_restart(
			.clk(clk), 
			.rst_n(rst_n),
			.en(en),
			.scl_hc(scl_hc),  
			.scl_ls(scl_ls),
			.scl_lc(scl_lc),
			.sdar(sdar[3]),
			.sdalink(sdalink[DRSTA-1]),
			.state(state_sig[DRSTA]),
			.state_code(DRSTA),//设置状态码,似曾相识的状态机
			.next_state_sig(state_sig[DRSTA+1])//当前状态位-1
);

//向从机发送地址模块和读指令模块
iic_write8 uut_iic_sdaddr(
			.clk(clk), 
			.rst_n(rst_n),
			.en(en), 
			.scl_hs(scl_hs), 
			.scl_ls(scl_ls), 
			.scl_lc(scl_lc),
			.sdar(sdar[4]),
			.sdalink(sdalink[DSABR-1]),
			.state(state_sig[DSABR]),
			.DEVICE_WRITE8(DEVICE_RDADD), 
			.state_code(DSABR),
			.next_state_sig(state_sig[DSABR+1])//当前状态位-1
);

//ACK3,发送地址后和读指令的ACK信号
iic_WRack uut_iic_add_r_ack(
			.clk(clk), 
			.rst_n(rst_n),
			.en(en), 
			.scl_hc(scl_hc),  
			.scl_ls(scl_ls),
			.scl_lc(scl_lc),
			.sda(sda),
			.sdalink(sdalink[D3ACK-1]),
			.state(state_sig[D3ACK]),
			.state_code(D3ACK),
			.nack(nack[2]),
			.next_state_sig(state_sig[D3ACK+1])//当前状态位-1
);

//读从机数据模块
//读从机发过来的高八位

iic_read8 uut_iic_readMSB(
			.clk(clk), 
			.rst_n(rst_n),
			.en(en), 
			.scl_hsm(scl_hsm),  
			.scl_hc(scl_hc),
			.scl(scl),
			.sda(sda),
			.sdalink(sdalink[DRDMS-1]),
			.state(state_sig[DRDMS]),
			.state_code(DRDMS),
			.DEVICE_READ8(iic_rdms),
			.next_state_sig(state_sig[DRDMS+1])//当前状态位-1
);

//ACK4,读取高八位数据后的ack
iic_RDack uut_iic_rd_msb_ack(
			.clk(clk), 
			.rst_n(rst_n),
			.en(en), 
			.scl_ls(scl_ls),
			.scl_lc(scl_lc),
			.sdar(sdar[5]),
			.sdalink(sdalink[D4ACK-1]),
			.state(state_sig[D4ACK]),
			.state_code(D4ACK),
			.next_state_sig(state_sig[D4ACK+1])//当前状态位-1
);

//读从机发过来的低八位
iic_read8 uut_iic_readLSB(
			.clk(clk), 
			.rst_n(rst_n),
			.en(en), 
			.scl_hsm(scl_hsm),  
			.scl_hc(scl_hc),
			.scl(scl),
			.sda(sda),
			.sdalink(sdalink[DRDLS-1]),
			.state(state_sig[DRDLS]),
			.state_code(DRDLS),
			.DEVICE_READ8(iic_rdls),
			.next_state_sig(state_sig[DRDLS+1])//当前状态位-1
);

//ACK5,读取低八位数据后的ack
iic_RDack uut_iic_rd_lsb_ack(
			.clk(clk), 
			.rst_n(rst_n),
			.en(en), 
			.scl_ls(scl_ls),
			.scl_lc(scl_lc),
			.sdar(sdar[6]),
			.sdalink(sdalink[D5ACK-1]),
			.state(state_sig[D5ACK]),
			.state_code(D5ACK),
			.next_state_sig(state_sig[D5ACK+1])//当前状态位-1
);

//停止模块
iic_stop uut_iic_stop(
			.clk(clk), 
			.rst_n(rst_n),
			.en(en),
			.scl_hc(scl_hc), 
			.scl_ls(scl_ls),
			.scl_lc(scl_lc),
			.sdar(sdar[7]),
			.sdalink(sdalink[DSTOP-1]),
			.nack(nack),//检测到nack信号，激活stp
			.state(state_sig[DSTOP]),
			.state_code(DSTOP),
			.next_state_sig(state_sig[DIDLE]),//当前状态位-1
			.stp(stp)
);
//某一个状态sdalink初始时为0，写数据时为1，写完后再变为0，
assign sda = (sdalink[DSTAR-1]|sdalink[DSABW-1]|sdalink[D1ACK-1]|sdalink[DRABW-1]|sdalink[D2ACK-1]|sdalink[DRSTA-1]|sdalink[DSABR-1]|sdalink[D3ACK-1]|sdalink[DRDMS-1]|sdalink[D4ACK-1]|sdalink[DRDLS-1]|sdalink[D5ACK-1]|sdalink[DSTOP-1])?(sdar[0]|sdar[1]|sdar[2]|sdar[3]|sdar[4]|sdar[5]|sdar[6]|sdar[7]):1'bz;

assign iic_ack = (state_sig[DSTOP]&&!stp);	//IIC读写完成响应，高电平有效	
		
endmodule
																																					