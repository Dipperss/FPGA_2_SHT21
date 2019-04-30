`timescale 1ns / 1ps
module temperature_compute(
				input clk,
				input rst_n,
				input com_sig,//1为计算温度，0为计算湿度
				input[15:0] readData,//温度数据
				output[15:0] displaydata
    );

reg[12:0]  sub_data;//加数
reg[14:0]  mul_data;//乘数

always @(posedge clk)
	if(com_sig) begin
			sub_data = 13'd4685;//温度加数 *100
			mul_data = 15'd17572;//温度乘数 *100	
	end
	else
	begin
			sub_data = 10'd600;//湿度加数，为便于计算和显示，将其乘以100
			mul_data = 14'd12500;//湿度乘数，*100
	end

//-------------------------------------------------
//温度换算
//value = a + b*c/d = a + W / d
parameter  div_num = 17'h10000;

// wire[15:0] suber_out = (mul_data*readData/div_num)-sub_data;
wire[31:0] mul_out;	//输出的乘法运算结果，取bit23-8为有效的16bit数据



mul 	uut_mul (
		  .clk(clk), // input clk
		  .a(readData), // input [15 : 0] a
		  .b(mul_data), // input [15 : 0] b
		  .p(mul_out) // output [31 : 0] p
		);


wire[31:0] div_out; 
div		W_div(
			.clk(clk),
			.rfd(),//output rfd
			.dividend(mul_out),// input [31 : 0] dividend
			.divisor(17'h10000),// input [17 : 0] divisor
			.quotient(div_out),// output [31 : 0] quotient
			.fractional()// output [15 : 0] fractional
);

wire[16:0] suber_out;
sub 	uut_sub (
		  .a(div_out), // input [15 : 0] a
  		.b(div_out), // input [15 : 0] b
          .clk(clk), // input clk
          .ce(ce), // input ce
         .s(suber_out) // output [15 : 0] s
);

//千位运算
wire[15:0] thousand_quotient,thousand_fractional; //千位除法运算结果与余数寄存器
div		thousand_div(
			.clk(clk),
			.rfd(),//output rfd
			.dividend(suber_out),// input [15 : 0] dividend
			.divisor(16'd1000),// input [15 : 0] divisor
			.quotient(thousand_quotient),// output [15 : 0] quotient
			.fractional(thousand_fractional)// output [15 : 0] fractional
);

wire[15:0] hundred_quotient,hundred_fractional; //千位除法运算结果与余数寄存器

//百位运算
div		hundred_div(
			.clk(clk),
			.rfd(),//output rfd 
			.dividend(thousand_fractional),// input [15 : 0] dividend
			.divisor(16'd100),// input [15 : 0] divisor
			.quotient(hundred_quotient),// output [15 : 0] quotient
			.fractional(hundred_fractional)// output [15 : 0] fractional
);

wire[15:0] ten_quotient,ten_fractional; //千位除法运echi算结果与余数寄存器

//十位运算
div		ten_div(
			.clk(clk),
			.rfd(),//output rfd
			.dividend(hundred_fractional),// input [15 : 0] dividend
			.divisor(16'd10),// input [15 : 0] divisor
			.quotient(ten_quotient),// output [15 : 0] quotient
			.fractional(ten_fractional)// output [15 : 0] fractional
);
assign displaydata = {thousand_quotient[3:0],hundred_quotient[3:0],ten_quotient[3:0],ten_fractional[3:0]};
endmodule
