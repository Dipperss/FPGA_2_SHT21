module iic_start(
			input clk,			// 100M时钟
			input rst_n,		//低电平复位信号
            input en,		//启动信号
			input scl_hc,     //scl high center
            input scl_lc,
			input scl_ls,	//scl low start
            output reg sdar,
            output reg sdalink,
            input state,
            input[3:0] state_code,
            output reg next_state_sig,//状态保持信号
            input stp
		);

always @(posedge clk or negedge rst_n)
    if(!rst_n || en) begin
        if(state_code == 4'b1)begin
            sdar <= 1'b1;
            sdalink <= 1'b1;	//output  
        end
        else begin
            sdar <= 1'b0;
            sdalink <= 1'b0;	//output
        end
        next_state_sig <= 1'b0;    
    end
    else if(state && !next_state_sig) begin 
        sdalink <= 1'b1;
        if(scl_hc) begin
            sdar <= 1'b0;	
        end
        else if(scl_ls) begin
            next_state_sig <= 1'b1; 
        end
        else if(scl_lc) begin
            sdar <= 1'b1;	
            sdalink <= 1'b1;
        end 		
	end
    
    else if(next_state_sig && scl_lc)begin
            sdar <= 1'b0;	
            sdalink <= 1'b0;

    end

endmodule