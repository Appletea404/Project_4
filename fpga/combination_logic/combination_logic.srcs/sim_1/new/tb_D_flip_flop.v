`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/23/2026 10:56:26 AM
// Design Name: 
// Module Name: tb_D_flip_flop
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


module tb_D_flip_flop;

    reg clk;
    reg d;
    wire q;

    D_flip_flop uut(
        .clk(clk),
        .d(d),
        .q(q)
    );

    // 클럭 생성기 ; 10ns 주기(100MHz)
    initial begin
        clk = 0;
        forever begin
            #5 clk = ~clk;
        end
    end

    initial begin
        d = 0;
        // 출력
        $display("\t\t\t\tTime\tclk d q");
        $monitor("%4t\t%b %b %b", $time, clk, d, q);

        // 15ns d = 1 설정 (clk 상승?)
        #15 d = 1;
        // 20ns d = 0
        #20 d = 0;
        #20 d = 1;
        #30 $finish;
    end

endmodule


module tb_D_flip_flop_n;

    reg d;
    reg clk;
    reg reset_p;
    reg enable;
    wire q;

    D_flip_flop_n uut(
        .d(d), .clk(clk), .reset_p(reset_p), .enable(enable),
        .q(q)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;        
    end

    initial begin
        // intial value
        d = 0;
        reset_p = 1;
        enable = 0;

        // 리셋 해제전에 잠시 유지
        #12;
        reset_p = 0;        // 리셋 해제
        
        #10 enable = 1;         // 인에이블 활성화

        // d 값 변화
        d = 1;
        #10;    // 한클럭 대기
        
        d = 0; #10;

        d = 1; #10;

        enable = 0;         // 인이에블 비활성 (q값 유지 확인??)
        d = 0; #20;

        enable = 1;         // 인에이블 활성화
        d = 1; #10;

        // reset test
        reset_p = 1;
        #10;
        reset_p = 0;
        #10

        $stop;      // 시뮤레이션 중지

    end
    
endmodule



module tb_T_flip_flop_n;
    reg clk, reset_p, t;
    wire q;

    T_flip_flop_n uut(
        .clk(clk), .reset_p(reset_p), .t(t),
        .q(q)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
    
    reset_p = 1; t = 0;
    #10 reset_p = 0;

    // T = 1 -> toggle
    t = 1; #10;  // clk nedge에서 토글
    #10;

    t = 0; #20;   // t = 0 -> 상태유지

    t = 1; #10;     // t = 1 -> toggle
    #10;

    reset_p = 1; #10;
    reset_p = 0;

    t = 1; #20;    // toggle

    $finish;
    end

endmodule


module tb_up_count_asyc;
    reg clk;
    reg reset_p;
    wire [3:0] count;
    
    up_counter_asyc uut(
        .clk(clk), .reset_p(reset_p), .count(count)
    );
    
    always #5 clk = ~clk;
    
    initial begin
    
        clk = 0;
        reset_p = 1;
        
        #10;
        reset_p = 0;
        
        #300;
        $finish;
     end
endmodule



module tb_down_counter_asyc;
    reg clk;
    reg reset_p;
    wire [3:0] count;

    down_counter_asyc uut(
        .clk(clk),
        .reset_p(reset_p),
        .count(count)
    );

    // 클럭 생성
    always #5 clk = ~clk;
    // 위 코드와 같음.
    // initial begin
    //     clk = 0;
    //     forever #5 clk = ~clk;
    // end

    initial begin
        // initial signal
        clk = 0;
        reset_p = 1;    // 초기 리셋 활성화

        #10;
        reset_p = 0;    // 리셋 비활성화 하면 카운팅 시작

        #300;       // 300ns 만큼 카운팅 시작
        $finish;

    end
    
endmodule     


module tb_up_down_counter;
    reg clk, reset_p, enable;
    wire [3:0] up_count;
    wire [3:0] down_count;

    up_counter_p    uut_up(
        .clk(clk), .reset_p(reset_p), .enable(enable), .count(up_count)
    );
    down_counter_p  uut_down(
        .clk(clk), .reset_p(reset_p), .enable(enable), .count(down_count)
    );

    initial begin
        clk = 0;
        forever begin
            #5 clk = ~clk;
        end
    end

    initial begin
        reset_p = 1;
        enable = 0;
        #10 reset_p = 0;
        #10 enable = 1;
        #100;               // 사태 파악
        enable = 0;         // 카운터 정지
        #20;

        reset_p = 1;        // 리셋
        #10 reset_p = 0;
        #20;

        $finish;
    end
endmodule


module tb_ring_counter;

    reg clk;
    reg reset_p;
    wire [3:0] q;
    
    ring_counter uut(
        .clk(clk),
        .reset_p(reset_p),
        .q(q)
    );
    always #5 clk = ~clk;
    
    initial begin
        clk = 0;
        reset_p = 1;
        
        #10 reset_p = 0;
        
        #100;               //100ns 만큼 시뮬레이션 진행
        
        #10;
        $finish;
      end
endmodule


module tb_edge_detector_n();
    reg clk;
    reg reset_p;
    reg cp;
    
    wire n_edge;
    
    edge_detector_n uut(
        .clk(clk), .reset_p(reset_p), .cp(cp), .n_edge(n_edge)
    );
    
    always #5 clk = ~clk;
    
    initial begin
    
        clk = 0;
        reset_p = 1;
        cp = 0;
        
        #20 reset_p = 0;
        
        #30 cp = 1;     // cp -> high
        #50 cp = 0;     // cp -> low (이 때,, n_edge가 1클럭 발생)
        
        #40 cp = 1;     
        #5  cp = 0;     // 클럭 하강엣지 이전에 신호가 없어지면??

        #40 cp = 1;
        #20 cp = 0;

        #100 $finish;
    end
endmodule


module tb_clock_div_100 ();
    reg clk;
    reg reset_p;
    wire clk_div_100;
    wire cp_div_100;

    clock_div_100 uut(
        .clk(clk), .reset_p(reset_p), .clk_div_100(clk_div_100), .cp_div_100(cp_div_100)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset_p = 1;
        #50 reset_p = 0;
    
        #3000;

        $finish;
    end


endmodule


module tb_clock_div_1000;
    reg clk;
    reg reset_p;

    wire clk_div_1000;

    clock_div_1000 uut(
        .clk(clk),
        .reset_p(reset_p),
        .clk_div_1000(clk_div_1000)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset_p = 1;
        #20 reset_p = 0;

        #12000;
        $finish;
    end
endmodule

module tb_shift_register_SISO_n;
    reg clk;
    reg reset_p;
    reg d;
    wire q;

    shift_register_SISO_n uut(
        .clk(clk), .reset_p(reset_p), .d(d), .q(q)
    );

    always #10 clk = ~clk;      // 클럭주기 20ns !!!!!! 

    initial begin
        clk = 0;
        reset_p = 1;
        d = 0;

        #15 reset_p = 0;

        // 1011 을 순차적으로 입력
        #15 d = 1;
        #20 d = 0;
        #20 d = 1;
        #20 d = 1;
        #40 d = 0;

        #60;
        $finish;
    end

endmodule

module tb_shift_register_SIPO_n;
    reg clk;
    reg reset_p;
    reg d;
    reg rd_en;
    wire [3:0] q;
    
    shift_register_SIPO_n uut(
        .clk(clk),
        .reset_p(reset_p),
        .d(d),
        .rd_en(rd_en),
        .q(q)
     );
     
     always #10 clk = ~clk;
     
     initial begin
        $display("==== SIPO 테스트 시작 ====");
        $dumpfile("sipo.vcd");                          //GTKWave
        $dumpvars(0, tb_shift_register_SIPO_n);         // 어떤 신호를 저장할지?? 0 -> 해당 모듈 포함 하위 모듈까지,, 
        
        
        clk = 0;
        reset_p = 1;
        d = 0;
        rd_en = 0;
        
        #15 reset_p = 0;
        //테스트 시나리오 d = 1, 0, 1, 1
        
        #15 d = 1;
        #20 d = 0;
        #20 d = 1;
        #20 d = 1;
        
        #10 rd_en = 0;
        #20 rd_en = 1;  // H-z
        #20 rd_en = 0;
        
        #30;
        $display("==== 테스트 종료 ====");
        
        $finish;
        
        
        
     end
     
endmodule



module tb_shift_register_PISO;
    reg clk;
    reg reset_p;
    reg [3:0] d;
    reg shift_load;
    wire q;

    shift_register_PISO uut(
        .clk(clk), .reset_p(reset_p), .d(d), .shift_load(shift_load), .q(q)
    );

    always #10 clk = ~clk;

    initial begin
        clk = 0;
        reset_p = 1;
        d = 4'b0000;
        shift_load = 0;
        
        #15 reset_p = 0;

        #20 d = 4'b1011;
        shift_load = 0;     // 데이터 로드
        #20;

        shift_load = 1;     // 시프트 모드
        #80;                // 4클럭 시프트 봐야지

        $finish;
    end
endmodule


module tb_register_Nbit_p;
    parameter N = 8;

    reg clk;
    reg reset_p;
    reg [N-1:0] d;
    reg wr_en;
    reg rd_en;
    wire [N-1:0] register_data;
    wire [N-1:0] q;

    register_Nbit_p #(N) uut(
        .clk(clk), .reset_p(reset_p), .d(d),
        .wr_en(wr_en), .rd_en(rd_en), .register_data(register_data), .q(q)
    );

    always #10 clk = ~clk;

    initial begin
        clk = 0;
        reset_p = 1;
        wr_en = 0;
        rd_en = 0;
        d = 0;

        #25 reset_p = 0;

        #20 d = 8'h3c;  wr_en = 1;
        #20 wr_en = 0;

        #20 rd_en = 1;
        #40;

        #20 rd_en = 0;
        #20;

        $finish;
    end

endmodule



module tb_memory;
    reg clk;
    reg reset_p;
    reg [7:0] i_data;
    reg [9:0] wr_addr;
    reg [9:0] rd_addr;
    wire [7:0] o_data;
    
    memory uut(
        .clk(clk), .reset_p(reset_p), .i_data(i_data), .wr_addr(wr_addr),
        .rd_addr(rd_addr), .o_data(o_data)
    );

    always #5 clk = ~clk;

    integer i, j;

    initial begin
        clk = 0;
        reset_p = 0;
        i_data = 0;
        wr_addr = 0;
        rd_addr = 0;

        #10 reset_p = 1; #10 reset_p = 0;

        $display("--- 쓰기 동작 시작 ---");
        for (i = 0; i < 10 ; i = i + 1) begin
            @(posedge clk);
            wr_addr = i;            // 주소 0, 1, 2......
            i_data = i + 10;        // 데이터는 10, 11, 12....
        end

        @(posedge clk);
        wr_addr = 0;
        i_data = 0;

        $display("--- 읽기 동작 시작 ---");
        for (j = 0; j < 10 ; j = j + 1 ) begin
            @(posedge clk);
            rd_addr = j;

            @(posedge clk);
            $display("Addr : %d, Data : %d",j, o_data);
        end
        #50 $finish;
    end
endmodule
    