%% PSTH para todas las neuronas de todos los animales
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc
clear all

% En estas lineas selecciono que animales, paradigma y sesiones quiero analizar
% rats = [10,11,13,14,16,17,18,19]; % Filtro por animales para apetitivo
rats = [11,12,13,17,18,19,20]; % Filtro por animales para aversivo.

paradigm_toinclude = 'aversive'; % Filtro por el paradigma
session_toinclude = {'EXT1','EXT2','TEST'}; % Filtro por las sesiones

type = {'good'}; % Filtro por el tipo de neurona: 'good', 'mua', 'unsorted'
position = {'BLA','BLP','BMP','LaVL','BLV','LaVM'}; % Filtro por la posición del electrodo. 'BLA','BLP','BMP','LaVL','BLV','LaVM','PL','IL'
event = 'Freezing'; % Filtramos por el evento con el cual quiero triggerear. 'CS1','CS2','Freezing'
pre_t = 20000; % Tiempo pre evento desde donde quiero calular, en ms.
post_t = 20000; % Tiempo post evento hasta donde quiero calcular, en ms.
bin_sz = 50; % Tamaño del bin para calcular el FR, en ms.
baseline_start = -5000; % Inicio de ventana para usar como baseline para zscorear, en ms
baseline_end = -500;   % Fin de ventana para usar como baseline para zscorear, en ms

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Define the parent folder containing the 'Rxx' folders
parentFolder = 'D:\Doctorado\Backup Ordenado';

% List all 'Rxx' folders in the parent folder
R_folders = dir(fullfile(parentFolder, 'R*'));

% Cargamos la tabla de EventsSheet
cd('D:\Doctorado\Analisis\Sheets');
EventsSheet = readtable('EventsSheet.csv');

% Definimos algunas variables
Fs = 30000;
psth3 = [];
psth_all_neurons = {}; % Para almacenar psth de todas las neuronas
trialspx_all_neurons = {}; % Para almacenar trialspx de todas las neuronas
event_Type_all_neurons = {}; % Para almacenar event_Type de todas las neuronas
stats = [];

% Iterate through each 'Rxx' folder
for r = rats
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
            if strcmp(paradigm,paradigm_toinclude) && any(strcmp(session, session_toinclude))||any(strcmp(session_end, session_toinclude));
                    % Filtramos la tabla para quedarme con los IDs, y los timestamps de inicio y fin.
                    filteredTable = EventsSheet(EventsSheet.Rat == r, :);
                    filteredTable = filteredTable(strcmp(filteredTable.Name, name), :);
                    filteredTable = filteredTable(strcmp(filteredTable.Event, event), :);
                    event_ID = filteredTable.ID;
                    event_Type = filteredTable.Type;
                    event_inicio = filteredTable.Inicio;
                    event_fin = filteredTable.Fin;

                    fstruct = dir('*Kilosort*'); % Busco la ruta completa de la carpeta Kilosort

                    if size(fstruct,1) == 1; % Si existe la ruta a la carpeta kilosort    
                        cd(fstruct.name); % Entro a la carpeta Kilosort
                        if exist(strcat('spike_clusters.npy')) == 2
                            spike_clusters = double(readNPY('spike_clusters.npy'));
                            spike_times = double(readNPY('spike_times.npy'));
                            table = readtable('cluster_info.csv');

                            % Aplico algunos filtros y sorting sobre la tabla
                            table = table(table.fr > 0.5, :); % Elimino aquellas neuronas que tienen un fr menor a 0.5               
                            table = table(ismember(table.type, type), :);
                            table = table(ismember(table.position, position), :);
                            table = table(table.target == 1, :); % Me quedo con las que están en el target
                            table = sortrows(table, 'n_spikes', 'descend');

                            clusters = table.cluster_id;
                            if size(clusters,1) >= 1;
                                for i = 1:size(clusters,1);
                                    disp(strcat('     Processing neuron = ', num2str(i)));
                                    neuron = clusters(i);
                                    spikes = spike_times(find(spike_clusters == neuron)); spikes = spikes/Fs;
                                    
                                    % Calcular psth y trialspx para la neurona actual
                                    [psth, trialspx] = mpsth(spikes, event_inicio, 'fr', 0, 'pre', pre_t, 'post', post_t, 'chart', 0, 'binsz', bin_sz);
                                    
                                    % Guardar psth, trialspx y event_Type en celdas
                                    psth_all_neurons{end+1} = psth;
                                    trialspx_all_neurons{end+1} = trialspx;
                                    event_Type_all_neurons{end+1} = event_Type;
                                    psth2(:,i) = psth(:,2);
                                end
                                psth3 = cat(2,psth3,psth2); clear psth2;
                            end
                        end
                    end
            end
        end
        clear table psth psth2
        
        % Go back to the 'Rxx' folder
        cd(current_R_folder);
    end
end

cd(parentFolder);

% Calculamos algunas cosas
t = -pre_t:bin_sz:post_t-bin_sz;
n = 1:size(psth3,2);

% % Zscoreamos por la actividad que sucede de -3 a -1 seg pre evento
% baseline_idx = t >= baseline_start & t <= baseline_end;
% baseline_firing_rates = psth3(baseline_idx, :);
% baseline_mean = mean(baseline_firing_rates, 1); %(media por neurona)
% baseline_std = std(baseline_firing_rates, 0, 1); % (desviación estándar por neurona
% baseline_mean = repmat(baseline_mean, size(psth3, 1), 1); % 200x3200
% baseline_std = repmat(baseline_std, size(psth3, 1), 1);   % 200x3200
% psth3 = (psth3 - baseline_mean) ./ baseline_std; % Realizar z-score: (X - mean) / std
psth4 = psth3;
psth3 = zscore(psth3,0,1);


% Ordenamos por respuesta
% Define the time window
timeStart = 0; % in ms
timeEnd = 1000;   % in ms
% Find the indices corresponding to the time window (400 ms to 500 ms)
indices = find(t >= timeStart & t <= timeEnd);
% Calculate the mean value for each neuron in this time window
meanValues = mean(psth3(indices, :), 1); % Compute mean across the selected time indices
% Sort the neurons based on the mean values
[sortedMeans, sortIdx] = sort(meanValues);
% Acá tenemos que ordenar todas las tablas que tenemos
psth3 = psth3(:, sortIdx);
psth4 = psth4(:, sortIdx);
psth_all_neurons = psth_all_neurons(sortIdx);
trialspx_all_neurons = trialspx_all_neurons(sortIdx);
event_Type_all_neurons = event_Type_all_neurons(1,sortIdx);

% Finalmente, guarda las variables psth_all_neurons, trialspx_all_neurons y event_Type_all_neurons en un archivo MAT
% save('PSTH_data.mat', 'psth_all_neurons', 'trialspx_all_neurons', 'event_Type_all_neurons');
%
psth_time = t';
psth_neurons = psth4;
trialspx_neurons = trialspx_all_neurons;
event_Type = event_Type_all_neurons;
clearvars -except psth_neurons psth_time trialspx_neurons event_Type

save('psth_neurons.mat');