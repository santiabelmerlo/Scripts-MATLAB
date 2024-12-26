%%
% Parameters
Fs = 1250;
window_size = 3 * Fs; % Window size in samples. Input in second (2 s).
window_step = 0.5 * Fs; % Step size in samples. Input in seconds (0.1 s).
window = hann(window_size); % Hanning window

% Compute spectrogram
[S, F, T] = spectrogram(ica_result(5,:), window, window_size - window_step, 2^nextpow2(window_size), Fs);

% Plot the spectrogram
figure;
subplot(211);
imagesc(T, F, 10*log10(abs(S)));
axis xy;
xlabel('Time (s)');
ylabel('Frequency (Hz)');
title('Time-Frequency Representation (Spectrogram)');
ylim([0 120]);
colormap(jet);    
hcb = colorbar; hcb.YLabel.String = 'Power (dB)'; hcb.FontSize = 12;
caxis([30 50]);
subplot(212);
plot(F,mean(10*log10(abs(S)),2));
xlim([0 120]);

%%
plot_matrix_smooth(abs(S'),T',F','l',5);
hcb = colorbar; hcb.YLabel.String = 'Power (dB)'; hcb.FontSize = 12;
caxis([40 50]);
ylim([0 12]);