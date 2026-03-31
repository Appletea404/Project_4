`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/23/2026 09:59:56 AM
// Design Name: 
// Module Name: glitch_example
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


module glitch_example(


    input a, b,
    output y
    );
    
    wire w1, w2;
    
    
   //서로 다른 delay
   
   
   assign #5 w1 = a & b;
   assign #2 w2 = ~a & b;


   assign #1 y = w1 | w2;
    

endmodule
