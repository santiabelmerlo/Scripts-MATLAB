%% Acceleration Folder Loop
% Change parentFolder in order to match the path where I have folders
% R01,R02,R03,etc.
% This script enters in each folder, then in each R00D00 subfolder,
% calculates the acceleration and saves the data in "R00D00_acceleration.mat" file in each
% subfolder

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
        disp(['Processing subfolder: ' current_D_folder]);
        
        % Change the current folder to the 'RxDy' subfolder
        cd(current_D_folder);
        [~,D,X] = fileparts(current_D_folder); name = D([1:6]);
        
        % Check if the .dat file exists
        file_path = strcat(name, '_lfp.dat');
        
        % Check if the sessioninfo.mat file exists
        sessioninfo_path = strcat(name, '_sessioninfo.mat');
        
        if exist(file_path, 'file') && exist(sessioninfo_path, 'file') == 2
            % The file exists, do something
            disp(['  File ' file_path ' exists. Performing action...']);
            load(strcat(name,'_sessioninfo.mat')); % Número de canales totales                        
           
            % Reiniciamos algunas variables
            movement = [];
            t_movement = [];
            aceleracion = [];
            cambio = [];
            cambio_puntos = [];
            desaceleracion = [];
            duracion_aceleracion = [];
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if ~isempty(ACC_channels)
                if exist(strcat(name,'_acceleration.mat'), 'file'); load(strcat(name,'_acceleration.mat')); end
                
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
                t_movement = timestamps;
                
                save(strcat(name,'_acceleration.mat'),...
                    'movement','t_movement','aceleracion','cambio','cambio_puntos',...
                    'desaceleracion','duracion_aceleracion');
                disp('     Acceleration.mat file saved!')
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        else
            if exist(file_path, 'file') == 0;
                % The file does not exist, do nothing
                disp(['  File ' file_path ' does not exist.']);
            end
            if exist(sessioninfo_path, 'file') == 0;
                % The file does not exist, do nothing
                disp(['  File ' sessioninfo_path ' does not exist.']);
            end
            disp(['  Skipping action...']);
        end
        
        % Go back to the 'Rxx' folder
        cd(current_R_folder);
    end
end
disp('Done!');
cd(parentFolder);