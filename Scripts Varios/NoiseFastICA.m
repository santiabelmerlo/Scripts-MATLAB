% % Assuming your data is stored in a variable called 'lfp_data'

amplifier_lfp(1,:) = LoadBinary(strcat(name,'_lfp.dat'), 25, ch_total);
amplifier_lfp(1,:) = amplifier_lfp(1,:) * 0.195; % Convertir un canal de registro de bits a microvolts (uV).

amplifier_lfp(2,:) = LoadBinary(strcat(name,'_lfp.dat'), 12, ch_total);
amplifier_lfp(2,:) = amplifier_lfp(2,:) * 0.195; % Convertir un canal de registro de bits a microvolts (uV).

amplifier_lfp(3,:) = LoadBinary(strcat(name,'_lfp.dat'), 9, ch_total);
amplifier_lfp(3,:) = amplifier_lfp(3,:) * 0.195; % Convertir un canal de registro de bits a microvolts (uV).

amplifier_lfp(4,:) = LoadBinary(strcat(name,'_lfp.dat'), 28, ch_total);
amplifier_lfp(4,:) = amplifier_lfp(4,:) * 0.195; % Convertir un canal de registro de bits a microvolts (uV).

%%
% Example: Low-pass filter to remove high-frequency noise

for i = 1:size(amplifier_lfp,1);
    highpass = 1; lowpass = 300; % Frecuencias de corte del filtro. Corte pasabajos en nyquist frequency.
    data = amplifier_lfp(i,:); % Señal que queremos filtrar
    samplePeriod = 1/1250; % Frecuencia de muestreo de la señal subsampleada
    % Aplicamos un filtro pasa altos con corte en 0.1 Hz
    filtHPF = (2*highpass)/(1/samplePeriod);
    [b, a] = butter(1, filtHPF, 'high');
    data_hp = filtfilt(b, a, data);
    % Aplicamos un filtro pasa bajos con corte en 300 Hz
    filtLPF = (2*lowpass)/(1/samplePeriod);
    [b, a] = butter(1, filtLPF, 'low');
    data_hlp = filtfilt(b, a, data_hp); %señal de mag de acel filtrada
    amplifier_lfp(i,:) = data_hlp; % Guardamos la señal filtrada como "amplifier_BLA_downsample_filt"
    clear data_hlp a b data filtHPF data_hp filtLPF highpass lowpass samplePeriod;% Borramos las variables que no me sirven más
end

%% Create a mixing matrix (A) if it's not known
num_components = size(amplifier_lfp, 1); % Number of independent components
A = rand(num_components, num_components); % Initialize with random values

[S, A_est, W] = fastica(amplifier_lfp, 'approach', 'symm');

% Visualize the components (you may need to adjust for your specific data)
figure;
for i = 1:num_components
    subplot(num_components, 1, i);
    plot(S(i, :));
    title(['Component ', num2str(i)]);
end

%%
params.Fs = 1250; 
params.err = [2 0.05]; 
params.tapers = [1 1]; 
params.pad = 3; 
params.fpass = [0 150];
movingwin = [1 0.05];

A = S;

[S,f,Serr]=mtspectrumc(A(1,:),params);

plot(f,S);


%%

% Example: If component 2 corresponds to 50 Hz noise, remove it
S_cleaned = S([1, 3:end], :);

lfp_cleaned = W * S_cleaned;