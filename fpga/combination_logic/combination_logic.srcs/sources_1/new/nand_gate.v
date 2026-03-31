`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////


module nand_gate(
    input a, b,
    output reg q);
    
    always @(a,b) begin
        if (a == 1'b1 && b == 1'b1)
            q = 1'b0;
        else
            q = 1'b1;
    end
endmodule

module nand_gate_structual(
    input a, b,
    output q);
    
    nand U1(q, a, b);
endmodule

module nand_gate_dataflow(
    input a, b,
    output q);
    
    assign q = ~(a & b);
 
endmodule