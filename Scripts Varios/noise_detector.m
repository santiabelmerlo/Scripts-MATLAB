%% Script detectar ruido y guardar esos timestamps
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
        file_path = strcat(name, '_lfp.dat');
        info_path = strcat(name, '_sessioninfo.mat');
        
        if exist(file_path, 'file') == 2 && exist(info_path, 'file') == 2
            % The file exists, do something
            disp(['    File ' file_path ' exists. Starting analysis...']);
            
            % Load data and do analysis on data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%            
            % Seteamos qué canal queremos levantar de la señal
            Fs = 1250; % Frecuencia de sampleo
            
            load(strcat(name,'_sessioninfo.mat'), 'BLA_mainchannel'); ch = BLA_mainchannel; clear BLA_mainchannel; % Canal a levantar
            if isempty(ch);
                clear ch;
                load(strcat(name,'_sessioninfo.mat'), 'PL_mainchannel'); ch = PL_mainchannel; clear PL_mainchannel; % Canal a levantar
                if isempty(ch);
                    clear ch;
                    load(strcat(name,'_sessioninfo.mat'), 'IL_mainchannel'); ch = IL_mainchannel; clear IL_mainchannel; % Canal a levantar
                end
            end

            load(strcat(name,'_sessioninfo.mat'), 'ch_total'); % Número de canales totales
            load(strcat(name,'_sessioninfo.mat'), 'paradigm'); % Tipo de paradigma. Appetitive or aversive

            % Cargamos los datos del amplificador
            amplifier_timestamps = readNPY(strcat(name,'_timestamps.npy')); % Cargamos el estado de cada input del IO Board.
            amplifier_timestamps = double(amplifier_timestamps(1):1:amplifier_timestamps(end)); % Hay que hacer esto porque amplifier.timestamps devuelve distinto número de tiempos que de registro.
            amplifier_timestamps_lfp = double(amplifier_timestamps(1):24:amplifier_timestamps(end)); % Hay que hacer esto porque amplifier.timestamps devuelve distinto número de tiempos que de registro.
            amplifier_timestamps_lfp = (amplifier_timestamps_lfp - amplifier_timestamps(1))/30000; % Le restamos el primer timestamp y lo pasamos a segundos. 

            % Cargamos un canal LFP del amplificador
            disp(['      Uploading amplifier data...']);
            [amplifier_lfp] = LoadBinary(strcat(name,'_lfp.dat'), ch, ch_total);
            amplifier_lfp = amplifier_lfp * 0.195; % Convertir un canal de registro de bits a microvolts (uV).
            amplifier_lfp = zscore(amplifier_lfp);

            % Buscamos los momentos que sobrepasa el umbral
            disp(['      Detecting noise...']);
            noise = abs(amplifier_lfp) > 5;
            noise_timestamps = amplifier_timestamps_lfp(find(diff(noise) == 1));
            noise_timestamps = noise_timestamps';

            % Buscamos aquellos timestamps que esten más cerca de 1 segundo y los
            % eliminamos para quedarnos solo con el primero
            % time_diff = diff(noise_timestamps);
            % remove_indices = find(time_diff < 1) + 1; % Adding 1 to shift indices to the right
            % noise_timestamps(remove_indices) = [];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%            
            % Save the results to a .mat file
            % Guardamos solo las variables f,S,Serr,t
            filename = strcat(name,'_noise.csv');
            csvwrite(filename,noise_timestamps);
            disp(['      Saving ' filename ' file into the Current Folder']);
        
            % Guardamos también en H:
            currentDir = pwd;
            parts = strsplit(currentDir, '\');
            lastTwoParts = fullfile(parts{end-1}, parts{end});
            newPath = fullfile('H:\', lastTwoParts);
            cd(newPath);
            csvwrite(filename,noise_timestamps);
            disp(['      Saving ' filename ' file into Backup H:']);
            cd(currentDir);
        else
            % The file does not exist, do nothing
            disp(['    File ' file_path ' does not exist. Skipping action...']);
        end
        
        % Go back to the 'Rxx' folder
        cd(current_R_folder);
    end
end