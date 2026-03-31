`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/20/2026 09:21:09 AM
// Design Name: 
// Module Name: mux
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


module mux_2_1(

    input [1:0] d,
    input s,
    output f
    
    );
    
    assign f= s ? d[1] : d[0];
    
    
endmodule    


module mux_4_1 (

    input [3:0] d,
    input [1:0] s,
    output f

);



    assign f = d[s];
    
//    //behavioral
//    always @(d or s) begin
//        case (s)
//         2'b00 : f = d[0];
//         2'b01 : f = d[1];
//         2'b10 : f = d[2];
//         2'b11 : f = d[3];
//         //default: f = 1'bx;
//         endcase
         
         
//     end
 
endmodule






module mux_8_1 (

    input [7:0] d,
    input [2:0] s,
    output f
);

    assign f = d[s];
    
endmodule



module demux_1_2 (
    input in,                   //데이터 입력 포트 1비트
    input s,                    //데이터 보낼 경로 선택 1비트
    output reg [1:0] out        // 출력 포트 (always 구문내에 할당하기 위해서 reg)
 );   
    
    always @(*) begin           //입력 신호가 바뀔때마다
        case (s)
            //선택신호가 0일때 : 입력을 out[0]으로 전달
            //{1'b0, in} 는 비트 결합 연산자 msbsms 0, lsb는 in
            1'b0 : out = {1'b0, in};
            1'b1 : out = {in, 1'b0};        //msb는 in, lsb는 0
            default : out = 2'b00;          //x(Don't care), Z(하이임피던스)
        endcase
    end
    
endmodule




module demux_1_4 (
    input d,            //단일 입력
    input [1:0] s,      //선택 2비트
    output [3:0] f      //출구가 4개 -> 선택된 위치로 출력(전달)
    
);
    assign f = (s == 2'b00) ? {3'b000, d} :              // s = 00-> f = 000d (f[0] = d)
               (s == 2'b01) ? {2'b00, d, 1'b0} :         // s = 01-> f = 00d0 (f[1] = d)    
               (s == 2'b10) ? {1'b0, d, 2'b00} :         // s = 10-> f = 0d00 (f[2] = d)
                              {d, 3'b000};              // s = 11-> f = d000 (f[3] = d)
                              
//    assign f[0] = (s == 2'b00) ? d : 0;                    
//    assign f[1] = (s == 2'b01) ? d : 0;                          
//    assign f[2] = (s == 2'b10) ? d : 0;                          
//    assign f[3] = (s == 2'b11) ? d : 0; 

endmodule           



module mux_demux_test (
    input [3:0] d,          // MUX 입력
    input [1:0] mux_s,      // MUX 선택
    input [1:0] demux_s,    // DEMUX 선택
    output [3:0] f          // DEMUX 출력
);
    wire mux_f;             // MUX 출력과 DEMUX 입력 연결하는 내부신호

    mux_4_1 mux4(
        .d(d),
        .s(mux_s),
        .f(mux_f)
    );

    demux_1_4 demux4(
        .d(mux_f),
        .s(demux_s),
        .f(f)
    );

    
endmodule   





module bin_to_dec (
    input [11:0] bin,
    output reg [15:0] bcd
    
);

    integer i;
    
    always @(bin) begin
        bcd = 0;
        
        for(i = 0; i < 12; i= i + 1) begin
        
        
            if(bcd[3:0] >= 5)
               bcd[3:0] = bcd[3:0] + 3;
            if(bcd[7:4] >= 5)
               bcd[7:4] = bcd[7:4] + 3;
            if(bcd[11:8] >= 5)
               bcd[11:8] = bcd[11:8] + 3;
            if(bcd[15:12] >= 5)
               bcd[15:12] = bcd[15:12] + 3;
               
               bcd = {bcd[14:0], bin[11-i]};      
        end
     end
     
endmodule