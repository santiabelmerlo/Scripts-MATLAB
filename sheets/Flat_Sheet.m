%% Columna Flat en la planilla de eventos
% Recorre todos los eventos de la planilla y busca en la carpeta de cada
% sesión los timestamps de los eventos Flat. Agrega una columna a la
% planilla EventsSheet que me dice el porcentaje del evento contaminado por
% un evento Flat.
clc;
clear;

% Define la carpeta principal y carga la tabla
parentFolder = 'D:\Doctorado\Backup Ordenado';
cd('D:\Doctorado\Analisis\Sheets');
EventsSheet = readtable('EventsSheet.csv');

% Inicializa la nueva columna
EventsSheet.Flat = zeros(height(EventsSheet), 1);

% Lista las carpetas de ratas (Rxx)
R_folders = dir(fullfile(parentFolder, 'R*'));
R_folders = R_folders([R_folders.isdir]);

% Itera por cada rata
for r = 1:length(R_folders)
    current_R_folder = fullfile(parentFolder, R_folders(r).name);
    disp(['Procesando carpeta: ' current_R_folder]);
    
    % Lista las subcarpetas (RxDy)
    D_folders = dir(fullfile(current_R_folder, 'R*D*'));
    D_folders = D_folders([D_folders.isdir]);
    
    % Itera por cada subcarpeta (RxDy)
    for d = 1:length(D_folders)
        current_D_folder = fullfile(current_R_folder, D_folders(d).name);
        disp(['Procesando subcarpeta: ' current_D_folder]);
        
        % Cambia al directorio actual
        cd(current_D_folder);
        [~, D, ~] = fileparts(current_D_folder);
        name = D(1:6);
        
        % Verifica si existe el archivo '_epileptic.mat'
        epilepticFile = strcat(name, '_epileptic.mat');
        if exist(epilepticFile, 'file') == 2
            load(epilepticFile, 'inicio_flat', 'fin_flat');
            
            % Verifica si existen las variables necesarias
            if exist('inicio_flat', 'var') && exist('fin_flat', 'var')
                % Filtra los eventos correspondientes a esta sesión
                sessionEvents = EventsSheet(strcmp(EventsSheet.Name, name), :);
                
                % Calcula la proporción de tiempo "flat" para cada evento
                for i = 1:height(sessionEvents)
                    eventStart = sessionEvents.Inicio(i);
                    eventEnd = sessionEvents.Fin(i);
                    
                    % Inicializamos flatDuration para el evento actual
                    flatDuration = 0;

                    % Iteramos sobre los segmentos "flat"
                    for j = 1:length(inicio_flat)
                        % Calculamos la intersección del segmento "flat" con el intervalo del evento
                        flatStart = max(inicio_flat(j), eventStart);
                        flatEnd = min(fin_flat(j), eventEnd);

                        % Si hay intersección (flatStart < flatEnd), sumamos la duración de la intersección
                        if flatStart < flatEnd
                            flatDuration = flatDuration + (flatEnd - flatStart);
                        end
                    end
                    
                    % Calcula el porcentaje de tiempo flat en el evento
                    eventDuration = eventEnd - eventStart;
                    flatPercentage = (flatDuration / eventDuration) * 100;
                    
                    % Almacena el valor en la tabla
                    EventsSheet.Flat(EventsSheet.ID == sessionEvents.ID(i)) = flatPercentage;
                end
            else
                disp(['Variables inicio_flat o fin_flat no encontradas en: ' epilepticFile]);
            end
        else
            disp(['Archivo no encontrado: ' epilepticFile]);
        end
    end
end

% Vuelve a la carpeta inicial
cd('D:\Doctorado\Analisis\Sheets');

% Guarda la tabla actualizada
writetable(EventsSheet, 'EventsSheet.csv');
disp('Tabla actualizada guardada como EventsSheet_updated.csv');
