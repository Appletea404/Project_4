`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/24/2026 07:19:38 PM
// Design Name: 
// Module Name: UART_controller
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

typedef enum logic [2:0]
{
    IDLE,
    START,
    BUSY,
    STOP
} st_t;

/*
     modport uart  ( input clk,rstn,RsRx, output vgaRed,vgaBlue,vgaGreen,RsTx);
*/
module UART_controller(my_vga_if.uart mi0);

    /*
        100Mhz/(115.2khz*16) = 54.25번으로 오버샘플링.
        안정한 구간의 데이터를 받기
        
        mi0.uartclk은 14.7453으로 115.2khz의 16*8배 샘플링임.
        mi0.div_8이 8분주
        
        UART IDLE 1-> 0이면 데이터 시작 마지막 1로 올리면 끝
    */    

    st_t state;
    logic [7:0] buff0;
    logic [3:0] buff0_cnt;
    logic [3:0] sig_tick;
    logic cal_valid;
    logic [1:0] command_cnt;

    always@(posedge mi0.uartclk or negedge mi0.rstn)begin
        if(!mi0.rstn)begin
            state <= IDLE;
            buff0_cnt <= 0;
            sig_tick <= 0;
            //mi0.wt_valid <= 0;//new
            cal_valid <= 0;
            command_cnt <= 0;
        end else begin
        
            case(state)
                IDLE:begin
                    //mi0.wt_valid <= 0;
                    if(mi0.RsRx == 0) begin
                        sig_tick <= 0;
                        mi0.en_div <= 1;
                        state <= START;//0이되고 div_8은 1로 맞춰서 이동
                    end
                end//idle
                
                START:begin//데이터의 중앙 셋팅 
                    if(mi0.div_8)begin
                        if(sig_tick == 7 && mi0.RsRx == 0)begin
                            sig_tick <= 0;
                            state <= BUSY;
                        end else begin
                            sig_tick <= sig_tick + 1;
                        end
                    end
                end//start
                
                BUSY:begin//한번하고 16번. 이걸 8번 하면 하나 끝
                    if(mi0.div_8)begin
                        if(sig_tick == 15)begin//타이밍 정렬
                            sig_tick <= 0;
                            buff0[buff0_cnt] <= mi0.RsRx;
                            if(buff0_cnt == 7) begin //누적 8개 했으면 초기화.
                                state <= STOP;
                                buff0_cnt <= 0;
                                cal_valid <= 1;
                                if(command_cnt >= 2) command_cnt <= 0;
                                else command_cnt <= command_cnt + 1;
                            end
                            else buff0_cnt <= buff0_cnt + 1;
                        end else begin
                            sig_tick <= sig_tick + 1;
                        end
                    end
                end//busy
                STOP:begin //STOP bit
                    //mi0.wt_valid <= 0;//new
                    cal_valid <= 0;
                    if(mi0.div_8)begin
                        if(sig_tick == 15 && mi0.RsRx == 1)begin
                            sig_tick <= 0;
                            state <= IDLE;
                        end else sig_tick <= sig_tick + 1;
                    end
                end//stop
            endcase
        end
    end
    
    /*
        2진수로 던져야 한다..
        Sub_address와 DATA를 한번에 받아야 한다.
        mi0.uart_valid와 mi0.uart_command_reg [15:0]을 적절히 전달
        
        uart는 11520클럭임!
    */
    always@(posedge mi0.uartclk or negedge mi0.rstn)begin
        if(!mi0.rstn)begin
            mi0.uart_command_reg <= 0;
            mi0.uart_valid <= 0;
            mi0.uart_done <= 0;
        end else if(cal_valid) begin
            // CA들어오면 명령 종료
            if(mi0.uart_command_reg[7:0] == 8'hCA || mi0.uart_command_reg[15:8] == 8'hCA)begin
                mi0.uart_done <= 1;
            end
            case(command_cnt)
                0:begin
                    mi0.uart_command_reg[7:0] <= buff0;
                    mi0.uart_valid <= 0;
                end
                1:begin
                    mi0.uart_command_reg[15:8] <= buff0;
                    mi0.uart_valid <= 1;
                end
            endcase
            
        end else mi0.uart_valid <= 0;
    end
    
endmodule














