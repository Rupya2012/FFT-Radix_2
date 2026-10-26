%% =========================================================================
%% FFT RADIX-2 INPUT DATA GENERATOR (4096 SAMPLES)
%% Generates iram_input.hex (2048 words x 64-bit) in Q1.1.14 format
%% =========================================================================
clear; clc;

NUM_SAMPLES  = 4096;            % Total input points
NUM_WORDS    = NUM_SAMPLES / 2; % 2048 addresses (64-bit words)
FRACTIONAL_L = 14;              % Q1.1.14 fixed point
SCALE_FACTOR = 2^FRACTIONAL_L;    % 16384
HEX_FILENAME = 'iram_input.hex';

% Set to true for complex random input; false for real-only (imag = 0)
COMPLEX_INPUT = true;

%% -------------------------------------------------------------------------
%% 1. Generate Random Float Values in Range [-0.5, 0.5]
%% -------------------------------------------------------------------------
real_part = rand(NUM_SAMPLES, 1) - 0.5;

if COMPLEX_INPUT
    imag_part = rand(NUM_SAMPLES, 1) - 0.5;
else
    imag_part = zeros(NUM_SAMPLES, 1);
end

complex_input = real_part + 1j * imag_part;

%% -------------------------------------------------------------------------
%% 2. Convert to Q1.1.14 Fixed-Point and Pack into 64-bit Hex Words
%%    Address i: [63:32] = Sample (2i + 1), [31:0] = Sample (2i)
%% -------------------------------------------------------------------------
fid = fopen(HEX_FILENAME, 'w');
if fid == -1
    error('Could not open file %s for writing.', HEX_FILENAME);
end

fprintf('Generating %d samples into %s (%d addresses)...\n', ...
        NUM_SAMPLES, HEX_FILENAME, NUM_WORDS);

sample_32hex = cell(NUM_SAMPLES, 1);

for n = 1:NUM_SAMPLES
    int_re = round(real_part(n) * SCALE_FACTOR);
    int_im = round(imag_part(n) * SCALE_FACTOR);
    
    int_re = max(-32768, min(32767, int_re));
    int_im = max(-32768, min(32767, int_im));
    
    if int_re < 0, u_re = int_re + 65536; else, u_re = int_re; end
    if int_im < 0, u_im = int_im + 65536; else, u_im = int_im; end
    
    % Pack 32-bit: MSB 16 = imag, LSB 16 = real
    sample_32hex{n} = sprintf('%04X%04X', u_im, u_re);
end

for i = 0:(NUM_WORDS - 1)
    s0_hex = sample_32hex{2*i + 1}; % Sample 2*i
    s1_hex = sample_32hex{2*i + 2}; % Sample 2*i + 1
    
    % 64-bit word: MSB 32 = sample 0 (2*i), LSB 32 = sample 1 (2*i + 1)
    word_64hex = sprintf('%s%s', s0_hex, s1_hex);
    fprintf(fid, '%s\n', word_64hex);
end

fclose(fid);
fprintf('Done! Successfully generated %s (2048 lines).\n', HEX_FILENAME);

%% -------------------------------------------------------------------------
%% 3. Optional: Save Golden Reference for Verification
%% -------------------------------------------------------------------------
golden_fft = fft(complex_input);
save('golden_fft_reference.mat', 'complex_input', 'golden_fft');
fprintf('Saved golden reference vectors to golden_fft_reference.mat.\n');
