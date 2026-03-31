`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/23/2026 10:43:30 AM
// Design Name: 
// Module Name: sequential_logic
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


module sequential_logic(

    );
endmodule


// 레지스터, 상태저장기(FSM), 카운터, 클럭동기화 회로, 시프트레지스터
module D_flip_flop (
    input d,                // 데이터 입력
    input clk,              // 클럭 입력
    output reg q            // 출력
    );
    
    always @(posedge clk) begin
        q <= d;     // 클럭 상승엣지에서 D를 Q에 저장      
    
    end
    
    
//    always @(*) begin
//        a = 1;
//        b = a + 1;    //b = 2
        
//    end
    
//    always @(*) begin
//        a <= 1;
//        b <= a + 1;    // b는 이전 a + 1 --> b = olda + 1;
    
//    end
    
    
    
endmodule





module D_flip_flop_n (
    input d,
    input clk,
    input reset_p,
    input enable,
    output reg q

);

    always @(negedge clk or posedge reset_p) begin
        //비동기 리셋 : reset_p가 1이되면 즉시 q를 0으로
        if(reset_p)
            q <= 0;
        // enable이 1일때만 입력 d를 q에 저장
        else if(enable)
            q <= d;   // q = d;
            
        
    end
endmodule




module D_flip_flop_p (
    input d,
    input clk,
    input reset_p,
    input enable,
    output reg q

);

    always @(posedge clk or posedge reset_p) begin
        //비동기 리셋 : reset_p가 1이되면 즉시 q를 0으로
        if(reset_p)
            q <= 0;
        // enable이 1일때만 입력 d를 q에 저장
        else if(enable)
            q <= d;   // q = d;
            
        
    end
endmodule   


/// behavioral 방식이 정확!!


// module D_flip_flop_dataflow (       // 부적합!!! 클럭에 반응 못함!!
//     input d,        // 데이터 입력
//     input clk,      // 클럭 입력
//     output reg q    // 출력
//     );

//     assign q = d;       // 이러면 클럭 동작을 알수가없어?? -> 플립플롭 동작이 아님!!

//     // always @(posedge clk) begin
//     //    q <= d;      // 클럭 상승엣지에서 D를 Q에 저장 
//     // end    

// endmodule

// module D_latch_structure (
//     input D, En,
//     output Q
// );
//     wire Dbar, S, R, Qbar;

//     not (Dbar, D);
//     and (S, D, En);
//     and (R, Dbar, En);
//     nor (Q, R, Qbar);
//     nor (Qbar, S, Q);
// endmodule

// module D_flip_flop_structural (     // 비추!!!! 너무 복잡!! 비실용적
//     input clk,
//     input D,
//     output Q
// );
//     wire Qm;

//     D_latch master (.D(D), .En(~clk), .Q(Qm));  // Master latch: clk low에서 활성
//     D_latch slave  (.D(Qm), .En(clk),  .Q(Q));   // Slave latch: clk high에서 활성
// endmodule  


module T_flip_flop_n(
    input clk, reset_p,
    //input en,
    input t,
    output reg q
);

    always @(negedge clk or posedge reset_p) begin
        if(reset_p) q = 0;
        else if(t) q = ~q;
    end
    
endmodule



module T_flip_flop_p (
    input clk, reset_p, t,
    output reg q,
    output qbar
);
    assign qbar = ~q;
    always @(posedge clk or posedge reset_p) begin
        if(reset_p)
            q <= 1'b0;   //비동기 리셋
        else if(t)
            q <= ~q;     // T = 1 ->토글
        else
            q <= q;      // T = 0  -> 유지
     end
endmodule    





// 비동기 업카운터
// T_플립플롭을 4개 직렬로 연결 4비트 카운터 구성
// 오르쪽 비트부터 차례로 다음단계 클럭으로 사용

module up_counter_asyc (
    input clk,                  // 외부클럭 입력(LSB에만 연결)
    input reset_p,              //비동기 리셋(전체 FF 연결)
    output [3:0] count          //카운터 출력
);
    //LSB 는 외부클럭 직접 사용
    T_flip_flop_n T(
        .clk(clk),          //외부클럭
        .reset_p(reset_p),  //리셋
        .t(1'b1),            //항상 토글
        .q(count[0])        //가장 하위 비트 출력
    );
    //T는 count[0]을 클럭으로 사용(비동기연결)
    T_flip_flop_n T1(.clk(count[0]), .reset_p(reset_p), .t(1), .q(count[1]));
    T_flip_flop_n T2(.clk(count[1]), .reset_p(reset_p), .t(1), .q(count[2]));
    T_flip_flop_n T3(.clk(count[2]), .reset_p(reset_p), .t(1), .q(count[3]));

endmodule


// 비동기 다운카운터
// 각 플립플롭은 이전단계의 출력이 클럭 역할을 함.
module down_counter_asyc (
    input clk,
    input reset_p,
    output [3:0] count
);
    T_flip_flop_p T0(.clk(clk),      .reset_p(reset_p), .t(1), .q(count[0]));
    T_flip_flop_p T1(.clk(count[0]), .reset_p(reset_p), .t(1), .q(count[1]));
    T_flip_flop_p T2(.clk(count[1]), .reset_p(reset_p), .t(1), .q(count[2]));
    T_flip_flop_p T3(.clk(count[2]), .reset_p(reset_p), .t(1), .q(count[3]));


endmodule


// 동기식 카운터
// 업카운터_p, 다운카운터_p (다른건 잘 안씀)
module up_counter_p(
    input clk, reset_p, enable,
    output reg [3:0] count
    
);
    always @(posedge clk or posedge reset_p) begin
        if(reset_p)
            count = 0;
        else if(enable)
            count <= count +1;
    end
endmodule

module down_counter_p (
    input clk, reset_p, enable,
    output reg [3:0] count
    
);
    always @(posedge clk or posedge reset_p) begin
        if(reset_p)
            count = 0;
        else if(enable)
            count <= count -1;
    end
endmodule



//링카운터
//1개의 비트가 정해진 순서대로 한비트씩 이동
module ring_counter (
    input clk,
    input reset_p,
    output reg [3:0] q
);
    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            q <= 4'b0001;  //리셋이 들어오면 초기값으로 변화
         end else begin
             case (q)
                4'b0001: q <= 4'b0010;  //첫번째 비트 -> 두번째 이동
                4'b0010: q <= 4'b0100;
                4'b0100: q <= 4'b1000;
                4'b1000: q <= 4'b0001;
             endcase
         end
       end
endmodule


module edge_detector_n (
    input clk,
    input reset_p,
    input cp,           //엣지를 감시할 대상(클럭 펄스)
    output n_edge       //cp의 하강 엣지

);
    reg ff_cur, ff_old;         //신호의 현재상태, 이전상태를 저장하기 위한 플립플롭 레지스터
    
    always @(negedge clk or posedge reset_p) begin
        if(reset_p) begin   // 리셋 신호가 들어오면 모든상태를 0으로 초기화
            ff_cur <= 0;
            ff_old <= 0;
        end
        else begin  //클럭마다 데이터를 한칸씩 밀어줌
            ff_old <= ff_cur;   //기존에 있던 현재값을 이전값으로 업데이트
            ff_cur <= cp;       //새로운 cp 값을 현재값으로 저장
        end
     end
  
  assign n_edge = (ff_old == 1 && ff_cur == 0);
endmodule



module clock_div_100 (
    input clk,
    input reset_p,
    output clk_div_100,     // 1MHz 펄스 출력
    output cp_div_100
);

    reg [6:0] cnt_sysclk;

    always @(negedge clk or posedge reset_p) begin
        if (reset_p)
            cnt_sysclk <= 1;
        else begin
            if(cnt_sysclk >= 99)
                cnt_sysclk <= 0;
            else
                cnt_sysclk <= cnt_sysclk + 1;
        end 
    end

    assign cp_div_100 = (cnt_sysclk < 50) ? 0 : 1;      // 50% Duty

    edge_detector_n ed(
        .clk(clk),
        .reset_p(reset_p),
        .cp(cp_div_100),
        .n_edge(clk_div_100)
    );
    
endmodule


module clock_div_1000 (
    input clk,
    input reset_p,
    output clk_div_1000
);
    reg [9:0] count;
    reg pulse;

    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            count <= 0;
            pulse <= 0;
        end else begin
            if(count == 999) begin
                count <= 0;
                pulse <= 1;
            end else begin
                count <= count + 1;
                pulse <= 0;
            end
        end
    end
    
    assign clk_div_1000 = pulse;

endmodule


module clock_div_1hz_top (
    input clk,
    input reset_p,
    output clk_1hz
);
    wire clk_1mhz;  // 100MHz -> 1MHz
    wire clk_1khz;  // 1MHz -> 1KHz

    // 100분주
    clock_div_100 u1(
        .clk(clk),
        .reset_p(reset_p),
        .clk_div_100(clk_1mhz),
        .cp_div_100()
    );
    // 1000분주
    clock_div_1000 u2(
        .clk(clk_1mhz),
        .reset_p(reset_p),
        .clk_div_1000(clk_1khz)
    );
    // 또 1000분주
    clock_div_1000 u3(
        .clk(clk_1khz),
        .reset_p(reset_p),
        .clk_div_1000(clk_1hz)
    );
    
endmodule


module top_led (
    input clk,
    input btnC,
    output reg led
);
    wire clk_1hz;

    clock_div_1hz_top led_div(
        .clk(clk),
        .reset_p(btnC),
        .clk_1hz(clk_1hz)
    );
    always @(posedge clk_1hz or posedge btnC) begin
        if(btnC)
            led <= 0;
        else
            led <= ~led;
    end

endmodule



module led_blink_1s (
    input clk,
    input reset_p,
    output reg [7:0] led
);
    reg clk_1Hz;
    reg [26:0] count;

    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            count <= 0;
            clk_1Hz <= 0;
        end else begin
            if (count == 49999999) begin     //줄이면 led 빨라짐 올리면 led 느려짐
                count <= 0;
                clk_1Hz <= ~clk_1Hz;
            end else begin
                count <= count + 1;
            end
        end
    end


    always @(posedge clk_1Hz or posedge reset_p) begin
        if (reset_p) begin
            led <= 8'b00000000;
        end else begin
            led <= ~led;
        end
    end

endmodule



module led_pattern
(
    input clk,
    input reset_p,
    input [1:0] sw,//버튼 추가
    output reg [7:0] led    
);
    reg clk_1Hz;
    reg [25:0] count ;//26bit로 해서 100Mhz를 표현하기 위해서임.
    
    reg dir;                 //방향
    reg [3:0] step;     //패턴 카운터
    
    // 그냥 카운트의 비트를 출력으로 연결하고픔.
    always@(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            count <= 0;
            clk_1Hz <= 0;
        end
        else begin
            if(count == 4999_9999)begin//5천만. 주기는 10^8, 10^8인 원주파수
                count <= 0;
                clk_1Hz <= ~clk_1Hz;
            end
            else begin
                count <= count + 1;
            end
        end
    end
    
    always@(posedge clk_1Hz or posedge reset_p)begin
        if(reset_p)begin
            led <= 8'b0000_0000;
            dir <= 0;
            step <= 0;
        end
        else begin
            case(sw)
                0:begin//==>  & <==
                    if(led == 8'b0000_0000) led <= 8'b1000_0000;
                    else if(dir == 0)begin
                        if(led == 8'b0000_0001) dir <= 1;
                        else led <= (led >> 1);
                    end else begin
                        if(led == 8'b1000_0000) dir <= 0;
                        else led <= (led << 1);
                    end
                end
                
                1:begin
                    if(led == 8'b0000_0000) led <= 8'b1100_0000;
                    else if(dir == 0)begin
                        if(led == 8'b0000_0011) dir <= 1;
                        else led <= (led >> 1);
                    end else begin
                        if(led == 8'b1100_0000) dir <= 0;
                        else led <= (led << 1);
                    end
                end
                    
                2:begin
                    if( led == 8'b1111_1111) led <= 8'b0000_0000;
                    else led <= (led << 1) | 8'b0000_0001;
                end
                
                3:begin
                    step <= step + 1;
                    case(step%4)
                        0 : led <= 8'b0001_1000;
                        1: led <= 8'b0010_0100;
                        2 : led <= 8'b0100_0010;
                        3 : led <= 8'b1000_0001;
                    endcase
                end
            endcase
        end
    end
    

endmodule



// 4비트 SISO(Serial In Serial Out)
module shift_register_SISO_n (
    input clk,
    input reset_p,
    input d,        // Serial In
    output q        // Serial Out
);

    reg [3:0] siso_reg;     // 4비트 레지스터

    always @(negedge clk or posedge reset_p) begin
        if (reset_p) begin
            siso_reg <= 4'b0000;    // 리셋 시 모든 비트 초기화
        end else begin
            siso_reg[3] <= d;           // 입력 d를 가장 왼쪽 비트에 저장
            siso_reg[2] <= siso_reg[3]; // 나머지 비트 오른쪽으로 이동
            siso_reg[1] <= siso_reg[2];
            siso_reg[0] <= siso_reg[1];
        end
    end
    
    assign q = siso_reg[0];     // 가장 마지막 비트를 출력으로 연결

endmodule



// SIPO (Serial In Parallel Out)
// 입력신호를 받아서 클럭에 따라서 시프트하고 결과를 병렬로 출력
module shift_register_SIPO_n (
    input clk,
    input reset_p,
    input d,
    input rd_en,        // 읽기 제어 : 0이면 출력 활성, 1이면 High_Z
    output [3:0] q
);
    reg [3:0] sipo_reg;

    always @(negedge clk or posedge reset_p) begin
        if (reset_p) begin
            sipo_reg <= 4'b0000;
        end else begin
            sipo_reg <= {d, sipo_reg[3:1]};      // d를 가장 왼쪽에 넣고 나머지를 오른쪽으로 
        end
    end

    // rd_en 0이면 레지스터값 출력, 1이면 출력버스를 High-Impendance 상태로 설정
    assign q = rd_en ? 4'bz : sipo_reg;

    // High-Impendance 는 출력버스에 여러개의 모듈이 연결되어 있을 때 충돌방지

endmodule


//PISO
module shift_register_PISO (
    input clk,
    input reset_p,
    input [3:0] d,
    input shift_load,       // 0 -> load, 1 -> shift
    output q
);

    reg [3:0] piso_reg;

    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            piso_reg = 4'b0000;
        end else begin
            if (shift_load) begin
                piso_reg <= {1'b0, piso_reg[3:1]};  // MSB -> LSB
            end else begin
                piso_reg <= d;
            end
        end
    end

    assign q = piso_reg[0];
    
endmodule


module register_Nbit_p #(parameter N = 8)(
    input clk,
    input reset_p,
    input [N-1:0] d,                // N 비트 입력 데이터
    input wr_en,                    // 쓰기 활성화 신호
    input rd_en,                    // 읽기 활성화 신호
    output [N-1:0] register_data,   // 내부 레지스터값
    output [N-1:0] q                // 읽기 활성화시 출력 아니면 Z
);
    reg [N-1:0] register;           // 내부 N비트 레지스터

    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            register = {N{1'b0}};       // 0 <- 초기화
        end
        else if (wr_en) begin
            register = d;               // 쓰기 활성화시 입력 저장
        end
    end

    assign q = rd_en ? register : {N{1'bz}};    // rd_en 신호에 따라 출력 활성화 or z

    assign register_data = register;            // 레지스터값 항상 출력(읽기신호무관)
    
endmodule



module ring_counter_led_flag(
    input clk, reset_p,
    output reg [15:0] led);
    
    reg [31:0] clk_div;
    always @(posedge clk)clk_div = clk_div + 1;
    
    reg flag;
       
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            led = 16'b0000_0000_0000_0001;
            flag = 0;
        end
        else begin
            if(clk_div[22] && flag == 0)begin
                led <= {led[14:0], led[15]};
                flag = 1;
            end
            if(clk_div[22] == 0)flag = 0;
        end
    end

endmodule



module memory (
    input clk,
    input reset_p,

    input [7:0] i_data,     // 입력 데이터
    input [9:0] wr_addr,    // write 주소
    input [9:0] rd_addr,    // read 주소

    output reg [7:0] o_data // 출력데이터
);

    reg [7:0] ram [0:1023];     // 1024 X 8bit RAM 선언

    always @(posedge clk) begin
        // write
        ram[wr_addr] <= i_data;
        //read
        o_data <= ram[rd_addr];
    end

endmodule



module memory_one_addr_bus (
    input clk,
    input reset_p,
    input [7:0] i_data,
    input wr_en,
    input [9:0] addr,

    output reg [7:0] o_data
);

    reg [7:0] ram [0:1023];

    always @(posedge clk) begin
        if (wr_en) begin
            ram[addr] <= i_data;
        end else begin
            o_data <= ram[addr];
        end
    end
    
endmodule