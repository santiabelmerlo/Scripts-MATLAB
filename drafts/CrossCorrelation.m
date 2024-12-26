% Parameters
fs = 1250;              % Sampling frequency in Hz
max_lag_ms = 125;       % Maximum lag in milliseconds
max_lag_samples = round(max_lag_ms / 1000 * fs); % Convert lag to samples
delay = 20;              % Delay en ms

% Example signals
% Create two signals (from the previous example)
t = 0:1/fs:5; % Time vector
lfp_BLA = sin(2 * pi * 10 * t) + 0.2 * randn(size(t)); % Signal 1 with noise
D = round((delay/1000)*fs);
lfp_PL = [zeros(1, D), lfp_BLA(1:end-D)]; % Signal 2, delayed by 20 ms

% Compute cross-correlation
[correlation, lags] = xcorr(lfp_PL, lfp_BLA, max_lag_samples, 'coeff');

% Convert lags to milliseconds
lag_ms = lags / fs * 1000;
disp(['Delay de: ' num2str(lag_ms(find(correlation == max(correlation))))]);

% Plot the cross-correlation
figure;
plot(lag_ms, correlation, 'LineWidth', 1.5);
xlabel('Lag (ms)');
ylabel('Cross-correlation (normalized)');
title('Cross-correlation of PL and BLA');
grid on;
