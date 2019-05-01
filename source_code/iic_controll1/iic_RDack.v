module iic_RDack(
			input clk,			// 100M时钟
			input rst_n,
			input en,
			input scl_ls,
			input scl_lc,		
            inout sda,	
            inout[3:0] state,
            input[3:0] state_code
		);
reg[3:0] cstate;
reg sdar;
reg sdalink;
reg bcnt;
always @(posedge clk or negedge rst_n)
	if (!rst_n || en) begin
		bcnt <= 1'b0;
		cstate <= state_code;
	end
	else if(state == state_code) begin
		if(scl_lc) begin 
				sdar <= 1'b0;
				sdalink <= 1'b1;
				bcnt <= 1'b1;
		end
		else if(scl_ls && bcnt == 1'b1)begin
			cstate <= cstate + 1'b1;
			bcnt <= 1'b0;
		end
	end
	else ;

assign state = (state == state_code)?cstate:4'bzzzz;
assign sda = (state == state_code && sdalink)?sdar:1'bz;

endmodule