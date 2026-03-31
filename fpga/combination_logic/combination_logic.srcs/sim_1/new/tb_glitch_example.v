`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/23/2026 10:02:42 AM
// Design Name: 
// Module Name: tb_glitch_example
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


module tb_glitch_example;



    reg a, b;
    wire y;
    
    glitch_example uut(
    
        .a(a),
        .b(b),
        .y(y)
    );
    
    initial begin
        a = 0;
        b = 1;
        
        #10 a = 1;
        #10 a = 0;
        #10 $finish;
    
            // a= 0 -> 1 ->

    end
endmodule
