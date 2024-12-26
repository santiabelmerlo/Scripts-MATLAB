%% Working with my data
clc
clear all
path = pwd;
[~,name,~] = fileparts(pwd);
name = name(1:6);

% Seteamos qué canal queremos levantar de la señal
Fs = 1250; % Frecuencia de sampleo

% load(strcat(name,'_sessioninfo.mat'), 'BLA_mainchannel'); ch = BLA_mainchannel; clear BLA_mainchannel; % Canal a levantar
load(strcat(name,'_sessioninfo.mat'), 'PL_mainchannel'); ch = PL_mainchannel; clear PL_mainchannel; % Canal a levantar
% load(strcat(name,'_sessioninfo.mat'), 'IL_mainchannel'); ch = IL_mainchannel; clear IL_mainchannel; % Canal a levantar
% load(strcat(name,'_sessioninfo.mat'), 'EO_channels'); ch = EO_channels; clear EO_channels; % Canal a levantar

load(strcat(name,'_sessioninfo.mat'), 'ch_total'); % Número de canales totales
load(strcat(name,'_sessioninfo.mat'), 'paradigm'); % Tipo de paradigma. Appetitive or aversive

% Cargo los tiempos de los tonos
load(strcat(name,'_freezing.mat'),'TTL_CS1_inicio','TTL_CS1_fin','TTL_CS2_inicio','TTL_CS2_fin');

% Cargo los tiempos de los tonos
load(strcat(name,'_epileptic.mat'));

% Cargamos los datos del amplificador
amplifier_timestamps = readNPY(strcat(name,'_timestamps.npy')); % Cargamos el estado de cada input del IO Board.
amplifier_timestamps = double(amplifier_timestamps(1):1:amplifier_timestamps(end)); % Hay que hacer esto porque amplifier.timestamps devuelve distinto número de tiempos que de registro.
amplifier_timestamps_lfp = double(amplifier_timestamps(1):24:amplifier_timestamps(end)); % Hay que hacer esto porque amplifier.timestamps devuelve distinto número de tiempos que de registro.
t = (amplifier_timestamps_lfp - amplifier_timestamps(1))/30000; % Le restamos el primer timestamp y lo pasamos a segundos.

% Cargamos un canal LFP del amplificador
disp(['Loading LFP signal...']);
[lfp] = LoadBinary(strcat(name,'_lfp.dat'), ch, ch_total);
lfp = lfp * 0.195; % Convertir un canal de registro de bits a microvolts (uV).
clear amplifier_timestamps amplifier_timestamps_lfp;

% Filtramos la señal
disp(['Filtering LFP signal...']);
highpass = 0.1; lowpass = 300; % Frecuencias de corte del filtro. Corte pasabajos en nyquist frequency.
data = lfp; % Señal que queremos filtrar
samplePeriod = 1/1250; % Frecuencia de muestreo de la señal subsampleada
% Aplicamos un filtro pasa altos con corte en 0.1 Hz
filtHPF = (2*highpass)/(1/samplePeriod);
[b, a] = butter(4, filtHPF, 'high');
data_hp = filtfilt(b, a, data);
% Aplicamos un filtro pasa bajos con corte en 300 Hz
filtLPF = (2*lowpass)/(1/samplePeriod);
[b, a] = butter(4, filtLPF, 'low');
data_hlp = filtfilt(b, a, data_hp); %señal de mag de acel filtrada
lfp = data_hlp; % Guardamos la señal filtrada como "amplifier_BLA_downsample_filt"
clear data_hlp a b data filtHPF data_hp filtLPF highpass lowpass samplePeriod;% Borramos las variables que no me sirven más

data_length = length(lfp);
srate = 1250;
dt = 1/srate;

% Borramos momentos de ruido
% lfp_noise = isoutlier(lfp,'median',10);
% lfp_noise = extendoutlier(lfp_noise,Fs*2.5);
% lfp(~lfp_noise == 0) = 0;
% figure()
% plot(lfp);

% Busco las posiciones en S donde inician y finalizan los tonos
j = 1;
for i = 1:size(TTL_CS1_inicio,1);
    CS1_inicioenS(j) = min(find(abs(t-TTL_CS1_inicio(i)) == min(abs(t-TTL_CS1_inicio(i)))));
    CS1_finenS(j) = min(find(abs(t-TTL_CS1_fin(i)) == min(abs(t-TTL_CS1_fin(i)))));
    CS2_inicioenS(j) = min(find(abs(t-TTL_CS2_inicio(i)) == min(abs(t-TTL_CS2_inicio(i)))));
    CS2_finenS(j) = min(find(abs(t-TTL_CS2_fin(i)) == min(abs(t-TTL_CS2_fin(i)))));
    j = j + 1;
end

% Busco las posiciones en S donde inician los freezing
j = 1;
for i = 1:size(inicio_freezing,2);
    freezing_inicioenS(j) = min(find(abs(t-inicio_freezing(1,i)) == min(abs(t-inicio_freezing(1,i)))));
    freezing_finenS(j) = min(find(abs(t-fin_freezing(1,i)) == min(abs(t-fin_freezing(1,i)))));
    j = j + 1;
end
% Busco las posiciones en S donde inician los epileptic
j = 1;
for i = 1:size(inicio_epileptic,2);
    epileptic_inicioenS(j) = min(find(abs(t-inicio_epileptic(1,i)) == min(abs(t-inicio_epileptic(1,i)))));
    epileptic_finenS(j) = min(find(abs(t-fin_epileptic(1,i)) == min(abs(t-fin_epileptic(1,i)))));
    j = j + 1;
end

%% Calculamos el Comodulograma
disp(['Processing Comodulogram...']);
clc
clear Comodulogram Comodulograms

for i = 1
    lfp1 = lfp(1,CS1_inicioenS(i):CS1_finenS(i));
    k = 1250 * randi(20,1); % Corrimiento de la fase de 1 a 20 seg.
    lfp_shift = lfp(1,CS1_inicioenS(i)+k:CS1_finenS(i)+k);
    data_length = length(lfp1);

    % Define the amplitude- and phase-frequencies
    PhaseFreqVector = 0:1:30;
    AmpFreqVector = 10:5:200;
    PhaseFreq_BandWidth = 1;
    AmpFreq_BandWidth = 20;

    % Calculamos el comodulograma
    Comodulogram(:,:,i) = comodulogram(lfp1); % Comodulograma normal
    Comodulogram_shift(:,:,i) = comodulogram_shift(lfp1,lfp_shift); % Comodulograma shift
end

% Plot comodulogram
Comodulograms = nanmean(Comodulogram,3);
Comodulograms_shift = nanmean(Comodulogram_shift,3);

figure();
subplot(121);
contourf(PhaseFreqVector+PhaseFreq_BandWidth/2,AmpFreqVector+AmpFreq_BandWidth/2,Comodulograms',1000,'lines','none');  % Aumentar valor de 30 a 1000 Si quiero más 
set(gca,'fontsize',14);
ylabel('Amplitude Frequency (Hz)');
xlabel('Phase Frequency (Hz)');
colormap('jet');
colorbar;
hcb1 = colorbar; hcb1.YLabel.String = strcat('Modulation Index'); hcb1.FontSize = 12;
xlim([1.5 30]);
ylim([30 100]);
clim([0 0.002]);

subplot(122);
contourf(PhaseFreqVector+PhaseFreq_BandWidth/2,AmpFreqVector+AmpFreq_BandWidth/2,Comodulograms_shift',1000,'lines','none');  % Aumentar valor de 30 a 1000 Si quiero más 
set(gca,'fontsize',14);
ylabel('Amplitude Frequency (Hz)');
xlabel('Phase Frequency (Hz)');
colormap('jet');
colorbar;
hcb1 = colorbar; hcb1.YLabel.String = strcat('Modulation Index'); hcb1.FontSize = 12;
xlim([1.5 30]);
ylim([30 100]);
clim([0 0.002]);

%% Comodulogram Phase(Degree) vs. Frequency(Hz) in Normalized Power Units
tic

for i = 1:20
    lfp1 = lfp(1,CS2_inicioenS(i):CS2_finenS(i));
    data_length = length(lfp1);

    % Define the frequency ranges
    PhaseFreq_Band = [2, 3]; % Phase frequency band
    AmpFreqVector = 20:5:200; % Amplitude frequencies
    AmpFreq_BandWidth = 10; % Amplitude frequency bandwidth

    % Define phase bins
    nbin = 5; % Number of phase bins
    position = zeros(1, nbin); % Phase bin positions
    winsize = 2 * pi / nbin;
    for j = 1:nbin
        position(j) = -pi + (j-1) * winsize; % -pi to pi
    end

    % Compute the phase of the phase frequency band
    PhaseFreq = eegfilt(lfp1, srate, PhaseFreq_Band(1), PhaseFreq_Band(2));
    Phase = angle(hilbert(PhaseFreq));
    % Phase values are naturally in -pi to pi

    % Initialize the comodulogram matrix
    Comodulogram = zeros(nbin, length(AmpFreqVector));

    % Compute the phase-amplitude coupling
    for j = 1:length(AmpFreqVector)
        AmpFreq = eegfilt(lfp1, srate, AmpFreqVector(j), AmpFreqVector(j) + AmpFreq_BandWidth);
        Amp = zscore(abs(hilbert(AmpFreq)),0,2); %Extraemos la amplitud de la transformada de Hilbert y la z-scoreamos

        MeanAmp = zeros(1, nbin);
        for k = 1:nbin
            I = find(Phase < position(k) + winsize & Phase >= position(k));
            MeanAmp(k) = mean(Amp(I));
        end

         Comodulogram(:, j) = MeanAmp;
    end

    % Extend the Comodulogram for seamless transition
    ExtendedComodulogram = [Comodulogram(end,:); Comodulogram; Comodulogram(1,:)]; % Duplicate the first and last bins at the ends
    ExtendedPosition = [-pi-winsize, position, pi+winsize]; % Extend the phase position
    
    ExtendedComodulogram1(:,:,i) = ExtendedComodulogram;
end

% Promediamos todos los comodulogramas
ExtendedComodulogram1 = mean(ExtendedComodulogram,3);

% Plot the comodulogram
figure();
contourf((ExtendedPosition + winsize/2) * 180 / pi, AmpFreqVector + AmpFreq_BandWidth / 2, ExtendedComodulogram1', 1000, 'lines', 'none');
set(gca, 'fontsize', 14);
xlabel('Phase (Degrees)');
ylabel('Frequency (Hz)');
colormap('jet');
colorbar;
hcb1 = colorbar;
hcb1.YLabel.String = 'Norm. Amplitude';
hcb1.FontSize = 12;

% Manually set x-axis ticks and labels
set(gca, 'XTick', -180:90:180);
set(gca, 'YTick', 30:10:200);
xlim([-180 180]);
ylim([35 100]);
clim([-0.35 0.35]);

title('4-Hz Phase vs Gamma Amplitude');

% Set figure properties
set(gcf, 'Color', 'white');
set(gcf, 'Position', [300, 200, 500, 400]);

% Obtenemos las posiciones de las figuras
pos_ax1 = get(gca, 'Position');
pos_ax1c = get(hcb1, 'Position');

% Seteamos la posición de la barra de color
set(hcb1, 'Position', [pos_ax1c(1) 0.42 pos_ax1c(3) 0.2]);

% Seteamos la posición de la figura
set(gca, 'Position', [0.13 0.18 0.65 0.7]);

%% Comodulogram Phase(Degree) vs. Frequency(Hz) in Normalized Power Units
tic

for i = 1:20
    lfp1 = lfp(1,CS1_inicioenS(i):CS1_finenS(i));
    data_length = length(lfp1);
    
    k = 1250 * randi(20,1); % Corrimiento de la fase de 1 a 20 seg.
    lfp_shift = lfp(1,CS1_inicioenS(i)+k:CS1_finenS(i)+k);
    
    % Define the frequency ranges
    PhaseFreq_Band = [2, 3]; % Phase frequency band
    AmpFreqVector = 20:5:200; % Amplitude frequencies
    AmpFreq_BandWidth = 10; % Amplitude frequency bandwidth

    % Define phase bins
    nbin = 5; % Number of phase bins
    position = zeros(1, nbin); % Phase bin positions
    winsize = 2 * pi / nbin;
    for j = 1:nbin
        position(j) = -pi + (j-1) * winsize; % -pi to pi
    end

    % Compute the phase of the phase frequency band
    PhaseFreq = eegfilt(lfp1, srate, PhaseFreq_Band(1), PhaseFreq_Band(2));
%     PhaseFreq = eegfilt(lfp_shift, srate, PhaseFreq_Band(1), PhaseFreq_Band(2));
    Phase = angle(hilbert(PhaseFreq));
    % Phase values are naturally in -pi to pi

    % Initialize the comodulogram matrix
    Comodulogram = zeros(nbin, length(AmpFreqVector));

    % Compute the phase-amplitude coupling
    for j = 1:length(AmpFreqVector)
        AmpFreq = eegfilt(lfp1, srate, AmpFreqVector(j), AmpFreqVector(j) + AmpFreq_BandWidth);
        Amp = zscore(abs(hilbert(AmpFreq)),0,2); %Extraemos la amplitud de la transformada de Hilbert y la z-scoreamos

        MeanAmp = zeros(1, nbin);
        for k = 1:nbin
            I = find(Phase < position(k) + winsize & Phase >= position(k));
            MeanAmp(k) = mean(Amp(I));
        end

         Comodulogram(:, j) = MeanAmp;
    end

    % Extend the Comodulogram for seamless transition
    ExtendedComodulogram = [Comodulogram(end,:); Comodulogram; Comodulogram(1,:)]; % Duplicate the first and last bins at the ends
    ExtendedPosition = [-pi-winsize, position, pi+winsize]; % Extend the phase position
    
    ExtendedComodulogram1(:,:,i) = ExtendedComodulogram;
end

% Promediamos todos los comodulogramas
ExtendedComodulogram1 = mean(ExtendedComodulogram,3);

% Plot the comodulogram
figure();
contourf((ExtendedPosition + winsize/2) * 180 / pi, AmpFreqVector + AmpFreq_BandWidth / 2, ExtendedComodulogram1', 1000, 'lines', 'none');
set(gca, 'fontsize', 14);
xlabel('Phase (Degrees)');
ylabel('Frequency (Hz)');
colormap('jet');
colorbar;
hcb1 = colorbar;
hcb1.YLabel.String = 'Norm. Amplitude';
hcb1.FontSize = 12;

% Manually set x-axis ticks and labels
set(gca, 'XTick', -180:90:180);
set(gca, 'YTick', 30:10:200);
xlim([-180 180]);
ylim([35 100]);
clim([-0.5 0.5]);

title('4-Hz Phase vs Gamma Amplitude');

% Set figure properties
set(gcf, 'Color', 'white');
set(gcf, 'Position', [100, 600, 500, 400]);

% Obtenemos las posiciones de las figuras
pos_ax1 = get(gca, 'Position');
pos_ax1c = get(hcb1, 'Position');

% Seteamos la posición de la barra de color
set(hcb1, 'Position', [pos_ax1c(1) 0.42 pos_ax1c(3) 0.2]);

% Seteamos la posición de la figura
set(gca, 'Position', [0.13 0.18 0.65 0.7]);