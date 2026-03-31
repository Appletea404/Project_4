`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/30/2026 09:24:35 AM
// Design Name: 
// Module Name: OV_from_uart
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


module OV_from_uart(my_vga_if.from_uart mi0);


    typedef enum logic [4:0]
    {
        IDLE1,
        WRITE1,
        READ1,
        COM1,
        PASS,
        FAIL,
        WAIT1
    } STATE_master;
    
    STATE_master st_master;//ov7670.sv
    
    /*
        자동 제어 or 버튼 제어
    */
    logic loop_en;
    logic [4:0] idx;
    logic [18:0] timer;//239980 10ms
    // pclk?? clk????
    always@(posedge mi0.uartclk, negedge mi0.rstn)begin //pclk..
        if(!mi0.rstn)begin
            st_master <= IDLE1;
            mi0.sccb_write_rstn <= 0;
            mi0.sccb_read_rstn <= 0;
            mi0.sccb_write_en <= 0;
            mi0.sccb_read_en <= 0;
             //mi0.sccb_master_done <= 0;
             idx <= 0;
             mi0.led_clk1 <= 0;
             timer <= 0;
        end else begin
            case(st_master)
                IDLE1:begin  
                    //mi0.led <= 4'b0001;
                    mi0.sccb_write_rstn <= 0;
                    mi0.sccb_read_rstn <= 0;
                    if(mi0.uart_valid)begin//======================================================
                        st_master <= WRITE1;
                    end
                end//idle1
                WRITE1:begin
                    //mi0.led <= 4'b0010;
                    mi0.sccb_write_rstn <= 1;
                    mi0.sccb_write_en   <= 1;//동시에 주면 안된다.
                    mi0.ID_address        <= {(8'h21 << 1) | 1'b0}; //Write : 0
                    mi0.Sub_address     <= mi0.uart_command_reg[15:8];
                    mi0.COM7                <= mi0.uart_command_reg[7:0];
                    if(mi0.sccb_write_done) begin
                        st_master <= READ1;
                        mi0.sccb_write_rstn <= 0;
                    end
                end//write1
                READ1:begin
                    mi0.sccb_read_en    <= 1;
                    mi0.sccb_read_rstn  <= 1;
                    mi0.ID_address         <= {(8'h21 << 1) | 1'b1}; //Read : 1
                    if(mi0.sccb_read_done) begin//0B -> 39?
                        mi0.sccb_read_rstn <= 0;
                        //st_master <= COM1;
                        if( {mi0.Sub_address,mi0.COM7} == {8'h12,8'h80})begin
                            st_master <= WAIT1;
                        end else st_master <= COM1;
                     end
                end//read1
                COM1:begin
                    mi0.led_clk1 <= 1;
                    //mi0.sccb_master_done <= 1;
                    st_master <= IDLE1;
                end//com1
                WAIT1:begin//10ms이상 리셋 대기
                    if(timer >= 16'd119435)begin
                        timer <= 0;
                        st_master <= IDLE1;
                    end else timer <= timer + 1;
                end
            endcase
        end
    end
    
endmodule











