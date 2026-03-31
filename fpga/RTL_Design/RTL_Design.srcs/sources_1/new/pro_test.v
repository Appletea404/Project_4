`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/30/2026 04:10:51 PM
// Design Name: 
// Module Name: pro_test
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



// ==========================================================
// 1. TOP MODULE: 토글 방식 수동 제어 포함
// ==========================================================
module fan_system_top(
    input clk, reset_p,
    inout dht11_data,
    input btn_mode,       // 모드 전환 버튼 (BTNC) - 자동/수동
    input btn_manual,     // 수동 토글 버튼 (BTNU) - 켜짐/꺼짐
    output fan_pwm,
    output [7:0] seg,     // 7세그먼트 데이터
    output [3:0] an,      // 7세그먼트 자릿수 선택
    output led_mode,      // LD0: ON(수동), OFF(자동)
    output led_manual_on, // LD1: 수동 모드에서 팬이 켜졌을 때 점등
    output led_fan_on,    // LD15: 실제로 팬이 돌고 있을 때 점등
    output scl,
    inout  sda
);

    wire [7:0] current_temp, current_humi;
    reg mode_reg;          // 0: 자동, 1: 수동
    reg manual_fan_reg;    // 수동 모드일 때 팬의 온/오프 상태 저장
    
    wire btn_mode_pedge;
    wire btn_manual_pedge;
    wire fan_on_signal;
    reg [7:0] duty_val;

    // 1. 에지 검출기: 버튼을 누르는 '순간'만 펄스 발생
    edge_detector_p ed_mode (.clk(clk), .reset_p(reset_p), .cp(btn_mode), .p_edge(btn_mode_pedge));
    edge_detector_p ed_manual (.clk(clk), .reset_p(reset_p), .cp(btn_manual), .p_edge(btn_manual_pedge));
    
    // 2. 모드 전환 로직 (BTNC 누를 때마다 반전)
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) mode_reg <= 0;
        else if(btn_mode_pedge) mode_reg <= ~mode_reg;
    end
    assign led_mode = mode_reg;

    // 3. 수동 팬 토글 로직 (수동 모드에서 BTNU 누를 때마다 반전)
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) manual_fan_reg <= 0;
        else if(mode_reg) begin // 수동 모드일 때만 작동
            if(btn_manual_pedge) manual_fan_reg <= ~manual_fan_reg;
        end
        else manual_fan_reg <= 0; // 자동 모드로 돌아오면 수동 상태 초기화
    end
    assign led_manual_on = manual_fan_reg;

    // 4. DHT11 센서 읽기
    dht11_cntr u_dht11 (
        .clk(clk), .reset_p(reset_p), .dht11_data(dht11_data),
        .temperature(current_temp), .humidity(current_humi)
    );

    // 5. 최종 팬 구동 신호 결정
    // 자동 모드(mode_reg=0): 센서 조건 | 수동 모드(mode_reg=1): 토글 레지스터 상태
    assign fan_on_signal = mode_reg ? manual_fan_reg : (current_temp >= 31 || current_humi >= 70);
    assign led_fan_on = fan_on_signal;

    // 6. PWM 출력
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) duty_val <= 0;
        else duty_val <= fan_on_signal ? 8'd200 : 8'd0;
    end

    pwm_Nfreq_Nstep u_pwm (.clk(clk), .reset_p(reset_p), .duty(duty_val), .pwm(fan_pwm));

    // 7. 7세그먼트 표시 (온도/습도)
    fnd_4digit_control u_fnd (
        .clk(clk), .reset_p(reset_p),
        .value_left(current_temp), .value_right(current_humi),
        .seg(seg), .an(an)
    );

    // 8. LCD I2C 출력 (온도/습도)
    lcd_i2c_top u_lcd (
        .clk(clk), .reset_p(reset_p),
        .temperature(current_temp), .humidity(current_humi),
        .scl(scl), .sda(sda)
    );

endmodule

// ==========================================================
// 2. 7세그먼트 4자리 제어기 (변경 없음)
// ==========================================================
module fnd_4digit_control(
    input clk, reset_p,
    input [7:0] value_left, value_right,
    output reg [7:0] seg, output reg [3:0] an
);
    wire [3:0] temp_10 = value_left / 10;
    wire [3:0] temp_1  = value_left % 10;
    wire [3:0] humi_10 = value_right / 10;
    wire [3:0] humi_1  = value_right % 10;
    reg [16:0] clk_div;
    always @(posedge clk) clk_div <= clk_div + 1;
    always @(*) begin
        case(clk_div[16:15])
            2'b00: begin an = 4'b0111; seg = fnd_decoder(temp_10); end
            2'b01: begin an = 4'b1011; seg = fnd_decoder(temp_1);  end
            2'b10: begin an = 4'b1101; seg = fnd_decoder(humi_10); end
            2'b11: begin an = 4'b1110; seg = fnd_decoder(humi_1);  end
        endcase
    end
    function [7:0] fnd_decoder(input [3:0] num);
        case(num)
            4'h0: fnd_decoder = 8'hC0; 4'h1: fnd_decoder = 8'hF9;
            4'h2: fnd_decoder = 8'hA4; 4'h3: fnd_decoder = 8'hB0;
            4'h4: fnd_decoder = 8'h99; 4'h5: fnd_decoder = 8'h92;
            4'h6: fnd_decoder = 8'h82; 4'h7: fnd_decoder = 8'hF8;
            4'h8: fnd_decoder = 8'h80; 4'h9: fnd_decoder = 8'h90;
            default: fnd_decoder = 8'hFF;
        endcase
    endfunction
endmodule

// ==========================================================
// 5. UTILITY MODULES: DHT11, PWM, ETC
// ==========================================================
module dht11_cntr(
    input clk, reset_p, inout dht11_data,
    output reg [7:0] humidity, temperature, output [15:0] led);

    localparam S_IDLE=6'b000001, S_LOW_18MS=6'b000010, S_HIGH_20US=6'b000100,
               S_LOW_80US=6'b001000, S_HIGH_80US=6'b010000, S_READ_DATA=6'b100000;
    wire clk_usec_nedge, dht_nedge, dht_pedge;
    reg [21:0] count_usec; reg count_usec_e;
    clock_usec usec_clk_inst(.clk(clk), .reset_p(reset_p), .clk_usec_nedge(clk_usec_nedge));
    edge_detector_p ed_inst(.clk(clk), .reset_p(reset_p), .cp(dht11_data), .p_edge(dht_pedge), .n_edge(dht_nedge));
    reg dht11_data_buffer, dht11_data_out_e;
    assign dht11_data = dht11_data_out_e ? dht11_data_buffer : 'bz;
    reg [5:0] state;
    reg [39:0] temp_data; reg [5:0] cnt_data; reg read_state;

    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin state <= S_IDLE; temp_data <= 0; cnt_data <= 0; count_usec_e <= 0; dht11_data_out_e <= 0; humidity <= 0; temperature <= 0; end
        else begin
            if(clk_usec_nedge && count_usec_e) count_usec <= count_usec + 1;
            case(state)
                S_IDLE: begin count_usec_e <= 1; if(count_usec >= 3000000) begin count_usec <= 0; state <= S_LOW_18MS; end end
                S_LOW_18MS: begin dht11_data_out_e <= 1; dht11_data_buffer <= 0; if(count_usec >= 20000) begin count_usec <= 0; dht11_data_out_e <= 0; state <= S_HIGH_20US; end end
                S_HIGH_20US: if(dht_nedge) begin count_usec <= 0; state <= S_LOW_80US; end
                S_LOW_80US: if(dht_pedge) state <= S_HIGH_80US;
                S_HIGH_80US: if(dht_nedge) state <= S_READ_DATA;
                S_READ_DATA: begin
                    if(dht_pedge) begin read_state <= 1; count_usec <= 0; end
                    if(read_state == 1 && dht_nedge) begin
                        temp_data <= {temp_data[38:0], (count_usec > 50)};
                        cnt_data <= cnt_data + 1; read_state <= 0;
                    end
                    if(cnt_data >= 40) begin humidity <= temp_data[39:32]; temperature <= temp_data[23:16]; state <= S_IDLE; cnt_data <= 0; count_usec <= 0; end
                end
            endcase
        end
    end
endmodule

module pwm_Nfreq_Nstep(input clk, reset_p, input [7:0] duty, output pwm);
    reg [7:0] cnt; always @(posedge clk or posedge reset_p) if(reset_p) cnt <= 0; else cnt <= cnt + 1;
    assign pwm = (cnt < duty);
endmodule

module clock_usec(input clk, reset_p, output clk_usec_nedge);
    reg [6:0] cnt; always @(posedge clk or posedge reset_p) if(reset_p) cnt <= 0; else if(cnt >= 99) cnt <= 0; else cnt <= cnt + 1;
    assign clk_usec_nedge = (cnt == 99);
endmodule

module edge_detector_p(input clk, reset_p, cp, output p_edge, output n_edge);
    reg ff1, ff2; always @(posedge clk or posedge reset_p) if(reset_p) {ff1, ff2} <= 0; else {ff2, ff1} <= {ff1, cp};
    assign p_edge = ({ff2, ff1} == 2'b01); assign n_edge = ({ff2, ff1} == 2'b10);
endmodule


