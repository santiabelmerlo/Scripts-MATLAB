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

% Cargamos los datos del TTL1
TTL_states = readNPY(strcat(name,'_TTL_channel_states.npy')); % Cargamos el estado de cada input del IO Board. 
TTL_timestamps = readNPY(strcat(name,'_TTL_timestamps.npy')); % Los timestamps estan en unidad de muestreo: 30 kHz.
TTL_channels = readNPY(strcat(name,'_TTL_channels.npy')); % Cargamos los estados de los canales.

% Cargamos los datos del amplificador
amplifier_timestamps = readNPY(strcat(name,'_timestamps.npy')); % Cargamos el estado de cada input del IO Board.
amplifier_timestamps = double(amplifier_timestamps(1):1:amplifier_timestamps(end)); % Hay que hacer esto porque amplifier.timestamps devuelve distinto número de tiempos que de registro.
amplifier_timestamps_lfp = double(amplifier_timestamps(1):24:amplifier_timestamps(end)); % Hay que hacer esto porque amplifier.timestamps devuelve distinto número de tiempos que de registro.
amplifier_timestamps_lfp = (amplifier_timestamps_lfp - amplifier_timestamps(1))/30000; % Le restamos el primer timestamp y lo pasamos a segundos. 

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

%%
clear Comodulogram;
tic
j = 1;
for i = 1:20;
    pos = find(abs(TTL_CS1_inicio(i)-amplifier_timestamps_lfp) == min(abs(TTL_CS1_inicio(i)-amplifier_timestamps_lfp)));
    Comodulogram(:,:,j) = comodulogram(amplifier_lfp(pos:pos+Fs*10));
    j = j + 1;
end
toc

%%
tic
Comodulogram = comodulogram(amplifier_lfp);

% Plot comodulogram

PhaseFreqVector = 1:1:32;
AmpFreqVector = 20:5:150;

PhaseFreq_BandWidth = 1;
AmpFreq_BandWidth = 20;

clf
contourf(PhaseFreqVector+PhaseFreq_BandWidth/2,AmpFreqVector+AmpFreq_BandWidth/2,Comodulogram',1000,'lines','none')
set(gca,'fontsize',14);
colormap('jet');
ylabel('Amplitude Frequency (Hz)')
xlabel('Phase Frequency (Hz)')
xlim([0 35]);
ylim([20 160]);
colorbar

toc
