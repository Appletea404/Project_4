`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////



module tb_and_gate;
    reg a, b;
    wire q;
    
    and_gate uut(.a(a), .b(b), .q(q));
    
    initial begin
        // test vector
        a = 0; b = 0; #10;
        a = 0; b = 1; #10;
        a = 1; b = 0; #10;
        a = 1; b = 1; #10;
        $finish;
    end
endmodule
