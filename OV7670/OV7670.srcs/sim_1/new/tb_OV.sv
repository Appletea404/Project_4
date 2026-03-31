`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/28/2026 02:57:01 PM
// Design Name: 
// Module Name: tb_OV
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


module tb_OV;

    logic wclk,rstn;//input
    logic SIO_C;//input
    logic MCLK;//input
    logic PCLK,Hs,Vs;//input
    logic one_shot_top;//input
    logic [7:0] image_data;//output
    logic led_clk1,led_clk2,led_clk3;//output
    logic [7:0] led_data;//output
    wire SIO_D;//때로는 입력이면서 때로는 출력이고..때로는 z이다.
    logic SIO_D_come_out;
    logic SIO_D_come_in;
    //assign SIO_D = (SIO_C) ? SIO_D_come_out : 1'bz ;
    assign SIO_D = 1'bz ;
    assign SIO_D_come_in = SIO_D;
    
    OV_VGA dfs
    (
         .wclk(wclk),
         .rstn(rstn),
        //OV7670
         .SIO_C(SIO_C),
         .SIO_D(SIO_D),
         .MCLK(MCLK),
         .PCLK(PCLK),
         .Camera_Hs(Hs),
         .Camera_Vs(Vs),
         .image_data(image_data),
        
        //test_set
         .one_shot_top(one_shot_top),
         .led_clk1(led_clk1),
         .led_clk2(led_clk2),
         .led_clk3(led_clk3)
    );
    
    always #20 wclk = ~wclk;
    assign MCLK = wclk;
    
    
    initial begin
        wclk = 0;
        rstn = 0;
        
        #100 rstn = 1;
        one_shot_top = 1;
        
        SIO_D_come_in = 1;
        #4_300_000;
        $finish;
    end

endmodule
