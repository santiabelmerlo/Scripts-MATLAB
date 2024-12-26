%%
name = 'R17D12';
[amplifier_lfp] = LoadBinary(strcat(name,'_lfp.dat'), 50, 70);
amplifier(1,:) = amplifier_lfp * 0.195; % Convertir un canal de registro de bits a microvolts (uV).
[amplifier_lfp] = LoadBinary(strcat(name,'_lfp.dat'), 32, 70);
amplifier(2,:) = amplifier_lfp * 0.195; % Convertir un canal de registro de bits a microvolts (uV).
[amplifier_lfp] = LoadBinary(strcat(name,'_lfp.dat'), 25, 70);
amplifier(3,:) = amplifier_lfp * 0.195; % Convertir un canal de registro de bits a microvolts (uV).
[amplifier_lfp] = LoadBinary(strcat(name,'_lfp.dat'), 12, 70);
amplifier(4,:) = amplifier_lfp * 0.195; % Convertir un canal de registro de bits a microvolts (uV).
[amplifier_lfp] = LoadBinary(strcat(name,'_lfp.dat'), 28, 70);
amplifier(5,:) = amplifier_lfp * 0.195; % Convertir un canal de registro de bits a microvolts (uV).
%%
signal = amplifier;
time = amplifier_timestamps_lfp;
% Perform Independent Component Analysis (ICA)
num_components = 10; % Number of components to extract
ica_result = fastica(signal, 'numOfIC', num_components);

%% Find the component representing the 50 Hz line noise
line_noise_component = ica_result(find(abs(mean(ica_result) - 10) < 1), :);

% Remove the line noise component from the original signal
cleaned_signal = signal - line_noise_component;

% Plot original signal, line noise component, and cleaned signal
figure;
subplot(3,1,1);
plot(time, signal);
xlabel('Time (s)');
ylabel('Amplitude');
title('Original Signal');

subplot(3,1,2);
plot(time, line_noise_component);
xlabel('Time (s)');
ylabel('Amplitude');
title('Extracted 50 Hz Line Noise Component');

subplot(3,1,3);
plot(time, cleaned_signal);
xlabel('Time (s)');
ylabel('Amplitude');
title('Cleaned Signal (Without 50 Hz Line Noise)');
