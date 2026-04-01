//`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////////
//// Company: 
//// Engineer: 
//// 
//// Create Date: 03/29/2026 11:50:23 AM
//// Design Name: 
//// Module Name: OV_MASTER
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


module OV_MASTER(my_vga_if.sccb_master mi0);

    //명령 숫자
    logic [5:0] COMMAND;
    logic [15:0] COMMAND_reg;
always@(*) begin
    case(COMMAND)
        // 1. 초기화 및 기본 모드
        0: COMMAND_reg = {8'h12, 8'h80}; // COM7: Reset
        1: COMMAND_reg = {8'h12, 8'h14}; // COM7: QVGA + RGB 선택 (0x14 = QVGA RGB)
        
        // 2. 사선 및 타이밍 해결
        2: COMMAND_reg = {8'h15, 8'h00}; // COM10: 기본 설정 (0x00)
        3: COMMAND_reg = {8'h11, 8'h01}; // CLKRC: 내부 분주 (PCLK 속도 조절, 0x01 = 6MHz @ 24MHz input)
        
        // 3. RGB444 및 데이터 순서 고정
        4: COMMAND_reg = {8'h40, 8'hD0}; // COM15: RGB444 + Full Range (0x10=RGB444, 0xC0=Full range)
        5: COMMAND_reg = {8'h8C, 8'h02}; // RGB444: 출력 활성화
        
        // 4. 화질 자동 조절
        6: COMMAND_reg = {8'h13, 8'hE7}; // COM8: Fast AGC/AEC/AWB 활성화
        7: COMMAND_reg = {8'h0C, 8'h00}; // COM3: Scale 활성화 (QVGA용)
        8: COMMAND_reg = {8'h3E, 8'h00}; // COM14: PCLK 분주 해제
        9: COMMAND_reg = {8'h42, 8'h00}; // COM17: Test Pattern Off
        
        default : COMMAND_reg = 16'hFFFF;
    endcase
end
//    always@(*) begin
//        case(COMMAND)
//            0: COMMAND_reg = {8'h12, 8'h80}; // 리셋 (반드시 10ms 대기 필요)
//            1: COMMAND_reg = {8'h12, 8'h14}; // QVGA 모드 (320*240) 14
//            2: COMMAND_reg = {8'h40, 8'hC0}; // RGB444 포맷 지정 (색상 정확도)
//            3: COMMAND_reg = {8'h8C, 8'h02}; // RGB444 출력 활성화
//            4: COMMAND_reg = {8'h11, 8'h01}; // 클럭 설정
//            default : COMMAND_reg = 16'hFFFF;
//        endcase
//    end
    
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
    logic [31:0] timer;//239980 10ms
    // pclk?? clk????
    always@(posedge mi0.clk, negedge mi0.rstn)begin //pclk..
        if(!mi0.rstn)begin
            st_master <= IDLE1;
            loop_en <= 1;
            mi0.sccb_write_rstn <= 0;
            mi0.sccb_read_rstn <= 0;
            mi0.sccb_write_en <= 0;
            mi0.sccb_read_en <= 0;
             COMMAND <= 0;
             mi0.sccb_master_done <= 0;
             idx <= 0;
             mi0.led_clk1 <= 0;
             timer <= 0;
        end else begin
            case(st_master)
                IDLE1:begin  
                    //mi0.led <= 4'b0001;
                    mi0.sccb_write_rstn <= 0;
                    mi0.sccb_read_rstn <= 0;
                    if(loop_en)begin//======================================================
                        st_master <= WRITE1;
                    end
                end//idle1
                WRITE1:begin
                    //mi0.led <= 4'b0010;
                    mi0.sccb_write_rstn <= 1;
                    mi0.sccb_write_en   <= 1;//동시에 주면 안된다.
                    mi0.ID_address        <= {(8'h21 << 1) | 1'b0}; //Write : 0
                    mi0.Sub_address     <= COMMAND_reg[15:8];
                    mi0.COM7                <= COMMAND_reg[7:0];
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
                    if(mi0.read_data == mi0.COM7)begin
                       if(COMMAND == 9)begin
                         loop_en <= 0;
                         mi0.led_clk1 <= 1;
                         mi0.sccb_master_done <= 1;
                      end else COMMAND <= COMMAND + 1;                       
                    end else begin
                        loop_en <= 0;
                    end
                    st_master <= IDLE1;
                end//com1
                WAIT1:begin//5ms이상 리셋 대기
                    if(timer >= 20'd1194350)begin
                        timer <= 0;
                        st_master <= IDLE1;
                        COMMAND <= COMMAND + 1;
                    end else timer <= timer + 1;
                end
            endcase
        end
    end
    
endmodule







