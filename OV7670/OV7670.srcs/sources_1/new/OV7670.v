`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/27/2026 08:29:21 PM
// Design Name: 
// Module Name: OV7670
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

/*
    실제 핀
    OV7670 Controller
    SCL, SDA
    VS,HS
    PCLK,MCLK
    [7:0] D x 2bytes
    
    Date sheet
    SCCB_E
    SIO_C
    SIO_D
    SIO0_OE_M_
    SIO0_OE_S_
*/
module OV7670(my_vga_if.ov mi0);

    /*
        QVGA셋팅, RGB444셋팅
        
        명령단계에서 SIO_C는 10us임
        1000배
        
        동작 24Mhz
    */
    
    always@(posedge mi0.clk , negedge mi0.rstn)begin
        if(!mi0.rstn)begin
            
        end else begin
        end
    end
    
    
endmodule


module clk_10u (my_vga_if.div mi0);

    logic [9:0] clk_10u_cnt;
    
    always@(posedge mi0.clk, negedge mi0.rstn)begin
        if(!mi0.rstn)begin
            
        end else begin
            
        end
endmodule
