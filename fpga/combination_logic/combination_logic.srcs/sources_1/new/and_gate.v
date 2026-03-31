`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

// Behavioral modeling
//동작적 모델링 
// > 사람이 무엇을 할건지 코드로 표현
// > 하드웨어 동작을 if,case, for 등 알고리즘 중심으로 기술
// > always 블록 사용
// > 주로 상위레벨 기능이나 복잡한 제어 사용
// > 설계하기는 쉬움, 복잡한 로직 가능
// > RTL 시뮬레이션을 가능하나 실제 구조파악에 어려움

// 구조적 모델


// 데이터 플로우 모델



module and_gate(            // Module은 입출력 포트가 있는 회로를 정의
    input a, b,             // ()안에는 입출력 포트의 목록이 들어감, 실제 IO처럼 동작
    output reg q
    );

    always @(a,b) // a 또는 b가 변하면
    begin // 시작
        case({a,b})
            2'b00 : q = 0;
            2'b01 : q = 0;
            2'b10 : q = 0;
            2'b11 : q = 1;
        endcase
    end   //정지
endmodule
 
 // Behavioral a, b의 AND 연산 결과를 출력 q에 저장
 // always  블록과 case, if 문을 사용해서 회로의 동작을 기술
 
 module and_gate_behavioral(
    input a, b,         // 두 개의 입력 신호 a, b
    output reg q);      // 출력 신호 q (레지스터 타입)

    // a 또는 b 중 하나라도 값이 변경되면 항상 블록 실행
    always @(a or b)    // a,b랑 같은 표현
    begin
        // a와 b가 모두 1이면 q에 1 저장
        if (a == 1'b1 && b == 1'b1)
            q = 1'b1;
        // 그렇지 않으면 q에 0 저장
        else
            q = 1'b0;
    end
endmodule

 // 구조적 모델 
 // -> 실제 회로도와 같이 하드웨어 블록 단위 연결
 // -> 모듈 인스턴스를 사용해서 회로를 구성
 // -> 하드웨어 (레지스터, 게이트)를 직접 연결
 // -> 회로의 구조를 verilog에 옮긴 느낌
 // -> 실제 횔를 표현, 합성 후 모습고 ㅏ유사
 // -> 대규모 회로는 복잡!
 
  module and_gate_structual(
    input a, b,         // 두 개의 입력 신호 a, b
    output q);      // 출력 신호 q (레지스터 타입)

    and U1(q, a, b);    // and gate 인스턴스 생성  U1은 그냥 보기 힘들어서 이름 지정해준거
endmodule

// DATA Flow 모델
// -> 신호의 흐름을 중심으로 기술
// -> assign 문을 이용
// -> 조합 논리
  module and_gate_dataflow(
    input a, b,         // 두 개의 입력 신호 a, b
    output q);      // 출력 신호 q (레지스터 타입)

    // assign 문 활용해 AND연산의 결과를 q에 연결
    assign q = a & b;
endmodule





