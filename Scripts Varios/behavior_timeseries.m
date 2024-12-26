%% Script que parado en una sesión apetitiva me calcula las series temporales 
% del comportamiento y me las plotea en un subplot

clc
clearvars;
path = pwd;
[~,name,~] = fileparts(pwd);
name = name(1:6);

% Seteamos qué canal queremos levantar de la señal
Fs = 1250; % Frecuencia de sampleo

load(strcat(name,'_sessioninfo.mat'), 'BLA_mainchannel'); ch = BLA_mainchannel; clear BLA_mainchannel; % Canal a levantar
% load(strcat(name,'_sessioninfo.mat'), 'PL_mainchannel'); ch = PL_mainchannel; clear PL_mainchannel; % Canal a levantar
% load(strcat(name,'_sessioninfo.mat'), 'IL_mainchannel'); ch = IL_mainchannel; clear IL_mainchannel; % Canal a levantar

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

if exist(strcat(name,'_freezing.mat')) == 2
    % The file exists, do something
    disp(['Uploading freezing data...']);
    % Cargo los datos de freezing
    load(strcat(name,'_freezing.mat'),'inicio_freezing');
    load(strcat(name,'_freezing.mat'),'duracion_freezing');
    fin_freezing = inicio_freezing + duracion_freezing;
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

load(strcat(name,'_sessioninfo.mat'), 'ch_total'); % Cargamos la cantidad de canales totales
load(strcat(name,'_sessioninfo.mat'), 'ACC_channels'); % Cargamos los canales del acelerómetro

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Importamos la señal del acelerómetro
[amplifier_aux1]=LoadBinary(strcat(name(1:6),'_lfp.dat'), ACC_channels(1), ch_total); % Cargamos señal de AUX1
amplifier_aux1 = amplifier_aux1 * 0.0000374; % Convertimos a volts
amplifier_aux1 = ((amplifier_aux1-0.4816)/0.3458)*100; % Convertimos a g
[amplifier_aux2]=LoadBinary(strcat(name(1:6),'_lfp.dat'), ACC_channels(2), ch_total); % Cargamos señal de AUX2
amplifier_aux2 = amplifier_aux2 * 0.0000374; % Convertimos a volts
amplifier_aux2 = ((amplifier_aux2-0.4927)/0.3420)*100; % Convertimos a g
[amplifier_aux3]=LoadBinary(strcat(name(1:6),'_lfp.dat'), ACC_channels(3), ch_total); % Cargamos señal de AUX3
amplifier_aux3 = amplifier_aux3 * 0.0000374; % Convertimos a volts
amplifier_aux3 = ((amplifier_aux3-0.5091)/0.3386)*100; % Convertimos a g

Fs = 1250; % Frecuencia de muestreo del acelerómetro
timestamps = (0:1/Fs:((size(amplifier_aux1,2)/Fs)-(1/Fs))); % Timestamps en seg.

% Filtramos Aux1
% Filtro pasa altos
samplePeriod = 1/Fs;
filtCutOff = 0.25; % Frecuencia de corte del pasaaltos.
filtHPF = (2*filtCutOff)/(1/samplePeriod);
[b, a] = butter(4, filtHPF, 'high');
amplifier_aux1_filt = filtfilt(b, a, amplifier_aux1); % Filtramos HPF a la señal aux1
% Filtro pasa bajos
filtCutOff = 6; % Frecuecia de corte del pasabajos.
filtLPF = (2*filtCutOff)/(1/samplePeriod);
[b, a] = butter(4, filtLPF, 'low');
amplifier_aux1_filt = filtfilt(b, a, amplifier_aux1_filt); % Filtramos LPF a la señal aux1

% Filtramos Aux2
% Filtro pasa altos
samplePeriod = 1/Fs;
filtCutOff = 0.25; % Frecuencia de corte del pasaaltos.
filtHPF = (2*filtCutOff)/(1/samplePeriod);
[b, a] = butter(4, filtHPF, 'high');
amplifier_aux2_filt = filtfilt(b, a, amplifier_aux2); % Filtramos HPF a la señal aux2
% Filtro pasa bajos
filtCutOff = 6; % Frecuecia de corte del pasabajos.
filtLPF = (2*filtCutOff)/(1/samplePeriod);
[b, a] = butter(4, filtLPF, 'low');
amplifier_aux2_filt = filtfilt(b, a, amplifier_aux2_filt); % Filtramos LPF a la señal aux2

% Filtramos Aux3
% Filtro pasa altos
samplePeriod = 1/Fs;
filtCutOff = 0.25; % Frecuencia de corte del pasaaltos.
filtHPF = (2*filtCutOff)/(1/samplePeriod);
[b, a] = butter(4, filtHPF, 'high');
amplifier_aux3_filt = filtfilt(b, a, amplifier_aux3); % Filtramos HPF a la señal aux3
% Filtro pasa bajos
filtCutOff = 6; % Frecuecia de corte del pasabajos.
filtLPF = (2*filtCutOff)/(1/samplePeriod);
[b, a] = butter(4, filtLPF, 'low');
amplifier_aux3_filt = filtfilt(b, a, amplifier_aux3_filt); % Filtramos LPF a la señal aux3

% Combinamos las tres señales de aceleración en una sola realizando la suma de cuadrados
% Queda en unidades de aceleración de cm/s^2
amplifier_aux123_filt = sqrt(sum(amplifier_aux1_filt(1,:).^2 + amplifier_aux2_filt(1,:).^2 + amplifier_aux3_filt(1,:).^2, 1)); % Magnitud de la aceleración

movement = amplifier_aux123_filt;
movement_timestamps = timestamps;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Assuming you have TTL_CS1_inicio, TTL_CS1_fin, IR2_inicio, IR2_fin, IR3_inicio, IR3_fin, TTL_CS2_inicio, TTL_CS2_fin, movement, and movement_timestamps variables loaded

% Define the time axis
time_start = 0;
time_end = movement_timestamps(end);
time_step = 0.5; % Define the time step (adjust as needed)
time_axis = time_start:time_step:time_end;

% Initialize time series matrix
time_series = zeros(8, length(time_axis));

% Generate the first row for CS1 tone on and off
for i = 1:length(TTL_CS1_inicio)
    tone_onset_idx = find(time_axis >= TTL_CS1_inicio(i), 1);
    tone_offset_idx = find(time_axis >= TTL_CS1_fin(i), 1);
    time_series(1, tone_onset_idx:tone_offset_idx) = 1;
end

% Generate the fourth row for CS2 tone on and off
for i = 1:length(TTL_CS2_inicio)
    tone_onset_idx = find(time_axis >= TTL_CS2_inicio(i), 1);
    tone_offset_idx = find(time_axis >= TTL_CS2_fin(i), 1);
    time_series(2, tone_onset_idx:tone_offset_idx) = 1;
end

% Generate the second row for IR2 behavior on and off
for i = 1:length(IR2_inicio)
    behavior_onset_idx = find(time_axis >= IR2_inicio(i), 1);
    behavior_offset_idx = find(time_axis >= IR2_fin(i), 1);
    time_series(3, behavior_onset_idx:behavior_offset_idx) = 1;
end

% Generate the third row for IR3 behavior on and off
for i = 1:length(IR3_inicio)
    behavior_onset_idx = find(time_axis >= IR3_inicio(i), 1);
    behavior_offset_idx = find(time_axis >= IR3_fin(i), 1);
    time_series(4, behavior_onset_idx:behavior_offset_idx) = 1;
end

% Generate the second row for IR2 behavior on and off
for i = 1:length(IR2_inicio)
    behavior_onset_idx = find(time_axis >= IR2_inicio(i), 1);
    time_series(5, behavior_onset_idx) = 1;
end

% Generate the third row for IR3 behavior on and off
for i = 1:length(IR3_inicio)
    behavior_onset_idx = find(time_axis >= IR3_inicio(i), 1);
    time_series(6, behavior_onset_idx) = 1;
end

% Generate the fifth row for movement
for i = 1:length(movement_timestamps)
    movement_idx = find(time_axis >= movement_timestamps(i), 1);
    time_series(7, movement_idx) = movement(i); % Assuming 'movement' contains movement values
end

% Generate the row for freezing
for i = 1:length(inicio_freezing)
    freezing_onset_idx = find(time_axis >= inicio_freezing(i), 1);
    freezing_offset_idx = find(time_axis >= fin_freezing(i), 1);
    time_series(8, freezing_onset_idx:freezing_offset_idx) = 1;
end

behavior_timeseries = time_series';

% Creamos primero las variables que van a guardar todos los trials de todos los animales
clc
clearvars -except name behavior_timeseries

CS1_head_entries = [];
CS1_nosepokes = [];
CS1_movement = [];
CS1_freezing = [];
CS1_number_head = [];
CS1_number_reward = [];

CS2_head_entries = [];
CS2_nosepokes = [];
CS2_movement = [];
CS2_freezing = [];
CS2_number_head = [];
CS2_number_reward = [];


% Assuming your data is stored in a matrix named 'data'
% where each row corresponds to a time step and each column corresponds to a variable
clc
% Load your data if it's not already in the workspace
data = behavior_timeseries;

% Define constants
time_step = 0.5; % seconds
num_samples = size(data, 1);
num_trials = 60;

% Define a time vector relative to CS1 onset
time_vector = ((1:num_samples) - 1) * time_step;

% Find CS1 onsets
CS1_onsets = find(diff(data(:, 1)) == 1);

% Define a time window around CS1 onset (e.g., -1 sec to +2 sec)
window_start = -5/time_step; % in time steps (-5 sec in this case)
window_end = 30/time_step;    % in time steps (30 sec in this case)

clear head_entries nosepoke movement freezing
% Initialize arrays to store data within the time window
head_entries = NaN(window_end - window_start + 1, num_trials);
nosepoke = NaN(window_end - window_start + 1, num_trials);
movement = NaN(window_end - window_start + 1, num_trials);
freezing = NaN(window_end - window_start + 1, num_trials);

% Populate arrays with data within the time window
for i = 1:num_trials
    if CS1_onsets(i) + window_start > 0 && CS1_onsets(i) + window_end <= num_samples
        head_entries(:,i) = data(CS1_onsets(i) + window_start : CS1_onsets(i) + window_end, 3);
        nosepoke(:,i) = data(CS1_onsets(i) + window_start : CS1_onsets(i) + window_end, 4);
        movement(:,i) = data(CS1_onsets(i) + window_start : CS1_onsets(i) + window_end, 7);
        number_head_entries(:,i) = data(CS1_onsets(i) + window_start : CS1_onsets(i) + window_end, 5);
        number_reward_seekings(:,i) = data(CS1_onsets(i) + window_start : CS1_onsets(i) + window_end, 6);
        freezing(:,i) = data(CS1_onsets(i) + window_start : CS1_onsets(i) + window_end, 8);
    end
end

tt = -5:time_step:30;

CS1_head_entries = cat(2,CS1_head_entries,head_entries);
CS1_nosepokes = cat(2,CS1_nosepokes,nosepoke);
CS1_movement = cat(2,CS1_movement,movement);
CS1_number_head = cat(2,CS1_number_head,number_head_entries);
CS1_number_reward = cat(2,CS1_number_reward,number_reward_seekings);
CS1_freezing = cat(2,CS1_freezing,freezing);

% Find CS2 onsets
CS2_onsets = find(diff(data(:, 2)) == 1);

% Define a time window around CS1 onset (e.g., -1 sec to +2 sec)
window_start = -5/time_step; % in time steps (-1 sec in this case)
window_end = 30/time_step;    % in time steps (2 sec in this case)

clear head_entries nosepoke movement freezing
% Initialize arrays to store data within the time window
head_entries = NaN(window_end - window_start + 1, num_trials);
nosepoke = NaN(window_end - window_start + 1, num_trials);
movement = NaN(window_end - window_start + 1, num_trials);
freezing = NaN(window_end - window_start + 1, num_trials);

% Populate arrays with data within the time window
for i = 1:num_trials
    if CS2_onsets(i) + window_start > 0 && CS2_onsets(i) + window_end <= num_samples
        head_entries(:,i) = data(CS2_onsets(i) + window_start : CS2_onsets(i) + window_end, 3);
        nosepoke(:,i) = data(CS2_onsets(i) + window_start : CS2_onsets(i) + window_end, 4);
        movement(:,i) = data(CS2_onsets(i) + window_start : CS2_onsets(i) + window_end, 7);
        number_head_entries(:,i) = data(CS2_onsets(i) + window_start : CS2_onsets(i) + window_end, 5);
        number_reward_seekings(:,i) = data(CS2_onsets(i) + window_start : CS2_onsets(i) + window_end, 6);
        freezing(:,i) = data(CS2_onsets(i) + window_start : CS2_onsets(i) + window_end, 8);
    end
end

CS2_head_entries = cat(2,CS2_head_entries,head_entries);
CS2_nosepokes = cat(2,CS2_nosepokes,nosepoke);
CS2_movement = cat(2,CS2_movement,movement);
CS2_number_head = cat(2,CS2_number_head,number_head_entries);
CS2_number_reward = cat(2,CS2_number_reward,number_reward_seekings);
CS2_freezing = cat(2,CS2_freezing,freezing);

tt = tt + 0.5; % Corremos medio segundo para corregir el momento que suceden las cosas

clear i data;
save([strcat(name,'_behavior_timeseries.mat')]);

% Finalmente ploteamos los tres comportamientos en la misma figura
ax1 = subplot(2,3,1);
    plot_behavior_prob(CS1_head_entries,CS2_head_entries,tt);
    xlim([-5 30]);
    ylabel('Inside port (probability)');
    xlabel('Time (sec.)');
ax4 = subplot(2,3,4);
    plot_behavior_prob(CS1_nosepokes,CS2_nosepokes,tt);
    xlim([-5 30]);
    ylabel('Reward-seeking (probability)');
    xlabel('Time (sec.)');
ax3 = subplot(2,3,3);
    plot_behavior_mov(CS1_movement,CS2_movement,tt);
    ylim([0 40]);
    xlim([-5 30]);
    ylabel('Acceleration (cm/s^2)');
    xlabel('Time (sec.)');  
ax2 = subplot(2,3,2);
    plot_behavior_num(CS1_number_head,CS2_number_head,tt);
    ylim([0 100]);
    xlim([-5 30]);
    ylabel('Port pokes (# pokes per min.)');
    xlabel('Time (sec.)');
ax5 = subplot(2,3,5);
    plot_behavior_num(CS1_number_reward,CS2_number_reward,tt);
    ylim([0 100]);
    xlim([-5 30]);
    ylabel('Reward poke (# pokes per min.)');
    xlabel('Time (sec.)'); 
ax6 = subplot(2,3,6);
    plot_behavior_prob(CS1_freezing,CS2_freezing,tt);
    xlim([-5 30]);
    ylabel('Immobility (probability)');
    xlabel('Time (sec.)');   
    
set(gcf, 'Color', 'white');

linkaxes([ax1 ax2 ax3 ax4 ax5 ax6],'x')
