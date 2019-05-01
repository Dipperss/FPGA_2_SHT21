`timescale  1ns / 1ps
// write and read operation is all for slaver
module iic_slaver_controller(
    input           clk,        // clock: 4MHz
    input           rst_n,      // reset signal, low
    inout           scl,        // scl (input for slaver)
    inout           sda,        // sda
    input     [6:0] addr,       // slaver 7bits address

    input     [15:0] writeData,   // slaver send Data
    output reg      writeOK,    // slaver send ok (slaver get ACK)

    output reg[7:0] readData,   // master send Data
    output reg      readOK,     // master send ok (slaver send ACK)

    output reg      nackError,  // master didn't respond (NACK)
    output reg      occupt      // high when slaver detected own address, low when get stp
);
pullup(scl);
pullup(sda);

reg sdaBuf,sdaCon;
assign sda = sdaCon ? sdaBuf : 1'bz;

/****************************************/
reg[2:0] state;
reg[2:0] ltate;//上一个状态
parameter   SIDL = 3'd0,    // idle
            SADD = 3'd1,    // master send address and read/write bit
            SACK = 3'd2,    // slaver send ACK to confirm address
            SDAM = 3'd3,    // master send data
            SMRM = 3'd4,    // slaver send ack (slaver get data)
            SMRL = 3'd5,
            SACM = 3'd6,    // master send ack (master get data)
            SNAC = 3'd7;    // slaver get nack (master get data failed)

reg rw;                     // read/write bit : 1: master read <- slaver write
                            //                  0: master write <- slaver read

/****************************************/
// bitcnt
reg[2:0] bitcnt;                 // read or write bit counter
always @(negedge rst_n or negedge scl)
    if(!rst_n) bitcnt <= 3'd7;
    else begin
        case(state)
           SDAM,SADD,SMRL,SMRM: bitcnt <= bitcnt - 1'b1;
            default: bitcnt <= 3'd7;
        endcase
    end

/****************************************/
// stt/stp
reg stt;                    // 3/4 period scl
reg stp;                    // 
always @(negedge sda or negedge rst_n or negedge scl)
    if(!rst_n) stt <= 1'b0;
    else if(scl && !sda) stt <= 1'b1;
    else stt <= 1'b0;

always @(posedge sda or negedge rst_n or negedge scl)
    if(!rst_n) stp <= 1'b0;    
    //else if(state == SIDL) stp <= 1'b0;
    else if(scl && sda) stp <= 1'b1;
    else stp <= 1'b0;

/****************************************/
//clk counter 
reg[9:0] clkcntBuf;              // clk counter buffer
reg[9:0] clkcnt;                 // clk counter
always @(negedge rst_n or posedge clk)
    if(!rst_n) clkcntBuf <= 10'd0;
    else if(stt && ltate == SIDL) clkcntBuf <= clkcntBuf + 1'b1;
    else if(state == SNAC) clkcntBuf <= 10'd0;

reg[1:0] scl_reg;
wire scl_n = (scl_reg == 2'b10);
wire scl_w = (clkcnt == clkcntBuf+1'b1);    //靠后点 
wire scl_r = (clkcnt == {clkcntBuf[8:0], 1'b1} + clkcntBuf); //靠后点
always @(negedge rst_n, posedge clk)
    if(!rst_n) scl_reg <= 2'd0;
    else scl_reg <= {scl_reg[0], scl};

always @(negedge rst_n, posedge clk)
    if(!rst_n) clkcnt <= 10'd0;
    else if(scl_n) clkcnt <= 10'd2;
    else if(clkcntBuf > 10'd2) clkcnt <= clkcnt + 1'b1;

/****************************************/
// addr
reg[6:0] addrBuf;           // get address buffer
always @(negedge rst_n, negedge scl) begin
    if(!rst_n) begin
        state <= SIDL;
        occupt <= 1'b0;
        ltate <= SIDL;
    end
    else begin
        case(state)
            SIDL:   if(stt) begin
                        state <= SADD;   
                    end

            SADD:   if(stp) state <= SIDL;
                    else if(bitcnt == 3'd0 && addrBuf === addr) begin
                        state <= SACK;
                        occupt <= 1'b1;
                        ltate <= SADD;
                    end
                    else if(bitcnt == 3'd0) state <= SIDL;
                    else state <= SADD;

            SACK:   if(rw && ltate == SADD) begin
                        state <= SMRM;//slaver send ACK主机读，从机写
                    end
                    else if(!rw && ltate == SADD) state <= SDAM;//主机写命令，从机读命令
                    else if(ltate == SDAM) state <= SIDL;//接收第二个stt信号

            SDAM:   if(bitcnt == 3'd0)  begin//master send command to slaver
                        state <= SACK;
                        ltate <= SDAM;
                    end
                    else state <= SDAM;

            SMRM:   if(bitcnt == 3'd0)  begin//master get data from slaver MSB
                        state <= SACM;
                        ltate <= SMRM;
                    end
                    else state <= SMRM;

            SMRL:   if(bitcnt == 3'd0)  begin//master get data from slaver LSB
                        state <= SACM;
                        ltate <= SMRL;
                    end
                    else state <= SMRL;

            SACM:   if(ltate == SMRM) state <= SMRL;
                    else if(ltate == SMRL) state <= SNAC;//send nack

            SNAC:   if(nackError) state <= SIDL;
                    else state <= SMRM;
            default:;
        endcase
        //     SACK:   if(rw) state <= SDAS;
        //             else state <= SDAM;
        //     SDAM:   if(stp) state <= SIDL;
        //             else if(stt) state <= SADD;
        //             else if(bitcnt == 3'd0)  state <= SACS;
        //     SDAS:   if(stp) state <= SIDL;
        //             else if(bitcnt == 3'd0)  state <= SACM;
        //     SACM:   if(nackError)  state <= SNAC;
        //             else if(stp) state <= SIDL;
        //             else state <= SDAS;
        //     SACS:   state <= SDAM;
        //     SNAC:   if(nackError) state <= SIDL;
        //             else state <= SDAS;
        //     default:;
        // endcase
    end
end

/****************************************/
//sda. writeOK, readOK, occupt, nackError
always @(negedge rst_n, posedge scl_n, posedge scl_w, posedge scl_r) begin
    if(!rst_n) begin
        addrBuf <= 8'h00;
        rw <= 1'b0;

        sdaBuf <= 1'b1;
        sdaCon <= 1'b0; // input sda

        nackError <= 1'b0;
        occupt <= 1'b0;

        readDataBuf <= 8'h00;

        writeOK <= 1'b0;
        readOK <= 1'b0;
    end       
    else begin
        case(state)
            SIDL:   begin
                addrBuf <= 8'h00;
                rw <= 1'b0;

                sdaBuf <= 1'b1;
                sdaCon <= 1'b0; // input sda

                nackError <= 1'b0;
                occupt <= 1'b0;

                readDataBuf <= 8'h00;

                writeOK <= 1'b0;
                readOK <= 1'b0;
            end

            SADD:   begin
                // read
                sdaBuf <= 1'b1;
                sdaCon <= 1'b0; // input sda
                if(scl_r && bitcnt > 3'd0) addrBuf[bitcnt - 1'b1] <= sda;
                if(scl_r && bitcnt == 3'd0) rw <= sda;
                
                writeOK <= 1'b0;
                readOK <= 1'b0;
            end

            SACK:   begin
                // write
                if(scl_w) begin
                    sdaBuf <= 1'b0;
                    sdaCon <= 1'b1; // output sda
                end
                
                
                if(ltate == SDAM) readOK <= 1'b1;
                else begin
                    writeOK <= 1'b0;
                    readOK <= 1'b0;
                end
            end
            
            SDAM:   begin            
                // read
                sdaBuf <= 1'b1;
                sdaCon <= 1'b0; // input sda
                if(scl_r) readDataBuf[bitcnt] <= sda;

                writeOK <= 1'b0;
                readOK <= 1'b0;
            end

                
            SMRM:   begin
                // write
                if(scl_w) begin
                    sdaBuf <= writeDataBuf[bitcnt+8];
                    sdaCon <= 1'b1; // output sda
                end

                writeOK <= 1'b0;
                readOK <= 1'b0;
            end

            SMRL:   begin
                // write
                if(scl_w) begin
                    sdaBuf <= writeDataBuf[bitcnt];
                    sdaCon <= 1'b1; // output sda
                end

                writeOK <= 1'b0;
                readOK <= 1'b0;
            end

            SACM:   begin
                // read
                sdaBuf <= 1'b1;
                sdaCon <= 1'b0; // input sda

                readOK <= 1'b0;
                if(scl_r && stp) writeOK <= 1'b1;
                else if(scl_r && sda) nackError <= 1'b1;
                else writeOK <= 1'b1; 
            end

            SNAC:   begin
                // read
                sdaBuf <= 1'b1;
                sdaCon <= 1'b0; // input sda

                readOK <= 1'b0;
                if(scl_r && stp) begin
                    writeOK <= 1'b1;
                    nackError <= 1'b0;
                end
                else if(scl_r && sda) nackError <= 1'b1;
                else begin
                    writeOK <= 1'b1; 
                    nackError <= 1'b0;
                end
            end
        endcase
    end
end

/****************************************/
//readDataBuf, writeDataBuf update
reg[7:0] readDataBuf;
reg[15:0] writeDataBuf;   
always @(negedge rst_n, posedge readOK) begin
    if(!rst_n) readData <= 8'h00;
    else if(readOK) readData <= readDataBuf;
end

always @(negedge rst_n, posedge writeOK, posedge stt) begin
    if(!rst_n) writeDataBuf <= 16'h00;
    else if(writeOK | stt) writeDataBuf <= writeData;
end


endmodule