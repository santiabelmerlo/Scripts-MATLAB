%% Head entries and Nosepokes detector
% Script para crear detectar los head entries y los nosepokes y guardarlos
% junto con epileptic.mat

clc;
clear all;

rats = 10:20; % Filtro por animales que quiero analizar
paradigm_toinclude = 'appetitive'; % Filtro por el paradigma
session_toinclude = {'TR1','TR2','TR3','TR4','TR5','TR6','TR7','TR8','TR9','EXT1','EXT2'}; % Filtro por las sesiones appetitivas

% Define the parent folder containing the 'Rxx' folders
parentFolder = 'D:\Doctorado\Backup Ordenado';

% List all 'Rxx' folders in the parent foldercurrent_D_folder
R_folders = dir(fullfile(parentFolder, 'R*'));

% Iterate through each 'Rxx' folder
k = 1;
for r = rats;
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
        
        if exist(strcat(name,'_sessioninfo.mat')) == 2;
            load(strcat(name,'_sessioninfo.mat'));
            if strcmp(paradigm,paradigm_toinclude) && any(strcmp(session,session_toinclude));
                disp(['      Session found, including in dataset...']);
                if exist(strcat(name,'_sessioninfo.mat')) == 2 && ...
                        exist(strcat(name,'_epileptic.mat')) == 2;  
                    load(strcat(name,'_epileptic.mat'));
                    disp(['      Loading epileptic.mat data...']);                  
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    Fs = 1250; % Frecuencia de sampleo

                    % Cargamos los datos del TTL1
                    TTL_states = readNPY(strcat(name,'_TTL_channel_states.npy')); % Cargamos el estado de cada input del IO Board. 
                    TTL_timestamps = readNPY(strcat(name,'_TTL_timestamps.npy')); % Los timestamps estan en unidad de muestreo: 30 kHz.
                    TTL_channels = readNPY(strcat(name,'_TTL_channels.npy')); % Cargamos los estados de los canales.

                    % Cargamos los datos del amplificador
                    amplifier_timestamps = readNPY(strcat(name,'_timestamps.npy')); % Cargamos el estado de cada input del IO Board.
                    amplifier_timestamps = double(amplifier_timestamps(1):1:amplifier_timestamps(end)); % Hay que hacer esto porque amplifier.timestamps devuelve distinto número de tiempos que de registro.

                    % Buscamos el primer timestamps y se lo restamos al vector de timestamps
                    TTL_start = amplifier_timestamps(1); % Seteamos el primer timestamp 
                    TTL_end = amplifier_timestamps(end); % Seteamos el último timestamp
                    TTL_timestamps = TTL_timestamps - TTL_start; % Le restamos el primer timestamp

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

                    % Llevo los tiempos de los HeadEntries a segundos y los sincronizo con los tiempos del registro
                    IR2_inicio = double(IR2_start);
                    IR2_fin = double(IR2_end);
                    port_inicio = IR2_inicio/30000; % Llevo los tiempos a segundos
                    port_fin = IR2_fin/30000; % Llevo los tiempos a segundos
                    port_duracion = port_fin - port_inicio;

                    % Llevo los tiempos de los nosepokes a segundos y los sincronizo con los tiempos del registro
                    IR3_inicio = double(IR3_start);
                    IR3_fin = double(IR3_end);
                    reward_inicio = IR3_inicio/30000; % Llevo los tiempos a segundos
                    reward_fin = IR3_fin/30000; % Llevo los tiempos a segundos
                    reward_duracion = reward_fin - reward_inicio;

                    clear amplifier_timestamps Fs TTL_channels TTL_end TTL_start TTL_states TTL_timestamps...
                        IR2_fin IR2_inicio IR2_end IR2_start IR3_fin IR3_inicio IR3_end IR3_start;
                    
                    % Guardamos las variables que calcule en el archivo epileptic.mat
                    save([strcat(name, '_epileptic.mat')], 'name', 'inicio_freezing', 'fin_freezing', 'duracion_freezing', ...
                        'inicio_quietud', 'fin_quietud', 'duracion_quietud', 'inicio_epileptic', ...
                        'inicio_sleep', 'fin_sleep', 'duracion_sleep', 'fin_epileptic', 'duracion_epileptic', ...
                        'paradigm', 'inicio_movement', 'fin_movement', 'duracion_movement', ...
                        'TTL_CS1_inicio', 'TTL_CS1_fin', 'TTL_CS2_inicio', 'TTL_CS2_fin',...
                        'preCS1_inicio', 'preCS1_fin', 'preCS1_duracion',...
                        'preCS2_inicio', 'preCS2_fin', 'preCS2_duracion',...
                        'ITI_inicio', 'ITI_fin', 'ITI_duracion',...
                        'port_inicio', 'port_fin', 'port_duracion',...
                        'reward_inicio', 'reward_fin', 'reward_duracion');
                     disp(['      Saving epiletic.mat file...']);
                    
                    clear todos_inicio todos_fin validos i start_f overlaps_bonsai end_f dontoverlap_freezing;
                    
                    clearvars -except parentFolder R_folders r current_R_folder D_folders d current_D_folder rats ...
                        paradigm_toinclude session_toinclude predur;
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    
                end
            end
        end
    end
end

disp('Ready!')
clear all;
