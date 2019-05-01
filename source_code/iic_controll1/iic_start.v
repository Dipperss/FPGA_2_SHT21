module iic_start(
			input clk,			// 100M时钟
			input rst_n,		//低电平复位信号
            input en,		//启动信号
			input scl_hc,     //scl high center
            input scl_lc,
			input scl_ls,	//scl low start
            inout sda,
            inout[3:0] state,
            input[3:0] state_code
		);

reg sdar;
reg sdalink;
reg[3:0] cstate;
always @(posedge clk or negedge rst_n)
    if(!rst_n || en) begin
        sdar <= 1'b1;
		sdalink <= 1'b1;	//output   
        cstate <= state_code; 
    end
    else if(state == state_code)begin   
        if(scl_hc) begin
            sdar <= 1'b0;	
        end
        else if(scl_ls) begin
            cstate <= cstate + 1'b1;
        end
        else if(scl_lc) begin
            sdar <= 1'b1;	
            sdalink <= 1'b1;
        end
        else ;    		
	end

assign state = (state == state_code)?cstate:4'bzzzz;
assign sda = (state == state_code && sdalink) ? sdar : 1'bz;
endmodule