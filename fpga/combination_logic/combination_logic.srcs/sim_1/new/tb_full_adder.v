


module tb_full_adder;
    reg a, b, cin;
    wire sum, carry;

    // full_adder_behavioral dut(
    //     .a(a),
    //     .b(b),
    //     .cin(cin),
    //     .sum(sum),
    //     .carry(carry)
    // );
    full_adder_structural dut(
        .a(a),
        .b(b),
        .cin(cin),
        .sum(sum),
        .carry(carry)
    );

    initial begin
        $display("Time\t a b cin | sum carry");
        // $monitor 는 한번만 선언하면 값이 바뀔때마다 자동 출력됨 
        $monitor("%4t\t%b %b %b | %b %b", $time, a, b, cin, sum, carry);
        // 입력값 변화
        a = 0; b = 0; cin = 0; #10;
        a = 0; b = 0; cin = 1; #10;
        a = 0; b = 1; cin = 0; #10;
        a = 1; b = 0; cin = 0; #10;
        a = 0; b = 1; cin = 1; #10;
        a = 1; b = 0; cin = 1; #10;
        a = 1; b = 1; cin = 0; #10;
        a = 1; b = 1; cin = 1; #10;
        $finish;
    end

endmodule




module tb_fadder_4bit_structural;


// 입 출력 신호 선언

    reg [3:0] a, b;
    reg cin;
    wire [3:0] sum;
    wire carry;
    
    fadder_4bit_structural uut(
        .a(a), .b(b), .cin(cin), .sum(sum), .carry(carry)
);

    initial begin
    
        cin = 0; a = 4'b0000; b = 4'b0000; #10;
        cin = 0; a = 4'b0001; b = 4'b0001; #10;
        cin = 1; a = 4'b0010; b = 4'b0011; #10;
        cin = 0; a = 4'b1111; b = 4'b0001; #10;
        cin = 1; a = 4'b1010; b = 4'b0101; #10;
        cin = 0; a = 4'b1111; b = 4'b1111; #10;
        cin = 1; a = 4'b1111; b = 4'b1111; #10;
        
        #10 $finish;
        
        end
        


endmodule




// N-bit fadder testbench
module tb_n_bit_adder;

    // 파라메터 맞춰야 함 !!
    parameter N = 8;

    reg [N-1:0] a, b;
    reg cin;
    wire [N-1:0] sum;
    wire carry;

    n_bit_adder_structural #(.N(N)) uut(
        .a(a),
        .b(b),
        .cin(cin),
        .sum(sum),
        .carry(carry)
    );

    initial begin
        // 초기값
        a = 0; b = 0; cin = 0;
        #10;     // 10나노 이후에

        // 100 + 50 = 150
        a = 8'd100; b = 8'd50; cin = 0;
        #10;

        // 200 + 100 -> 8비트 초과 캐리 발생
        a = 8'd200; b = 8'd100; cin = 0;
        #10;

        // 모든 비트가 1일때(최대값)
        a = {N{1'b1}};  // N비트를 모두 1로 채움
        b = {N{1'b1}};
        cin = 1;
        #10;

        repeat (5) begin
            #10;
            a = $random;
            b = $random;
            cin = $random % 2;
        end
        #20;
        $finish;
    end
    
endmodule