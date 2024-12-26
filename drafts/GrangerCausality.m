%% Working with my data
clc
clear all
path = pwd;
[~,name,~] = fileparts(pwd);
name = name(1:6);
% Seteamos qué canal queremos levantar de la señal
Fs = 1250; % Frecuencia de sampleo

load(strcat(name,'_sessioninfo.mat'), 'BLA_mainchannel'); ch_BLA = BLA_mainchannel; clear BLA_mainchannel; % Canal a levantar
load(strcat(name,'_sessioninfo.mat'), 'PL_mainchannel'); ch_PL = PL_mainchannel; clear PL_mainchannel; % Canal a levantar
load(strcat(name,'_sessioninfo.mat'), 'IL_mainchannel'); ch_IL = IL_mainchannel; clear IL_mainchannel; % Canal a levantar
load(strcat(name,'_sessioninfo.mat'), 'ch_total'); % Número de canales totales
load(strcat(name,'_sessioninfo.mat'), 'paradigm'); % Tipo de paradigma. Appetitive or aversive

% Cargo los tiempos de los tonos
load(strcat(name,'_freezing.mat'),'TTL_CS1_inicio','TTL_CS1_fin','TTL_CS2_inicio','TTL_CS2_fin');

% Cargo los eventos de freezing
% load(strcat(name,'_epileptic.mat'));

% Cargamos los datos del amplificador
amplifier_timestamps = readNPY(strcat(name,'_timestamps.npy')); % Cargamos el estado de cada input del IO Board.
amplifier_timestamps = double(amplifier_timestamps(1):1:amplifier_timestamps(end)); % Hay que hacer esto porque amplifier.timestamps devuelve distinto número de tiempos que de registro.
amplifier_timestamps_lfp = double(amplifier_timestamps(1):24:amplifier_timestamps(end)); % Subsampleamos a 1250
t = (amplifier_timestamps_lfp - amplifier_timestamps(1))/30000; % Le restamos el primer timestamp y lo pasamos a segundos.

% Cargamos un canal LFP del amplificador
disp(['Loading BLA LFP signal...']);
[lfp_BLA] = LoadBinary(strcat(name,'_lfp.dat'), ch_BLA, ch_total);
lfp_BLA = lfp_BLA * 0.195; % Convertir un canal de registro de bits a microvolts (uV).
clear amplifier_timestamps amplifier_timestamps_lfp;

% Cargamos un canal LFP del amplificador
disp(['Loading PL LFP signal...']);
[lfp_PL] = LoadBinary(strcat(name,'_lfp.dat'), ch_PL, ch_total);
lfp_PL = lfp_PL * 0.195; % Convertir un canal de registro de bits a microvolts (uV).
clear amplifier_timestamps amplifier_timestamps_lfp;

% Cargamos un canal LFP del amplificador
disp(['Loading IL LFP signal...']);
[lfp_IL] = LoadBinary(strcat(name,'_lfp.dat'), ch_IL, ch_total);
lfp_IL = lfp_IL * 0.195; % Convertir un canal de registro de bits a microvolts (uV).
clear amplifier_timestamps amplifier_timestamps_lfp;

% Cargamos los eventos de freezing
% load(strcat(name,'_epileptic.mat'));

% % Subsampleamos las señales a 250 Hz (tomamos 1 sample cada 5 en una señal en 1250 Hz)
lfp_BLA = downsample(lfp_BLA,5);
lfp_PL = downsample(lfp_PL,5);
lfp_IL = downsample(lfp_IL,5);
t = downsample(t,5);

%% Determine the maximum number of samples in any trial

max_samples_CSplus = ceil(median(TTL_CS1_fin - TTL_CS1_inicio) * fs);
max_samples_CSminus = ceil(median(TTL_CS2_fin - TTL_CS2_inicio) * fs);
% Extract segments for CS+ events
[X1(1,:,:), X1(2,:,:), X1(3,:,:)] = extract_segments(lfp_BLA, lfp_PL, lfp_IL, t, TTL_CS1_inicio, TTL_CS1_fin, max_samples_CSplus);
% Extract segments for CS- events
[X2(1,:,:), X2(2,:,:), X2(3,:,:)] = extract_segments(lfp_BLA, lfp_PL, lfp_IL, t, TTL_CS2_inicio, TTL_CS2_fin, max_samples_CSminus);
% Generamos los timestamps del preCS: 5 seg previos al CS apetitivo, 10 seg previos al CS aversivo
if strcmp(paradigm_toinclude,'aversive');
    tlength = 10;
else strcmp(paradigm_toinclude,'appetitive');
    tlength = 5;
end
TTL_preCS_inicio = [TTL_CS1_inicio - tlength; TTL_CS2_inicio - tlength];
TTL_preCS_fin = [TTL_CS1_inicio; TTL_CS2_inicio];
[TTL_preCS_inicio, sortIdx] = sort(TTL_preCS_inicio);
TTL_preCS_fin = TTL_preCS_fin(sortIdx);
% Extract segments for preCS events
[X3(1,:,:), X3(2,:,:), X3(3,:,:)] = extract_segments(lfp_BLA, lfp_PL, lfp_IL, t, TTL_preCS_inicio, TTL_preCS_fin, max_samples_CSminus);


%% Iteramos en cada uno de los CSs.
