%% Events Sheet
% Script para crear la table de eventos con los CS1, CS2, preCS, ITI, Freezing y Movimiento

% ID: identificador único de número de evento
% Event: tipo de evento. Freezing, Movement, CS1, CS2, preCS1, preCS2, ITI, PortPoke, RewardSeeking
% Rat: número de la rata
% Name: Nombre de la carpeta "R00D00"
% Session: Nombre de la sesión. Ej: EXT1
% Type: Tipo de evento si cae dentro del CS1 (1), del CS2 (2), en el preCS1 (3) o en el preCS2 (4), ITI (5), otro momento (NaN)
% Trial: Si cae dentro del CS o el preCS, a qué trial pertenece
% Inicio: timestamp de inicio del evento en segundos
% Fin: timestamp de finalizacion del evento en segundos
% Duracion: duración del evento en segundos

clc;
clear all;

rats = 10:20; % Filtro por animales que quiero analizar
paradigm_toinclude = 'aversive'; % Filtro por el paradigma
session_toinclude = {'EXT1','EXT2','TEST'}; % Filtro por las sesiones appetitivas

% Define the parent folder containing the 'Rxx' folders
parentFolder = 'D:\Doctorado\Backup Ordenado';

% List all 'Rxx' folders in the parent foldercurrent_D_folder
R_folders = dir(fullfile(parentFolder, 'R*'));

% Creamos la tabla general donde vamos a guardar los datos
EventsSheet = table();

% Iterate through each 'Rxx' folder
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
        
        % Reseteamos las tablas de CS1, CS2, preCS1, etc
        tableCS1 = table();
        tableCS2 = table();
        tablepreCS1 = table();
        tablepreCS2 = table();
        tableITI = table();
        tableFreezing = table();
        tableMovement = table();
        tableStack = table();
        
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
                    
                    %%%%%%%%%%%%%%%%%
                    % Freezing events
                    if exist('inicio_freezing');
                        n = size(inicio_freezing,2);
                        % Initialize output arrays
                        freezing_type = [];
                        freezing_trial = [];
                        
                        for i = 1:size(inicio_freezing, 2)

                            % Check if freezing onset occurs during CS1
                            trial_cs1 = find((inicio_freezing(i) >= TTL_CS1_inicio) & (inicio_freezing(i) < TTL_CS1_fin), 1);
                            if ~isempty(trial_cs1)
                                freezing_type(1, i) = 1; % Type 1 for freezing onset during CS1
                                freezing_trial(1, i) = trial_cs1; % Store the trial number for CS1

                            % Check if freezing onset occurs during CS2
                            elseif any((inicio_freezing(i) >= TTL_CS2_inicio) & (inicio_freezing(i) < TTL_CS2_fin))
                                trial_cs2 = find((inicio_freezing(i) >= TTL_CS2_inicio) & (inicio_freezing(i) < TTL_CS2_fin), 1);
                                freezing_type(1, i) = 2; % Type 2 for freezing onset during CS2
                                freezing_trial(1, i) = trial_cs2; % Store the trial number for CS2

                            % Check if freezing onset occurs during preCS1
                            elseif any((inicio_freezing(i) >= TTL_CS1_inicio - 20) & (inicio_freezing(i) < TTL_CS1_inicio))
                                trial_preCS1 = find((inicio_freezing(i) >= TTL_CS1_inicio - 20) & (inicio_freezing(i) < TTL_CS1_inicio), 1);
                                freezing_type(1, i) = 3; % Type 3 for freezing onset during preCS1
                                freezing_trial(1, i) = trial_preCS1; % Store the trial number for preCS1

                            % Check if freezing onset occurs during preCS2
                            elseif any((inicio_freezing(i) >= TTL_CS2_inicio - 20) & (inicio_freezing(i) < TTL_CS2_inicio))
                                trial_preCS2 = find((inicio_freezing(i) >= TTL_CS2_inicio - 20) & (inicio_freezing(i) < TTL_CS2_inicio), 1);
                                freezing_type(1, i) = 4; % Type 4 for freezing onset during preCS2
                                freezing_trial(1, i) = trial_preCS2; % Store the trial number for preCS2

                            % If not within CS1, CS2, preCS1, or preCS2, mark as ITI
                            else
                                if (inicio_freezing(i) >= TTL_CS1_inicio(1)) & (inicio_freezing(i) < TTL_CS1_fin(end))
                                    freezing_type(1, i) = 5; % Type 5 for freezing onset during ITI
                                    freezing_trial(1, i) = NaN; % No trial number for ITI
                                else
                                    freezing_type(1, i) = NaN; % Mark any other moment
                                    freezing_trial(1, i) = NaN;
                                end
                            end
                        end
                        Event = repmat({'Freezing'}, n, 1);
                        Rat = repmat(r, n, 1);
                        Name = repmat({name}, n, 1);
                        Session = repmat({session}, n, 1);
                        Type = freezing_type';
                        Trial = freezing_trial';
                        Inicio = inicio_freezing';
                        Fin = fin_freezing';
                        Duracion = duracion_freezing';
                        % Creamos la tabla
                        tableFreezing = table(Event, Rat, Name, Session, Type, Trial, Inicio, Fin, Duracion);
                        clear Event Rat Name Session Type Trial Inicio Fin Duracion;
                    end
                    %%%%%%%%%%%%%%%%%
                    
                    %%%%%%%%%%%%%%%%%
                    if exist('inicio_movement');
                        % Movement events
                        n = size(inicio_movement,2);
                        % Initialize output arrays for movement
                        movement_type = [];
                        movement_trial = [];

                        for i = 1:size(inicio_movement, 2)

                            % Check if movement onset occurs during CS1
                            trial_cs1 = find((inicio_movement(i) >= TTL_CS1_inicio) & (inicio_movement(i) < TTL_CS1_fin), 1);
                            if ~isempty(trial_cs1)
                                movement_type(1, i) = 1; % Type 1 for movement onset during CS1
                                movement_trial(1, i) = trial_cs1; % Store the trial number for CS1

                            % Check if movement onset occurs during CS2
                            elseif any((inicio_movement(i) >= TTL_CS2_inicio) & (inicio_movement(i) < TTL_CS2_fin))
                                trial_cs2 = find((inicio_movement(i) >= TTL_CS2_inicio) & (inicio_movement(i) < TTL_CS2_fin), 1);
                                movement_type(1, i) = 2; % Type 2 for movement onset during CS2
                                movement_trial(1, i) = trial_cs2; % Store the trial number for CS2

                            % Check if movement onset occurs during preCS1
                            elseif any((inicio_movement(i) >= TTL_CS1_inicio - 20) & (inicio_movement(i) < TTL_CS1_inicio))
                                trial_preCS1 = find((inicio_movement(i) >= TTL_CS1_inicio - 20) & (inicio_movement(i) < TTL_CS1_inicio), 1);
                                movement_type(1, i) = 3; % Type 3 for movement onset during preCS1
                                movement_trial(1, i) = trial_preCS1; % Store the trial number for preCS1

                            % Check if movement onset occurs during preCS2
                            elseif any((inicio_movement(i) >= TTL_CS2_inicio - 20) & (inicio_movement(i) < TTL_CS2_inicio))
                                trial_preCS2 = find((inicio_movement(i) >= TTL_CS2_inicio - 20) & (inicio_movement(i) < TTL_CS2_inicio), 1);
                                movement_type(1, i) = 4; % Type 4 for movement onset during preCS2
                                movement_trial(1, i) = trial_preCS2; % Store the trial number for preCS2

                            % If not within CS1, CS2, preCS1, or preCS2, mark as ITI
                            else
                                if (inicio_movement(i) >= TTL_CS1_inicio(1)) & (inicio_movement(i) < TTL_CS1_fin(end))
                                    movement_type(1, i) = 5; % Type 5 for movement onset during ITI
                                    movement_trial(1, i) = NaN; % No trial number for ITI
                                else
                                    movement_type(1, i) = NaN; % Mark any other moment
                                    movement_trial(1, i) = NaN;
                                end
                            end
                        end
                        Event = repmat({'Movement'}, n, 1);
                        Rat = repmat(r, n, 1);
                        Name = repmat({name}, n, 1);
                        Session = repmat({session}, n, 1);
                        Type = movement_type';
                        Trial = movement_trial';
                        Inicio = inicio_movement';
                        Fin = fin_movement';
                        Duracion = duracion_movement';
                        % Creamos la tabla
                        tableMovement = table(Event, Rat, Name, Session, Type, Trial, Inicio, Fin, Duracion);
                        clear Event Rat Name Session Type Trial Inicio Fin Duracion;
                    end
                    %%%%%%%%%%%%%%%%%%
                    
                    %%%%%%%%%%%%%%%%%%
                    % CS1 events
                    n = size(TTL_CS1_inicio,1);
                    Event = repmat({'CS1'}, n, 1);
                    Rat = repmat(r, n, 1);
                    Name = repmat({name}, n, 1);
                    Session = repmat({session}, n, 1);
                    Type = repmat(1, n, 1);
                    Trial = (1:n)';
                    Inicio = TTL_CS1_inicio;
                    Fin = TTL_CS1_fin;
                    Duracion = (TTL_CS1_fin - TTL_CS1_inicio);
                    % Creamos la tabla
                    tableCS1 = table(Event, Rat, Name, Session, Type, Trial, Inicio, Fin, Duracion);
                    clear Event Rat Name Session Type Trial Inicio Fin Duracion;
                    %%%%%%%%%%%%%%%%%%
                    
                    %%%%%%%%%%%%%%%%%%
                    % CS2 events
                    n = size(TTL_CS2_inicio,1);
                    Event = repmat({'CS2'}, n, 1);
                    Rat = repmat(r, n, 1);
                    Name = repmat({name}, n, 1);
                    Session = repmat({session}, n, 1);
                    Type = repmat(2, n, 1);
                    Trial = (1:n)';
                    Inicio = TTL_CS2_inicio;
                    Fin = TTL_CS2_fin;
                    Duracion = (TTL_CS2_fin - TTL_CS2_inicio);
                    % Creamos la tabla
                    tableCS2 = table(Event, Rat, Name, Session, Type, Trial, Inicio, Fin, Duracion);
                    clear Event Rat Name Session Type Trial Inicio Fin Duracion;
                    %%%%%%%%%%%%%%%%%%
                    
                    %%%%%%%%%%%%%%%%%%
                    % preCS1 events
                    n = size(preCS1_inicio,1);
                    Event = repmat({'preCS1'}, n, 1);
                    Rat = repmat(r, n, 1);
                    Name = repmat({name}, n, 1);
                    Session = repmat({session}, n, 1);
                    Type = repmat(3, n, 1);
                    Trial = (1:n)';
                    Inicio = preCS1_inicio;
                    Fin = preCS1_fin;
                    Duracion = preCS1_duracion;
                    % Creamos la tabla
                    tablepreCS1 = table(Event, Rat, Name, Session, Type, Trial, Inicio, Fin, Duracion);
                    clear Event Rat Name Session Type Trial Inicio Fin Duracion;
                    %%%%%%%%%%%%%%%%%%
                    
                    %%%%%%%%%%%%%%%%%%
                    % preCS2 events
                    n = size(preCS2_inicio,1);
                    Event = repmat({'preCS2'}, n, 1);
                    Rat = repmat(r, n, 1);
                    Name = repmat({name}, n, 1);
                    Session = repmat({session}, n, 1);
                    Type = repmat(4, n, 1);
                    Trial = (1:n)';
                    Inicio = preCS2_inicio;
                    Fin = preCS2_fin;
                    Duracion = preCS2_duracion;
                    % Creamos la tabla
                    tablepreCS2 = table(Event, Rat, Name, Session, Type, Trial, Inicio, Fin, Duracion);
                    clear Event Rat Name Session Type Trial Inicio Fin Duracion;
                    %%%%%%%%%%%%%%%%%%
                    
                    %%%%%%%%%%%%%%%%%%
                    % ITI events
                    n = size(ITI_inicio,1);
                    Event = repmat({'ITI'}, n, 1);
                    Rat = repmat(r, n, 1);
                    Name = repmat({name}, n, 1);
                    Session = repmat({session}, n, 1);
                    Type = repmat(5, n, 1);
                    Trial = repmat(NaN, n, 1);
                    Inicio = ITI_inicio;
                    Fin = ITI_fin;
                    Duracion = ITI_duracion;
                    % Creamos la tabla
                    tableITI = table(Event, Rat, Name, Session, Type, Trial, Inicio, Fin, Duracion);
                    clear Event Rat Name Session Type Trial Inicio Fin Duracion;
                    %%%%%%%%%%%%%%%%%%
                    
                    % Creamos la tabla con todas las otras tablas agrupadas verticalmente
                    tableStack = vertcat(tableCS1,tableCS2,tablepreCS1,tablepreCS2,tableITI,tableFreezing,tableMovement);
                    
                    % Agregamos tableStack verticalmente abajo de EventsSheet
                    EventsSheet = vertcat(EventsSheet,tableStack);
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                end
            end
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Agregamos el ID único en la primera columna
clearvars -except EventsSheet
% Creamos el ID
ID = (1:size(EventsSheet,1))';
% Agregar la columna ID a la tabla como la primera columna
EventsSheet.ID = ID;
% Reordenar para que la columna ID sea la primera
EventsSheet = [table(ID), EventsSheet(:, 1:end-1)];
clear ID;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Guardamos la tabla como un .mat y .csv
cd('D:\Doctorado\Analisis');
save('EventsSheet.mat', 'EventsSheet');
writetable(EventsSheet, 'EventsSheet.csv');
