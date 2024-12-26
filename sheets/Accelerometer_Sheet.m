%% Accelerometer Sheet durante todos los eventos de EventsSheet.csv
% Me guarda una tabla llamada Accelerometer_Sheet.csv con el vector de
% aceleración para el onset del evento (-5,+5 seg)
% Acceleración en unidades cm/s2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc
clear all

rats = 10:20;
paradigm_toinclude = 'aversive'; % Filtro por el paradigma
session_toinclude = {'EXT1','EXT2','TEST'}; % Filtro por las sesiones
fs = 1250; % Sample rate original de la señal (Hz)

% Calculamos algunas variables que son constantes
Accelerometer_Sheet = {};
ID = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Define the parent folder containing the 'Rxx' folders
parentFolder = 'D:\Doctorado\Backup Ordenado';

% List all 'Rxx' folders in the parent folder
R_folders = dir(fullfile(parentFolder, 'R*'));

% Cargamos la tabla de EventsSheet
cd('D:\Doctorado\Analisis\Sheets');
EventsSheet = readtable('EventsSheet.csv');

for r = rats % Iterate through each 'Rxx' folder
    current_R_folder = fullfile(parentFolder, R_folders(r).name);
    disp(['Processing folder: ' current_R_folder]);
    
    % List all subfolders inside the 'Rxx' folder
    D_folders = dir(fullfile(current_R_folder, 'R*D*'));
    D_folders = D_folders([D_folders.isdir]);
    
    % Iterate through each 'RxDy' folder
    for d = 1:length(D_folders)
        current_D_folder = fullfile(current_R_folder, D_folders(d).name);
        disp(['Processing subfolder: ' current_D_folder]);
        
        % Change the current folder to the 'RxDy' subfolder
        cd(current_D_folder);
        [~,D,X] = fileparts(current_D_folder); name = D([1:6]);
        
        if exist(strcat(name,'_sessioninfo.mat')) == 2;
            session_end = [];
            load(strcat(name,'_sessioninfo.mat'));
            if exist(strcat(name, '_lfp.dat')) && ...
                    exist(strcat(name, '_timestamps.npy')) && ...
                    strcmp(paradigm,paradigm_toinclude) && ...
                    any(strcmp(session, session_toinclude))||any(strcmp(session_end, session_toinclude));
                disp(['  All required files exists. Performing action...']);
                
                % Filtramos la tabla para quedarme con los IDs, y los timestamps de inicio y fin.
                filteredTable = EventsSheet(EventsSheet.Rat == r, :);
                filteredTable = filteredTable(strcmp(filteredTable.Name, name), :);
                event_ID = filteredTable.ID;
                event_inicio = filteredTable.Inicio;
                event_fin = filteredTable.Fin;
                
                % The file exists, do something
                ch_ACC = ACC_channels;

                % ACC
                if ~isempty(ch_ACC)
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
                end

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % Analizamos GCI solo si tenemos las tres señales
                if exist('movement')
                    % Comenzamos el análisis de Accelerometer
                    disp(['  Calculating acceleration during event...']);
                    for i = 1:size(event_inicio,1)
                        disp(['  Processing event: ' num2str(i) ' of ' num2str(size(event_inicio,1))]);
                        if ~isempty(event_inicio)
                            if event_inicio(i) > 10 && event_inicio(i) < timestamps(end) - 10
                                [~, idx] = min(abs(movement_timestamps - event_inicio(i)));
                                movement_vector = movement(1,idx-(5*Fs):idx+(5*Fs));
                                Accelerometer_Sheet{end+1, 1} = event_ID(i);
                                Accelerometer_Sheet{end, 2} = movement_vector;
                            end
                        end                                             
                    end
                end        
            else
                disp(['  Some required file do not exist.']);
                disp(['  Skipping action...']);
            end

        end
    end
    % Go back to the 'Rxx' folder
    cd(current_R_folder);
end

cd(parentFolder);

t = -5:1/Fs:5;

column_names = {'ID','Acceleration'};

clearvars -except t Accelerometer_Sheet column_names

cd('D:\Doctorado\Analisis\Sheets');
save('Accelerometer_Sheet.mat','-v7.3');
disp('Ready!');