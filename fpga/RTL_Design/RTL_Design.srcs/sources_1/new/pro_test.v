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
// 1. TOP MODULE
// ==========================================================
// ==========================================================
// 1. TOP MODULE: 전체 시스템 연결 (Parallel 처리)
// ==========================================================
module fan_auto_system_top(
    input clk, reset_p,
    inout dht11_data,
    output fan_pwm,
    output led_fan_on,
    output scl, sda
);
    wire [7:0] current_temp, current_humi;
    wire fan_on_condition;
    
    // 설정 온도/습도 임계값 (테스트를 위해 낮게 설정 가능)
    parameter TEMP_THRESHOLD = 8'd26; 
    parameter HUMI_THRESHOLD = 8'd70; 

    // [모듈 1] DHT11 센서 제어기 (온습도 읽기)
    dht11_cntr u_dht11 (
        .clk(clk), .reset_p(reset_p), .dht11_data(dht11_data),
        .temperature(current_temp), .humidity(current_humi), .led()
    );

    // [모듈 2] 선풍기 작동 조건 (온도 OR 습도)
    assign fan_on_condition = (current_temp >= TEMP_THRESHOLD || current_humi >= HUMI_THRESHOLD);
    assign led_fan_on = fan_on_condition; // 조건 만족 시 LD15 점등

    // [모듈 3] PWM 생성기 (모터 제어)
    pwm_Nfreq_Nstep u_pwm (
        .clk(clk), .reset_p(reset_p), 
        .duty(fan_on_condition ? 8'd200 : 8'd0), 
        .pwm(fan_pwm)
    );

    // [모듈 4] I2C LCD 컨트롤러 (화면 출력)
    i2c_lcd_main_control u_lcd (
        .clk(clk), .reset_p(reset_p),
        .temperature(current_temp), .humidity(current_humi),
        .scl(scl), .sda(sda)
    );
endmodule

// ==========================================================
// 2. LCD MAIN CONTROL: 초기화 대기 시간 강화 버전
// ==========================================================
module i2c_lcd_main_control(
    input clk, reset_p,
    input [7:0] temperature, humidity,
    output scl, sda
);
    localparam LCD_ADDR = 7'h3F; // 안 나오면 7'h3F로 변경

    reg [7:0] send_buffer;
    reg send, rs;
    wire busy;

    i2c_lcd_send_byte lcd_send_inst (
        .clk(clk), .reset_p(reset_p), .addr(LCD_ADDR),
        .send_buffer(send_buffer), .send(send), .rs(rs),
        .scl(scl), .sda(sda), .busy(busy)
    );

    wire [7:0] t10 = (temperature / 10) + 8'h30;
    wire [7:0] t1  = (temperature % 10) + 8'h30;
    wire [7:0] h10 = (humidity / 10) + 8'h30;
    wire [7:0] h1  = (humidity % 10) + 8'h30;

    reg [5:0] state;
    reg [23:0] wait_cnt;

    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin 
            state <= 0; send <= 0; rs <= 0; wait_cnt <= 0; 
        end else begin
            case(state)
                // 전원 인가 후 LCD 안정화 대기 (약 100ms)
                0: begin
                    if(wait_cnt >= 24'd10_000_000) begin wait_cnt <= 0; state <= 1; end
                    else wait_cnt <= wait_cnt + 1;
                end
                // 정석 초기화 시퀀스
                1: if(!busy) begin send_buffer <= 8'h33; rs <= 0; send <= 1; state <= 2; end
                2: begin send <= 0; state <= 3; end
                3: if(!busy) begin send_buffer <= 8'h32; rs <= 0; send <= 1; state <= 4; end
                4: begin send <= 0; state <= 5; end
                5: if(!busy) begin send_buffer <= 8'h28; rs <= 0; send <= 1; state <= 6; end
                6: begin send <= 0; state <= 7; end
                7: if(!busy) begin send_buffer <= 8'h0C; rs <= 0; send <= 1; state <= 8; end
                8: begin send <= 0; state <= 9; end
                9: if(!busy) begin send_buffer <= 8'h01; rs <= 0; send <= 1; state <= 10; end
                10: begin send <= 0; state <= 11; end

                // 첫 줄 출력 "T:XXC"
                11: if(!busy) begin send_buffer <= 8'h80; rs <= 0; send <= 1; state <= 12; end
                12: begin send <= 0; state <= 13; end
                13: if(!busy) begin send_buffer <= "T"; rs <= 1; send <= 1; state <= 14; end
                14: begin send <= 0; state <= 15; end
                15: if(!busy) begin send_buffer <= ":"; rs <= 1; send <= 1; state <= 16; end
                16: begin send <= 0; state <= 17; end
                17: if(!busy) begin send_buffer <= t10; rs <= 1; send <= 1; state <= 18; end
                18: begin send <= 0; state <= 19; end
                19: if(!busy) begin send_buffer <= t1; rs <= 1; send <= 1; state <= 20; end
                20: begin send <= 0; state <= 21; end
                21: if(!busy) begin send_buffer <= "C"; rs <= 1; send <= 1; state <= 22; end
                22: begin send <= 0; state <= 23; end

                // 둘째 줄 출력 "H:XX%"
                23: if(!busy) begin send_buffer <= 8'hC0; rs <= 0; send <= 1; state <= 24; end
                24: begin send <= 0; state <= 25; end
                25: if(!busy) begin send_buffer <= "H"; rs <= 1; send <= 1; state <= 26; end
                26: begin send <= 0; state <= 27; end
                27: if(!busy) begin send_buffer <= ":"; rs <= 1; send <= 1; state <= 28; end
                28: begin send <= 0; state <= 29; end
                29: if(!busy) begin send_buffer <= h10; rs <= 1; send <= 1; state <= 30; end
                30: begin send <= 0; state <= 31; end
                31: if(!busy) begin send_buffer <= h1; rs <= 1; send <= 1; state <= 32; end
                32: begin send <= 0; state <= 33; end
                33: if(!busy) begin send_buffer <= "%"; rs <= 1; send <= 1; state <= 34; end
                34: begin send <= 0; state <= 35; end

                // 화면 갱신 대기 (약 0.5초)
                35: begin 
                    if(wait_cnt >= 24'd10_000_000) begin wait_cnt <= 0; state <= 11; end
                    else wait_cnt <= wait_cnt + 1;
                end
                default: state <= 0;
            endcase
        end
    end
endmodule

// ==========================================================
// 3. I2C LCD SEND BYTE: 바이트 분할 전송
// ==========================================================
module i2c_lcd_send_byte(
    input clk, reset_p,
    input [6:0] addr, input [7:0] send_buffer,
    input send, rs,
    output scl, sda, output reg busy
);
    localparam IDLE=3'd0, SHD=3'd1, SHE=3'd2, SLD=3'd3, SLE=3'd4, SD=3'd5;
    wire clk_usec_nedge, send_pedge, i2c_busy;
    reg [21:0] count_usec; reg count_usec_e, comm_start;
    reg [7:0] data; reg [2:0] state;

    clock_usec usec_clk(.clk(clk), .reset_p(reset_p), .clk_usec_nedge(clk_usec_nedge));
    edge_detector_p ed_start(.clk(clk), .reset_p(reset_p), .cp(send), .p_edge(send_pedge));
    
    // I2C Master 연결
    I2C_master master_inst (.clk(clk), .reset_p(reset_p), .addr(addr), .data(data), .rw(1'b0), .start(comm_start), .scl(scl), .sda(sda), .busy(i2c_busy));

    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin 
            state <= IDLE; comm_start <= 0; count_usec_e <= 0; busy <= 0; count_usec <= 0; 
        end else begin
            if(clk_usec_nedge && count_usec_e) count_usec <= count_usec + 1;
            case(state)
                IDLE: begin busy <= 0; if(send_pedge) begin busy <= 1; state <= SHD; count_usec <= 0; end end
                SHD: begin count_usec_e <= 1; data <= {send_buffer[7:4], 3'b100, rs}; comm_start <= 1; 
                     if(count_usec >= 200) begin comm_start <= 0; state <= SHE; count_usec <= 0; end end
                SHE: begin count_usec_e <= 1; data <= {send_buffer[7:4], 3'b110, rs}; comm_start <= 1; 
                     if(count_usec >= 200) begin comm_start <= 0; state <= SLD; count_usec <= 0; end end
                SLD: begin count_usec_e <= 1; data <= {send_buffer[3:0], 3'b100, rs}; comm_start <= 1; 
                     if(count_usec >= 200) begin comm_start <= 0; state <= SLE; count_usec <= 0; end end
                SLE: begin count_usec_e <= 1; data <= {send_buffer[3:0], 3'b110, rs}; comm_start <= 1; 
                     if(count_usec >= 200) begin comm_start <= 0; state <= SD; count_usec <= 0; end end
                SD:  begin count_usec_e <= 1; data <= {send_buffer[3:0], 3'b100, rs}; comm_start <= 1; 
                     if(count_usec >= 200) begin comm_start <= 0; state <= IDLE; count_usec <= 0; count_usec_e <= 0; end end
            endcase
        end
    end
endmodule

// ==========================================================
// 4. I2C MASTER: 합성 에러 방지 버전 (Perfect)
// ==========================================================
module I2C_master(
    input clk, reset_p,
    input [6:0] addr, input [7:0] data, input rw, input start,
    output reg scl, inout sda, output reg busy
);
    parameter IDLE=4'd0, START=4'd1, ADDR=4'd2, ACK1=4'd3, DATA=4'd4, ACK2=4'd5, STOP=4'd6;
    reg [3:0] state;
    reg [6:0] addr_reg; reg [7:0] data_reg; reg rw_reg;
    reg [3:0] bit_cnt; reg sda_out, sda_en;
    assign sda = sda_en ? sda_out : 1'bz;

    reg [8:0] clk_cnt; reg i2c_clk;
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin clk_cnt <= 0; i2c_clk <= 0; end
        else if(clk_cnt >= 249) begin clk_cnt <= 0; i2c_clk <= ~i2c_clk; end
        else clk_cnt <= clk_cnt + 1;
    end

    always @(posedge i2c_clk or posedge reset_p) begin
        if(reset_p) begin 
            state <= IDLE; bit_cnt <= 7; busy <= 0; scl <= 1; sda_out <= 1; sda_en <= 1; 
        end else begin
            case(state)
                IDLE: begin 
                    busy <= 0; scl <= 1; sda_out <= 1; sda_en <= 1;
                    if(start) begin state <= START; addr_reg <= addr; data_reg <= data; rw_reg <= rw; busy <= 1; end
                end
                START: begin sda_out <= 0; state <= ADDR; end
                ADDR: begin 
                    scl <= ~scl; 
                    if(scl) begin
                        if(bit_cnt > 0) sda_out <= addr_reg[bit_cnt-1];
                        else sda_out <= rw_reg;
                        if(bit_cnt == 0) begin state <= ACK1; bit_cnt <= 7; end
                        else bit_cnt <= bit_cnt - 1;
                    end
                end
                ACK1: begin scl <= ~scl; if(scl) begin sda_en <= 0; state <= DATA; end end
                DATA: begin 
                    scl <= ~scl; sda_en <= 1;
                    if(scl) begin
                        sda_out <= data_reg[bit_cnt];
                        if(bit_cnt == 0) begin state <= ACK2; bit_cnt <= 7; end
                        else bit_cnt <= bit_cnt - 1;
                    end
                end
                ACK2: begin scl <= ~scl; if(scl) begin sda_en <= 0; state <= STOP; end end
                STOP: begin 
                    if(!scl) scl <= 1;
                    else begin sda_en <= 1; sda_out <= 1; state <= IDLE; end
                end
            endcase
        end
    end
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