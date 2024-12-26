clc;
clearvars -except amplifier_lfp amplifier_timestamps_lfp Fs
% Define filter parameters
bandpass_freq = [2, 4]; % Bandpass frequency range (Hz)
filter_order = 4; % Filter order

% Design bandpass filterc
[b, a] = butter(filter_order, bandpass_freq / (Fs / 2), 'bandpass');

% Apply bandpass filter to the signal
filtered_signal = filtfilt(b, a, amplifier_lfp);

% Apply Hilbert transform to get instantaneous amplitude
hilbert_transform = hilbert(filtered_signal);
instantaneous_amplitude = abs(hilbert_transform);
% instantaneous_amplitude = instantaneous_amplitude/mean(instantaneous_amplitude);
time = amplifier_timestamps_lfp;

% Plot original signal and instantaneous amplitude
figure;
ax1 = subplot(2,1,1);
plot(time, filtered_signal);
xlabel('Time (s)');
ylabel('Amplitude');
title('Original Signal');

ax2 = subplot(2,1,2);
plot(time, instantaneous_amplitude);
xlabel('Time (s)');
ylabel('Instantaneous Amplitude');
title('Instantaneous Theta Amplitude');

linkaxes([ax1 ax2], 'x');