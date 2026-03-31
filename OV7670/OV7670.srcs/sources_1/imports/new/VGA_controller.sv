////`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////////
////// Company: 
////// Engineer: 
////// 
////// Create Date: 03/24/2026 09:44:43 AM
////// Design Name: 
////// Module Name: VGA_controller
////// Project Name: 
////// Target Devices: 
////// Tool Versions: 
////// Description: 
////// 
////// Dependencies: 
////// 
////// Revision:
////// Revision 0.01 - File Created
////// Additional Comments:
////// 
//////////////////////////////////////////////////////////////////////////////////////

//////25Mhz받아서 출력.
/////*
////    640*480을 RAM용량이 1.8M이므로 320*240으로 사용한다.
////    중앙정렬 필요
////    열 
////*/
////module VGA_controller_b ( my_vga_if.bot mi0 );

////    /*
////        1. Tpw = 96clock
////        2. Tbp = 48clock
////        3. Tdisp = 640clk
////        4. Tfp = 16clk
////        총 800 clk인 사이클을 만들면 된다
////    */
////    /*
////        행렬의 조건을 모두 충족해야 던짐.
////        col       160 ~ 480 :: sys_cnt
////        row     120 ~ 360 ::  row_cnt
////    */
    
////    logic [1:0] finish_sync;
////    always@(posedge mi0.clk_vga,negedge mi0.rstn)begin
////        if(!mi0.rstn)begin
////            finish_sync <= 0;
////        end else begin
////            finish_sync[0] <= mi0.finish;
////            finish_sync[1] <= finish_sync[0];
////        end
////    end
    
////    logic [9:0] sys_cnt; //1024clk
////    always@(posedge mi0.clk_vga or negedge mi0.rstn)begin
////        if(!mi0.rstn)begin
////            sys_cnt <= 0;
////            mi0.line_done <= 0;
////            mi0.Hsync <= 0;
////             mi0.vgaRed <= 0;
////            mi0.vgaBlue <= 0;
////            mi0.vgaGreen <= 0;
////            mi0.addrb <= 0;//new
////            //mi0.led_data <= 8'h0;
////            mi0.led_clk3 <= 0;
////        end
////        else begin
////            if(mi0.Vsync == 0)begin
////                mi0.addrb <= 0;
////            end
        
////            //if(mi0.finish)begin
////            if(finish_sync[1])begin
////                if(sys_cnt < mi0.Tpw)begin//0~95
////                    sys_cnt <= sys_cnt + 1;
////                    mi0.line_done <= 0;
////                    mi0.Hsync <= 0;
                    
////                end else if(sys_cnt < mi0.Tbp)begin//96 ~ 143
////                    sys_cnt <= sys_cnt + 1;
////                    mi0.Hsync <= 1;
                    
////                end else if(sys_cnt < mi0.Tdisp)begin//Send to Image
////                    sys_cnt <= sys_cnt + 1;
////                    //=========================================
////                    // BRAM의 1클럭 지연이 존재. 40*16 + 명령1클럭 2클럭 늦음.
////                    // 640 * 480 
////                    // 144 ~ 784까지에서 중간을 찾아야 한다.
////                    // 302 624
////                    //=========================================
//////                     if( sys_cnt >= 304 && sys_cnt < 624 )begin
////                     if( (mi0.row_cnt >= 132 && mi0.row_cnt < 372) &&//Real
////                         (sys_cnt >= 304 && sys_cnt < 624) )begin
////                         mi0.led_clk3 <= 1;
////                         mi0.addrb <=mi0.addrb + 1;
//////                        if(mi0.addrb >= 76799) mi0.addrb <= 0;//순환.
//////                        else mi0.addrb <=mi0.addrb + 1;//만약 76799까지 안갔다면?Vsync와 맞춰야 한다.
////                        mi0.rd_ready <= 1; 
                        
//////                        mi0.vgaRed <= mi0.doutb[11:8];// RGB
//////                        mi0.vgaGreen <= mi0.doutb[7:4];//7:4가 가장 쎔...
//////                        mi0.vgaBlue <= mi0.doutb[3:0];
////                        mi0.vgaRed <= 4'hF;// 사용
////                        mi0.vgaGreen <= 4'hF;
////                        mi0.vgaBlue <= 4'hF;
////                    end
////                    else begin
////                        mi0.vgaRed <= 0;
////                        mi0.vgaBlue <= 0;
////                        mi0.vgaGreen <= 0;
////                    end
////                    //=========================================
////                end else if(sys_cnt < mi0.Ts)begin
////                    sys_cnt <= sys_cnt + 1;
////                    mi0.vgaRed <= 0;//r
////                    mi0.vgaBlue <= 0;
////                    mi0.vgaGreen <= 0;
////                    //799에서 바로 0사이클.
////                    if(sys_cnt == (mi0.Ts - 1)) begin
////                        sys_cnt <= 0;
////                        mi0.line_done <= 1;
////                    end
////                end else begin
////                end
////            end//finish
////        end
////    end
    
////endmodule



module VGA_controller_b ( my_vga_if.bot mi0 );

    /*
        1. Tpw = 96clock
        2. Tbp = 48clock
        3. Tdisp = 640clk
        4. Tfp = 16clk
        총 800 clk인 사이클을 만들면 된다
    */
    /*
        행렬의 조건을 모두 충족해야 던짐.
        col       160 ~ 480 :: sys_cnt
        row     120 ~ 360 ::  row_cnt
    */
    
    logic [9:0] sys_cnt; //1024clk
    logic Vsync_p_edge;
    logic Vsync_ff;
    always@(posedge mi0.clk_vga or negedge mi0.rstn)begin
        if(!mi0.rstn)begin
            sys_cnt <= 0;
            mi0.line_done <= 0;
            mi0.Hsync <= 0;
             mi0.vgaRed <= 0;
            mi0.vgaBlue <= 0;
            mi0.vgaGreen <= 0;
            mi0.addrb <= 0;//new
            Vsync_p_edge <= 0;
            Vsync_ff <= 0;
        end
        else begin
            Vsync_ff <= mi0.Vsync;
            Vsync_p_edge <= ({Vsync_ff,mi0.Vsync} == 2'b01);
            
            //if(mi0.Vsync == 0)begin
            if(Vsync_p_edge)begin
                mi0.addrb <= 0;
                sys_cnt <= 0;//new
                mi0.line_done <= 0;//new
            end
        
            if(mi0.finish)begin
                if(sys_cnt < mi0.Tpw)begin//0~95
                    sys_cnt <= sys_cnt + 1;
                    mi0.line_done <= 0;
                    mi0.Hsync <= 0;
                    
                end else if(sys_cnt < mi0.Tbp)begin//96 ~ 143
                    sys_cnt <= sys_cnt + 1;
                    mi0.Hsync <= 1;
                    
                end else if(sys_cnt < mi0.Tdisp)begin//Send to Image
                    sys_cnt <= sys_cnt + 1;
                    //=========================================
                    // BRAM의 1클럭 지연이 존재. 40*16 + 명령1클럭 2클럭 늦음.
                    // 640 * 480 
                    // 144 ~ 784까지에서 중간을 찾아야 한다.
                    // 302 624
                    //=========================================
//                    if( (mi0.row_cnt >= 1 && mi0.row_cnt < 3) && //TB용
//                         (sys_cnt >= 302 && sys_cnt < 624) )begin
                     if( (mi0.row_cnt >= 132 && mi0.row_cnt < 372) &&//Real 132 372
                         (sys_cnt >= 304 && sys_cnt < 624) )begin
                         mi0.addrb <=mi0.addrb + 1;
//                        if(mi0.addrb >= 76799) mi0.addrb <= 0;//순환.
//                        else mi0.addrb <=mi0.addrb + 1;//만약 76799까지 안갔다면?Vsync와 맞춰야 한다.
                        mi0.rd_ready <= 1; 
                        
                        mi0.vgaRed <= mi0.doutb[11:8];// RGB
                        mi0.vgaGreen <= mi0.doutb[7:4];
                        mi0.vgaBlue <= mi0.doutb[3:0];
//                        mi0.vgaRed <= mi0.vgaRed + 1;// 사용
//                        mi0.vgaBlue <= mi0.vgaBlue + 1;
//                        mi0.vgaGreen <= mi0.vgaGreen+1;
//                    end
                    end
                    else begin
                        mi0.vgaRed <= 0;
                        mi0.vgaBlue <= 0;
                        mi0.vgaGreen <= 0;
                    end
                    //=========================================
                end else if(sys_cnt < mi0.Ts)begin
                    sys_cnt <= sys_cnt + 1;
                    mi0.vgaRed <= 0;//r
                    mi0.vgaBlue <= 0;
                    mi0.vgaGreen <= 0;
                    //799에서 바로 0사이클.
                    if(sys_cnt == (mi0.Ts - 1)) begin
                        sys_cnt <= 0;
                        mi0.line_done <= 1;
                    end
                end else begin
                end
            end//finish
        end
    end
    
endmodule




