`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/24/2026 09:44:43 AM
// Design Name: 
// Module Name: VGA_controller
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


module VGA_controller_b ( my_vga_if.bot mi0 );

    logic [1:0] finish_sync;
    always@(posedge mi0.clk_vga,negedge mi0.rstn)begin
        if(!mi0.rstn)begin
            finish_sync <= 0;
        end else begin
            finish_sync[0] <= mi0.finish;
            finish_sync[1] <= finish_sync[0];
        end
    end
    
    /*
        Image_conv에서 온 room_ff의 CDC문제를 해결
    */
    logic [1:0] room_ff;
    always@(posedge mi0.clk_vga or negedge mi0.rstn)begin
        if(!mi0.rstn)begin
            room_ff <= 0;
        end
        else begin
            room_ff[0] <= mi0.room_chk;
            room_ff[1] <= room_ff[0];
        end
    end
    
    /*
        Vsync, Hsync
        Vsync는 2클럭동안 0 이며 주기는 clk_vga 800클럭이다.
        Hsync는 Vsync가 0에서 시작하여 96클럭부터 500클럭까지 
    */
    logic [9:0] Vsync_cnt;
    logic [9:0] Hsync_cnt;
    always@(posedge mi0.clk_vga or negedge mi0.rstn)begin
        if(!mi0.rstn)begin
            Vsync_cnt <= 0;
            Hsync_cnt <= 0;
        end
        else begin
            if(Hsync_cnt == 799)begin
                Hsync_cnt <= 0;
                
                if(Vsync_cnt == 524)begin
                    Vsync_cnt <= 0;
                end else Vsync_cnt <= Vsync_cnt + 1;
                
            end else begin
                Hsync_cnt <= Hsync_cnt + 1;
            end
            
        end
    end
    
    /*
        실제 Hsync,Vsync Assignment
        1    2 변할때 데이터 즉시 대입 필요.
        95 96
    */
    always@(posedge mi0.clk_vga or negedge mi0.rstn)begin
        if(!mi0.rstn)begin
            mi0.Hsync <= 1;//default 1
            mi0.Vsync <= 1;
        end
        else begin
            mi0.Vsync <= (Vsync_cnt < 2) ? 0 : 1; //2
            mi0.Hsync <= (Hsync_cnt < 96) ? 0 : 1; //96
        end
    end
    
    /*
        room_chk(room_ff[1])를 활용하여 일부분만 있기
        addrb
        초기화 할 때 addrb를 어떻게 초기화 할것인가.
        
    */
    //assign offset <= (room_ff[1]==0) ? 72000 : 0;
    logic rot;
    always@(posedge mi0.clk_vga or negedge mi0.rstn)begin
        if(!mi0.rstn)begin
            mi0.addrb <= 0;
            rot <= 0;
        end
        else begin
        
            if(Vsync_cnt == 0)begin  
                //mi0.addrb <= (room_ff[1]==0) ? 0 : 72000;
                mi0.addrb <= (room_ff[1]==0) ? 72000 : 0;
            end else begin
            /*
                640*480
                320*24
            */
            // 162 ~ 386 :: 31 ~ 511 303 623
//            if((Vsync_cnt >= 162) && (Vsync_cnt < 386) &&
//                    (Hsync_cnt >= 303) && (Hsync_cnt < 623))begin
                    
//                    //지금3단이다. 위.아래,X,위,아래,x..
//                    //                            위, 아래,아래  위 아래 아래 ...
//                    mi0.addrb <= mi0.addrb + 1;
////                    if(!room_ff[1]) mi0.addrb <= (mi0.addrb < 143999) ? mi0.addrb + 1 : 72000;
////                    else mi0.addrb <= (mi0.addrb < 71999) ? mi0.addrb + 1 : 0;
//                end
//            end
                if((Vsync_cnt >= 31) && (Vsync_cnt < 511) &&
                    (Hsync_cnt >= 304) && (Hsync_cnt < 624))begin
                    
                    //지금3단이다. 위.아래,X,위,아래,x..
                    //                            위, 아래,아래  위 아래 아래 ...
                    mi0.addrb <= mi0.addrb + 1;
//                    if(!room_ff[1]) mi0.addrb <= (mi0.addrb < 143999) ? mi0.addrb + 1 : 72000;
//                    else mi0.addrb <= (mi0.addrb < 71999) ? mi0.addrb + 1 : 0;
                end
            end
            /*
            수평
                144 ~ 784 default  
                304 ~ 624
                BRAM +1 clock
                303 ~ 623
            수직
                31 ~ 511
                162 ~ 386
                ver.2
                31 ~ 271
                272 ~ 511
            */
            //304 624, 162 386
//                if((Hsync_cnt >= 304 && Hsync_cnt < 624) &&
//                    (Vsync_cnt >= 162 && Vsync_cnt < 386) )begin
//                    mi0.vgaRed     <= mi0.doutb[11:8];
//                    mi0.vgaGreen <= mi0.doutb[7:4];
//                    mi0.vgaBlue    <= mi0.doutb[3:0];
//                end
//                else begin
//                    mi0.vgaRed     <= 0;
//                    mi0.vgaGreen <= 0;
//                    mi0.vgaBlue    <= 0;
//                end
                /*
                    0번방 쓰고 있으면 1번방 출력. !
                    1번방 쓰고 있으면 0번방 출력. x 271 ~ 511
                    &&
                    (mi0.addrb <= 71999)
                    00 0x 11 01 ..
                    
                    1번 사진을 내려서 0번사진이 좀더 잘나오게 쓰레기값 제거.
                */
                 if((Hsync_cnt >= 304 && Hsync_cnt < 624) &&
                    (Vsync_cnt >= 31 && Vsync_cnt < 271) )begin
                    mi0.vgaRed     <= mi0.doutb[11:8];
                    mi0.vgaGreen <= mi0.doutb[7:4];
                    mi0.vgaBlue    <= mi0.doutb[3:0];
                end
                else if((Hsync_cnt >= 304 && Hsync_cnt < 624) && //거의 다썻을때
                            (Vsync_cnt >= 271 && Vsync_cnt < 511) )begin
                    mi0.vgaRed     <= mi0.doutb[11:8];
                    mi0.vgaGreen <= mi0.doutb[7:4];
                    mi0.vgaBlue    <= mi0.doutb[3:0];
                end 
                else begin
                    mi0.vgaRed     <= 0;
                    mi0.vgaGreen <= 0;
                    mi0.vgaBlue    <= 0;
                end

        end
    end
    
endmodule



//`timescale 1ns / 1ps

//module VGA_controller_b ( my_vga_if.bot mi0 );

//    // =========================================================
//    // 1. Double Buffering 동기화 (CDC: Clock Domain Crossing)
//    // pclk에서 넘어온 room_chk를 clk_vga 영역으로 안전하게 가져옴
//    // =========================================================
//    logic [1:0] room_chk_ff;
//    always_ff @(posedge mi0.clk_vga or negedge mi0.rstn) begin
//        if(!mi0.rstn) begin
//            room_chk_ff <= 0;
//        end else begin
//            room_chk_ff[0] <= mi0.room_chk;
//            room_chk_ff[1] <= room_chk_ff[0];
//        end
//    end

//    // =========================================================
//    // 2. 표준 VGA 640x480 @ 60Hz 카운터 (Total: 800 x 525)
//    // 모니터 동기화를 위해 카메라 상태와 무관하게 무한 반복됨
//    // =========================================================
//    logic [9:0] h_cnt; 
//    logic [9:0] v_cnt;

//    always_ff @(posedge mi0.clk_vga or negedge mi0.rstn) begin
//        if(!mi0.rstn) begin
//            h_cnt <= 0;
//            v_cnt <= 0;
//        end else begin
//            if (h_cnt == 799) begin
//                h_cnt <= 0;
//                if (v_cnt == 524) v_cnt <= 0;
//                else              v_cnt <= v_cnt + 1;
//            end else begin
//                h_cnt <= h_cnt + 1;
//            end
//        end
//    end

//    // =========================================================
//    // 3. VGA Sync 신호 생성
//    // =========================================================
//    always_ff @(posedge mi0.clk_vga or negedge mi0.rstn) begin
//        if(!mi0.rstn) begin
//            mi0.Hsync <= 1;
//            mi0.Vsync <= 1;
//        end else begin
//            // Active Low 기준 (표준)
//            // H: Sync(96) + BP(48) + Active(640) + FP(16) = 800
//            mi0.Hsync <= (h_cnt < 96) ? 0 : 1; 
//            // V: Sync(2) + BP(33) + Active(480) + FP(10) = 525
//            mi0.Vsync <= (v_cnt < 2) ? 0 : 1;
//        end
//    end

//    // =========================================================
//    // 4. 화면 중앙 정렬 및 출력 구간 설정 (320x225)
//    // H 시작점 = 144(블랭크끝) + 160(여백) = 304 (304 ~ 623 구간)
//    // V 시작점 = 35(블랭크끝) + 127(여백) = 162 (162 ~ 386 구간)
//    // =========================================================
//    wire img_req_h = (h_cnt >= 304 && h_cnt < 624);
//    wire img_req_v = (v_cnt >= 162 && v_cnt < 387);
//    wire img_req   = (img_req_h && img_req_v); // 데이터 요청 구간

//    // BRAM 1 Clock Delay 보상용 딜레이 레지스터
//    logic img_req_d;
//    always_ff @(posedge mi0.clk_vga or negedge mi0.rstn) begin
//        if(!mi0.rstn) img_req_d <= 0;
//        else          img_req_d <= img_req;
//    end

//    // =========================================================
//    // 5. BRAM Address 제어 및 RGB 출력
//    // =========================================================
//    always_ff @(posedge mi0.clk_vga or negedge mi0.rstn) begin
//        if(!mi0.rstn) begin
//            mi0.addrb <= 0;
//            mi0.vgaRed <= 0;
//            mi0.vgaGreen <= 0;
//            mi0.vgaBlue <= 0;
//            mi0.rd_ready <= 0;
//        end else begin
//            mi0.rd_ready <= 1; // 항상 읽기준비

//            // [어드레스 제어]
//            // 새로운 프레임이 시작되는 시점 (0,0)에서 더블 버퍼링 읽기 위치 세팅
//            if (v_cnt == 0 && h_cnt == 0) begin
//                // 쓰는 쪽(Image_conv)에서 room_chk==0일때 72000에 씀.
//                // 즉, room_chk==0이면 우리는 0번지(안전한 곳)를 읽어야 함.
//                mi0.addrb <= (room_chk_ff[1] == 1'b0) ? 0 : 72000;
//            end 
//            // 실제 이미지가 출력되는 구간에서만 어드레스 증��
//            else if (img_req) begin
//                mi0.addrb <= mi0.addrb + 1;
//            end

//            // [RGB 출력] - BRAM 특성상 주소를 주고 1클럭 뒤에 데이터가 나옴 (img_req_d 사용)
//            if (img_req_d) begin
//                mi0.vgaRed   <= mi0.doutb[11:8];
//                mi0.vgaGreen <= mi0.doutb[7:4];
//                mi0.vgaBlue  <= mi0.doutb[3:0];
//            end else begin
//                // 이미지가 아닌 테두리(여백) 부분은 검은색 출력
//                mi0.vgaRed   <= 4'h0;
//                mi0.vgaGreen <= 4'h0;
//                mi0.vgaBlue  <= 4'h0;
//            end
//        end
//    end

//    // 사용하지 않는 Interface 신호 0으로 묶어줌 (Latch 방지)
//    always_comb begin
//        mi0.row_cnt = 0;
//        mi0.one_done = 0;
//        mi0.line_done = 0;
//    end

//endmodule
