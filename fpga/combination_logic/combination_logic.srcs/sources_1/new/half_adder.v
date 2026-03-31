`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////



module half_adder(
    input a,                        //1비트 입력 a
    input b,                        //1비트 입력 b
    output reg sum,                 //합 을 저장할 레지스터 타입 출력
    output reg carry                //자리올림 을 저장할 레지스터 타입 출력
    );
    
    
    
    always @(a,b) begin
        case ({a,b})                // 입력 a,b를 묶어서 2비트 벡터로 만들고 case로 분기
        2'b00 : begin               //
            sum = 0;
            carry = 0 ;
          end
          2'b01 : begin
            sum = 1;
            carry = 0;
          end
          2'b11 : begin
            sum = 0;
            carry = 1;
           end
          endcase
          end
endmodule




    module half_adder_structural(
        input A,
        input B,
        output s,
        output c
        );
        
        and (c, A, B);
        xor (s, A, B);
        
        endmodule
        
        
        
    module half_adder_dataflow(
        input A,
        input B,
        output S,
        output C 
        );
        
        wire [1:0] sum_value;
        
        assign sum_value = A + B;
        
        assign S = sum_value[0];     //합
        
        assign C = sum_value[1];     //자리올림
        
        
        
endmodule