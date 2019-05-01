`timescale 1ns / 1ps

module tb_iic_controller;

reg         clk;
reg         rst_n;
wire        scl;
wire        sda;
pullup(scl);
pullup(sda);

reg         soc;
reg[9:0]    sclDiv;
//master
wire[7:0] iic_rdms;
wire[7:0] iic_rdls;
wire iic_ack;
//slaver
reg[15:0]    SwriteData;
wire[7:0]   SreadData;
wire        SwriteOK;
wire        SreadOK;
wire        SnackError;
wire        occupt;

iic_controller 			uut_iic_tem_controller (
							.clk(clk), 
							.rst_n(rst_n), 
							.en(soc),
							.DEVICE_WRADD(8'h80), 
							.DEVICE_RDADD(8'h81), 
							.DEVICE_SDCMD(8'he3),
							.iic_rdms(iic_rdms), 
							.iic_rdls(iic_rdls), 
							.iic_ack(iic_ack), 
							.scl(scl), 
							.sda(sda)
						);

iic_slaver_controller u_iic_slaver_controller(
    .clk(clk),
    .rst_n(rst_n),   
    .addr(7'b1000_000),  

    .scl(scl),    
    .sda(sda),      

    .writeData(SwriteData),  
    .writeOK(SwriteOK),   

    .readData(SreadData),  
    .readOK(SreadOK),   

    .nackError(SnackError), 
    .occupt(occupt)    
);


parameter   clkperiod = 6'd10;

initial
begin
// Initialize Inputs
    rst_n = 1'b0;
    clk = 1'b1;
    
    //master
    sclDiv = 10'd512;
    
    soc = 1'b0;
    //slaver
    SwriteData = 8'h00;

// Wait 100 ns for global reset to finish
	#(clkperiod*sclDiv*2)
	rst_n = 1'b1;
    #(clkperiod*sclDiv*4)
    
    #(clkperiod*sclDiv*3)
    soc = 1'b1;
    #(clkperiod*sclDiv*3)
    
    SwriteData <= 16'hc2;
    #(clkperiod*sclDiv*10)
    
    soc = 1'b0;
    #(clkperiod*sclDiv*20)
    
    // //
    // addr = 7'b101_1001;
    // MwriteData <= 8'ha1;
    
    // #(clkperiod*sclDiv*3)
    // soc = 1'b1;
    // #(clkperiod*sclDiv*3)
    // MwriteData <= 8'ha2;
    // #(clkperiod*sclDiv*20)
    // soc = 1'b0;

    // #(clkperiod*sclDiv*20)
    
    $finish;
end

always #(clkperiod/2) clk <= ~clk;

initial begin
 $dumpfile("controller_test.vcd");
 $dumpvars(0, tb_iic_controller);
end

endmodule