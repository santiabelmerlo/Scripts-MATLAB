%% Script para plotear espectrograma de una sesión apetitiva o aversiva
% Ploteamos bajas frecuencias, altas frecuencias y señal raw con los
% eventos encima
clc
clear all
path = pwd;
[~,name,~] = fileparts(pwd);
name = name(1:6);

% Seteamos qué canal queremos levantar de la señal
Fs = 1250; % Frecuencia de sampleo

load(strcat(name,'_sessioninfo.mat'), 'BLA_mainchannel'); ch = BLA_mainchannel; clear BLA_mainchannel; % Canal a levantar
% load(strcat(name,'_sessioninfo.mat'), 'PL_mainchannel'); ch = PL_mainchannel; clear PL_mainchannel; % Canal a levantar
% load(strcat(name,'_sessioninfo.mat'), 'IL_mainchannel'); ch = IL_mainchannel; clear IL_mainchannel; % Canal a levantar
% load(strcat(name,'_sessioninfo.mat'), 'EO_channels'); ch = EO_channels; clear EO_channels; % Canal a levantar

load(strcat(name,'_sessioninfo.mat'), 'ch_total'); % Número de canales totales
load(strcat(name,'_sessioninfo.mat'), 'paradigm'); % Tipo de paradigma. Appetitive or aversive

% Seteamos algunos colores para los ploteos
if strcmp(paradigm,'appetitive');
    cs1_color = [0 128 0]/255; % Seteo el color para el CS+ apetitivo
    cs2_color = [96 96 96]/255; % Seteo el color para el CS-
    behaviour_color = [10 10 10]/255; % Seteo el color para comportamiento
elseif strcmp(paradigm,'aversive');
    cs1_color = [118 6 154]/255; % Seteo el color para el CS+ aversivo
    cs2_color = [96 96 96]/255; % Seteo el color para el CS-
    behaviour_color = [10 10 10]/255; % Seteo el color para comportamiento
end

% Cargamos los datos del TTL1
TTL_states = readNPY(strcat(name,'_TTL_channel_states.npy')); % Cargamos el estado de cada input del IO Board. 
TTL_timestamps = readNPY(strcat(name,'_TTL_timestamps.npy')); % Los timestamps estan en unidad de muestreo: 30 kHz.
TTL_channels = readNPY(strcat(name,'_TTL_channels.npy')); % Cargamos los estados de los canales.

% Cargamos los datos del amplificador
amplifier_timestamps = readNPY(strcat(name,'_timestamps.npy')); % Cargamos el estado de cada input del IO Board.
amplifier_timestamps = double(amplifier_timestamps(1):1:amplifier_timestamps(end)); % Hay que hacer esto porque amplifier.timestamps devuelve distinto número de tiempos que de registro.
amplifier_timestamps_lfp = double(amplifier_timestamps(1):24:amplifier_timestamps(end)); % Hay que hacer esto porque amplifier.timestamps devuelve distinto número de tiempos que de registro.
amplifier_timestamps_lfp = (amplifier_timestamps_lfp - amplifier_timestamps(1))/30000; % Le restamos el primer timestamp y lo pasamos a segundos. 

if exist(strcat(name,'_epileptic.mat')) == 2
    % The file exists, do something
    disp(['Uploading freezing data...']);
    % Cargo los datos de freezing
    load(strcat(name,'_epileptic.mat'));
else
    % The file does not exist, do nothing
    disp(['Freezing data do not exists. Skipping action...']);
end

% Calculamos los tiempos de los CSs.
% Buscamos los tiempos asociados a cada evento.
TTL_start = amplifier_timestamps(1); % Seteamos el primer timestamp 
TTL_end = amplifier_timestamps(end); % Seteamos el último timestamp
% Inicio y fin del CS+ asociado con la recompensa. Entrada #1 del IO board.
TTL_CS1_start = TTL_timestamps(find(TTL_states == 1));
TTL_CS1_end = TTL_timestamps(find(TTL_states == -1));
% Inicio y fin del CS-. Entrada #1 del IO board. Entrada #2 del IO board.
TTL_CS2_start = TTL_timestamps(find(TTL_states == 2));
TTL_CS2_end = TTL_timestamps(find(TTL_states == -2));

% Inicio y fin de los nosepokes en la puerta. Entrada #5 del IO board.
IR2_start = TTL_timestamps(find(TTL_states == 5));
IR2_end = TTL_timestamps(find(TTL_states == -5));
% Borramos el dato si arranca en end o termina en start
if size(IR2_start,1) ~= size(IR2_end,1);
    if IR2_start(1) >= IR2_end(1);
        if size(IR2_start,1) > size(IR2_end,1);  % Este if fue agregado despues y falta agregarlo para la condicion de IR3
            IR2_start(end) = [];
        elseif size(IR2_start,1) < size(IR2_end,1);
            IR2_end(1) = [];
        end
    elseif IR2_end(end) <= IR2_start(end);
        IR2_start(end) = [];
    end
end

% Inicio y fin de los nosepokes en el target. Entrada #6 del IO board.
IR3_start = TTL_timestamps(find(TTL_states == 6));
IR3_end = TTL_timestamps(find(TTL_states == -6));

% Borramos el dato si arranca en end o termina en start
if size(IR3_start,1) ~= size(IR3_end,1);
    if IR3_start(1) >= IR3_end(1);
        IR3_end(1) = [];
    elseif IR3_end(end) <= IR3_start(end);
        IR3_start(end) = [];
    end
end   

% Llevo los tiempos del CS1 a segundos y los sincronizo con los tiempos del registro
TTL_CS1_inicio = TTL_CS1_start - TTL_start; TTL_CS1_inicio = double(TTL_CS1_inicio);
TTL_CS1_fin = TTL_CS1_end - TTL_start; TTL_CS1_fin = double(TTL_CS1_fin);
TTL_CS1_inicio = TTL_CS1_inicio/30000; % Llevo los tiempos a segundos
TTL_CS1_fin = TTL_CS1_fin/30000; % Llevo los tiempos a segundos
% Llevo los tiempos del CS2 a segundos y los sincronizo con los tiempos del registro
TTL_CS2_inicio = TTL_CS2_start - TTL_start; TTL_CS2_inicio = double(TTL_CS2_inicio);
TTL_CS2_fin = TTL_CS2_end - TTL_start; TTL_CS2_fin = double(TTL_CS2_fin);
TTL_CS2_inicio = TTL_CS2_inicio/30000; % Llevo los tiempos a segundos
TTL_CS2_fin = TTL_CS2_fin/30000; % Llevo los tiempos a segundos
% Llevo los tiempos del Nosepoke a segundos y los sincronizo con los tiempos del registro
IR2_inicio = IR2_start - TTL_start; IR2_inicio = double(IR2_inicio);
IR2_fin = IR2_end - TTL_start; IR2_fin = double(IR2_fin);
IR2_inicio = IR2_inicio/30000; % Llevo los tiempos a segundos
IR2_fin = IR2_fin/30000; % Llevo los tiempos a segundos
% Llevo los tiempos del licking a segundos y los sincronizo con los tiempos del registro
IR3_inicio = IR3_start - TTL_start; IR3_inicio = double(IR3_inicio);
IR3_fin = IR3_end - TTL_start; IR3_fin = double(IR3_fin);
IR3_inicio = IR3_inicio/30000; % Llevo los tiempos a segundos
IR3_fin = IR3_fin/30000; % Llevo los tiempos a segundos

% Cargamos un canal LFP del amplificador
disp(['Uploading amplifier data...']);
[amplifier_lfp] = LoadBinary(strcat(name,'_lfp.dat'), ch, ch_total);
amplifier_lfp = amplifier_lfp * 0.195; % Convertir un canal de registro de bits a microvolts (uV).

% Filtramos la señal
disp(['Filtering LFP signal...']);
highpass = 0.1; lowpass = 300; % Frecuencias de corte del filtro. Corte pasabajos en nyquist frequency.
data = amplifier_lfp; % Señal que queremos filtrar
samplePeriod = 1/1250; % Frecuencia de muestreo de la señal subsampleada
% Aplicamos un filtro pasa altos con corte en 0.1 Hz
filtHPF = (2*highpass)/(1/samplePeriod);
[b, a] = butter(4, filtHPF, 'high');
data_hp = filtfilt(b, a, data);
% Aplicamos un filtro pasa bajos con corte en 300 Hz
filtLPF = (2*lowpass)/(1/samplePeriod);
[b, a] = butter(4, filtLPF, 'low');
data_hlp = filtfilt(b, a, data_hp); %señal de mag de acel filtrada
amplifier_lfp = data_hlp; % Guardamos la señal filtrada como "amplifier_BLA_downsample_filt"
clear data_hlp a b data filtHPF data_hp filtLPF highpass lowpass samplePeriod;% Borramos las variables que no me sirven más

% Parámetros óptimos para analizar frecuencias de 0 a 30 Hz.
% Igualmente calculo hasta 150 para tener el espectro completo
params.Fs = 1250; 
params.err = [2 0.05]; 
params.tapers = [3 5]; 
params.pad = 2; 
params.fpass = [1 12];
movingwin = [3 0.5];

disp(['Analizing low frequency multi-taper spectrogram...']);
[S,t,f,Serr] = mtspecgramc(amplifier_lfp, movingwin, params);
S = 10*log10(S);

disp(['Plotting low frequency multi-taper spectrogram...']);
% ax2 = subplot(3,1,2);
plot_matrix(S,t,f,'n');
        ylabel(['Frequency (Hz)']);
        xlabel('');
        title('Single-taper Low Frequency Spectrogram (0-30 Hz)');
        colormap(jet);    
        hcb = colorbar; hcb.YLabel.String = 'Power (dB)'; hcb.FontSize = 12;
        caxis([10 40]);
        ylim(params.fpass);
        xlabel('Time (sec.)');
        
hold on;
disp(['Plotting events...']);
for i = 1:length(TTL_CS1_inicio);
    line([TTL_CS1_inicio(i) TTL_CS1_fin(i)],[11.5 11.5],'Color',[173 7 227]/255,'LineWidth',5);
end
for i = 1:length(TTL_CS2_inicio);
    line([TTL_CS2_inicio(i) TTL_CS2_fin(i)],[11.5 11.5],'Color',[128 128 128]/255,'LineWidth',5);
end

if strcmp(paradigm,'aversive');
    for i = 1:size(inicio_freezing,2);
        line([inicio_freezing(i) (inicio_freezing(i)+duracion_freezing(i))],[10.4 10.4],'Color',[1 1 1],'LineWidth',5);
    end
    for i = 1:size(inicio_epileptic,2);
        line([inicio_epileptic(i) fin_epileptic(i)],[10 10],'Color',[1 0.5 1],'LineWidth',5);
    end
end

%%
% Parámetros óptimos para analizar frecuencias de 30 a 150 Hz.
% Si quiero cuantificar gamma en un periodo largo de tiempo
% Periodo mayor a 500 ms
params.Fs = 1250; 
params.err = [2 0.05]; 
params.tapers = [3 5]; 
params.pad = 2; 
params.fpass = [30 100];
movingwin = [1 0.25];

% Parámetros óptimos para analizar frecuencias de 30 a 150 Hz.
% Si quiero cuantificar gamma dentro de una oscilación de theta
% Periodo menor a 500 ms
% params.Fs = 1250; 
% params.err = [2 0.05]; 
% params.tapers = [1 1]; 
% params.pad = 2; 
% params.fpass = [30 100];
% movingwin = [0.1 0.01];

disp(['Analizing high frequency multi-taper spectrogram...']);
[S,t,f,Serr] = mtspecgramc(amplifier_lfp, movingwin, params);
S = 10*log10(S);

disp(['Plotting high frequency multi-taper spectrogram...']);
ax1 = subplot(3,1,1);
plot_matrix(S,t,f,'n');
        ylabel(['Frequency (Hz)']);
        xlabel('');
        title('Multi-taper High Frequency Spectrogram (30-120 Hz)');
        set(gca,'xtick',[],'xlabel',[]);
        colormap(jet);    
        hcb = colorbar; hcb.YLabel.String = 'Power (dB)'; hcb.FontSize = 12;
        caxis([0 25]);
        colorbar('off');
        ylim(params.fpass);

% Ploteamos la señal raw y arriba los eventos
disp(['Plotting LFP signal...']);
ax3 = subplot(3,1,3);
plot(amplifier_timestamps_lfp,zscore(amplifier_lfp));
        ylabel(['Amplitude (uV)']);
        xlabel('Time (sec.)');
        title('LFP Raw Signal');
        ylim([-5 5]);
hold on

disp(['Plotting events...']);
for i = 1:length(TTL_CS1_inicio);
    line([TTL_CS1_inicio(i) TTL_CS1_fin(i)],[4.5 4.5],'Color',cs1_color,'LineWidth',2);
end
for i = 1:length(TTL_CS2_inicio);
    line([TTL_CS2_inicio(i) TTL_CS2_fin(i)],[4.5 4.5],'Color',cs2_color,'LineWidth',2);
end

if strcmp(paradigm,'appetitive');
    for i = 1:size(IR2_start,1);
        line([IR2_inicio(i,1) IR2_fin(i,:)],[4 4],'Color',behaviour_color,'LineWidth',2);
    end
    for i = 1:size(IR3_start,1);
        line([IR3_inicio(i,1) IR3_fin(i,:)],[3.8 3.8],'Color',behaviour_color,'LineWidth',2);
    end
elseif strcmp(paradigm,'aversive');
    for i = 1:size(inicio_freezing,2);
        line([inicio_freezing(i) (inicio_freezing(i)+duracion_freezing(i))],[4 4],'Color',behaviour_color,'LineWidth',2);
    end
end

linkaxes([ax1 ax2 ax3],'x');
disp(['Ready']);

%% Ploteamos espectro de potencias para CS+ vs CS-

% Parámetros óptimos para analizar frecuencias de 0 a 30 Hz.
% Igualmente calculo hasta 150 para tener el espectro completo
params.Fs = 1250; 
params.err = [2 0.05]; 
params.tapers = [3 5]; 
params.pad = 2; 
params.fpass = [0 30];
movingwin = [3 0.5];

[S,t,f,Serr] = mtspecgramc(amplifier_lfp, movingwin, params);

% Busco las posiciones en S donde inician y finalizan los tonos
for i = 1:size(TTL_CS1_inicio,1);
    CS1_inicioenS(i) = find(abs(t-TTL_CS1_inicio(i)) == min(abs(t-TTL_CS1_inicio(i))));
    CS1_finenS(i) = find(abs(t-TTL_CS1_fin(i)) == min(abs(t-TTL_CS1_fin(i))));
    CS2_inicioenS(i) = find(abs(t-TTL_CS2_inicio(i)) == min(abs(t-TTL_CS2_inicio(i))));
    CS2_finenS(i) = find(abs(t-TTL_CS2_fin(i)) == min(abs(t-TTL_CS2_fin(i))));
end

%% Metemos todos los pedazos de S durante el CS en una gran matriz y
% calculamos la media

S_CS1 = [];
S_CS2 = [];

window= round(mean(CS1_finenS - CS1_inicioenS));

for i = 1:size(CS1_inicioenS,2);
    S_CS1(:,:,i) = S(CS1_inicioenS(1,i):CS1_inicioenS(1,i)+window,:);
    S_CS2(:,:,i) = S(CS2_inicioenS(1,i):CS2_inicioenS(1,i)+window,:);
end
S_CS1 = mean(S_CS1,1); S_CS1 = squeeze(S_CS1); S_CS1 = S_CS1';
S_CS2 = mean(S_CS2,1); S_CS2 = squeeze(S_CS2); S_CS2 = S_CS2';

S_CS1 = 10*log10(S_CS1);
S_CS2 = 10*log10(S_CS2);

% Espectro de potencias para el CS+
S_data = S_CS1;
y = mean(S_data); % your mean vector;
x = f;
stdem = std(S_data,1)/sqrt(size(S_data,1));
curve1 = y + stdem;
curve2 = y - stdem;
x2 = [x, fliplr(x)];
inBetween = [curve1, fliplr(curve2)];
p1 = fill(x2, inBetween, cs1_color,'LineStyle','none');
set(p1,'facealpha',.4)
hold on;
plot(x, y, 'Color',cs1_color, 'LineWidth', 1);
hold on;
clear S_data;

% Espectro de potencias para el CS+
S_data = S_CS2;
y = mean(S_data); % your mean vector;
x = f;
stdem = std(S_data,1)/sqrt(size(S_data,1));
curve1 = y + stdem;
curve2 = y - stdem;
x2 = [x, fliplr(x)];
inBetween = [curve1, fliplr(curve2)];
p2 = fill(x2, inBetween,cs2_color,'LineStyle','none');
set(p2,'facealpha',.3)
hold on;
plot(x, y, 'Color',cs2_color, 'LineWidth', 1);
hold on;
clear S_data;

xlim([params.fpass(1) params.fpass(2)]);
lims = ylim;
ylim1 = lims(1);
ylim2 = lims(2);
xlabel('Frequency (Hz)');
ylabel('Power (µV/Hz)');
title('Power Spectrum');