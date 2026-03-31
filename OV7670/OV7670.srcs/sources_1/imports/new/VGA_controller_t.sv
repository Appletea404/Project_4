//`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////////
//// Company: 
//// Engineer: 
//// 
//// Create Date: 03/24/2026 11:36:11 AM
//// Design Name: 
//// Module Name: VGA_controller_t
//// Project Name: 
//// Target Devices: 
//// Tool Versions: 
//// Description: 
//// 
//// Dependencies: 
//// 
//// Revision:
//// Revision 0.01 - File Created
//// Additional Comments:
//// 
////////////////////////////////////////////////////////////////////////////////////

///*
//    행
//*/
//module VGA_controller_m(my_vga_if.mid mi0 );

//    /*
//        line_done = 1이 되면 row_cnt ++
//        1. Tpw = 2clk
//        2. Tbp = 29clk
//        3. Tdisp = 480clk
//        4. Tfp = 10clk
//        총 521 clk
//    */
//    //reg [9:0] row_cnt;  // 525
   
//    always@(posedge mi0.clk_vga or negedge mi0.rstn)begin
//        if(!mi0.rstn)begin
//            mi0.row_cnt <= 0;
//            mi0.one_done <= 0;
//            mi0.Vsync <= 0;//
//            mi0.led_clk4 <= 0;
//        end
//        else begin
//            /*
//                Vs가 너무 짧은 걸까? 2클럭으로 
//            */
//            if(mi0.row_cnt < 2)begin//line_done안에 있어서.
//                mi0.Vsync <= 0;
//                mi0.led_clk4 <= 0;
//            end else begin
//                mi0.Vsync <= 1;
//                mi0.led_clk4 <= 1;
//            end 
                
//            if(mi0.line_done)begin
            
//                if(mi0.row_cnt > mi0.ROW)begin//524 //// TB >=3===================================================
//                    mi0.one_done <= 1;
//                    mi0.row_cnt <= 0;   
//                end else begin
//                    mi0.one_done <= 0;
//                    mi0.row_cnt <= mi0.row_cnt + 1;
//                end
                                
//            end 
////            else begin//line_done
////                mi0.one_done <= 0;
////            end
//        end//else
//    end
    
//endmodule

////module VGA_controller_t(my_vga_if.top mi0);

////    //일단 이미지 1개 
////endmodule


module VGA_controller_m(my_vga_if.mid mi0 );

    /*
        line_done = 1이 되면 row_cnt ++
        1. Tpw = 2clk
        2. Tbp = 29clk
        3. Tdisp = 480clk
        4. Tfp = 10clk
        총 521 clk
    */
    //reg [9:0] row_cnt;  // 525
   
    always@(posedge mi0.clk_vga or negedge mi0.rstn)begin
        if(!mi0.rstn)begin
            mi0.row_cnt <= 0;
            mi0.one_done <= 0;
            mi0.Vsync <= 0;//
        end
        else begin
            if(mi0.row_cnt < 2)begin//line_done안에 있어서.
                mi0.Vsync <= 0;
            end else begin
                mi0.Vsync <= 1;
            end 
                
            if(mi0.line_done)begin
            
                if(mi0.row_cnt >= (mi0.ROW-1))begin//525 //// TB >=3===================================================
                    mi0.one_done <= 1;
                    mi0.row_cnt <= 0;   
                end else begin
                    mi0.one_done <= 0;
                    mi0.row_cnt <= mi0.row_cnt + 1;
                end
                                
            end 
//            else begin//line_done
//                mi0.one_done <= 0;
//            end
        end//else
    end
    
endmodule