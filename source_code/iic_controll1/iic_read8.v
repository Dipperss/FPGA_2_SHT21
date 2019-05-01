module iic_read8(
			input clk,			// 100M时钟
			input rst_n,		//低电平复位信号
            input en,
            input scl_hsm,
            input scl_hc,
            input scl,
            input sda,
            inout[3:0] state,
            input[3:0] state_code,
            output reg[7:0] DEVICE_READ8
		);


reg[3:0] cstate;
reg sdar;
reg sdalink;
reg[2:0] bcnt;	//数据位寄存器,bit0-7
always @(posedge clk or negedge rst_n)
	if(!rst_n || en) begin
        bcnt <= 3'd7;
        cstate <= state_code;
    end
    else if(state == state_code) begin
        if(scl_hsm && scl == 1'b1) bcnt <= bcnt-1'b1;
        else if(scl_hc  && (scl == 1'b1)) begin
                 DEVICE_READ8[bcnt+1'b1] <= sda;
                 if (bcnt == 3'd7) begin
                     cstate <= cstate + 1'b1;
                 end      
        end
    else ;
    end

assign state = (state == state_code)?cstate:4'bzzzz;
assign sda = (state == state_code) ? 1'bz : 1'bz;            
endmodule

    