`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/16/2026 02:57:15 PM
// Design Name: 
// Module Name: and_gate
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


module and_gate(
    input a, b,
    output reg q
    );
    
    always @(a, b)begin
        case({a,b})
            2'b00 : q = 0;
            2'b01 : q = 0;
            2'b10 : q = 0;
            2'b11 : q = 1;            
        endcase
    end
    
endmodule
