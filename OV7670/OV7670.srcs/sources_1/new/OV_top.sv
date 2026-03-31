`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/28/2026 09:47:53 AM
// Design Name: 
// Module Name: OV_top
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



module OV_top(my_vga_if.sccb_top mi0);

    typedef enum logic [4:0]
    {
        IDLE1,
        WRITE1,
        READ1,
        COM1,
        PASS,
        FAIL,
        WAIT1
    } STATE_top;
    STATE_top st_top;//ov7670.sv
    
    /*
        자동 제어 or 버튼 제어
    */
    //logic one_shot_top;
    logic [8:0] wait_tick;
    always@(posedge mi0.clk, negedge mi0.rstn)begin
        if(!mi0.rstn)begin
            st_top <= IDLE1;
            //one_shot_top <= 0;
            mi0.sccb_write_rstn <= 0;
            mi0.sccb_read_rstn <= 0;
            mi0.sccb_write_en <= 0;
            mi0.sccb_read_en <= 0;
             mi0.led_clk1 <= 0;
             mi0.led_clk2 <= 0;
             mi0.led_data <= 0;
             wait_tick <= 0;
            //mi0.led <= 0;
        end else begin
            case(st_top)
                IDLE1:begin  
                    //mi0.led <= 4'b0001;
                    mi0.sccb_write_rstn <= 0;
                    mi0.sccb_read_rstn <= 0;
                    if(mi0.one_shot_top_in)begin//======================================================
                        st_top <= WRITE1;
                    end
                end
                WRITE1:begin
                    //mi0.led <= 4'b0010;
                    mi0.sccb_write_rstn <= 1;
                    mi0.sccb_write_en   <= 1;//동시에 주면 안된다.
                    mi0.ID_address        <= {(8'h21 << 1) | 1'b0}; //Write : 0
                    mi0.Sub_address     <= 8'h12;//COM7 register address, 0A:
                    mi0.COM7                <= 8'h14;//QVGA, RGB set
                    if(mi0.sccb_write_done) begin
                        st_top <= READ1;
                        //st_top <= READ1;
                        mi0.sccb_write_rstn <= 0;
                    end
                end//write1
//                WAIT1:begin
//                    if(wait_tick >=49)begin//20us
//                        wait_tick <= 0;
//                        st_top <= READ1;
//                    end else wait_tick <= wait_tick + 1;
//                end
                READ1:begin
                    //mi0.led <= 4'b0100;
                    mi0.sccb_read_en    <= 1;
                    mi0.sccb_read_rstn  <= 1;
                    mi0.ID_address         <= {(8'h21 << 1) | 1'b1}; //Read : 1
                    if(mi0.sccb_read_done) begin//0B -> 39?
                        st_top <= COM1;
                        mi0.sccb_read_rstn <= 0;
                     end
                end//read1
                COM1:begin
                    if(mi0.read_data == mi0.COM7)begin
                        st_top <= PASS;
                    end else begin
                        st_top <= FAIL;
                    end
                end
                PASS:begin
                    mi0.led_data <= mi0.read_data;
                    mi0.led_clk1 <= 1;
                end
                FAIL:begin
                    mi0.led_data <= mi0.read_data;
                    mi0.led_clk2 <= 1;
                end
            endcase
        end
    end
    

    
endmodule







