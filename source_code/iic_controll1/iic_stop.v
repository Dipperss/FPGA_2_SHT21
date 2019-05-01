module iic_stop(
			input clk,			// 100M时钟
			input rst_n,		//低电平复位信号
            input en,
            input scl_hc,
            input scl_ls,
            input scl_lc,
            inout sda,
            inout[3:0] state,
            input[3:0] state_code
);
reg[3:0] cstate;
reg sdar;
reg sdalink;
always @(posedge clk or negedge rst_n)
    if(!rst_n || en) cstate <= state_code;
    else if(state == state_code) begin
        if(scl_lc) begin 
            sdalink <= 1'b1;	//output
            sdar <= 1'b0;
        end
        else if(scl_hc) sdar <= 1'b1;
        else if(scl_ls) cstate <= 4'b0;
        else ;
    end
    else ;

assign state = (state == state_code)?cstate:4'bzzzz;
assign sda = (state == state_code && sdalink)?sdar:1'bz;

endmodule