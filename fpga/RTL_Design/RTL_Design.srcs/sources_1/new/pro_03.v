`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/30/2026 03:40:01 PM
// Design Name: 
// Module Name: pro_03
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
// 1. TOP MODULE: 전체 시스템 연결
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
    
    // 설정 온도/습도 임계값
    parameter TEMP_THRESHOLD = 8'd26; 
    parameter HUMI_THRESHOLD = 8'd70; 

    // [모듈 1] DHT11 센서 제어기 (온습도 읽기)
    dht11_cntr u_dht11 (
        .clk(clk), .reset_p(reset_p), .dht11_data(dht11_data),
        .temperature(current_temp), .humidity(current_humi), .led()
    );

    // [모듈 2] 선풍기 작동 로직 (온도 OR 습도 조건)
    assign fan_on_condition = (current_temp >= TEMP_THRESHOLD || current_humi >= HUMI_THRESHOLD);
    assign led_fan_on = fan_on_condition; // 조건 만족 시 LD15 점등

    // [모듈 3] PWM 생성기
    pwm_Nfreq_Nstep u_pwm (
        .clk(clk), .reset_p(reset_p), 
        .duty(fan_on_condition ? 8'd200 : 8'd0), 
        .pwm(fan_pwm)
    );

    // [모듈 4] I2C LCD 컨트롤러
    i2c_lcd_main_control u_lcd (
        .clk(clk), .reset_p(reset_p),
        .temperature(current_temp), .humidity(current_humi),
        .scl(scl), .sda(sda)
    );
endmodule

// ==========================================================
// 2. LCD MAIN CONTROL: 화면 데이터 구성
// ==========================================================
module i2c_lcd_main_control(
    input clk, reset_p,
    input [7:0] temperature, humidity,
    output scl, sda
);
    localparam LCD_ADDR = 7'h27; 

    reg [7:0] send_buffer;
    reg send, rs;
    wire busy;

    i2c_lcd_send_byte lcd_send_inst (
        .clk(clk), .reset_p(reset_p), .addr(LCD_ADDR),
        .send_buffer(send_buffer), .send(send), .rs(rs),
        .scl(scl), .sda(sda), .busy(busy), .led()
    );

    // 숫자를 ASCII로 변환
    wire [7:0] t10 = (temperature / 10) + 8'h30;
    wire [7:0] t1  = (temperature % 10) + 8'h30;
    wire [7:0] h10 = (humidity / 10) + 8'h30;
    wire [7:0] h1  = (humidity % 10) + 8'h30;

    reg [5:0] state;
    reg [21:0] wait_cnt;

    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin state <= 0; send <= 0; rs <= 0; wait_cnt <= 0; end
        else begin
            case(state)
                0: if(!busy) begin send_buffer <= 8'h33; rs <= 0; send <= 1; state <= 1; end
                1: begin send <= 0; state <= 2; end
                2: if(!busy) begin send_buffer <= 8'h0C; rs <= 0; send <= 1; state <= 3; end
                3: begin send <= 0; state <= 4; end
                4: if(!busy) begin send_buffer <= 8'h80; rs <= 0; send <= 1; state <= 5; end
                5: begin send <= 0; state <= 6; end
                6: if(!busy) begin send_buffer <= "T"; rs <= 1; send <= 1; state <= 7; end
                7: begin send <= 0; state <= 8; end
                8: if(!busy) begin send_buffer <= ":"; rs <= 1; send <= 1; state <= 9; end
                9: begin send <= 0; state <= 10; end
                10: if(!busy) begin send_buffer <= t10; rs <= 1; send <= 1; state <= 11; end
                11: begin send <= 0; state <= 12; end
                12: if(!busy) begin send_buffer <= t1; rs <= 1; send <= 1; state <= 13; end
                13: begin send <= 0; state <= 14; end
                14: if(!busy) begin send_buffer <= "C"; rs <= 1; send <= 1; state <= 15; end
                15: begin send <= 0; state <= 16; end
                16: if(!busy) begin send_buffer <= 8'hC0; rs <= 0; send <= 1; state <= 17; end
                17: begin send <= 0; state <= 18; end
                18: if(!busy) begin send_buffer <= "H"; rs <= 1; send <= 1; state <= 19; end
                19: begin send <= 0; state <= 20; end
                20: if(!busy) begin send_buffer <= ":"; rs <= 1; send <= 1; state <= 21; end
                21: begin send <= 0; state <= 22; end
                22: if(!busy) begin send_buffer <= h10; rs <= 1; send <= 1; state <= 23; end
                23: begin send <= 0; state <= 24; end
                24: if(!busy) begin send_buffer <= h1; rs <= 1; send <= 1; state <= 25; end
                25: begin send <= 0; state <= 26; end
                26: if(!busy) begin send_buffer <= "%"; rs <= 1; send <= 1; state <= 27; end
                27: begin send <= 0; state <= 28; end
                28: begin 
                    if(wait_cnt >= 22'd1_000_000) begin wait_cnt <= 0; state <= 4; end
                    else wait_cnt <= wait_cnt + 1;
                end
                default: state <= 0;
            endcase
        end
    end
endmodule

// ==========================================================
// 3. I2C LCD SEND BYTE
// ==========================================================
module i2c_lcd_send_byte(
    input clk, reset_p,
    input [6:0] addr, input [7:0] send_buffer,
    input send, rs,
    output scl, sda, output reg busy, output [15:0] led
);
    localparam IDLE=6'b000001, SHD=6'b000010, SHE=6'b000100, SLD=6'b001000, SLE=6'b010000, SD=6'b100000;
    wire clk_usec_nedge, send_pedge, i2c_busy;
    reg [21:0] count_usec; reg count_usec_e, comm_start;
    reg [7:0] data; reg [5:0] state, next_state;

    clock_usec usec_clk(.clk(clk), .reset_p(reset_p), .clk_usec_nedge(clk_usec_nedge));
    edge_detector_p ed_start(.clk(clk), .reset_p(reset_p), .cp(send), .p_edge(send_pedge));
    I2C_master master(clk, reset_p, addr, data, 1'b0, comm_start, scl, sda, i2c_busy, led);

    always @(negedge clk or posedge reset_p) begin
        if(reset_p) count_usec <= 0;
        else if(clk_usec_nedge && count_usec_e) count_usec <= count_usec + 1;
        else if(!count_usec_e) count_usec <= 0;
    end
    always @(negedge clk or posedge reset_p) if(reset_p) state <= IDLE; else state <= next_state;
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin next_state <= IDLE; comm_start <= 0; count_usec_e <= 0; busy <= 0; end
        else begin
            case(state)
                IDLE: begin busy <= 0; if(send_pedge) begin busy <= 1; next_state <= SHD; end end
                SHD: if(count_usec >= 200) begin comm_start <= 0; next_state <= SHE; count_usec_e <= 0; end
                     else begin data <= {send_buffer[7:4], 3'b100, rs}; comm_start <= 1; count_usec_e <= 1; end
                SHE: if(count_usec >= 200) begin comm_start <= 0; next_state <= SLD; count_usec_e <= 0; end
                     else begin data <= {send_buffer[7:4], 3'b110, rs}; comm_start <= 1; count_usec_e <= 1; end
                SLD: if(count_usec >= 200) begin comm_start <= 0; next_state <= SLE; count_usec_e <= 0; end
                     else begin data <= {send_buffer[3:0], 3'b100, rs}; comm_start <= 1; count_usec_e <= 1; end
                SLE: if(count_usec >= 200) begin comm_start <= 0; next_state <= SD; count_usec_e <= 0; end
                     else begin data <= {send_buffer[3:0], 3'b110, rs}; comm_start <= 1; count_usec_e <= 1; end
                SD:  if(count_usec >= 200) begin comm_start <= 0; next_state <= IDLE; count_usec_e <= 0; end
                     else begin data <= {send_buffer[3:0], 3'b100, rs}; comm_start <= 1; count_usec_e <= 1; end
            endcase
        end
    end
endmodule

// [I2C 엔진 - 합성 오류 수정 완료]
module I2C_master(
    input clk, reset_p,
    input [6:0] addr, input [7:0] data, input rw, input start,
    output reg scl, inout sda, output reg busy, output [15:0] led
);
    parameter IDLE=4'd0, START=4'd1, ADDR=4'd2, ACK1=4'd3, DATA=4'd4, ACK2=4'd5, STOP=4'd6;
    reg [3:0] state, next_state;
    reg [6:0] addr_reg; reg [7:0] data_reg; reg rw_reg;
    reg [3:0] bit_cnt; reg sda_out, sda_en;
    assign sda = sda_en ? sda_out : 1'bz;
    assign led = {12'd0, state};

    reg [8:0] clk_cnt; reg i2c_clk;
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin clk_cnt <= 0; i2c_clk <= 0; end
        else if(clk_cnt == 249) begin clk_cnt <= 0; i2c_clk <= ~i2c_clk; end
        else clk_cnt <= clk_cnt + 1;
    end
    always @(posedge i2c_clk or posedge reset_p) if(reset_p) state <= IDLE; else state <= next_state;
    always @(*) begin
        next_state = state;
        case(state)
            IDLE: if(start) next_state = START;
            START: next_state = ADDR;
            ADDR: if(bit_cnt == 0) next_state = ACK1;
            ACK1: next_state = DATA;
            DATA: if(bit_cnt == 0) next_state = ACK2;
            ACK2: next_state = STOP;
            STOP: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    // 출력 로직에서 scl 신호 직접 참조 제거
    always @(negedge i2c_clk or posedge reset_p) begin
        if(reset_p) begin bit_cnt <= 7; busy <= 0; scl <= 1; sda_out <= 1; sda_en <= 1; end
        else begin
            case(state)
                IDLE: begin busy <= 0; scl <= 1; sda_out <= 1; sda_en <= 1; if(start) begin addr_reg <= addr; data_reg <= data; rw_reg <= rw; end end
                START: begin busy <= 1; sda_out <= 0; end
                ADDR: begin scl <= i2c_clk; sda_out <= (bit_cnt > 0) ? addr_reg[bit_cnt-1] : rw_reg; if(bit_cnt == 0) bit_cnt <= 7; else bit_cnt <= bit_cnt - 1; end
                ACK1: begin scl <= i2c_clk; sda_en <= 0; end
                DATA: begin scl <= i2c_clk; sda_en <= 1; sda_out <= data_reg[bit_cnt]; if(bit_cnt == 0) bit_cnt <= 7; else bit_cnt <= bit_cnt - 1; end
                ACK2: begin scl <= i2c_clk; sda_en <= 0; end
                STOP: begin scl <= 1; sda_en <= 1; sda_out <= 1; end
            endcase
        end
    end
endmodule

// ==========================================================
// 4. UTILITY MODULES
// ==========================================================
module dht11_cntr(
    input clk, reset_p, inout dht11_data,
    output reg [7:0] humidity, temperature, output [15:0] led);

    localparam S_IDLE=6'b000001, S_LOW_18MS=6'b000010, S_HIGH_20US=6'b000100,
               S_LOW_80US=6'b001000, S_HIGH_80US=6'b010000, S_READ_DATA=6'b100000;
    wire clk_usec_nedge, dht_nedge, dht_pedge;
    reg [21:0] count_usec; reg count_usec_e;
    clock_usec usec_clk(.clk(clk), .reset_p(reset_p), .clk_usec_nedge(clk_usec_nedge));
    edge_detector_p ed(.clk(clk), .reset_p(reset_p), .cp(dht11_data), .p_edge(dht_pedge), .n_edge(dht_nedge));
    reg dht11_data_buffer, dht11_data_out_e;
    assign dht11_data = dht11_data_out_e ? dht11_data_buffer : 'bz;
    reg [5:0] state, next_state;
    always @(negedge clk or posedge reset_p) if(reset_p) state <= S_IDLE; else state <= next_state;
    reg [39:0] temp_data; reg [5:0] cnt_data; reg read_state;
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin next_state <= S_IDLE; temp_data <= 0; cnt_data <= 0; count_usec_e <= 0; dht11_data_out_e <= 0; end
        else begin
            case(state)
                S_IDLE: if(count_usec < 3000000) begin count_usec_e <= 1; dht11_data_out_e <= 0; end else begin count_usec_e <= 0; next_state <= S_LOW_18MS; end
                S_LOW_18MS: if(count_usec < 20000) begin count_usec_e <= 1; dht11_data_out_e <= 1; dht11_data_buffer <= 0; end else begin count_usec_e <= 0; dht11_data_out_e <= 0; next_state <= S_HIGH_20US; end
                S_HIGH_20US: if(dht_nedge) next_state <= S_LOW_80US;
                S_LOW_80US: if(dht_pedge) next_state <= S_HIGH_80US;
                S_HIGH_80US: if(dht_nedge) next_state <= S_READ_DATA;
                S_READ_DATA: begin
                    if(dht_pedge) read_state <= 1;
                    if(read_state == 1 && dht_nedge) begin
                        temp_data <= {temp_data[38:0], (count_usec > 50)};
                        cnt_data <= cnt_data + 1; read_state <= 0;
                    end
                    if(cnt_data >= 40) begin humidity <= temp_data[39:32]; temperature <= temp_data[23:16]; next_state <= S_IDLE; cnt_data <= 0; end
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