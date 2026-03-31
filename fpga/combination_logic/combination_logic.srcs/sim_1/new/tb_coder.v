`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/19/2026 02:27:27 PM
// Design Name: 
// Module Name: tb_coder
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


module tb_encoder_4_2;

    reg [3:0] signal;
    wire [1:0] code;

    encoder_4_2 uut(
        .signal(signal),
        .code(code)
    );

    initial begin
        signal = 4'b0000;

        #10 signal = 4'b0001;
        #10 signal = 4'b0010;
        #10 signal = 4'b0100;
        #10 signal = 4'b1000;

        #10 signal = 4'b0000;
        #10 signal = 4'b0011;

        #10 $finish;

    end

endmodule




module tb_decoder_2_4;

    reg [1:0] code;      // 입력은 reg
    wire [3:0] signal;   // 출력은 wire

    // 디코더 모듈 인스턴스화
    decoder_2_4 uut (
        .code(code),
        .signal(signal)
    );

    initial begin
        // 초기값 설정
        code = 2'b00;

        // 10ns 간격으로 입력 변화
        #10 code = 2'b00; // 결과: 0001
        #10 code = 2'b01; // 결과: 0010
        #10 code = 2'b10; // 결과: 0100
        #10 code = 2'b11; // 결과: 1000

        #10 $finish;      // 시뮬레이션 종료
    end


endmodule