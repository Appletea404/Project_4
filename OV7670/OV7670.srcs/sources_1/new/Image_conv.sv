`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/29/2026 12:46:07 PM
// Design Name: 
// Module Name: Image_conv
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
    Hs, Vs 
    image_data 8bit -> 12bit convertion
    xxxx rrrr  , gggg bbbb
*/
module Image_conv(my_vga_if.image_cov m);

    logic rgb;
    logic [4:0] red;
    logic [2:0] green;
    logic edge_reg;
    logic p_edge;
    logic [1:0] sync_pclk;
    // 2단 싱크로
    always@(posedge m.pclk , negedge m.rstn)begin
        if(!m.rstn)begin
            sync_pclk <= 0;
        end else begin
            //sync_pclk[0] <= m.uart_done;//m.sccb_master_done
            sync_pclk[0] <= m.sccb_master_done;//m.sccb_master_done
            sync_pclk[1] <= sync_pclk[0];
        end
    end
    
    always@(posedge m.pclk , negedge m.rstn)begin
        if(!m.rstn)begin
            rgb <= 0;
            m.in_dt <= 0;
            m.wt_valid <= 0;
            m.addra <= 0;
            m.finish <= 0;
            m.led_clk2 <= 0;
            edge_reg <= 0;
            p_edge <= 0;
            red <= 0;
            green <= 0;
        end else begin
            edge_reg <= m.Camera_Vs; // 카메라의 Vs는 Active High 평소에 0
            p_edge <= ({edge_reg, m.Camera_Vs} == 2'b01); //rising edge찾기
            
            //case(sync_pclk[1])
            case(m.sccb_master_done)
                0:begin
                    //waiting master_done
                    //m.finish <= 0;//너???
                end
                1:begin
                    //다음 줄 시작전 초기화
                    if(p_edge)begin           
                        rgb <= 0;
                        m.addra <= 0;
                        m.finish <= 1;      // 이미지 한장 완료
                        m.wt_valid <= 0;
                        m.led_clk2 <= 1;
                    end else if( !m.Camera_Vs)begin
                        if(m.Camera_Hs)begin
                             if(rgb)begin
                                rgb <= 0;
                                {red,green} <= {m.image_data[7:4],m.image_data[2:0]};
                                m.wt_valid <= 0;
                            end else begin
                                rgb <= 1;
                                m.in_dt <= {red,green,m.image_data[7],m.image_data[4:1]};
                                m.wt_valid <= 1;
                                m.addra <= m.addra + 1;
                            end
                        end else begin  // Camera_Hs = 0
                            rgb <= 0;
                            m.wt_valid <= 0;
                        end
                    end else begin
                        m.wt_valid <= 0;
                        rgb <= 0;//new
                     end
                end//1
            endcase
        end
    end
    
endmodule


//module Image_conv(my_vga_if.image_cov m);

//    logic rgb;
//    logic [3:0] rgb_bu;
//    logic edge_reg;
//    logic p_edge;
//    always@(posedge m.pclk , negedge m.rstn)begin
//        if(!m.rstn)begin
//            rgb <= 0;
//            m.in_dt <= 0;
//            m.wt_valid <= 0;
//            m.addra <= 0;
//            rgb_bu <= 0;
//            m.finish <= 0;
//            m.led_clk2 <= 0;
//            edge_reg <= 0;
//            p_edge <= 0;
//        end else begin
//            edge_reg <= m.Camera_Vs; // 카메라의 Vs는 Active High 평소에 0
//            p_edge <= ({edge_reg, m.Camera_Vs} == 2'b01); //rising edge찾기
            
//            case(m.sccb_master_done)
//                0:begin
//                    //waiting master_done
//                end
//                1:begin
//                    //다음 줄 시작전 초기화
//                    if(p_edge)begin           
//                        rgb <= 0;
//                        m.addra <= 0;
//                        m.finish <= 1;      // 이미지 한장 완료.여기!!
//                        m.wt_valid <= 0;
//                        m.led_clk2 <= 1;
//                    end else if( !m.Camera_Vs &&m.Camera_Hs)begin
//                        if(!rgb)begin
//                            rgb <= 1;
//                            rgb_bu <= m.image_data[3:0];//xr
//                            m.wt_valid <= 0;
//                        end else begin
//                            rgb <= 0;
//                            m.in_dt <= (rgb_bu << 8) | m.image_data;//gb
//                            m.wt_valid <= 1;
                            
//                            m.addra <= m.addra + 1;
//                        end
                        
//                    end else begin
//                        m.wt_valid <= 0;
//                        rgb <= 0;//new
//                     end
//                end//1
//            endcase
//        end
//    end
    
//endmodule



