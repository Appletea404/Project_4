`timescale 1ns / 1ps

// ==========================================================
// I2C Master (Write Only), 100MHz → 100kHz
// ==========================================================
module i2c_master(
    input        clk, reset_p,
    input        start,
    input  [6:0] addr,
    input  [7:0] data,
    output reg   scl,
    inout        sda,
    output reg   done
);
    localparam HALF = 499;

    localparam S_IDLE=3'd0, S_START=3'd1, S_ADDR=3'd2,
               S_ACK1=3'd3, S_DATA=3'd4,  S_ACK2=3'd5, S_STOP=3'd6;

    reg [2:0] state;
    reg [9:0] clk_cnt;
    reg       scl_en;
    reg       sda_out, sda_oe;
    reg [3:0] bit_cnt;
    reg [7:0] shift_reg;

    assign sda = sda_oe ? sda_out : 1'bz;

    wire scl_fall = scl_en && (clk_cnt == HALF) && (scl == 1'b1);
    wire scl_rise = scl_en && (clk_cnt == HALF) && (scl == 1'b0);

    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin clk_cnt <= 0; scl <= 1; end
        else if (scl_en) begin
            if (clk_cnt >= HALF) begin clk_cnt <= 0; scl <= ~scl; end
            else clk_cnt <= clk_cnt + 1;
        end else begin clk_cnt <= 0; scl <= 1; end
    end

    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            state <= S_IDLE; scl_en <= 0;
            sda_out <= 1; sda_oe <= 1;
            bit_cnt <= 0; shift_reg <= 0; done <= 0;
        end else begin
            done <= 0;
            case (state)
                S_IDLE: begin
                    sda_out <= 1; sda_oe <= 1; scl_en <= 0;
                    if (start) begin scl_en <= 1; state <= S_START; end
                end
                S_START: begin
                    sda_out <= 0;
                    if (scl_fall) begin
                        // 첫 번째 SCL HIGH 전에 MSB(addr[6])를 SDA에 올림
                        sda_out   <= addr[6];
                        shift_reg <= {addr[5:0], 1'b0, 1'b0}; // 남은 6비트 + W=0 + 패딩
                        bit_cnt   <= 6; // S_ADDR에서 7번 전송(6→0→ACK)
                        state     <= S_ADDR;
                    end
                end
                S_ADDR: begin
                    if (scl_fall) begin
                        sda_out <= shift_reg[7]; sda_oe <= 1;
                        shift_reg <= {shift_reg[6:0], 1'b0};
                        if (bit_cnt == 0) state <= S_ACK1;
                        else bit_cnt <= bit_cnt - 1;
                    end
                end
                S_ACK1: begin
                    sda_oe <= 0;
                    if (scl_fall) begin
                        // 첫 번째 데이터 SCL HIGH 전에 MSB(data[7])를 SDA에 올림
                        sda_out   <= data[7];
                        shift_reg <= {data[6:0], 1'b0}; // 남은 7비트 + 패딩
                        bit_cnt   <= 6; // S_DATA에서 7번 전송(6→0→ACK)
                        sda_oe    <= 1;
                        state     <= S_DATA;
                    end
                end
                S_DATA: begin
                    if (scl_fall) begin
                        sda_out <= shift_reg[7]; sda_oe <= 1;
                        shift_reg <= {shift_reg[6:0], 1'b0};
                        if (bit_cnt == 0) state <= S_ACK2;
                        else bit_cnt <= bit_cnt - 1;
                    end
                end
                S_ACK2: begin
                    sda_oe <= 0;
                    if (scl_fall) begin sda_out <= 0; sda_oe <= 1; state <= S_STOP; end
                end
                S_STOP: begin
                    if (scl_rise) begin
                        sda_out <= 1; scl_en <= 0; done <= 1; state <= S_IDLE;
                    end
                end
            endcase
        end
    end
endmodule


// ==========================================================
// HD44780 LCD over I2C (PCF8574 백팩, 4비트 모드)
// Line1: "Temp: XXC"
// Line2: "Humi: XX%"
// ==========================================================
module lcd_i2c_top(
    input        clk, reset_p,
    input  [7:0] temperature,
    input  [7:0] humidity,
    output       scl,
    inout        sda
);
    localparam I2C_ADDR = 7'h27; // PCF8574T 기본값
    localparam BL       = 1'b1;  // 백라이트 ON

    // ----------------------------------------------------------
    // 틱 생성: clk_us (1μs), clk_ms (1ms)
    // ----------------------------------------------------------
    reg [6:0] us_cnt; reg clk_us;
    always @(posedge clk or posedge reset_p)
        if (reset_p) begin us_cnt<=0; clk_us<=0; end
        else if (us_cnt>=99) begin us_cnt<=0; clk_us<=1; end
        else begin us_cnt<=us_cnt+1; clk_us<=0; end

    reg [9:0] ms_cnt; reg clk_ms;
    always @(posedge clk or posedge reset_p)
        if (reset_p) begin ms_cnt<=0; clk_ms<=0; end
        else begin
            clk_ms <= 0;
            if (clk_us) begin
                if (ms_cnt>=999) begin ms_cnt<=0; clk_ms<=1; end
                else ms_cnt <= ms_cnt+1;
            end
        end

    // ----------------------------------------------------------
    // I2C Master 연결
    // ----------------------------------------------------------
    reg        i2c_start;
    reg  [7:0] i2c_data;
    wire       i2c_done;
    i2c_master u_i2c(
        .clk(clk), .reset_p(reset_p),
        .start(i2c_start), .addr(I2C_ADDR), .data(i2c_data),
        .scl(scl), .sda(sda), .done(i2c_done)
    );

    // ----------------------------------------------------------
    // TX 서브FSM: nibble 전송 + 대기
    // i2c_start / i2c_data 는 이 블록에서만 구동
    // ----------------------------------------------------------
    localparam TX_IDLE=3'd0, TX_HI_E1=3'd1, TX_HI_E0=3'd2,
               TX_LO_E1=3'd3, TX_LO_E0=3'd4, TX_WAIT=3'd5, TX_DONE=3'd6;

    reg [2:0]  tx_st;
    reg        tx_busy, tx_done_p;
    reg [15:0] tx_wait_cnt;

    // 메인 FSM → TX 서브FSM 인터페이스 (reg, 메인 FSM에서 구동)
    reg        tx_start;
    reg [7:0]  tx_byte;
    reg        tx_is_cmd;      // 1=command(RS=0), 0=data(RS=1)
    reg        tx_nibble_only; // 1=상위nibble만 (init용)
    reg [15:0] tx_wait_us;

    wire rs_bit = ~tx_is_cmd;

    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            tx_st<=TX_IDLE; tx_busy<=0; tx_done_p<=0;
            i2c_start<=0; i2c_data<=0; tx_wait_cnt<=0;
        end else begin
            i2c_start <= 0;
            tx_done_p <= 0;
            case (tx_st)
                TX_IDLE: begin
                    tx_busy <= 0;
                    if (tx_start) begin tx_busy<=1; tx_st<=TX_HI_E1; end
                end
                TX_HI_E1: begin
                    i2c_data  <= {tx_byte[7:4], BL, 1'b1, 1'b0, rs_bit};
                    i2c_start <= 1;
                    tx_st     <= TX_HI_E0;
                end
                TX_HI_E0: begin
                    if (i2c_done) begin
                        i2c_data  <= {tx_byte[7:4], BL, 1'b0, 1'b0, rs_bit};
                        i2c_start <= 1;
                        tx_st     <= TX_LO_E1;
                    end
                end
                TX_LO_E1: begin
                    if (i2c_done) begin
                        if (tx_nibble_only) begin
                            tx_wait_cnt <= 0;
                            tx_st       <= TX_WAIT;
                        end else begin
                            i2c_data  <= {tx_byte[3:0], BL, 1'b1, 1'b0, rs_bit};
                            i2c_start <= 1;
                            tx_st     <= TX_LO_E0;
                        end
                    end
                end
                TX_LO_E0: begin
                    if (i2c_done) begin
                        i2c_data    <= {tx_byte[3:0], BL, 1'b0, 1'b0, rs_bit};
                        i2c_start   <= 1;
                        tx_wait_cnt <= 0;
                        tx_st       <= TX_WAIT;
                    end
                end
                TX_WAIT: begin
                    // i2c 완료 후 μs 단위 대기 (i2c_done 무관, 자유 카운트)
                    if (!i2c_start) begin
                        if (clk_us) begin
                            if (tx_wait_cnt >= tx_wait_us) tx_st <= TX_DONE;
                            else tx_wait_cnt <= tx_wait_cnt + 1;
                        end
                    end
                end
                TX_DONE: begin
                    tx_done_p <= 1;
                    tx_busy   <= 0;
                    tx_st     <= TX_IDLE;
                end
            endcase
        end
    end

    // ----------------------------------------------------------
    // 문자 데이터
    // ----------------------------------------------------------
    wire [7:0] t_ten = 8'h30 + (temperature / 10);
    wire [7:0] t_one = 8'h30 + (temperature % 10);
    wire [7:0] h_ten = 8'h30 + (humidity    / 10);
    wire [7:0] h_one = 8'h30 + (humidity    % 10);

    reg [7:0] line1 [0:15];
    reg [7:0] line2 [0:15];
    always @(*) begin
        line1[0]="T"; line1[1]="e"; line1[2]="m"; line1[3]="p";
        line1[4]=":"; line1[5]=" "; line1[6]=t_ten; line1[7]=t_one;
        line1[8]="C"; line1[9]=" "; line1[10]=" "; line1[11]=" ";
        line1[12]=" "; line1[13]=" "; line1[14]=" "; line1[15]=" ";

        line2[0]="H"; line2[1]="u"; line2[2]="m"; line2[3]="i";
        line2[4]=":"; line2[5]=" "; line2[6]=h_ten; line2[7]=h_one;
        line2[8]="%"; line2[9]=" "; line2[10]=" "; line2[11]=" ";
        line2[12]=" "; line2[13]=" "; line2[14]=" "; line2[15]=" ";
    end

    // ----------------------------------------------------------
    // 메인 FSM: step 기반 시퀀서 (명령 전송과 대기를 분리)
    //
    // step  0: power-on wait (20ms)
    // step  1~4: HD44780 init (8bit x3, 4bit mode)
    // step  5~9: func set, disp off, clear, entry, disp on
    // step 10: DDRAM 0x00 (line1 시작)
    // step 11~26: line1 16문자
    // step 27: DDRAM 0x40 (line2 시작)
    // step 28~43: line2 16문자
    // step 44: 1초 대기 후 step 10으로
    // ----------------------------------------------------------
    localparam MS_POWERWAIT = 2'd0; // 전원 대기
    localparam MS_TX        = 2'd1; // tx_start 1클럭 발생
    localparam MS_WAIT_DONE = 2'd2; // tx_done_p 대기
    localparam MS_REFRESH   = 2'd3; // 1초 대기

    reg [1:0] ms;
    reg [5:0] step;

    // 전원 대기용 ms 카운터 (20ms 원샷)
    reg [4:0] pw_cnt; reg pw_done;
    always @(posedge clk or posedge reset_p)
        if (reset_p) begin pw_cnt<=0; pw_done<=0; end
        else begin
            pw_done <= 0;
            if (clk_ms && !pw_done) begin
                if (pw_cnt >= 20) pw_done <= 1;
                else pw_cnt <= pw_cnt + 1;
            end
        end

    // 1초 refresh tick
    reg [9:0] ref_cnt; reg ref_tick;
    always @(posedge clk or posedge reset_p)
        if (reset_p) begin ref_cnt<=0; ref_tick<=0; end
        else begin
            ref_tick <= 0;
            if (clk_ms) begin
                if (ref_cnt >= 999) begin ref_cnt<=0; ref_tick<=1; end
                else ref_cnt <= ref_cnt+1;
            end
        end

    // step → 명령 디코더 (combinational)
    reg [7:0]  cmd_byte;
    reg        cmd_nibble_only, cmd_is_cmd;
    reg [15:0] cmd_wait_us;

    always @(*) begin
        cmd_is_cmd      = 1;
        cmd_nibble_only = 0;
        cmd_wait_us     = 300; // [버그 수정] 50→300: I2C 1 트랜잭션 최대 200μs, 마지막 nibble 완료 보장
        cmd_byte        = 8'h00;
        case (step)
            1: begin cmd_byte=8'h30; cmd_nibble_only=1; cmd_wait_us=5000; end
            2: begin cmd_byte=8'h30; cmd_nibble_only=1; cmd_wait_us=200;  end
            3: begin cmd_byte=8'h30; cmd_nibble_only=1; cmd_wait_us=200;  end
            4: begin cmd_byte=8'h20; cmd_nibble_only=1; cmd_wait_us=50;   end
            5: begin cmd_byte=8'h28; end                                   // function set
            6: begin cmd_byte=8'h08; end                                   // display off
            7: begin cmd_byte=8'h01; cmd_wait_us=2000; end                 // clear
            8: begin cmd_byte=8'h06; end                                   // entry mode
            9: begin cmd_byte=8'h0C; end                                   // display on
           10: begin cmd_byte=8'h80; end                                   // DDRAM 0x00
           11: begin cmd_byte=line1[ 0]; cmd_is_cmd=0; end
           12: begin cmd_byte=line1[ 1]; cmd_is_cmd=0; end
           13: begin cmd_byte=line1[ 2]; cmd_is_cmd=0; end
           14: begin cmd_byte=line1[ 3]; cmd_is_cmd=0; end
           15: begin cmd_byte=line1[ 4]; cmd_is_cmd=0; end
           16: begin cmd_byte=line1[ 5]; cmd_is_cmd=0; end
           17: begin cmd_byte=line1[ 6]; cmd_is_cmd=0; end
           18: begin cmd_byte=line1[ 7]; cmd_is_cmd=0; end
           19: begin cmd_byte=line1[ 8]; cmd_is_cmd=0; end
           20: begin cmd_byte=line1[ 9]; cmd_is_cmd=0; end
           21: begin cmd_byte=line1[10]; cmd_is_cmd=0; end
           22: begin cmd_byte=line1[11]; cmd_is_cmd=0; end
           23: begin cmd_byte=line1[12]; cmd_is_cmd=0; end
           24: begin cmd_byte=line1[13]; cmd_is_cmd=0; end
           25: begin cmd_byte=line1[14]; cmd_is_cmd=0; end
           26: begin cmd_byte=line1[15]; cmd_is_cmd=0; end
           27: begin cmd_byte=8'hC0; end                                   // DDRAM 0x40
           28: begin cmd_byte=line2[ 0]; cmd_is_cmd=0; end
           29: begin cmd_byte=line2[ 1]; cmd_is_cmd=0; end
           30: begin cmd_byte=line2[ 2]; cmd_is_cmd=0; end
           31: begin cmd_byte=line2[ 3]; cmd_is_cmd=0; end
           32: begin cmd_byte=line2[ 4]; cmd_is_cmd=0; end
           33: begin cmd_byte=line2[ 5]; cmd_is_cmd=0; end
           34: begin cmd_byte=line2[ 6]; cmd_is_cmd=0; end
           35: begin cmd_byte=line2[ 7]; cmd_is_cmd=0; end
           36: begin cmd_byte=line2[ 8]; cmd_is_cmd=0; end
           37: begin cmd_byte=line2[ 9]; cmd_is_cmd=0; end
           38: begin cmd_byte=line2[10]; cmd_is_cmd=0; end
           39: begin cmd_byte=line2[11]; cmd_is_cmd=0; end
           40: begin cmd_byte=line2[12]; cmd_is_cmd=0; end
           41: begin cmd_byte=line2[13]; cmd_is_cmd=0; end
           42: begin cmd_byte=line2[14]; cmd_is_cmd=0; end
           43: begin cmd_byte=line2[15]; cmd_is_cmd=0; end
           default: begin cmd_byte=8'h00; end
        endcase
    end

    // 메인 FSM
    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            ms             <= MS_POWERWAIT;
            step           <= 0;
            tx_start       <= 0;
            tx_byte        <= 0;
            tx_is_cmd      <= 1;
            tx_nibble_only <= 0;
            tx_wait_us     <= 50;
        end else begin
            tx_start <= 0; // 매 클럭 초기화, MS_TX에서만 1클럭 pulse

            case (ms)
                MS_POWERWAIT: begin
                    if (pw_done) begin
                        step <= 1;
                        ms   <= MS_TX;
                    end
                end

                MS_TX: begin
                    // 명령 래치 후 tx_start 1클럭 pulse
                    tx_byte        <= cmd_byte;
                    tx_is_cmd      <= cmd_is_cmd;
                    tx_nibble_only <= cmd_nibble_only;
                    tx_wait_us     <= cmd_wait_us;
                    tx_start       <= 1;
                    ms             <= MS_WAIT_DONE;
                end

                MS_WAIT_DONE: begin
                    if (tx_done_p) begin
                        if (step == 43) begin
                            ms <= MS_REFRESH;
                        end else begin
                            step <= step + 1;
                            ms   <= MS_TX;
                        end
                    end
                end

                MS_REFRESH: begin
                    if (ref_tick) begin
                        step <= 10; // DDRAM 0x00 부터 다시
                        ms   <= MS_TX;
                    end
                end
            endcase
        end
    end

endmodule
