%% Script para backupear los archivos R00D00_freezing.mat
clc;
clear all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% En estas lineas selecciono que animales, paradigma y sesiones quiero analizar
% rats = [10,11,13,14,16,17,18,19]; % Filtro por animales para apetitivo
rats = [11,12,13,17,18,19,20]; % Filtro por animales para aversivo
paradigm_toinclude = 'aversive'; % Filtro por el paradigma
% session_toinclude = {'EXT1','EXT2','TEST'}; % Filtro por las sesiones
session_toinclude = {'TEST'}; % Filtro por las sesiones
trials_toinclude = 1:4; % Qué trials me interesa incluir
meantitle = 'Freezing vs. no-Freezing during Aversive'; % Titulo general que le voy a poner a la figura
region = 'BLA';
remove_50hz = 0; % 1 para limpiar e interpolar 50Hz, 0 para no limpiar.
remove_100hz = 1; % 1 para limpiar e interpolar 100Hz, 0 para no limpiar.
remove_epileptic = 1; % 1 para limpiar los momentos epilépticos de la señal, 0 para no limpiar
trigger = 'onset'; % Trigerrear al 'onset' o al 'offset'
fr_dur_1 = 1; % Duración de freezing minimo con la que me quedo
fr_dur_2 = 100; % Duración de freezing máximo con la que me quedo
clim = [-0.5,0.5]; % Limite de la escala en z del espectrograma
lim_y = [0 12]; % Limites en el eje y 
frange = 1; % Determinar qué rango de frecuencias quiero analizar (1 a 5; 4Hz,Theta,Beta,sGamma,fGamma)
select_CS = 1; % Elegimos si queremos quedarnos con los freezing que caen en CS1, CS2 o ITI (1,2,3). Sino dejar vacío [].

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Define the parent folder containing the 'Rxx' folders
parentFolder = 'D:\Doctorado\Backup Ordenado';

% List all 'Rxx' folders in the parent folder
R_folders = dir(fullfile(parentFolder, 'R*'));

% Inicializo algunas variables
PSD_freezing = [];
PSD_nofreezing = [];
SPG_freezing = [];
SPG_nofreezing = [];
freezing_dist = [];
freezing_id = [];
freezing_when = [];

% Iterate through each 'Rxx' folder
k = 1;
m = 1;
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
            session_end = [];
            load(strcat(name,'_sessioninfo.mat'));
            if strcmp(paradigm,paradigm_toinclude) && (any(strcmp(session, session_toinclude))||any(strcmp(session_end, session_toinclude)));
                disp(['      Session found, including in dataset...']);
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                if exist(strcat(name,'_sessioninfo.mat')) == 2 && ...
                        exist(strcat(name,'_epileptic.mat')) == 2 && ...
                        exist(strcat(name,'_freezing.mat')) == 2;        
                    
                    load(strcat(name,'_sessioninfo.mat'), 'ch_total'); % Número de canales totales
                    load(strcat(name,'_sessioninfo.mat'), 'paradigm'); % Tipo de paradigma. Appetitive or aversive

                    % Cargo los tiempos de los tonos
                    load(strcat(name,'_freezing.mat'),'TTL_CS1_inicio','TTL_CS1_fin','TTL_CS2_inicio','TTL_CS2_fin');
                    % Filtramos los trials que me interesan
                    TTL_CS1_inicio = TTL_CS1_inicio(trials_toinclude,:);
                    TTL_CS1_fin = TTL_CS1_fin(trials_toinclude,:);
                    TTL_CS2_inicio = TTL_CS2_inicio(trials_toinclude,:);
                    TTL_CS2_fin = TTL_CS2_fin(trials_toinclude,:);
                    
                    % Cargamos los eventos de freezing
                    load(strcat(name,'_epileptic.mat'),'inicio_freezing','fin_freezing','inicio_epileptic','fin_epileptic','inicio_sleep','fin_sleep');
                    duracion_freezing = fin_freezing - inicio_freezing;

                    % Nos quedamos con los freezing que duran tanto tiempo
                    inicio_freezing = inicio_freezing(duracion_freezing>=fr_dur_1);
                    fin_freezing = fin_freezing(duracion_freezing>=fr_dur_1);
                    duracion_freezing = duracion_freezing(duracion_freezing>=fr_dur_1);
                    
                    % Divide freezing by onset in CS1, CS2 or ITI
                    freezing_type = [];
                    for i = 1:size(inicio_freezing,2);
                        if any((inicio_freezing(i) >= TTL_CS1_inicio) .* (inicio_freezing(i) < TTL_CS1_fin));
                            freezing_type(1,i) = 1; % Type 1 for freezing onset during CS1
                        elseif any((inicio_freezing(i) >= TTL_CS2_inicio) .* (inicio_freezing(i) < TTL_CS2_fin));
                            freezing_type(1,i) = 2; % Type 2 for freezing onset during CS2
                        elseif any((inicio_freezing(i) >= TTL_CS1_inicio - 60) .* (inicio_freezing(i) < TTL_CS1_inicio));
                            freezing_type(1,i) = 3; % Type 3 for freezing onset during ITI
                        end
                    end
                    
                    % Me quedo solo con los freezing que estan dentro de los CS o en el ITI
                    if ~isempty(select_CS)
                        duracion_freezing = duracion_freezing(freezing_type == select_CS);
                    end
                    
                    freezing_dist = cat(2,freezing_dist,duracion_freezing);
                    freezing_id = cat(2,freezing_id,repmat(m,[1,size(duracion_freezing,2)]));
                    freezing_when = cat(2,freezing_when,freezing_type);
                    
                end
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            end
        end      
    end      
    % Go back to the 'Rxx' folder
    cd(current_R_folder);
    m = m + 1; % Contador de las distintas ratas para guardar el id de cada rata en las duraciones de freezing
end
cd(parentFolder);

% Cuantificamos por animal el número de eventos de freezing y la duración media del evento de freezing

unique_ids = unique(freezing_id); % Encuentra los IDs únicos de los animales
% Inicializa vectores para almacenar los resultados
num_eventos = zeros(size(unique_ids));  % Número de eventos por animal
mean_duracion = zeros(size(unique_ids)); % Duración media por animal
% Itera sobre cada ID único para calcular las estadísticas
for i = 1:length(unique_ids)
    % Encuentra los índices de los eventos de freezing para este animal
    idx = freezing_id == unique_ids(i);
    % Cuantifica el número de eventos de freezing
    num_eventos(i) = sum(idx);
    % Calcula la duración media de los eventos de freezing
    mean_duracion(i) = mean(freezing_dist(idx));
end
% Muestra los resultados
resultados = table(unique_ids', num_eventos', mean_duracion')