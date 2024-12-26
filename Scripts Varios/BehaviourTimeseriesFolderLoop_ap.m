%% Script para recorrer todas las carpetas y calcular behaviour timeseries
clc;
clear all;

% Define the parent folder containing the 'Rxx' folders
parentFolder = 'D:\Doctorado\Backup Ordenado';

% List all 'Rxx' folders in the parent folder
R_folders = dir(fullfile(parentFolder, 'R*'));

% Iterate through each 'Rxx' folder
for r = 1:length(R_folders)
    current_R_folder = fullfile(parentFolder, R_folders(r).name);
    disp(['Processing folder: ' current_R_folder]);
    
    % List all subfolders inside the 'Rxx' folder
    D_folders = dir(fullfile(current_R_folder, 'R*D*'));
    D_folders = D_folders([D_folders.isdir]);
    
    % Iterate through each 'RxDy' folder
    for d = 1:length(D_folders)
        current_D_folder = fullfile(current_R_folder, D_folders(d).name);
        disp(['  Processing subfolder: ' current_D_folder]);
        
        % Change the current folder to the 'RxDy' subfolder
        cd(current_D_folder);
        [~,D,X] = fileparts(current_D_folder); name = D([1:6]);
        
        % Check if the .dat file exists
        freezing_file = strcat(name, '_freezing.mat');
        sessioninfo_file = strcat(name, '_sessioninfo.mat');
        
        % Copiamos R00D00_freezing.mat
        if exist(freezing_file, 'file') == 2 && exist(sessioninfo_file, 'file') == 2;
            disp(['    File ' freezing_file ' and ' sessioninfo_file ' exists. Computing behaviour timeseries... ']);
            load(strcat(name,'_sessioninfo.mat'),'ACC_channels');
            load(strcat(name,'_sessioninfo.mat'),'paradigm');
            if isempty(ACC_channels) || strcmp(paradigm,'aversive');
                disp(['    ACC_channels do not exist or paradigm is aversive. Skipping action...']);
            else
                
                %%%%%%% Pegamos el script que quiero que corra%%%%%%%%%%%%%
                
                % Seteamos qu� canal queremos levantar de la se�al
                Fs = 1250; % Frecuencia de sampleo

                load(strcat(name,'_sessioninfo.mat'), 'BLA_mainchannel'); ch = BLA_mainchannel; clear BLA_mainchannel; % Canal a levantar
                % load(strcat(name,'_sessioninfo.mat'), 'PL_mainchannel'); ch = PL_mainchannel; clear PL_mainchannel; % Canal a levantar
                % load(strcat(name,'_sessioninfo.mat'), 'IL_mainchannel'); ch = IL_mainchannel; clear IL_mainchannel; % Canal a levantar

                load(strcat(name,'_sessioninfo.mat'), 'ch_total'); % N�mero de canales totales
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
                amplifier_timestamps = double(amplifier_timestamps(1):1:amplifier_timestamps(end)); % Hay que hacer esto porque amplifier.timestamps devuelve distinto n�mero de tiempos que de registro.
                amplifier_timestamps_lfp = double(amplifier_timestamps(1):24:amplifier_timestamps(end)); % Hay que hacer esto porque amplifier.timestamps devuelve distinto n�mero de tiempos que de registro.
                amplifier_timestamps_lfp = (amplifier_timestamps_lfp - amplifier_timestamps(1))/30000; % Le restamos el primer timestamp y lo pasamos a segundos. 

                if exist(strcat(name,'_freezing.mat')) == 2
                    % The file exists, do something
                    disp(['      Uploading freezing data...']);
                    % Cargo los datos de freezing
                    load(strcat(name,'_freezing.mat'),'inicio_freezing');
                    load(strcat(name,'_freezing.mat'),'duracion_freezing');
                    fin_freezing = inicio_freezing + duracion_freezing;
                else
                    % The file does not exist, do nothing
                    disp(['      Freezing data do not exists. Skipping action...']);
                end

                % Calculamos los tiempos de los CSs.
                % Buscamos los tiempos asociados a cada evento.
                TTL_start = amplifier_timestamps(1); % Seteamos el primer timestamp 
                TTL_end = amplifier_timestamps(end); % Seteamos el �ltimo timestamp
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
                load(strcat(name,'_sessioninfo.mat'), 'ACC_channels'); % Cargamos los canales del aceler�metro

                % Importamos la se�al del aceler�metro
                [amplifier_aux1]=LoadBinary(strcat(name(1:6),'_lfp.dat'), ACC_channels(1), ch_total); % Cargamos se�al de AUX1
                amplifier_aux1 = amplifier_aux1 * 0.0000374; % Convertimos a volts
                amplifier_aux1 = ((amplifier_aux1-0.4816)/0.3458)*100; % Convertimos a g
                [amplifier_aux2]=LoadBinary(strcat(name(1:6),'_lfp.dat'), ACC_channels(2), ch_total); % Cargamos se�al de AUX2
                amplifier_aux2 = amplifier_aux2 * 0.0000374; % Convertimos a volts
                amplifier_aux2 = ((amplifier_aux2-0.4927)/0.3420)*100; % Convertimos a g
                [amplifier_aux3]=LoadBinary(strcat(name(1:6),'_lfp.dat'), ACC_channels(3), ch_total); % Cargamos se�al de AUX3
                amplifier_aux3 = amplifier_aux3 * 0.0000374; % Convertimos a volts
                amplifier_aux3 = ((amplifier_aux3-0.5091)/0.3386)*100; % Convertimos a g

                Fs = 1250; % Frecuencia de muestreo del aceler�metro
                timestamps = (0:1/Fs:((size(amplifier_aux1,2)/Fs)-(1/Fs))); % Timestamps en seg.

                % Filtramos Aux1
                % Filtro pasa altos
                samplePeriod = 1/Fs;
                filtCutOff = 0.25; % Frecuencia de corte del pasaaltos.
                filtHPF = (2*filtCutOff)/(1/samplePeriod);
                [b, a] = butter(4, filtHPF, 'high');
                amplifier_aux1_filt = filtfilt(b, a, amplifier_aux1); % Filtramos HPF a la se�al aux1
                % Filtro pasa bajos
                filtCutOff = 6; % Frecuecia de corte del pasabajos.
                filtLPF = (2*filtCutOff)/(1/samplePeriod);
                [b, a] = butter(4, filtLPF, 'low');
                amplifier_aux1_filt = filtfilt(b, a, amplifier_aux1_filt); % Filtramos LPF a la se�al aux1

                % Filtramos Aux2
                % Filtro pasa altos
                samplePeriod = 1/Fs;
                filtCutOff = 0.25; % Frecuencia de corte del pasaaltos.
                filtHPF = (2*filtCutOff)/(1/samplePeriod);
                [b, a] = butter(4, filtHPF, 'high');
                amplifier_aux2_filt = filtfilt(b, a, amplifier_aux2); % Filtramos HPF a la se�al aux2
                % Filtro pasa bajos
                filtCutOff = 6; % Frecuecia de corte del pasabajos.
                filtLPF = (2*filtCutOff)/(1/samplePeriod);
                [b, a] = butter(4, filtLPF, 'low');
                amplifier_aux2_filt = filtfilt(b, a, amplifier_aux2_filt); % Filtramos LPF a la se�al aux2

                % Filtramos Aux3
                % Filtro pasa altos
                samplePeriod = 1/Fs;
                filtCutOff = 0.25; % Frecuencia de corte del pasaaltos.
                filtHPF = (2*filtCutOff)/(1/samplePeriod);
                [b, a] = butter(4, filtHPF, 'high');
                amplifier_aux3_filt = filtfilt(b, a, amplifier_aux3); % Filtramos HPF a la se�al aux3
                % Filtro pasa bajos
                filtCutOff = 6; % Frecuecia de corte del pasabajos.
                filtLPF = (2*filtCutOff)/(1/samplePeriod);
                [b, a] = butter(4, filtLPF, 'low');
                amplifier_aux3_filt = filtfilt(b, a, amplifier_aux3_filt); % Filtramos LPF a la se�al aux3

                % Combinamos las tres se�ales de aceleraci�n en una sola realizando la suma de cuadrados
                % Queda en unidades de aceleraci�n de cm/s^2
                amplifier_aux123_filt = sqrt(sum(amplifier_aux1_filt(1,:).^2 + amplifier_aux2_filt(1,:).^2 + amplifier_aux3_filt(1,:).^2, 1)); % Magnitud de la aceleraci�n

                movement = amplifier_aux123_filt;
                movement_timestamps = timestamps;

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
                clearvars -except name behavior_timeseries current_D_folder current_R_folder d D D_folders parentFolder r R_folders X paradigm

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
                
                % Find CS2 onsets
                CS2_onsets = find(diff(data(:, 2)) == 1);
                
                if size(CS1_onsets,1) >= 60 && size(CS2_onsets,1) >= 60

                    % Define a time window around CS1 onset (e.g., -1 sec to +2 sec)
                    window_start = -5/time_step; % in time steps (-5 sec in this case)
                    window_end = 30/time_step;    % in time steps (30 sec in this case)

                    clear head_entries nosepoke movement freezing
                    % Initialize arrays to store data within the time window
                    head_entries = NaN(window_end - window_start + 1, num_trials);
                    nosepoke = NaN(window_end - window_start + 1, num_trials);
                    movement = NaN(window_end - window_start + 1, num_trials);
                    freezing = NaN(window_end - window_start + 1, num_trials);
                    number_head_entries = NaN(window_end - window_start + 1, num_trials);
                    number_reward_seekings = NaN(window_end - window_start + 1, num_trials);

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

                    % Define a time window around CS1 onset (e.g., -1 sec to +2 sec)
                    window_start = -5/time_step; % in time steps (-1 sec in this case)
                    window_end = 30/time_step;    % in time steps (2 sec in this case)

                    clear head_entries nosepoke movement freezing
                    % Initialize arrays to store data within the time window
                    head_entries = NaN(window_end - window_start + 1, num_trials);
                    nosepoke = NaN(window_end - window_start + 1, num_trials);
                    movement = NaN(window_end - window_start + 1, num_trials);
                    freezing = NaN(window_end - window_start + 1, num_trials);
                    number_head_entries = NaN(window_end - window_start + 1, num_trials);
                    number_reward_seekings = NaN(window_end - window_start + 1, num_trials);

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

                    disp(['      Saving ' strcat(name,'_behavior_timeseries.mat') ' file...']);
%                     save([strcat(name,'_behavior_timeseries.mat')]);
                else
                    disp(['      Number of trials is not 60. Skipping action...']);
                end
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                clearvars -except current_D_folder current_R_folder d D D_folders parentFolder r R_folders X
            end
        else
            disp(['    File ' freezing_file ' or ' sessioninfo_file ' do not exist. Skipping action...']);
        end      
 
        % Go back to the 'Rxx' folder
        cd(current_R_folder);
    end
end
disp('Done!');
cd(parentFolder);