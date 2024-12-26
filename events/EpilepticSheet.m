%% Cargamos todos los eventos epilepticos en una planilla que tenga Rat, Session, Inicio, Fin, Duracion
% La guardamos en Sheets con el nombre Epileptic_Sheet.csv
% Luego quiero agregar una columna a Events_Sheet que me diga qué
% porcentaje del evento está contaminado por un evento epiléptico

clc
clear all

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
        
        % Reseteamos las tablas de epileptic
        tableEpileptic = table();
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
                    % Epileptic events
                    n = size(inicio_epileptic,2);
                    Event = repmat({'Epileptic'}, n, 1);
                    Rat = repmat(r, n, 1);
                    Name = repmat({name}, n, 1);
                    Session = repmat({session}, n, 1);
                    Type = repmat(NaN, n, 1);
                    Trial = repmat(NaN, n, 1);
                    Inicio = inicio_epileptic';
                    Fin = fin_epileptic';
                    Duracion = duracion_epileptic';
                    % Creamos la tabla
                    tableEpileptic = table(Event, Rat, Name, Session, Type, Trial, Inicio, Fin, Duracion);
                    clear Event Rat Name Session Type Trial Inicio Fin Duracion;
                    %%%%%%%%%%%%%%%%%
                    
                    % Creamos la tabla con todas las otras tablas agrupadas verticalmente
                    tableStack = vertcat(tableEpileptic);
                    
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
cd('D:\Doctorado\Analisis\Sheets');
writetable(EventsSheet, 'EpilepticSheet.csv');