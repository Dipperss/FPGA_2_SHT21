module iic_stop(
			input clk,			// 100M时钟
			input rst_n,		//低电平复位信号
            input en,
            input scl_hc,
            input scl_ls,
            input scl_lc,
            output reg sdar,
            output reg sdalink,
            input[2:0] nack,
            input state,
            input[3:0] state_code,
            output reg next_state_sig,//??????
            output reg stp//stp信号
);

reg bcnt;
always @(posedge clk or negedge rst_n)
    if(!rst_n || en) begin
        bcnt <= 1'b0;
        next_state_sig <= 1'b1; 
        stp <= 1'b0;
        sdalink <= 1'b0;
        sdar <= 1'b0;
    end
    else if(((state && next_state_sig)||(nack[0] | nack[1] | nack[2])) && !stp) begin
        if(scl_lc) begin 
            sdalink <= 1'b1;	//output
            sdar <= 1'b0;
        end
        else if(scl_hc && bcnt == 1'b0)begin
			sdar <= 1'b1;
            bcnt <= 1'b1;
		end
        else if(scl_ls && bcnt == 1'b1) begin
            bcnt <= 1'b0;
            next_state_sig <= 1'b1;
            sdalink <= 1'b0;
            sdar <= 1'b0;
            stp <= 1'b1;
		end
        
        else ;
    end
    else ;


endmodule