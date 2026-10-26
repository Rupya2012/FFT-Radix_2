%% =========================================================================
%% FFT OUTPUT VERIFICATION SCRIPT (MATLAB)
%% Compares Hardware Output (oram_bins.txt) with Golden Reference (golden_fft_reference.mat)
%% =========================================================================
clear; clc; close all;

%% -------------------------------------------------------------------------
%% 1. Load Golden Reference
%% -------------------------------------------------------------------------
if ~exist('golden_fft_reference.mat', 'file')
    error('golden_fft_reference.mat not found. Please run generate_input_data.m first.');
end

load('golden_fft_reference.mat'); % Loads 'complex_input' and 'golden_fft'
golden_fft = golden_fft(:); % Ensure column vector to match hw_fft
N = length(golden_fft);
fprintf('Loaded golden FFT reference (%d points).\n', N);

%% -------------------------------------------------------------------------
%% 2. Read and Parse Hardware Output from oram_bins.txt
%% -------------------------------------------------------------------------
bins_file = 'oram_bins.txt';
if ~exist(bins_file, 'file')
    error('%s not found. Please run the simulation first.', bins_file);
end

fid = fopen(bins_file, 'r');
data = textscan(fid, '%d %s');
fclose(fid);

bin_indices = data{1};
hex_strings = data{2};

if length(bin_indices) ~= N
    warning('Expected %d bins, but read %d from %s', N, length(bin_indices), bins_file);
end

hw_fft = zeros(N, 1);
FRACTIONAL_L = 14;
SCALE_FACTOR = 2^FRACTIONAL_L; % 16384 for Q1.14

for idx = 1:length(bin_indices)
    b_num = bin_indices(idx) + 1; % 1-based indexing
    if b_num <= N
        h_str = hex_strings{idx};
        val32 = hex2dec(h_str);
        
        % 32-bit format: MSB 16 = Imag, LSB 16 = Real
        u_im = bitshift(val32, -16);
        u_re = bitand(val32, 65535);
        
        % Two's complement conversion
        if u_re >= 32768, s_re = u_re - 65536; else, s_re = u_re; end
        if u_im >= 32768, s_im = u_im - 65536; else, s_im = u_im; end
        
        % Convert from Q1.14 to float
        hw_fft(b_num) = (s_re + 1j * s_im) / SCALE_FACTOR;
    end
end
fprintf('Successfully parsed %d hardware output bins.\n\n', length(bin_indices));

%% -------------------------------------------------------------------------
%% 3. Account for Hardware Butterfly Divide-by-2 per Stage Scaling
%%    In hardware: 12 stages with divide-by-2 gives 1/(2^12) = 1/4096 factor
%% -------------------------------------------------------------------------
% Scaled Golden reference to match hardware's 1/N scaling
golden_scaled = golden_fft / N;

%% -------------------------------------------------------------------------
%% 4. Check Both Natural Order and Bit-Reversed Order
%% -------------------------------------------------------------------------
% Natural order comparison
norm_golden = norm(golden_scaled);
norm_hw     = norm(hw_fft);
corr_nat    = abs(hw_fft' * golden_scaled) / (norm_hw * norm_golden);

% Bit-reversed index mapping
br_indices = bitrevorder(1:N);
hw_fft_br  = hw_fft(br_indices);
corr_br    = abs(hw_fft_br' * golden_scaled) / (norm(hw_fft_br) * norm_golden);

fprintf('=================================================================\n');
fprintf('                   VERIFICATION METRICS                          \n');
fprintf('=================================================================\n');
fprintf('Correlation (Natural Order)    : %8.4f %%\n', corr_nat * 100);
fprintf('Correlation (Bit-Reversed Order): %8.4f %%\n', corr_br * 100);

if corr_nat >= corr_br
    selected_hw = hw_fft;
    best_mode = 'Natural Order';
else
    selected_hw = hw_fft_br;
    best_mode = 'Bit-Reversed Order';
end
fprintf('Best Matching Output Mode      : %s\n', best_mode);

% Error metrics
err = selected_hw - golden_scaled;
mse = mean(abs(err).^2);
signal_power = mean(abs(golden_scaled).^2);
sqnr_db = 10 * log10(signal_power / mse);

fprintf('Mean Squared Error (MSE)       : %e\n', mse);
fprintf('Signal-to-Quantization Noise   : %6.2f dB\n', sqnr_db);
fprintf('Max Absolute Error             : %e\n', max(abs(err)));
fprintf('=================================================================\n\n');

%% -------------------------------------------------------------------------
%% 5. Display Comparison for Top 10 Energy Bins
%% -------------------------------------------------------------------------
[~, top_bins] = sort(abs(golden_scaled), 'descend');
top10 = top_bins(1:min(10, N));

fprintf('Top 10 Energy Frequency Bins Comparison:\n');
fprintf(' Bin # | Golden Mag | HW Mag   | Golden (Real, Imag)     | HW (Real, Imag)\n');
fprintf('-------+------------+----------+-------------------------+-------------------------\n');
for k = 1:length(top10)
    b = top10(k);
    fprintf(' %5d | %10.5f | %8.5f | (%8.4f, %8.4f) | (%8.4f, %8.4f)\n', ...
            b - 1, abs(golden_scaled(b)), abs(selected_hw(b)), ...
            real(golden_scaled(b)), imag(golden_scaled(b)), ...
            real(selected_hw(b)), imag(selected_hw(b)));
end
fprintf('-----------------------------------------------------------------\n');

%% -------------------------------------------------------------------------
%% 6. Plotting Spectra & Error
%% -------------------------------------------------------------------------
figure('Name', 'FFT Hardware vs Golden Verification', 'Position', [100, 100, 1100, 700]);

% Subplot 1: Magnitude Spectra
subplot(3, 1, 1);
plot(0:(N-1), abs(golden_scaled), 'b-', 'LineWidth', 1.2); hold on;
plot(0:(N-1), abs(selected_hw), 'r--', 'LineWidth', 1.0);
grid on;
legend('MATLAB Golden (Scaled 1/4096)', sprintf('Hardware Output (%s)', best_mode));
title(sprintf('Magnitude Spectrum Comparison (N = %d, SQNR = %.2f dB)', N, sqnr_db));
xlabel('Frequency Bin'); ylabel('Magnitude');

% Subplot 2: Absolute Error
subplot(3, 1, 2);
plot(0:(N-1), abs(err), 'k-', 'LineWidth', 0.8);
grid on;
title('Absolute Error Magnitude per Frequency Bin (|HW - Golden|)');
xlabel('Frequency Bin'); ylabel('Error Magnitude');

% Subplot 3: First 32 Bins Zoom (Real and Imaginary)
subplot(3, 1, 3);
stem(0:31, real(golden_scaled(1:32)), 'bo', 'LineWidth', 1.0); hold on;
stem(0:31, real(selected_hw(1:32)), 'rx', 'LineWidth', 1.2);
grid on;
legend('Golden Real', 'HW Real');
title('Zoom-In Comparison: First 32 Bins (Real Component)');
xlabel('Frequency Bin'); ylabel('Amplitude');

fprintf('\nVerification plots generated successfully.\n');
