module iic_RDack(
			input clk,			// 100M时钟
			input rst_n,
			input en,
			input scl_ls,
			input scl_lc,		
            output reg sdar,
			output reg sdalink,	
            input state,
            input[3:0] state_code,
			output reg next_state_sig//??????
		);

reg bcnt;
always @(posedge clk or negedge rst_n)
	if (!rst_n || en) begin
		bcnt <= 1'b0;
		next_state_sig <= 1'b0;
		sdalink <= 1'b0;
		sdar <= 1'b0;
	end
	else if(state && !next_state_sig) begin
		sdalink <= 1'b1;
		if(scl_lc) begin 
				sdar <= 1'b0;
				bcnt <= 1'b1;
		end
		else if(scl_ls && bcnt == 1'b1)begin
			bcnt <= 1'b0;
			next_state_sig <= 1'b1;
			sdalink <= 1'b0;
			sdar <= 1'b0;
		end
	end
	else ;

endmodule