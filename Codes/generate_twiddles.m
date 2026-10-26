%% =========================================================================
%% FFT RADIX-2 TWIDDLE FACTOR GENERATOR
%% Memory Layout (12-bit address space, 4096 entries):
%%   - Addr 0000..2047: Data Buffer Area (initialized to 0)
%%   - Addr 2048..3071: Levels 12 down to 2 Twiddles (1024 words)
%%   - Addr 3072..3083: Waste Cycle Reference Twiddles (12 words, W_N^1 padded with 32 zeros)
%%   - Addr 3084..4094: Padding
%%   - Addr 4095:       Level 1 Twiddle (1 word, W_2^0)
%% =========================================================================
clear; clc;

FRACTIONAL_L = 14;              % Q1.1.14 fixed point
SCALE_FACTOR = 2^FRACTIONAL_L;    % 16384

%% -------------------------------------------------------------------------
%% 1. Generate Reference Twiddles File (twiddle_ref_64bit.hex)
%%    12 lines: W_N^1 for N = 2^1 to 2^12
%%    64-bit word: [63:32] = 32'h00000000 (padded with 32 zeros)
%%                 [31:0]  = {imag[15:0], real[15:0]}
%% -------------------------------------------------------------------------
ref_filename = 'twiddle_ref_64bit.hex';
fid_ref = fopen(ref_filename, 'w');
fprintf('Generating Reference Twiddles (twiddle_ref_64bit.hex)...\n');

ref_words = cell(12, 1);
for lvl = 1:12
    N = 2^lvl;
    tw32 = make_twiddle_32(1, N, SCALE_FACTOR);
    tw64_ref = sprintf('00000000%s', tw32);
    ref_words{lvl} = tw64_ref;
    fprintf(fid_ref, '%s\n', tw64_ref);
    fprintf('  Lvl %2d (N=%4d): %s\n', lvl, N, tw64_ref);
end
fclose(fid_ref);

%% -------------------------------------------------------------------------
%% 2. Generate Separate Hex Files for Each Level (Levels 12 down to 1)
%%    64-bit word: {tw1 [63:32], tw0 [31:0]} = {W^{4m+2}, W^{4m}}
%% -------------------------------------------------------------------------
fprintf('\nGenerating Level-wise Twiddle Files:\n');
lvl_config = [
    12, 4096, 512;   % 1024 twiddles (powers 0,2,4..2046) in 512 words (Addr 2048..2559)
    11, 2048, 256;   %  512 twiddles (powers 0,2,4..1022) in 256 words (Addr 2560..2815)
    10, 1024, 128;   %  256 twiddles (powers 0,2,4..510)  in 128 words (Addr 2816..2943)
     9,  512,  64;   %  128 twiddles in 64 words (Addr 2944..3007)
     8,  256,  32;   %   64 twiddles in 32 words (Addr 3008..3039)
     7,  128,  16;   %   32 twiddles in 16 words (Addr 3040..3055)
     6,   64,   8;   %   16 twiddles in 8 words  (Addr 3056..3063)
     5,   32,   4;   %    8 twiddles in 4 words  (Addr 3064..3067)
     4,   16,   2;   %    4 twiddles in 2 words  (Addr 3068..3069)
     3,    8,   1;   %    2 twiddles in 1 word   (Addr 3070)
     2,    4,   1;   %    W4^0 in 1 word         (Addr 3071)
     1,    2,   1    %    W2^0 in 1 word         (Addr 4095)
];

for i = 1:size(lvl_config, 1)
    lvl       = lvl_config(i, 1);
    N         = lvl_config(i, 2);
    num_words = lvl_config(i, 3);
    
    lvl_filename = sprintf('twiddle_lvl%d.hex', lvl);
    fid_lvl = fopen(lvl_filename, 'w');
    
    for m = 0:(num_words - 1)
        if lvl > 2
            p = 2 * m;        % Base twiddle W^{2m} for both BF0 and BF1
            tw_32 = make_twiddle_32(p, N, SCALE_FACTOR);
            tw0_32 = tw_32;
            tw1_32 = tw_32;
        elseif lvl == 2
            tw0_32 = make_twiddle_32(0, 4, SCALE_FACTOR);
            tw1_32 = make_twiddle_32(0, 4, SCALE_FACTOR);
        else % lvl == 1
            tw0_32 = make_twiddle_32(0, 2, SCALE_FACTOR);
            tw1_32 = make_twiddle_32(0, 2, SCALE_FACTOR);
        end
        tw64 = sprintf('%s%s', tw1_32, tw0_32);
        fprintf(fid_lvl, '%s\n', tw64);
    end
    fclose(fid_lvl);
    fprintf('  Level %2d: %-18s (%4d words)\n', lvl, lvl_filename, num_words);
end

%% -------------------------------------------------------------------------
%% 3. Generate Complete Buffer Memory File (addresses 0 to 4095)
%% -------------------------------------------------------------------------
all_filename = 'buff_mem_twiddles_all.hex';
fid_all = fopen(all_filename, 'w');

TOTAL_ADDR = 4096;
mem = cell(TOTAL_ADDR, 1);
for addr = 0:(TOTAL_ADDR - 1)
    mem{addr + 1} = '0000000000000000';
end

% Default fill twiddle area (2048..4095) with W_2^0 = 1 + 0j
w2_0 = make_twiddle_32(0, 2, SCALE_FACTOR);
default_word = sprintf('%s%s', w2_0, w2_0);
for addr = 2048:4095
    mem{addr + 1} = default_word;
end

% 2048..2559: Level 12 (512 words)
for m = 0:511
    tw = make_twiddle_32(2*m, 4096, SCALE_FACTOR);
    mem{2048 + m + 1} = sprintf('%s%s', tw, tw);
end

% 2560..2815: Level 11 (256 words)
for m = 0:255
    tw = make_twiddle_32(2*m, 2048, SCALE_FACTOR);
    mem{2560 + m + 1} = sprintf('%s%s', tw, tw);
end

% 2816..2943: Level 10 (128 words)
for m = 0:127
    tw = make_twiddle_32(2*m, 1024, SCALE_FACTOR);
    mem{2816 + m + 1} = sprintf('%s%s', tw, tw);
end

% 2944..3007: Level 9 (64 words)
for m = 0:63
    tw = make_twiddle_32(2*m, 512, SCALE_FACTOR);
    mem{2944 + m + 1} = sprintf('%s%s', tw, tw);
end

% 3008..3039: Level 8 (32 words)
for m = 0:31
    tw = make_twiddle_32(2*m, 256, SCALE_FACTOR);
    mem{3008 + m + 1} = sprintf('%s%s', tw, tw);
end

% 3040..3055: Level 7 (16 words)
for m = 0:15
    tw = make_twiddle_32(2*m, 128, SCALE_FACTOR);
    mem{3040 + m + 1} = sprintf('%s%s', tw, tw);
end

% 3056..3063: Level 6 (8 words)
for m = 0:7
    tw = make_twiddle_32(2*m, 64, SCALE_FACTOR);
    mem{3056 + m + 1} = sprintf('%s%s', tw, tw);
end

% 3064..3067: Level 5 (4 words)
for m = 0:3
    tw = make_twiddle_32(2*m, 32, SCALE_FACTOR);
    mem{3064 + m + 1} = sprintf('%s%s', tw, tw);
end

% 3068..3069: Level 4 (2 words)
for m = 0:1
    tw = make_twiddle_32(2*m, 16, SCALE_FACTOR);
    mem{3068 + m + 1} = sprintf('%s%s', tw, tw);
end

% 3070: Level 3 (1 word)
tw3 = make_twiddle_32(0, 8, SCALE_FACTOR);
mem{3070 + 1} = sprintf('%s%s', tw3, tw3);

% 3071: Level 2 (1 word)
mem{3071 + 1} = sprintf('%s%s', make_twiddle_32(0, 4, SCALE_FACTOR), ...
                                make_twiddle_32(0, 4, SCALE_FACTOR));

% 3072..3083: Waste Cycle Reference Twiddles (12 words, right after 2048+1024)
for lvl = 1:12
    mem{3072 + (lvl - 1) + 1} = ref_words{lvl};
end

% 4095: Last Address - Level 1 Twiddle (1 word)
mem{4095 + 1} = sprintf('%s%s', make_twiddle_32(0, 2, SCALE_FACTOR), ...
                                make_twiddle_32(0, 2, SCALE_FACTOR));

% Write full memory hex file
for addr = 0:(TOTAL_ADDR - 1)
    fprintf(fid_all, '%s\n', mem{addr + 1});
end
fclose(fid_all);
fprintf('\n  Full memory file generated: %s (Addresses 0..4095)\n', all_filename);

%% =========================================================================
%% Helper Function: Compute 32-bit Q1.14 Twiddle in Hex {imag[15:0], real[15:0]}
%% =========================================================================
function hex32 = make_twiddle_32(k, N, SCALE_FACTOR)
    c = cos(2.0 * pi * k / N);
    s = -sin(2.0 * pi * k / N);
    
    int_re = round(c * SCALE_FACTOR);
    int_im = round(s * SCALE_FACTOR);
    
    int_re = max(-32768, min(32767, int_re));
    int_im = max(-32768, min(32767, int_im));
    
    if int_re < 0, u_re = int_re + 65536; else, u_re = int_re; end
    if int_im < 0, u_im = int_im + 65536; else, u_im = int_im; end
    
    hex32 = sprintf('%04X%04X', u_im, u_re);
end
