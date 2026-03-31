`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////



module full_adder_behavioral(
    input a, b, cin,
    output reg sum, carry
    
    );
    always @(a,b,cin) begin
        case({a,b,cin})
            3'b000 : begin sum = 0; carry = 0; end //0+0+0 = sum 0, carry 0
            3'b001 : begin sum = 1; carry = 0; end //0+0+0 = sum 0, carry 0
            3'b010 : begin sum = 1; carry = 0; end //0+0+0 = sum 0, carry 0
            3'b011 : begin sum = 0; carry = 1; end //0+0+0 = sum 0, carry 0
            3'b100 : begin sum = 1; carry = 0; end //0+0+0 = sum 0, carry 0
            3'b101 : begin sum = 0; carry = 1; end //0+0+0 = sum 0, carry 0
            3'b110 : begin sum = 0; carry = 1; end //0+0+0 = sum 0, carry 0
            3'b111 : begin sum = 1; carry = 1; end //0+0+0 = sum 0, carry 0
        endcase
    
    




    end
endmodule




module full_adder_dataflow(
input a, b, cin,
output sum, carry
);

wire [1:0] sum_value;

assign sum_value = a + b + cin;

assign sum = sum_value[0];
assign carry = sum_value[1];
endmodule


module full_adder_structural(
input a, b, cin,
output sum, carry
);

wire sum_0;
wire carry_0;
wire carry_1;

half_adder_structural ha0(

.A(a),
.B(b),
.s(sum_0),
.c(carry_0)

);

   half_adder_structural ha1(
    .A(sum_0),
    .B(cin),
    .s(sum),
    .c(carry_1)
);



or (carry, carry_0, carry_1);


endmodule



module fadder_4bit_dataflow (
    input [3:0] a, b,
    input cin,
    output [3:0] sum,
    output carry
);
    wire [4:0] sum_value;
    
    assign sum_value = a + b +cin;
    
    assign sum = sum_value[3:0];
    assign carry = sum_value[4];
endmodule


module fadder_4bit_structural (

    input [3:0] a, b,
    input cin,
    output [3:0] sum,
    output carry
);
    wire [2:0] carry_w;
    
    full_adder_structural fa0(
        .a(a[0]), .b(b[0]), .cin(cin), .sum(sum[0]), .carry(carry_w[0])
);


    full_adder_structural fa1(
        .a(a[1]), .b(b[1]), .cin(carry_w[0]), .sum(sum[1]), .carry(carry_w[1])
);
    full_adder_structural fa2(
        .a(a[2]), .b(b[2]), .cin(carry_w[1]), .sum(sum[2]), .carry(carry_w[2])
);
    full_adder_structural fa3(
        .a(a[3]), .b(b[3]), .cin(carry_w[2]), .sum(sum[3]), .carry(carry)
);


endmodule
    
    
    
module n_bit_adder_structural #(
    parameter N = 8
)(
    input [N-1:0] a, b,
    input cin,
    output [N-1:0] sum,
    output carry
);

wire [N:0] carry_w;
assign carry_w[0] = cin;
assign carry = carry_w[N];

genvar i;     //generate  구문에서 사용할 반복 변수

generate

    for(i = 0; i < N; i = i + 1) begin : fa_loop
        full_adder_structural ga(
        .a(a[i]),
        .b(b[i]),
        .cin(carry_w[i]),
        .sum(sum[i]),
        .carry(carry_w[i+1])
        );
        
        
        
        
        end  
    endgenerate
endmodule    



