`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////


module tb_half_adder;


    reg a, b;
    wire sum, carry;

    half_adder_dataflow uut(
        .A(a),
        .B(b),
        .S(sum),
        .C(carry)
        
    );
    
    
    initial begin
        $display("Time\ta b | sum carry");
        $monitor("%4t\t%b %b | %b %b", $time, a, b, sum, carry);
        
        a = 0; b = 0; #10;
        a = 0; b = 1; #10;
        a = 1; b = 0; #10;
        a = 1; b = 1; #10;
    
        $finish;
        
        end
    
endmodule
