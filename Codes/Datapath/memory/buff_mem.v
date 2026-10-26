module buff #(
    parameter ADDR_WIDTH   = 12,
    parameter WORD_WIDTH   = 64,
    parameter FRACTIONAL_L = 14
)(
    input clk,
    input rstn,
    input buff_wr_enbl,
    input buff_rd_enbl,
    input [ADDR_WIDTH-1:0] buff_wr_addr,
    input [ADDR_WIDTH-1:0] buff_rd_addr,
    input [WORD_WIDTH-1:0] buff_wr_data,
    output reg [WORD_WIDTH-1:0] buff_rd_data
);

reg [WORD_WIDTH-1:0] memory_buff [0:(1 << ADDR_WIDTH)-1];
integer i;

// Synchronous Write / Memory Reset
// Only resets working data buffer (0 to 2047); twiddle table (2048 to 4095) is preserved
always @(posedge clk) begin
    if (!rstn) begin
        for (i = 0; i < (1 << (ADDR_WIDTH-1)); i = i + 1) begin
            memory_buff[i] <= {WORD_WIDTH{1'b0}};
        end
    end else if (buff_wr_enbl) begin
        memory_buff[buff_wr_addr] <= buff_wr_data;
    end
end

// Synchronous Read
always @(posedge clk) begin
    if (!rstn) begin
        buff_rd_data <= {WORD_WIDTH{1'b0}};
    end else if (buff_rd_enbl) begin
        buff_rd_data <= memory_buff[buff_rd_addr];
    end
end

// =============================================================================
// Preload Twiddle Factors into upper half of buff_mem (addresses 2048 to 4095)
// Strictly follows the case (lvl) address mapping in loading_add.v & tw_init_cycle.v
// Fixed-Point Format: Q1.1.14 ({imag[15:0], real[15:0]})
// Word layout: {tw_w1 [63:32], tw_w0 [31:0]}
// =============================================================================
localparam real PI = 3.14159265358979323846;
localparam real SCALE_FACTOR = (1 << FRACTIONAL_L);

function [31:0] make_twiddle;
    input integer k;
    input integer n_pts;
    real c, s;
    integer int_re, int_im;
    reg signed [15:0] q_re, q_im;
    begin
        c = $cos(2.0 * PI * k / n_pts);
        s = -$sin(2.0 * PI * k / n_pts);
        int_re = $rtoi(c * SCALE_FACTOR);
        int_im = $rtoi(s * SCALE_FACTOR);
        if (int_re > 32767) int_re = 32767;
        if (int_re < -32768) int_re = -32768;
        if (int_im > 32767) int_im = 32767;
        if (int_im < -32768) int_im = -32768;
        q_re = int_re[15:0];
        q_im = int_im[15:0];
        make_twiddle = {q_im, q_re};
    end
endfunction

integer idx, k_tw;
reg [31:0] tw0, tw1;

initial begin
    // Clear data memory region (0 to 2047)
    for (idx = 0; idx < (1 << (ADDR_WIDTH-1)); idx = idx + 1) begin
        memory_buff[idx] = {WORD_WIDTH{1'b0}};
    end

    // Default fill twiddle region (2048 to 4095) with W_2^0 = 1 + 0j
    tw0 = make_twiddle(0, 2);
    for (idx = (1 << (ADDR_WIDTH-1)); idx < (1 << ADDR_WIDTH); idx = idx + 1) begin
        memory_buff[idx] = {tw0, tw0};
    end

    // -------------------------------------------------------------------------
    // lvl = 12: tw_addr = {1'b1, 1'b0, 1'b0, tw_cnt[8:0]} (Addresses 2048..2559)
    // -------------------------------------------------------------------------
    for (k_tw = 0; k_tw < 512; k_tw = k_tw + 1) begin
        tw0 = make_twiddle(2 * k_tw,     4096);
        tw1 = make_twiddle(2 * k_tw + 1, 4096);
        memory_buff[{1'b1, 1'b0, 1'b0, k_tw[8:0]}] = {tw1, tw0};
    end

    // -------------------------------------------------------------------------
    // lvl = 11: tw_addr = {1'b1, 1'b0, 1'b1, 1'b0, tw_cnt[7:0]} (Addresses 2560..2815)
    // -------------------------------------------------------------------------
    for (k_tw = 0; k_tw < 256; k_tw = k_tw + 1) begin
        tw0 = make_twiddle(2 * k_tw,     2048);
        tw1 = make_twiddle(2 * k_tw + 1, 2048);
        memory_buff[{1'b1, 1'b0, 1'b1, 1'b0, k_tw[7:0]}] = {tw1, tw0};
    end

    // -------------------------------------------------------------------------
    // lvl = 10: tw_addr = {1'b1, 1'b0, 2'b11, 1'b0, tw_cnt[6:0]} (Addresses 2816..2943)
    // -------------------------------------------------------------------------
    for (k_tw = 0; k_tw < 128; k_tw = k_tw + 1) begin
        tw0 = make_twiddle(2 * k_tw,     1024);
        tw1 = make_twiddle(2 * k_tw + 1, 1024);
        memory_buff[{1'b1, 1'b0, 2'b11, 1'b0, k_tw[6:0]}] = {tw1, tw0};
    end

    // -------------------------------------------------------------------------
    // lvl = 9:  tw_addr = {1'b1, 1'b0, 3'b111, 1'b0, tw_cnt[5:0]} (Addresses 2944..3007)
    // -------------------------------------------------------------------------
    for (k_tw = 0; k_tw < 64; k_tw = k_tw + 1) begin
        tw0 = make_twiddle(2 * k_tw,     512);
        tw1 = make_twiddle(2 * k_tw + 1, 512);
        memory_buff[{1'b1, 1'b0, 3'b111, 1'b0, k_tw[5:0]}] = {tw1, tw0};
    end

    // -------------------------------------------------------------------------
    // lvl = 8:  tw_addr = {1'b1, 1'b0, 4'b1111, 1'b0, tw_cnt[4:0]} (Addresses 3008..3039)
    // -------------------------------------------------------------------------
    for (k_tw = 0; k_tw < 32; k_tw = k_tw + 1) begin
        tw0 = make_twiddle(2 * k_tw,     256);
        tw1 = make_twiddle(2 * k_tw + 1, 256);
        memory_buff[{1'b1, 1'b0, 4'b1111, 1'b0, k_tw[4:0]}] = {tw1, tw0};
    end

    // -------------------------------------------------------------------------
    // lvl = 7:  tw_addr = {1'b1, 1'b0, 5'b11111, 1'b0, tw_cnt[3:0]} (Addresses 3040..3055)
    // -------------------------------------------------------------------------
    for (k_tw = 0; k_tw < 16; k_tw = k_tw + 1) begin
        tw0 = make_twiddle(2 * k_tw,     128);
        tw1 = make_twiddle(2 * k_tw + 1, 128);
        memory_buff[{1'b1, 1'b0, 5'b11111, 1'b0, k_tw[3:0]}] = {tw1, tw0};
    end

    // -------------------------------------------------------------------------
    // lvl = 6:  tw_addr = {1'b1, 1'b0, 6'b111111, 1'b0, tw_cnt[2:0]} (Addresses 3056..3063)
    // -------------------------------------------------------------------------
    for (k_tw = 0; k_tw < 8; k_tw = k_tw + 1) begin
        tw0 = make_twiddle(2 * k_tw,     64);
        tw1 = make_twiddle(2 * k_tw + 1, 64);
        memory_buff[{1'b1, 1'b0, 6'b111111, 1'b0, k_tw[2:0]}] = {tw1, tw0};
    end

    // -------------------------------------------------------------------------
    // lvl = 5:  tw_addr = {1'b1, 1'b0, 7'b1111111, 1'b0, tw_cnt[1:0]} (Addresses 3064..3067)
    // -------------------------------------------------------------------------
    for (k_tw = 0; k_tw < 4; k_tw = k_tw + 1) begin
        tw0 = make_twiddle(2 * k_tw,     32);
        tw1 = make_twiddle(2 * k_tw + 1, 32);
        memory_buff[{1'b1, 1'b0, 7'b1111111, 1'b0, k_tw[1:0]}] = {tw1, tw0};
    end

    // -------------------------------------------------------------------------
    // lvl = 4:  tw_addr = {1'b1, 1'b0, 8'b11111111, 1'b0, tw_cnt[0]} (Addresses 3068..3069)
    // -------------------------------------------------------------------------
    for (k_tw = 0; k_tw < 2; k_tw = k_tw + 1) begin
        tw0 = make_twiddle(2 * k_tw,     16);
        tw1 = make_twiddle(2 * k_tw + 1, 16);
        memory_buff[{1'b1, 1'b0, 8'b11111111, 1'b0, k_tw[0]}] = {tw1, tw0};
    end

    // -------------------------------------------------------------------------
    // lvl = 3:  tw_addr = {1'b1, 1'b0, 9'b111111111, 1'b0} (Address 3070)
    // -------------------------------------------------------------------------
    tw0 = make_twiddle(0, 8); // W_8^0 = 1 + 0j
    tw1 = make_twiddle(1, 8); // W_8^1
    memory_buff[{1'b1, 1'b0, 9'b111111111, 1'b0}] = {tw1, tw0};

    // -------------------------------------------------------------------------
    // lvl = 2:  tw_addr = {1'b1, 1'b0, 10'b1111111111} (Address 3071)
    // -------------------------------------------------------------------------
    tw0 = make_twiddle(0, 4); // W_4^0 = 1 + 0j
    tw1 = make_twiddle(0, 4); // W_4^0 = 1 + 0j
    memory_buff[{1'b1, 1'b0, 10'b1111111111}] = {tw1, tw0};

    // -------------------------------------------------------------------------
    // tw_init_cycle: addr_tw_init = {1'b1, 1'b1, 7'b0000000, temp_addr_tw_init} (Addresses 3072..3079)
    // Reference factor: W_4^1 = -j
    // -------------------------------------------------------------------------
    tw0 = make_twiddle(1, 4); // W_4^1 = -j
    tw1 = make_twiddle(1, 4);
    for (k_tw = 0; k_tw < 8; k_tw = k_tw + 1) begin
        memory_buff[{1'b1, 1'b1, 7'b0000000, k_tw[2:0]}] = {tw1, tw0};
    end

    // -------------------------------------------------------------------------
    // lvl = 1:  tw_addr = {1'b1, 1'b1, 10'b1111111111} (Address 4095)
    // -------------------------------------------------------------------------
    tw0 = make_twiddle(0, 2); // W_2^0 = 1 + 0j
    tw1 = make_twiddle(0, 2);
    memory_buff[{1'b1, 1'b1, 10'b1111111111}] = {tw1, tw0};
end

endmodule