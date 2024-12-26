%% Flat detector loop
% Detecta los momentos flat y los guarda en epileptic.mat como inicio_flat
% y fin_flat
% Este script usa la función find_regions

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
        
        if exist(file_path, 'file') && exist(sessioninfo_path, 'file') == 2 && exist(strcat(name,'_epileptic.mat'), 'file')
            % The file exists, do something
            disp(['  File ' file_path ' exists. Performing action...']);
            load(strcat(name,'_sessioninfo.mat'), 'ch_total'); % Número de canales totales                        
         
            % BLA
            % Load data and do analysis on data
            load(strcat(name,'_sessioninfo.mat'), 'BLA_mainchannel'); ch = BLA_mainchannel; clear BLA_mainchannel; % Canal a levantar
            if ~isempty(ch)
                % BLA low-freq specgram
                % Cargamos un canal LFP del amplificador
                disp(['    Uploading BLA amplifier data...']);
                [amplifier_lfp] = LoadBinary(strcat(name,'_lfp.dat'), ch, ch_total);
                amplifier_lfp = amplifier_lfp * 0.195; % Convertir un canal de registro de bits a microvolts (uV).
                lfp_BLA = zpfilt(amplifier_lfp,1250,0.1,300); % Filtramos la señal entre 0.1 y 300
                lfp_BLA = zscorem(lfp_BLA); % Lo normalizamos con zscore
            end
            
            % PL
            % Load data and do analysis on data
            load(strcat(name,'_sessioninfo.mat'), 'PL_mainchannel'); ch = PL_mainchannel; clear PL_mainchannel; % Canal a levantar
            if ~isempty(ch)
                % PL low-freq specgram
                % Cargamos un canal LFP del amplificador
                disp(['    Uploading PL amplifier data...']);
                [amplifier_lfp] = LoadBinary(strcat(name,'_lfp.dat'), ch, ch_total);
                amplifier_lfp = amplifier_lfp * 0.195; % Convertir un canal de registro de bits a microvolts (uV).
                lfp_PL = zpfilt(amplifier_lfp,1250,0.1,300); % Filtramos la señal entre 0.1 y 300
                lfp_PL = zscorem(lfp_PL); % Lo normalizamos con zscore
            end
            
            % IL
            % Load data and do analysis on data
            load(strcat(name,'_sessioninfo.mat'), 'IL_mainchannel'); ch = IL_mainchannel; clear IL_mainchannel; % Canal a levantar
            if ~isempty(ch)
                % IL low-freq specgram
                % Cargamos un canal LFP del amplificador
                disp(['    Uploading IL amplifier data...']);
                [amplifier_lfp] = LoadBinary(strcat(name,'_lfp.dat'), ch, ch_total);
                amplifier_lfp = amplifier_lfp * 0.195; % Convertir un canal de registro de bits a microvolts (uV).
                lfp_IL = zpfilt(amplifier_lfp,1250,0.1,300); % Filtramos la señal entre 0.1 y 300
                lfp_IL = zscorem(lfp_IL); % Lo normalizamos con zscore
            end 
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Calculamos los eventos flat, cargamos epileptic y guardamos
            % los eventos en ese archivo.
            
            if exist('lfp_BLA')
                lfp = lfp_BLA;
            elseif exist('lfp_PL')
                lfp = lfp_PL;
            elseif exist('lfp_IL')
                lfp = lfp_IL;
            end
         
            if exist('lfp')
               % Parámetros
                Fs = 1250; % Frecuencia de muestreo en Hz

                % Calcular diferencias consecutivas
                threshold = 0.01; % Umbral para diferencias pequeñas
                flat_signal = abs(diff(lfp)) < threshold;

                % Detectar regiones planas
                min_samples = 5; % Mínimo número de muestras consecutivas para considerar "plano"
                flat_regions = find_regions(flat_signal, min_samples);

                % Convertir índices a tiempos en segundos
                inicio_flat = (flat_regions(:,1) - 1) / Fs; % Inicio de cada región plana
                fin_flat = flat_regions(:,2) / Fs;         % Fin de cada región plana
                inicio_flat = inicio_flat';
                fin_flat = fin_flat';
                
                if exist(strcat(name,'_epileptic.mat'), 'file')
                    disp(['    Saving flat timestamps...']);
                    save(strcat(name,'_epileptic.mat'), 'inicio_flat', 'fin_flat', '-append');
                end
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