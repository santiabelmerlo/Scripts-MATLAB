%% preCS and ITI events detector
% Script para crear las variables preCS1, preCS2 e ITI y guardarlas en el archivo epileptic.mat de cada sesion.
clc;
clear all;

% PreCS aversivo: 20 segundos previos al CS de 60 seg (ITI 20 a 40 seg)
% PreCS apetitivo: 5 seg previos al CS de 10 seg (ITI 10 a 30 seg)

rats = 10:20; % Filtro por animales que quiero analizar

% paradigm_toinclude = 'aversive'; % Filtro por el paradigma
% session_toinclude = {'EXT1','EXT2','TEST'}; % Filtro por las sesiones aversivas
% predur = 20; % Duración del preCS para el aversivo

paradigm_toinclude = 'appetitive'; % Filtro por el paradigma
session_toinclude = {'TR1','TR2','TR3','TR4','TR5','TR6','TR7','TR8','TR9','EXT1','EXT2'}; % Filtro por las sesiones appetitivas
predur = 5; % Duración del preCS para el apetitivo

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
                   % Verificar si las longitudes de los TTL_CS son diferentes
                    if size(TTL_CS1_inicio, 1) ~= size(TTL_CS1_fin, 1)
                        % Verificar si el primer inicio es mayor o igual que el primer fin
                        if TTL_CS1_inicio(1) >= TTL_CS1_fin(1)
                            % Si hay más inicios que fines, eliminar el último inicio
                            if size(TTL_CS1_inicio, 1) > size(TTL_CS1_fin, 1)
                                TTL_CS1_inicio(end) = [];         
                            % Si hay más fines que inicios, eliminar el primer fin
                            elseif size(TTL_CS1_inicio, 1) < size(TTL_CS1_fin, 1)
                                TTL_CS1_fin(1) = [];
                            end
                        end
                        % Verificar si el último fin es menor o igual que el último inicio
                        if TTL_CS1_fin(end) <= TTL_CS1_inicio(end)
                            TTL_CS1_inicio(end) = [];
                        end
                    end
                    
                    if size(TTL_CS2_inicio, 1) ~= size(TTL_CS2_fin, 1)
                        % Verificar si el primer inicio es mayor o igual que el primer fin
                        if TTL_CS2_inicio(1) >= TTL_CS2_fin(1)
                            % Si hay más inicios que fines, eliminar el último inicio
                            if size(TTL_CS2_inicio, 1) > size(TTL_CS2_fin, 1)
                                TTL_CS2_inicio(end) = [];         
                            % Si hay más fines que inicios, eliminar el primer fin
                            elseif size(TTL_CS2_inicio, 1) < size(TTL_CS2_fin, 1)
                                TTL_CS2_fin(1) = [];
                            end
                        end
                        % Verificar si el último fin es menor o igual que el último inicio
                        if TTL_CS2_fin(end) <= TTL_CS2_inicio(end)
                            TTL_CS2_inicio(end) = [];
                        end
                    end
                    
                    % preCS1
                    preCS1_inicio = TTL_CS1_inicio - predur;
                    preCS1_fin = TTL_CS1_inicio;
                    preCS1_duracion = preCS1_fin - preCS1_inicio;

                    % preCS2
                    preCS2_inicio = TTL_CS2_inicio - predur;
                    preCS2_fin = TTL_CS2_inicio;
                    preCS2_duracion = preCS2_fin - preCS2_inicio;

                    % ITI
                    % Combinar todos los inicios y finales de eventos
                    todos_inicio = sort([TTL_CS1_inicio; TTL_CS2_inicio; preCS1_inicio; preCS2_inicio]);
                    todos_fin = sort([TTL_CS1_fin; TTL_CS2_fin; preCS1_fin; preCS2_fin]);
                    % Definir los ITI (Inter-Trial Interval) como los intervalos entre los eventos
                    ITI_inicio = todos_fin(1:end-1);   % Los ITIs empiezan cuando termina un bloque
                    ITI_fin = todos_inicio(2:end);     % Los ITIs terminan cuando empieza el siguiente bloque
                    % Filtrar los ITIs que sean válidos (asegurarse de que no sean negativos)
                    validos = ITI_inicio < ITI_fin;
                    ITI_inicio = ITI_inicio(validos);
                    ITI_fin = ITI_fin(validos);
                    clear validos;
                    % Calcular la duración de los ITIs
                    ITI_duracion = ITI_fin - ITI_inicio;
                    % Filtrar ITIs que no ocurren antes del primer evento o después del último
                    validos = ITI_inicio >= todos_inicio(1) & ITI_fin <= todos_fin(end);
                    ITI_inicio = ITI_inicio(validos);
                    ITI_fin = ITI_fin(validos);
                    ITI_duracion = ITI_duracion(validos);
                    % Filtrar los ITIs que al menos duran 1 seg
                    validos = ITI_duracion > 1;
                    ITI_inicio = ITI_inicio(validos);
                    ITI_fin = ITI_fin(validos);
                    ITI_duracion = ITI_duracion(validos);
                    
                    % Guardamos las variables que calcule en el archivo epileptic.mat
                    save([strcat(name, '_epileptic.mat')], 'name', 'inicio_freezing', 'fin_freezing', 'duracion_freezing', ...
                        'inicio_quietud', 'fin_quietud', 'duracion_quietud', 'inicio_epileptic', ...
                        'inicio_sleep', 'fin_sleep', 'duracion_sleep', 'fin_epileptic', 'duracion_epileptic', ...
                        'paradigm', 'inicio_movement', 'fin_movement', 'duracion_movement', ...
                        'TTL_CS1_inicio', 'TTL_CS1_fin', 'TTL_CS2_inicio', 'TTL_CS2_fin',...
                        'preCS1_inicio', 'preCS1_fin', 'preCS1_duracion',...
                        'preCS2_inicio', 'preCS2_fin', 'preCS2_duracion',...
                        'ITI_inicio', 'ITI_fin', 'ITI_duracion');
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