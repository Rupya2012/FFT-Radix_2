`timescale 1ns/1ps

module tb_fft;
    parameter ADDR_WIDTH   = 12;
    parameter WORD_WIDTH   = 64;
    parameter DATA_WIDTH   = 32;
    parameter REAL_LENGTH  = 16;
    parameter FRACTIONAL_L = 14; 
    reg clk;
    reg rstn;
    wire rst = ~rstn;
    reg  ext_iram_wr_enbl;
    reg  [ADDR_WIDTH-1:0] ext_iram_wr_addr;
    reg  [WORD_WIDTH-1:0] ext_iram_wr_data;
    reg  ext_oram_rd_enbl;
    reg  [ADDR_WIDTH-1:0] ext_oram_rd_addr;
    wire [WORD_WIDTH-1:0] oram_rd_data;
    wire done;
    wire valid;
    wire busy;
    wire [3:0] lvl;
    wire [WORD_WIDTH-1:0] y;
    wire [DATA_WIDTH-1:0] y1 = y[WORD_WIDTH-1:DATA_WIDTH];
    wire [DATA_WIDTH-1:0] y2 = y[DATA_WIDTH-1:0];
    wire [ADDR_WIDTH-1:0] buff_ram_wr_addr = u_fft_top.buff_ram_wr_addr;
    wire buff_wr_enbl                      = u_fft_top.buff_wr_enbl;
    wire oram_wr_enbl                      = u_fft_top.oram_wr_enbl;

    wire [3:0]         stage = lvl;

    wire signed [15:0] x1_real = u_fft_top.u_datapath.x_1[15:0];
    wire signed [15:0] x1_imag = u_fft_top.u_datapath.x_1[31:16];
    wire signed [15:0] x2_real = u_fft_top.u_datapath.x_2[15:0];
    wire signed [15:0] x2_imag = u_fft_top.u_datapath.x_2[31:16];
    wire signed [15:0] tw_real = u_fft_top.u_datapath.W[15:0];
    wire signed [15:0] tw_imag = u_fft_top.u_datapath.W[31:16];
    wire signed [15:0] y1_real = y1[15:0];
    wire signed [15:0] y1_imag = y1[31:16];
    wire signed [15:0] y2_real = y2[15:0];
    wire signed [15:0] y2_imag = y2[31:16];

    // Stage 1 Input from IRAM
    wire [ADDR_WIDTH-2:0] iram_rd_addr = u_fft_top.u_datapath.iram_rd_addr_int;
    wire signed [15:0] iram_s0_real = u_fft_top.u_datapath.iram_rd_data[15:0];
    wire signed [15:0] iram_s0_imag = u_fft_top.u_datapath.iram_rd_data[31:16];
    wire signed [15:0] iram_s1_real = u_fft_top.u_datapath.iram_rd_data[47:32];
    wire signed [15:0] iram_s1_imag = u_fft_top.u_datapath.iram_rd_data[63:48];

    // Buffer Memory (Intermediate data & Twiddles)
    wire [ADDR_WIDTH-1:0] buff_rd_addr = u_fft_top.u_datapath.buff_rd_addr_int;
    wire [ADDR_WIDTH-1:0] buff_wr_addr = u_fft_top.buff_ram_wr_addr;
    wire [WORD_WIDTH-1:0] buff_wr_data = u_fft_top.u_datapath.compute_wr_data;
    wire signed [15:0] buff_wr_y1_real = u_fft_top.u_datapath.compute_wr_data[47:32];
    wire signed [15:0] buff_wr_y1_imag = u_fft_top.u_datapath.compute_wr_data[63:48];
    wire signed [15:0] buff_wr_y2_real = u_fft_top.u_datapath.compute_wr_data[15:0];
    wire signed [15:0] buff_wr_y2_imag = u_fft_top.u_datapath.compute_wr_data[31:16];

    fft_top #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .WORD_WIDTH(WORD_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .REAL_LENGTH(REAL_LENGTH),
        .FRACTIONAL_L(FRACTIONAL_L)
    ) u_fft_top (
        .clk(clk),
        .clk_enb(1'b1),
        .rstn(rstn),
        .cpu_intrpt(1'b0),
        .iram_wr_enbl(ext_iram_wr_enbl),
        .iram_wr_addr(ext_iram_wr_addr),
        .iram_wr_data(ext_iram_wr_data),
        .oram_rd_enbl(ext_oram_rd_enbl),
        .oram_rd_addr(ext_oram_rd_addr),
        .oram_rd_data(oram_rd_data),
        .valid(valid),
        .done(done),
        .busy(busy),
        .lvl(lvl),
        .y(y)
    );

    always #5 clk = ~clk;

    localparam real PI = 3.14159265358979323846;
    localparam real SCALE_FACTOR = (1 << FRACTIONAL_L); // 16384.0 for Q1.14

    function signed [15:0] float_to_q(input real val);
        integer int_val;
        begin
            int_val = $rtoi(val * SCALE_FACTOR);
            if (int_val > 32767) int_val = 32767;
            if (int_val < -32768) int_val = -32768;
            float_to_q = int_val[15:0];
        end
    endfunction

    function real q_to_float(input signed [15:0] q_val);
        begin
            q_to_float = q_val / SCALE_FACTOR;
        end
    endfunction

    function [31:0] make_twiddle;
        input integer k;
        input integer n_pts;
        real c, s;
        reg signed [15:0] q_re, q_im;
        begin
            c = $cos(2.0 * PI * k / n_pts);
            s = -$sin(2.0 * PI * k / n_pts);
            q_re = float_to_q(c);
            q_im = float_to_q(s);
            // 32-bit complex number: {imag[15:0], real[15:0]}
            make_twiddle = {q_im, q_re};
        end
    endfunction

    // Variables for testbench stimulus
    integer i, k;
    real test_val_0_r, test_val_0_i;
    real test_val_1_r, test_val_1_i;
    reg signed [15:0] q_0_r, q_0_i;
    reg signed [15:0] q_1_r, q_1_i;
    reg [31:0] sample_0;
    reg [31:0] sample_1;

    real tw_r, tw_i;
    reg signed [15:0] q_tw_r, q_tw_i;
    reg [31:0] tw_sample;
    real mag;

    reg [3:0] last_lvl;
    integer target_stage;
    reg dump_started;
    initial begin
        clk = 0;
        rstn = 0;
        ext_iram_wr_enbl = 0;
        ext_iram_wr_addr = 0;
        ext_iram_wr_data = 0;
        ext_oram_rd_enbl = 0;
        ext_oram_rd_addr = 0;
        last_lvl = 4'd1;
        dump_started = 0;

        target_stage = 12; // Default: 12 = Full 12-stage FFT, 0 = 3 stages, 1 = Stage 1 only, 2 = Stage 2 only, 3 = Stage 3 only
        if ($value$plusargs("stage=%d", target_stage)) begin
            $display("[INFO] Running specifically for Target Stage = %0d", target_stage);
        end

        if (target_stage == 1) begin
            $dumpfile("fft_stage1.vcd");
            $dumpvars(0, tb_fft);
            dump_started = 1;
        end else if (target_stage == 0) begin
            $dumpfile("fft_stage1_2_3.vcd");
            $dumpvars(0, tb_fft);
            dump_started = 1;
        end

        $display(" Starting Radix-2 4096-Point FFT Verification");
        $display(" Fixed-point configuration: Q1.1.%0d (FRACTIONAL_L = %0d)", FRACTIONAL_L, FRACTIONAL_L);
        $display(" Input range constraint: [-0.5, 0.5]");

        begin : load_iram_block
            integer f_check;
            f_check = $fopen("iram_input.hex", "r");
            if (f_check != 0) begin
                $fclose(f_check);
                $readmemh("iram_input.hex", u_fft_top.u_datapath.u_iram.memory_iram);
                $display("[INFO] Loaded custom input signal from iram_input.hex.");
            end else begin
                $display("[INFO] Generating input signal with amplitude in [-0.5, 0.5] and loading IRAM...");
                for (i = 0; i < 2048; i = i + 1) begin
                    // Sample 2*i: Amplitude 0.45 * cos(2*pi*8*(2*i)/4096) -> strictly within [-0.45, +0.45]
                    test_val_0_r = 0.45 * $cos(2.0 * PI * 8.0 * (2*i) / 4096.0);
                    test_val_0_i = 0.0; // Real input signal, zero imaginary

                    // Sample 2*i + 1:
                    test_val_1_r = 0.45 * $cos(2.0 * PI * 8.0 * (2*i + 1) / 4096.0);
                    test_val_1_i = 0.0;

                    q_0_r = float_to_q(test_val_0_r);
                    q_0_i = float_to_q(test_val_0_i);
                    q_1_r = float_to_q(test_val_1_r);
                    q_1_i = float_to_q(test_val_1_i);

                    // 32-bit sample: {imag[15:0], real[15:0]}
                    sample_0 = {q_0_i, q_0_r};
                    sample_1 = {q_1_i, q_1_r};

                    // Write 64-bit word directly into IRAM
                    u_fft_top.u_datapath.u_iram.memory_iram[i] = {sample_1, sample_0};
                end
            end
        end
        $display("[INFO] All 4096 input samples loaded into IRAM.");

     
        rstn = 0;
        repeat (2) @(posedge clk);
        #1;
        rstn = 1;


        $display("[INFO] Initializing Twiddle Factor LUT in buff_mem (addresses 2048-4095)...");

        begin : load_twiddle_block
            integer f_all, f_lvl, f_ref;

            // 1. Try loading complete memory twiddle file if present
            f_all = $fopen("buff_mem_twiddles_all.hex", "r");
            if (f_all != 0) begin
                $fclose(f_all);
                $readmemh("buff_mem_twiddles_all.hex", u_fft_top.u_datapath.u_buff_mem.memory_buff);
                $display("[INFO] Successfully loaded Twiddle Factors from buff_mem_twiddles_all.hex.");
            end else begin
                // 2. Try loading individual level hex files if present
                f_lvl = $fopen("twiddle_lvl12.hex", "r");
                if (f_lvl != 0) begin
                    $fclose(f_lvl);
                    $display("[INFO] Loading Twiddle Factors from individual level hex files...");
                    $readmemh("twiddle_lvl12.hex", u_fft_top.u_datapath.u_buff_mem.memory_buff, 2048, 2559);
                    $readmemh("twiddle_lvl11.hex", u_fft_top.u_datapath.u_buff_mem.memory_buff, 2560, 2815);
                    $readmemh("twiddle_lvl10.hex", u_fft_top.u_datapath.u_buff_mem.memory_buff, 2816, 2943);
                    $readmemh("twiddle_lvl9.hex",  u_fft_top.u_datapath.u_buff_mem.memory_buff, 2944, 3007);
                    $readmemh("twiddle_lvl8.hex",  u_fft_top.u_datapath.u_buff_mem.memory_buff, 3008, 3039);
                    $readmemh("twiddle_lvl7.hex",  u_fft_top.u_datapath.u_buff_mem.memory_buff, 3040, 3055);
                    $readmemh("twiddle_lvl6.hex",  u_fft_top.u_datapath.u_buff_mem.memory_buff, 3056, 3063);
                    $readmemh("twiddle_lvl5.hex",  u_fft_top.u_datapath.u_buff_mem.memory_buff, 3064, 3067);
                    $readmemh("twiddle_lvl4.hex",  u_fft_top.u_datapath.u_buff_mem.memory_buff, 3068, 3069);
                    $readmemh("twiddle_lvl3.hex",  u_fft_top.u_datapath.u_buff_mem.memory_buff, 3070, 3070);
                    $readmemh("twiddle_lvl2.hex",  u_fft_top.u_datapath.u_buff_mem.memory_buff, 3071, 3071);
                    $readmemh("twiddle_lvl1.hex",  u_fft_top.u_datapath.u_buff_mem.memory_buff, 4095, 4095);
                    $display("[INFO] Loaded Levels 12 to 1 (addresses 2048..3071 and 4095).");
                end else begin
                    $display("[INFO] Hex level files not found, generating Twiddle Factors programmatically...");
                    for (k = 0; k < 512; k = k + 1) begin
                        u_fft_top.u_datapath.u_buff_mem.memory_buff[2048 + k] = 
                            {make_twiddle(4*k + 2, 4096), make_twiddle(4*k, 4096)};
                    end
                    for (k = 0; k < 256; k = k + 1) begin
                        u_fft_top.u_datapath.u_buff_mem.memory_buff[2560 + k] = 
                            {make_twiddle(4*k + 2, 2048), make_twiddle(4*k, 2048)};
                    end
                    for (k = 0; k < 128; k = k + 1) begin
                        u_fft_top.u_datapath.u_buff_mem.memory_buff[2816 + k] = 
                            {make_twiddle(4*k + 2, 1024), make_twiddle(4*k, 1024)};
                    end
                    for (k = 0; k < 64; k = k + 1) begin
                        u_fft_top.u_datapath.u_buff_mem.memory_buff[2944 + k] = 
                            {make_twiddle(4*k + 2, 512), make_twiddle(4*k, 512)};
                    end
                    for (k = 0; k < 32; k = k + 1) begin
                        u_fft_top.u_datapath.u_buff_mem.memory_buff[3008 + k] = 
                            {make_twiddle(4*k + 2, 256), make_twiddle(4*k, 256)};
                    end
                    for (k = 0; k < 16; k = k + 1) begin
                        u_fft_top.u_datapath.u_buff_mem.memory_buff[3040 + k] = 
                            {make_twiddle(4*k + 2, 128), make_twiddle(4*k, 128)};
                    end
                    for (k = 0; k < 8; k = k + 1) begin
                        u_fft_top.u_datapath.u_buff_mem.memory_buff[3056 + k] = 
                            {make_twiddle(4*k + 2, 64), make_twiddle(4*k, 64)};
                    end
                    for (k = 0; k < 4; k = k + 1) begin
                        u_fft_top.u_datapath.u_buff_mem.memory_buff[3064 + k] = 
                            {make_twiddle(4*k + 2, 32), make_twiddle(4*k, 32)};
                    end
                    for (k = 0; k < 2; k = k + 1) begin
                        u_fft_top.u_datapath.u_buff_mem.memory_buff[3068 + k] = 
                            {make_twiddle(4*k + 2, 16), make_twiddle(4*k, 16)};
                    end
                    u_fft_top.u_datapath.u_buff_mem.memory_buff[3070] = 
                        {make_twiddle(2, 8), make_twiddle(0, 8)};
                    u_fft_top.u_datapath.u_buff_mem.memory_buff[3071] = 
                        {make_twiddle(0, 4), make_twiddle(0, 4)};
                    u_fft_top.u_datapath.u_buff_mem.memory_buff[4095] = 
                        {make_twiddle(0, 2), make_twiddle(0, 2)};
                end

                // 3. Load reference twiddles (waste cycle padded values at addresses 3072..3083)
                f_ref = $fopen("twiddle_ref_64bit.hex", "r");
                if (f_ref != 0) begin
                    $fclose(f_ref);
                    $readmemh("twiddle_ref_64bit.hex", u_fft_top.u_datapath.u_buff_mem.memory_buff, 3072, 3083);
                    $display("[INFO] Loaded 12 reference twiddles into addresses 3072..3083 from twiddle_ref_64bit.hex.");
                end else begin
                    // Fallback reference twiddles: W_4^1 = -j
                    for (k = 0; k < 8; k = k + 1) begin
                        u_fft_top.u_datapath.u_buff_mem.memory_buff[3072 + k] = 
                            {make_twiddle(1, 4), make_twiddle(1, 4)};
                    end
                end
            end
        end

        $display("[INFO] Twiddle Factor LUT loaded successfully matching loading_add case statements.");

        while (!done) begin
            @(posedge clk);

            if (!dump_started) begin
                if (target_stage == 2 && lvl == 4'd2) begin
                    $dumpfile("fft_stage2.vcd");
                    $dumpvars(0, tb_fft);
                    dump_started = 1;
                    $display("[INFO] Started VCD dump specifically for Stage 2 -> fft_stage2.vcd");
                end else if (target_stage == 3 && lvl == 4'd3) begin
                    $dumpfile("fft_stage3.vcd");
                    $dumpvars(0, tb_fft);
                    dump_started = 1;
                    $display("[INFO] Started VCD dump specifically for Stage 3 -> fft_stage3.vcd");
                end
            end

            if (lvl != last_lvl) begin
                $display("[TIME: %0d ns] Advancing to FFT Level (Stage) %0d", $time, lvl);
                $fflush();
                last_lvl = lvl;
                if (target_stage == 1 && lvl == 4'd2) begin : dump_s1
                    integer f_s1;
                    $display("[INFO] Stage 1 completed successfully! Waveform saved to fft_stage1.vcd");
                    repeat (5) @(posedge clk);
                    f_s1 = $fopen("stage1_dump.txt", "w");
                    for (i = 0; i < 2048; i = i + 1) begin
                        $fdisplay(f_s1, "%0d %016h", i, u_fft_top.u_datapath.u_buff_mem.memory_buff[i]);
                    end
                    $fclose(f_s1);
                    $display("[INFO] Dumped Stage 1 memory to stage1_dump.txt");
                    $dumpflush;
                    $finish;
                end else if (target_stage == 2 && lvl == 4'd3) begin : dump_s2
                    integer f_s2;
                    $display("[INFO] Stage 2 completed successfully! Waveform saved to fft_stage2.vcd");
                    repeat (5) @(posedge clk);
                    f_s2 = $fopen("stage2_dump.txt", "w");
                    for (i = 0; i < 2048; i = i + 1) begin
                        $fdisplay(f_s2, "%0d %016h", i, u_fft_top.u_datapath.u_buff_mem.memory_buff[i]);
                    end
                    $fclose(f_s2);
                    $display("[INFO] Dumped Stage 2 memory to stage2_dump.txt");
                    $dumpflush;
                    $finish;
                end else if (target_stage == 3 && lvl == 4'd4) begin : dump_s3
                    integer f_s3;
                    $display("[INFO] Stage 3 completed successfully! Waveform saved to fft_stage3.vcd");
                    repeat (5) @(posedge clk);
                    f_s3 = $fopen("stage3_dump.txt", "w");
                    for (i = 0; i < 2048; i = i + 1) begin
                        $fdisplay(f_s3, "%0d %016h", i, u_fft_top.u_datapath.u_buff_mem.memory_buff[i]);
                    end
                    $fclose(f_s3);
                    $display("[INFO] Dumped Stage 3 memory to stage3_dump.txt");
                    $dumpflush;
                    $finish;
                end else if (target_stage == 0 && lvl == 4'd4) begin
                    $display("[INFO] All 3 stages (1, 2, and 3) completed successfully!");
                    $display("[INFO] Combined waveform saved to fft_stage1_2_3.vcd");
                    repeat (5) @(posedge clk);
                    $dumpflush;
                    $finish;
                end
            end
        end

        $display("[INFO] Computation complete! 'done' signal asserted at time %0d ns.", $time);
        $display("[INFO] Verifying stage 12 stop behavior...");
        $fflush();

        repeat (10) @(posedge clk);

        if (done === 1'b1 && oram_wr_enbl === 1'b0 && buff_wr_enbl === 1'b0 && lvl === 4'd12) begin
            $display("[PASS] Control signals successfully halted. No spurious writes after stage 12.");
        end else begin
            $display("[FAIL] Control signals did not freeze properly after stage 12!");
        end
        $fflush();
        $display(" Reading Output Spectrum from ORAM (First 32 Bins) - FIXED POINT REPRESENTATION (Q1.1.14):");
        $display(" Bin # | Real (Signed Dec) | Imag (Signed Dec) | Real (16-bit Hex) | Imag (16-bit Hex) | 32-bit Word Hex");

        ext_oram_rd_enbl = 1;
        
        begin : dump_oram_file
            integer f_oram, f_bins;
            f_oram = $fopen("oram_dump.txt", "w");
            f_bins = $fopen("oram_bins.txt", "w");
            for (i = 0; i < 2048; i = i + 1) begin
                $fdisplay(f_oram, "%0d %016h", i, u_fft_top.u_datapath.u_oram.memory_oram[i]);
                // In data i: MSB [63:32] is Bin 2*i, LSB [31:0] is Bin 2*i + 1
                $fdisplay(f_bins, "%0d %08h", 2*i,     u_fft_top.u_datapath.u_oram.memory_oram[i][63:32]);
                $fdisplay(f_bins, "%0d %08h", 2*i + 1, u_fft_top.u_datapath.u_oram.memory_oram[i][31:0]);
            end
            $fclose(f_oram);
            $fclose(f_bins);
            $display("[INFO] Dumped all 2048 ORAM words (4096 complex bins) to oram_dump.txt and oram_bins.txt");
        end
        
        for (i = 0; i < 2048; i = i + 1) begin
            ext_oram_rd_addr = i;
            @(posedge clk);
            #1;
            
            // MSB [63:32]: Bin 2*i
            q_0_r = oram_rd_data[47:32];
            q_0_i = oram_rd_data[63:48];

            // LSB [31:0]: Bin 2*i + 1
            q_1_r = oram_rd_data[15:0];
            q_1_i = oram_rd_data[31:16];

            // Display first 32 bins sequentially (Bin 0, Bin 1, Bin 2, Bin 3, ...)
            if (i < 16) begin
                $display(" %5d | %17d | %17d |        16'h%04h |        16'h%04h | 32'h%08h", 
                         2*i,     q_0_r, q_0_i, q_0_r, q_0_i, {q_0_i, q_0_r});
                $display(" %5d | %17d | %17d |        16'h%04h |        16'h%04h | 32'h%08h", 
                         2*i + 1, q_1_r, q_1_i, q_1_r, q_1_i, {q_1_i, q_1_r});
            end

            // Display significant peaks across the rest of spectrum
            if (i >= 16) begin
                if (q_0_r > 50 || q_0_r < -50 || q_0_i > 50 || q_0_i < -50) begin
                    $display(" Bin %4d (Addr %4d MSB): Real = %6d (16'h%04h), Imag = %6d (16'h%04h)", 
                             2*i,     i, q_0_r, q_0_r, q_0_i, q_0_i);
                end
                if (q_1_r > 50 || q_1_r < -50 || q_1_i > 50 || q_1_i < -50) begin
                    $display(" Bin %4d (Addr %4d LSB): Real = %6d (16'h%04h), Imag = %6d (16'h%04h)", 
                             2*i + 1, i, q_1_r, q_1_r, q_1_i, q_1_i);
                end
            end
        end

        ext_oram_rd_enbl = 0;
        $display(" FFT Verification Completed Successfully!");
        $fflush();
        $finish;
    end

    initial begin
        #2000000;
        $display("[TIMEOUT] Simulation exceeded 2ms without completing FFT! lvl=%0d, buff_wr_addr=%0d", lvl, buff_ram_wr_addr);
        $finish;
    end
    // Monitor butterfly writes for stages 1, 2, and 3
    integer num_stage_writes;
    reg [3:0] prev_lvl;
    always @(posedge clk) begin
        if (!rstn) begin
            num_stage_writes <= 0;
            prev_lvl <= 4'd1;
        end else begin
            if (lvl != prev_lvl) begin
                num_stage_writes <= 0;
                prev_lvl <= lvl;
            end
            if ((u_fft_top.u_control.count_5 == 3'd4 || u_fft_top.u_control.count_5 == 3'd5) && lvl <= 4'd3) begin
                if (num_stage_writes < 8) begin
                    $display("  [T=%0d ns] [Stage %0d Compute BF#%0d (C5=%0d)] wref=(%6d, %6di) In: x1=(%6d, %6di), x2=(%6d, %6di), W=(%6d, %6di) -> Out: y1=(%6d, %6di), y2=(%6d, %6di)",
                        $time, lvl, num_stage_writes, u_fft_top.u_control.count_5,
                        $signed(u_fft_top.u_datapath.wref_out[15:0]), $signed(u_fft_top.u_datapath.wref_out[31:16]),
                        x1_real, x1_imag,
                        x2_real, x2_imag,
                        tw_real, tw_imag,
                        y1_real, y1_imag,
                        y2_real, y2_imag);
                    num_stage_writes <= num_stage_writes + 1;
                end
            end
        end
    end

endmodule
