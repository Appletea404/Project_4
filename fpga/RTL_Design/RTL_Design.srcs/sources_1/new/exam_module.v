`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/25/2026 02:56:32 PM
// Design Name: 
// Module Name: exam_module
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


module watch(
    input clk, reset_p,
    input [2:0] btn,
    output reg [7:0] sec, min
    );

    reg set_watch;      // 시계설정 모드
    
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) set_watch = 0;
        else if(btn[0]) set_watch = ~set_watch; // 모드 전환(btn[0] 토글)
    end

    integer cnt_sysclk;     // 시간 1초짜리 만들라고
    always @(posedge clk ) begin
        if(reset_p) begin
            cnt_sysclk = 0;
            sec = 0;
            min = 0;
        end
        else begin
            if(set_watch) begin
                // btn[1] -> 초 증가
                if(btn[1])begin
                    if(sec >= 59) sec = 0;
                    else sec = sec + 1;
                end
                // btn[2] -> 분 증가
                if(btn[2])begin
                    if(min >= 59) min = 0;
                    else min = min + 1;
                end
            end
            else begin
                // 100MHz 기준 1초
                if(cnt_sysclk >= 27'd99_999_999)begin
                    cnt_sysclk = 0;

                    //초 증가
                    if(sec >= 59)begin
                        sec = 0;
                        //분 증가
                        if(min>=59) min = 0;
                        else min = min + 1;
                    end
                    else sec = sec + 1;
                end
                else cnt_sysclk = cnt_sysclk + 1;   //클럭 카운트 증가
            end
        end
    end

endmodule



module top_watch(
    input clk,            // Basys 3 기본 클럭 (100MHz)
    input reset_p,        // 중앙 버튼 (BTNC)
    input [2:0] btn,      // BTNU(0), BTNL(1), BTNR(2) 등 사용
    output [7:0] seg,     // 7세그먼트 LED 패턴
    output [3:0] an       // 4자리 중 어느 것을 켤지 결정 (Digit Select)
    );

    wire [7:0] sec, min;
    reg [3:0] btn_reg; 
    wire [2:0] btn_pulse;

    // --- 1. 버튼 엣지 검출 (디바운싱 대용 간단 로직) ---
    // 버튼을 누르는 순간 1클럭 동안만 1이 됨
    reg [21:0] clk_div_btn;
    always @(posedge clk) clk_div_btn <= clk_div_btn + 1;
    wire btn_clk = clk_div_btn[16]; // 약 1.5ms 주기로 샘플링

    reg [2:0] btn_f1, btn_f2;
    always @(posedge btn_clk) begin
        btn_f1 <= btn;
        btn_f2 <= btn_f1;
    end
    assign btn_pulse = btn_f1 & ~btn_f2; // Rising Edge 검출

    // --- 2. 시계 로직 (사용자 코드 수정 보완) ---
    watch my_watch(
        .clk(clk),
        .reset_p(reset_p),
        .btn_pulse(btn_pulse), // 엣지 검출된 신호 전달
        .sec(sec),
        .min(min)
    );

    // --- 3. 7세그먼트 멀티플렉싱 제어 ---
    reg [17:0] clk_div;
    always @(posedge clk) clk_div <= clk_div + 1;

    wire [1:0] sel = clk_div[17:16]; // 4자리를 순환 선택 (약 380Hz)
    reg [3:0] hex_value;
    reg [3:0] an_reg;

    always @(*) begin
        case(sel)
            2'b00: begin hex_value = sec % 10; an_reg = 4'b1110; end // 초 일의자리
            2'b01: begin hex_value = sec / 10; an_reg = 4'b1101; end // 초 십의자리
            2'b10: begin hex_value = min % 10; an_reg = 4'b1011; end // 분 일의자리
            2'b11: begin hex_value = min / 10; an_reg = 4'b0111; end // 분 십의자리
        endcase
    end

    assign an = an_reg;
    seg_decoder my_decoder(.hex_value(hex_value), .seg(seg));

endmodule

// 수정된 watch 모듈
module watch(
    input clk, reset_p,
    input [2:0] btn_pulse,
    output reg [7:0] sec, min
    );

    reg set_watch;
    
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) set_watch <= 0;
        else if(btn_pulse[0]) set_watch <= ~set_watch; 
    end

    integer cnt_sysclk;
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            cnt_sysclk <= 0;
            sec <= 0;
            min <= 0;
        end
        else begin
            if(set_watch) begin
                if(btn_pulse[1]) begin
                    if(sec >= 59) sec <= 0;
                    else sec <= sec + 1;
                end
                if(btn_pulse[2]) begin
                    if(min >= 59) min <= 0;
                    else min <= min + 1;
                end
            end
            else begin
                if(cnt_sysclk >= 99_999_999) begin
                    cnt_sysclk <= 0;
                    if(sec >= 59) begin
                        sec <= 0;
                        if(min >= 59) min <= 0;
                        else min <= min + 1;
                    end
                    else sec <= sec + 1;
                end
                else cnt_sysclk <= cnt_sysclk + 1;
            end
        end
    end
endmodule





module hc_sr04_cntr(
    input clk, reset_p,
    input echo,
    output reg trig,
    output reg [8:0] distance_cm);
    
    localparam time_1cm = 58;

    integer cnt_sysclk, cnt_sysclk0, cnt_usec;
    reg count_usec_e; 
    reg [8:0] cnt_cm; 
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)begin
            cnt_sysclk0 = 0;
            cnt_usec = 0;
            cnt_cm = 0;
        end
        else if(count_usec_e)begin
            if(cnt_sysclk0 >= 99)begin
                cnt_sysclk0 = 0;
                if(cnt_usec >= time_1cm - 1)begin
                    cnt_usec = 0;
                    cnt_cm = cnt_cm + 1;
                end
                else cnt_usec = cnt_usec + 1;
            end
            else cnt_sysclk0 = cnt_sysclk0 + 1;
        end
        else begin
            cnt_sysclk0 = 0;
            cnt_usec = 0;
            cnt_cm = 0;
        end
    end
    
    always @(posedge clk)cnt_sysclk = cnt_sysclk + 1;
    wire cnt26_pedge, cnt9_pedge;
    edge_detector_n ed26(.clk(clk), .reset_p(reset_p),
                       .cp(cnt_sysclk[24]), .p_edge(cnt26_pedge));
    edge_detector_n ed9(.clk(clk), .reset_p(reset_p),
                       .cp(cnt_sysclk[9]), .p_edge(cnt9_pedge));
                       
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)trig = 0;
        else if(cnt26_pedge)trig = 1;
        else if(cnt9_pedge)trig = 0;
    end
    
    wire echo_pedge, echo_nedge;
    edge_detector_n ed_echo(.clk(clk), .reset_p(reset_p),
                       .cp(echo), .p_edge(echo_pedge), .n_edge(echo_nedge));
                     
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)begin
            distance_cm = 0;
            count_usec_e = 0;
        end
        else if(echo_pedge)begin
            count_usec_e = 1;
        end
        else if(echo_nedge)begin
            distance_cm = cnt_cm;
            count_usec_e = 0;
        end
    end
endmodule



module top_ultrasonic(
    input clk, reset_p,
    input echo,
    output trig,
    output [7:0] seg,
    output [3:0] an
);
    wire [8:0] distance;
    wire [3:0] d100, d10, d1;

    // 1. 초음파 센서 제어
    hc_sr04_cntr hc_inst(
        .clk(clk), .reset_p(reset_p),
        .echo(echo), .trig(trig),
        .distance_cm(distance)
    );

    // 2. 거리값을 10진수로 변환
    bin_to_bcd bcd_inst(
        .bin(distance),
        .bcd2(d100), .bcd1(d10), .bcd0(d1)
    );

    // 3. 세븐 세그먼트에 표시
    fnd_controller fnd_inst(
        .clk(clk), .reset_p(reset_p),
        .digit3(4'h0), .digit2(d100), .digit1(d10), .digit0(d1),
        .seg(seg), .an(an)
    );
endmodule


module fnd_controller(
    input clk, reset_p,
    input [3:0] digit3, digit2, digit1, digit0, // 각 자리수 데이터
    output reg [7:0] seg, // a, b, c, d, e, f, g, dp
    output reg [3:0] an   // digit 선택 (Common Anode)
);
    // 1ms 스캔 클럭 생성 (100MHz / 100,000)
    integer cnt;
    reg [1:0] fnd_sel;
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin cnt <= 0; fnd_sel <= 0; end
        else if(cnt >= 99999) begin cnt <= 0; fnd_sel <= fnd_sel + 1; end
        else cnt <= cnt + 1;
    end

    // 자릿수 선택 및 데이터 출력
    reg [3:0] hex_value;
    always @(*) begin
        case(fnd_sel)
            2'b00: begin an = 4'b1110; hex_value = digit0; end
            2'b01: begin an = 4'b1101; hex_value = digit1; end
            2'b10: begin an = 4'b1011; hex_value = digit2; end
            2'b11: begin an = 4'b0111; hex_value = digit3; end
        endcase
    end

    // 7세그먼트 디코더 (0~9)
    always @(*) begin
        case(hex_value)
            4'h0: seg = 8'b1100_0000; 4'h1: seg = 8'b1111_1001;
            4'h2: seg = 8'b1010_0100; 4'h3: seg = 8'b1011_0000;
            4'h4: seg = 8'b1001_1001; 4'h5: seg = 8'b1001_0010;
            4'h6: seg = 8'b1000_0010; 4'h7: seg = 8'b1101_1000;
            4'h8: seg = 8'b1000_0000; 4'h9: seg = 8'b1001_0000;
            default: seg = 8'b1111_1111;
        endcase
    end
endmodule


module bin_to_bcd(
    input [8:0] bin,
    output [3:0] bcd2, bcd1, bcd0
);
    assign bcd2 = bin / 100;           // 백의 자리
    assign bcd1 = (bin % 100) / 10;    // 십의 자리
    assign bcd0 = bin % 10;            // 일의 자리
endmodule



module dht11_cntr(
    input clk, reset_p,
    inout dht11_data,
    output reg [7:0] humidity, temperature,
    output [15:0] led);

    localparam S_IDLE       = 6'b00_0001;
    localparam S_LOW_18MS   = 6'b00_0010;
    localparam S_HIGH_20US  = 6'b00_0100;
    localparam S_LOW_80US   = 6'b00_1000;
    localparam S_HIGH_80US  = 6'b01_0000;
    localparam S_READ_DATA  = 6'b10_0000;
    
    localparam S_WAIT_PEDGE = 2'b01;
    localparam S_WAIT_NEDGE = 2'b10;
    
    wire clk_usec_nedge;
    clock_usec usec_clk(.clk(clk), .reset_p(reset_p), 
                        .clk_usec_nedge(clk_usec_nedge));
    
    reg [21:0] count_usec;
    reg count_usec_e;
    always @(negedge clk, posedge reset_p)begin
        if(reset_p)count_usec = 0;
        else if(clk_usec_nedge && count_usec_e)count_usec = count_usec + 1;
        else if(!count_usec_e)count_usec = 0;
    end
    
    wire dht_nedge, dht_pedge;
    edge_detector_p ed(.clk(clk), .reset_p(reset_p),
                       .cp(dht11_data), .p_edge(dht_pedge),
                       .n_edge(dht_nedge));
    reg dht11_data_buffer, dht11_data_out_e;
    assign dht11_data = dht11_data_out_e ? dht11_data_buffer : 'bz;  
    
    reg [5:0] state, next_state;
    always @(negedge clk, posedge reset_p)begin
        if(reset_p)state = S_IDLE;
        else state = next_state;
    end  
    assign led[5:0] = state;
    reg [39:0] temp_data;
    reg [5:0] cnt_data;
    assign led[15:10] = cnt_data;
    reg [1:0] read_state;
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)begin
            next_state = S_IDLE;
            temp_data = 0;
            cnt_data = 0;
            count_usec_e = 0;
            dht11_data_out_e = 0;
            dht11_data_buffer = 0;
            read_state = S_WAIT_PEDGE;
        end
        else begin
            case(state)
                S_IDLE:begin
                    if(count_usec < 22'd3_000_000)begin
                        count_usec_e = 1;
                        dht11_data_out_e = 0;
                    end
                    else begin
                        count_usec_e = 0;
                        next_state = S_LOW_18MS;
                    end
                end
                S_LOW_18MS:begin
                    if(count_usec < 22'd20_000)begin
                        count_usec_e = 1;
                        dht11_data_out_e = 1;
                        dht11_data_buffer = 0;
                    end
                    else begin
                        count_usec_e = 0;
                        dht11_data_out_e = 0;
                        next_state = S_HIGH_20US;
                    end
                end 
                S_HIGH_20US:begin
                    if(dht_nedge)begin
                        count_usec_e = 0;
                        next_state = S_LOW_80US;
                    end
                end
                S_LOW_80US:begin
                    if(dht_pedge)begin
                        next_state = S_HIGH_80US;
                    end
                end
                S_HIGH_80US:begin
                    if(dht_nedge)begin
                        next_state = S_READ_DATA;
                    end
                end
                S_READ_DATA:begin
                    case(read_state)
                        S_WAIT_PEDGE:begin
                            if(dht_pedge)read_state = S_WAIT_NEDGE;
                            count_usec_e = 0;
                        end
                        S_WAIT_NEDGE:begin
                            count_usec_e = 1;
                            if(dht_nedge)begin
                                if(count_usec < 50) temp_data = {temp_data[38:0], 1'b0};
                                else temp_data = {temp_data[38:0], 1'b1};
                                cnt_data = cnt_data + 1;
                                read_state = S_WAIT_PEDGE;
                            end
                        end
                        default: read_state = S_WAIT_PEDGE;
                    endcase
                    if(cnt_data >= 40)begin
                        next_state = S_IDLE;
                        cnt_data = 0;
                        
                        humidity = temp_data[39:32];
                        temperature = temp_data[23:16];        
                    end
                end
                default: next_state = S_IDLE;
            endcase
        end
    end              
    
endmodule




module i2c_lcd_send_byte(
    input clk, reset_p,
    input [6:0] addr, 
    input [7:0] send_buffer,
    input send, rs,
    output scl, sda,
    output reg busy,
    output[15:0] led);

    localparam IDLE                     = 6'b00_0001;
    localparam SEND_HIGH_NIBBLE_DISABLE = 6'b00_0010;
    localparam SEND_HIGH_NIBBLE_ENABLE  = 6'b00_0100;
    localparam SEND_LOW_NIBBLE_DISABLE  = 6'b00_1000;
    localparam SEND_LOW_NIBBLE_ENABLE   = 6'b01_0000;
    localparam SEND_DISABLE             = 6'b10_0000;
    
    wire clk_usec_nedge;
    clock_usec usec_clk(.clk(clk), .reset_p(reset_p), 
                        .clk_usec_nedge(clk_usec_nedge));
    wire send_pedge;
    edge_detector_p ed_start(.clk(clk), .reset_p(reset_p),
                       .cp(send), .p_edge(send_pedge));
                       
    reg [21:0] count_usec;
    reg count_usec_e;
    always @(negedge clk, posedge reset_p)begin
        if(reset_p)count_usec = 0;
        else if(clk_usec_nedge && count_usec_e)count_usec = count_usec + 1;
        else if(!count_usec_e)count_usec = 0;
    end 
                     
    reg [7:0] data;
    reg comm_start;
    wire i2c_busy;
    I2C_master master(clk, reset_p, addr, data, 1'b0, 
                                comm_start, scl, sda, i2c_busy, led);                   
    
    reg [5:0] state, next_state;
    always @(negedge clk, posedge reset_p)begin
        if(reset_p)state = IDLE;
        else state = next_state;
    end
    
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)begin
            next_state = IDLE;
            comm_start = 0;
            count_usec_e = 0;
            data = 0;
            busy = 0;
        end
        else begin
            case(state)
                IDLE                    :begin
                    busy = 0;
                    if(send_pedge)begin
                        busy = 1;
                        next_state = SEND_HIGH_NIBBLE_DISABLE;
                    end
                end
                SEND_HIGH_NIBBLE_DISABLE:begin
                    if(count_usec >= 22'd200)begin
                        comm_start = 0;
                        next_state =  SEND_HIGH_NIBBLE_ENABLE;
                        count_usec_e = 0;
                    end
                    else begin
                              //d7 d6 d5 d4  BL en, rw, rs    
                        data = {send_buffer[7:4], 3'b100, rs};
                        comm_start = 1;
                        count_usec_e = 1;
                    end
                end
                SEND_HIGH_NIBBLE_ENABLE :begin
                    if(count_usec >= 22'd200)begin
                        comm_start = 0;
                        next_state = SEND_LOW_NIBBLE_DISABLE;
                        count_usec_e = 0;
                    end
                    else begin
                        data = {send_buffer[7:4], 3'b110, rs};
                        comm_start = 1;
                        count_usec_e = 1;
                    end
                end
                SEND_LOW_NIBBLE_DISABLE :begin
                    if(count_usec >= 22'd200)begin
                        comm_start = 0;
                        next_state =  SEND_LOW_NIBBLE_ENABLE;
                        count_usec_e = 0;
                    end
                    else begin
                        data = {send_buffer[3:0], 3'b100, rs};
                        comm_start = 1;
                        count_usec_e = 1;
                    end
                end
                SEND_LOW_NIBBLE_ENABLE  :begin
                    if(count_usec >= 22'd200)begin
                        comm_start = 0;
                        next_state = SEND_DISABLE;
                        count_usec_e = 0;
                    end
                    else begin
                        data = {send_buffer[3:0], 3'b110, rs};
                        comm_start = 1;
                        count_usec_e = 1;
                    end
                end
                SEND_DISABLE            :begin
                    if(count_usec >= 22'd200)begin
                        comm_start = 0;
                        next_state = IDLE;
                        count_usec_e = 0;
                    end
                    else begin
                        data = {send_buffer[3:0], 3'b100, rs};
                        comm_start = 1;
                        count_usec_e = 1;
                    end
                end
                default: next_state = IDLE;
            endcase
        end
    end
                       
endmodule





module fan_auto_control_top(
    input clk,            // 100MHz
    input reset_p,
    inout dht11_data,     // DHT11 센서 데이터
    output fan_pwm,       // 선풍기 모터 PWM 출력
    output led_fan_on,     // 선풍기 작동 중 표시 LED (LD15)
    output [7:0] seg,      // 7세그먼트 데이터
    output [3:0] an        // 7세그먼트 자릿수 선택
);

    wire [7:0] current_temp, current_humi;
    reg [7:0] duty_val;
    wire fan_on_condition;

    // 임계값 설정
    parameter TEMP_THRESHOLD = 8'd26; 
    parameter HUMI_THRESHOLD = 8'd70; 

    // 1. DHT11 센서 모듈 (온습도 읽기)
    dht11_cntr u_dht11 (
        .clk(clk), .reset_p(reset_p), .dht11_data(dht11_data),
        .temperature(current_temp), .humidity(current_humi), .led()
    );

    // 2. 작동 조건 판단
    assign fan_on_condition = (current_temp >= TEMP_THRESHOLD || current_humi >= HUMI_THRESHOLD);
    assign led_fan_on = fan_on_condition; // 조건 만족 시 LD15 켜짐

    // 3. Duty 값 결정 (조건 만족 시 Duty 200, 아니면 0)
    always @(posedge clk or posedge reset_p) begin
        if (reset_p) duty_val <= 8'd0;
        else duty_val <= fan_on_condition ? 8'd200 : 8'd0;
    end

    // 4. PWM 생성 모듈 (모터 제어 신호 출력)
    pwm_Nfreq_Nstep u_pwm (
        .clk(clk), .reset_p(reset_p), .duty(duty_val), .pwm(fan_pwm)
    );

    // 5. 7세그먼트 습도 표시 모듈
    fnd_control u_fnd (
        .clk(clk), .reset_p(reset_p), .value(current_humi), 
        .seg(seg), .an(an)
    );

endmodule


module clock_usec(
    input clk, reset_p,
    output clk_usec_nedge
);
    reg [6:0] cnt;
    // 100MHz 클럭을 100번 세면 1MHz (1us)가 됩니다.
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) cnt <= 0;
        else if(cnt >= 99) cnt <= 0;
        else cnt <= cnt + 1;
    end
    assign clk_usec_nedge = (cnt == 99);
endmodule

module edge_detector_p(
    input clk, reset_p, cp,
    output p_edge, n_edge
);
    reg ff1, ff2;
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin ff1 <= 0; ff2 <= 0; end
        else begin ff1 <= cp; ff2 <= ff1; end
    end
    assign p_edge = ({ff2, ff1} == 2'b01); // 상승 에지
    assign n_edge = ({ff2, ff1} == 2'b10); // 하강 에지
endmodule

module pwm_Nfreq_Nstep(
    input clk, reset_p,
    input [7:0] duty,
    output pwm
);
    reg [7:0] cnt;
    // 0~255까지 계속 반복해서 세는 카운터
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) cnt <= 0;
        else cnt <= cnt + 1;
    end
    // 카운터가 설정한 duty값보다 작을 때만 High 신호를 내보냄
    assign pwm = (cnt < duty) ? 1 : 0;
endmodule



//module button_edge(
//    input clk, reset_p, btn,
//    output p_edge
//);
//    reg [16:0] debounced_cnt; // 노이즈 제거용 간단한 카운터
//    reg btn_reg;
//    always @(posedge clk) begin
//        // 간단한 디바운싱 로직 생략 버전 (필요시 추가)
//        btn_reg <= btn;
//    end
    
//    edge_detector_p ed_btn (
//        .clk(clk), .reset_p(reset_p), .cp(btn_reg), 
//        .p_edge(p_edge), .n_edge()
//    );
//endmodule


module fnd_control(
    input clk, reset_p,
    input [7:0] value, // 표시할 값 (습도)
    output reg [7:0] seg,
    output reg [3:0] an
);
    // 십진수 분리 (십의 자리, 일의 자리)
    wire [3:0] digit_10 = value / 10;
    wire [3:0] digit_1  = value % 10;

    // FND 스캔 클럭 (약 1ms 주기)
    reg [16:0] clk_div;
    always @(posedge clk) clk_div <= clk_div + 1;

    // 디스플레이 선택 및 데이터 출력
    always @(*) begin
        case(clk_div[16:15]) // 두 자리만 번갈아 켬
            2'b00: begin
                an = 4'b1110; // 첫 번째 자리(일의 자리) ON
                seg = fnd_decoder(digit_1);
            end
            2'b01: begin
                an = 4'b1101; // 두 번째 자리(십의 자리) ON
                seg = fnd_decoder(digit_10);
            end
            default: begin an = 4'b1111; seg = 8'hff; end
        endcase
    end

    // 숫자 -> 세그먼트 패턴 변환 함수 (Common Anode 기준)
    function [7:0] fnd_decoder(input [3:0] num);
        case(num)
            4'h0: fnd_decoder = 8'hC0; 4'h1: fnd_decoder = 8'hF9;
            4'h2: fnd_decoder = 8'hA4; 4'h3: fnd_decoder = 8'hB0;
            4'h4: fnd_decoder = 8'h99; 4'h5: fnd_decoder = 8'h92;
            4'h6: fnd_decoder = 8'h82; 4'h7: fnd_decoder = 8'hF8;
            4'h8: fnd_decoder = 8'h80; 4'h9: fnd_decoder = 8'h90;
            default: fnd_decoder = 8'hff;
        endcase
    endfunction
endmodule