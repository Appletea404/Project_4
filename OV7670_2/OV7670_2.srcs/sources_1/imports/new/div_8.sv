`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/24/2026 09:41:28 PM
// Design Name: 
// Module Name: div_8
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module div_8( my_vga_if.div8 mi0);
    
    logic [2:0] sig_cnt;
    //8분주.
    always@(posedge mi0.uartclk or negedge mi0.rstn)begin
        if(!mi0.rstn)begin
            sig_cnt <= 0;
            mi0.div_8 <= 0;
        end
        else begin
            if(mi0.en_div)begin
                if(sig_cnt == 7) begin
                    sig_cnt <= 0;
                    mi0.div_8 <= 1;//AI,펄스로 줘서 관리하기 쉽게.
                end else begin
                    mi0.div_8 <= 0;
                    sig_cnt <= sig_cnt + 1;
                end
            end//en_div
        end//else
    end
    
endmodule


//module div_96( my_vga_if.div96 mi0);
    
//    logic [6:0] sig_cnt96;
//    //8분주.
//    always@(posedge mi0.uartclk or negedge mi0.rstn)begin
//        if(!mi0.rstn)begin
//            sig_cnt96 <= 0;
//            mi0.div_96 <= 0;
//        end
//        else begin
//            if(sig_cnt96 == 95) begin
//                sig_cnt96 <= 0;
//                mi0.div_96 <= 1;//AI,펄스로 줘서 관리하기 쉽게.
//            end else begin
//                mi0.div_96 <= 0;
//                sig_cnt96 <= sig_cnt96 + 1;
//            end
//        end
//    end
    
//endmodule
