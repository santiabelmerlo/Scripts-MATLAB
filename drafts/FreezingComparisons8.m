%% Comparaciones de los eventos de freezing en diferentes condiciones
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc
clear all

rats = [11,12,13,17,18,19,20]; % Filtro por animales para aversivo.
paradigm_toinclude = 'aversive'; % Filtro por el paradigma
session_toinclude = {'EXT1','EXT2','TEST'}; % Filtro por las sesiones
region = 'BLA'; % Región cerebral que quiero analizar: BLA, PL, IL, EO.
fband = 'FourHz'; % Banda frecuencial que quiero analizar: FourHz, Theta, Beta, sGamma, fGamma.
event = 'Freezing'; % Evento que quiero filtrar
Fs = 1250; % Sample rate original de la señal (Hz)
FiltType = []; % Filtramos el type de evento que queremos

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Define the parent folder containing the 'Rxx' folders
% parentFolder = 'D:\Doctorado\Backup Ordenado';
parentFolder = 'D:\';

% List all 'Rxx' folders in the parent folder
R_folders = dir(fullfile(parentFolder, 'R*'));

% Cargamos los datos
% cd('D:\Doctorado\Analisis\Sheets');
cd('D:\Sheets');
EventsSheet = readtable('EventsSheet.csv');
PowerSheet = readtable('ZPower_Sheet.csv');
WaveletSheet = readtable('WaveletEnrich.csv');

% Filtramos la tabla PowerSheet y la mergeamos con la de EventsSheet
column = strcat(fband,'_',region);
PowerSheet = table(PowerSheet.ID,PowerSheet.(column),'VariableNames',{'ID','Power'});
% Borramos aquellas filas en donde se repite el ID
[~, uniqueIdx] = unique(PowerSheet.ID, 'first');
PowerSheet = PowerSheet(uniqueIdx, :); clear uniqueIdx;

% Mergeamos ambas tablas en EventsSheet
MergedSheet = join(EventsSheet, PowerSheet, 'Keys', 'ID');
MergedSheet = join(WaveletSheet, MergedSheet, 'Keys', 'ID');

% Inicializamos variables vacías
PowerData = table();
SpecData = table();
BehaviorTimeSeries = table();

for r = rats % Iterate through each 'Rxx' folder
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
        
        % Reseteamos las tablas de datos con los datos originales
        MergedTable = MergedSheet; % Reseteamos la tabla MergedTable
        
        if exist(strcat(name,'_sessioninfo.mat')) == 2;
            session_end = [];    
            load(strcat(name,'_sessioninfo.mat'));
            if exist(strcat(name,'_specgram_',region,'LowFreq.mat')) == 2 && ...
               strcmp(paradigm,paradigm_toinclude) && ...
               any(strcmp(session, session_toinclude))||any(strcmp(session_end, session_toinclude));
               
               %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
               disp(['  All required files exists. Performing action...']);
               
               % Filtramos la tabla con las distintas condiciones
               MergedTable = MergedTable(MergedTable.Rat == r, :);
               MergedTable = MergedTable(strcmp(MergedTable.Name, name), :);
               MergedTable = MergedTable(strcmp(MergedTable.Event, event), :);
               MergedTable = MergedTable(MergedTable.noisy == 0, :); % Solo me quedo con los eventos no ruidosos
               MergedTable = MergedTable(MergedTable.Epileptic <= 5, :); % Tolerancia de 5% del evento con evento epiléptico
               MergedTable = MergedTable(MergedTable.Flat <= 0.1, :); % Tolerancia de 0.1% del evento con evento Flat
               MergedTable = MergedTable(~isnan(MergedTable.Power), :);
               event_ID = MergedTable.ID;
               event_type = MergedTable.Type;
               event_fztype = MergedTable.Enrich;
               event_inicio = MergedTable.Inicio;
               event_fin = MergedTable.Fin;
               event_duracion = MergedTable.Duracion;
               
               if ~isempty(event_inicio);
                   % Cargamos el espectrograma y hacemos vertcat de los datos
                   load(strcat(name,'_specgram_',region,'LowFreq.mat'));
                   S1 = zscorem(S,1);

                    window_size = 5; % Define window in seconds

                    for i = 1:length(event_inicio)
                        [~, event_idx] = min(abs(t - event_inicio(i)));
                        offset = round(window_size * (1 / mean(diff(t))));  % Calculate offset in indices based on sampling interval
                        start_idx = max(1, event_idx - offset);       % Make sure start_idx is within bounds
                        end_idx = min(length(t), event_idx + offset); % Make sure end_idx is within bounds
                        Sstack{i,1} = S1(start_idx:end_idx, :);
                    end

                    data = table(event_ID, event_type, Sstack, event_fztype,'VariableNames',{'ID','Type','S','Enrich'});
                    SpecData = vertcat(SpecData,data); 
                    clear data Sstack;

                   % Hacemos vertcat de los datos de potencia
                   PowerData = vertcat(PowerData,MergedTable);
                   
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % Acelerómetro
                    if exist(strcat(name,'_behavior_timeseries.mat')) == 2
                        load(strcat(name,'_behavior_timeseries.mat'), 'behavior_timeseries','time_vector')
                        behavior_timeseries = behavior_timeseries(:,7);
                        
                        % Loop through each event to extract the time segment
                        for i = 1:length(event_inicio)
                            % Find the index in `time_vector` closest to `event_inicio(i)`
                            [~, idx_event] = min(abs(time_vector - event_inicio(i)));

                            % Define the start and end indices based on the time window around the event
                            % For example, extracting 10 samples before and after the event (adjustable)
                            segment_length = 10; % Number of samples before and after the event (adjust as needed)
                            idx_start = max(1, idx_event - segment_length); % Ensure we don't go below 1
                            idx_end = min(length(time_vector), idx_event + segment_length); % Ensure we don't go beyond the array length

                            % Extract the segment from `behavior_timeseries` and store it
                            behavior_segments{i,1} = behavior_timeseries(idx_start:idx_end);
                        end

                        % Combine data into a table
                        BehaviorSeries = table(event_ID, event_type, event_fztype, behavior_segments, ...
                                               'VariableNames', {'ID', 'Type', 'Enrich','Acc'});
                                   
                        BehaviorTimeSeries = vertcat(BehaviorTimeSeries,BehaviorSeries);                   
                        clear behavior_segments BehaviorSeries                             
                    end
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
               end
               %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
               
            else
                disp(['  Some required file do not exist.']);
                disp(['  Skipping action...']);
            end
        end
    end
    % Go back to the 'Rxx' folder
    cd(current_R_folder);
end

disp('Ready!')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Filtramos ambas tablas para quitar los Type que son NaN y juntamos preCS
% 1 = CS+; 2 = CS-; 3 = preCS; 5 = ITI
PowerData = PowerData(~isnan(PowerData.Type), :);
SpecData = SpecData(~isnan(SpecData.Type), :);
PowerData.Type(PowerData.Type == 4) = 3;
SpecData.Type(SpecData.Type == 4) = 3;
BehaviorTimeSeries.Type(BehaviorTimeSeries.Type == 4) = 3;

% Filtramos PowerData, SpecData y BehaviorTimeSeries con el Type que pongo más arriba
if ~isempty(FiltType)
    PowerData = PowerData(PowerData.Type == FiltType,:);
    SpecData = SpecData(SpecData.Type == FiltType,:);
    BehaviorTimeSeries = BehaviorTimeSeries(BehaviorTimeSeries.Type == FiltType,:);
end

% Ploteamos los boxplot
figure; % Create a new figure
h = boxplot(PowerData.Power, PowerData.Enrich, ...
    'color', lines, ...
    'labels', {'4Hz-Fz', 'Theta-Fz'}, ...
    'symbol', '', ...
    'whisker', 1, ...
    'widths', 0.8); 

% Adding labels and title
if strcmp(fband,'FourHz');
    ylabel('4Hz Power (z-scored)');
elseif strcmp(fband,'Theta');
    ylabel('Theta Power (z-scored)');   
elseif strcmp(fband,'Beta');
    ylabel('Beta Power (z-scored)');
elseif strcmp(fband,'sGamma');
    ylabel('sGamma Power (z-scored)');
elseif strcmp(fband,'fGamma');
    ylabel('fGamma Power (z-scored)');   
end
ylim([-3,3]);

% Set figure properties
set(gcf, 'Color', 'white');
set(gcf, 'Position', [100, 500, 200 200]);

% Extract data for each condition
CS_plus = PowerData.Power(strcmp(PowerData.Enrich, '4Hz'));
CS_minus = PowerData.Power(strcmp(PowerData.Enrich, 'Theta'));

% Define pairs of groups for comparison
groupPairs = {CS_plus, CS_minus};

% Perform pairwise comparisons with ranksum
pValues = zeros(size(groupPairs, 1), 1); % Initialize p-value array
pValues = ranksum(groupPairs{1, 1}, groupPairs{1, 2});

% Display results
disp('Power Statistics:');
disp(array2table(pValues, 'VariableNames', {'pValues'}));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Ploteamos los boxplot de duración
figure; % Create a new figure
h = boxplot(PowerData.Duracion, PowerData.Enrich, ...
    'color', lines, ...
    'labels', {'4Hz-Fz', 'Theta-Fz'}, ...
    'symbol', '', ...
    'whisker', 1, ...
    'widths', 0.8); 

% Adding labels and title
ylabel('Event Duration (sec.)');      % Label for y-axis
ylim([0,8]);

% hold on; line([1 2],[6.5 6.5],'Color',[0 0 0],'LineWidth',0.5,'LineStyle','-');
% hold on; line([2 4],[7 7],'Color',[0 0 0],'LineWidth',0.5,'LineStyle','-');

% Set figure properties
set(gcf, 'Color', 'white');
set(gcf, 'Position', [100, 500, 200 200]);

% Extract data for each condition
CS_plus = PowerData.Duracion(strcmp(PowerData.Enrich,'4Hz'));
CS_minus = PowerData.Duracion(strcmp(PowerData.Enrich,'Theta'));

% Define pairs of groups for comparison
groupPairs = {CS_plus, CS_minus};

% Perform pairwise comparisons with ranksum
pValues = zeros(size(groupPairs, 1), 1); % Initialize p-value array
pValues = ranksum(groupPairs{1, 1}, groupPairs{1, 2});

% Display results
disp('Event Duration Statistics:');
disp(array2table(pValues, 'VariableNames', {'pValues'}));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Calculamos los espectrogramas
% Initialize a cell array to store the results for each Type
uniqueTypes = unique(SpecData.Enrich);  % Get unique values in 'Type' column
nanMediansByType = cell(length(uniqueTypes), 1);  % Store the nanmedians per type

% Loop over each unique type and compute the nanmedian of 'S' matrices
for i = 1:length(uniqueTypes)
    % Find rows corresponding to the current Type value
    currentTypeRows = strcmp(SpecData.Enrich, uniqueTypes(i)); 
    S_size(i) = sum(currentTypeRows);
    
    % Extract the 'S' matrices for the current Type group
    S_matrices = SpecData.S(currentTypeRows);  % S matrices for the current Type
    
    % Compute the nanmedian across the rows of S (ignoring NaN values)
    % nanmedian operates along each dimension, so it will calculate the median
    % for each column across the different matrices.
    
    S_nanmean = nanmedian(cat(3, S_matrices{:}), 3); 
    
    % Store the result in the cell array
    nanMediansByType{i} = S_nanmean;
end
SByType = nanMediansByType;
t_S = -5:0.5:5;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Ploteamos los espectrogramas
figure;
subplot(121)
S_1 = bsxfun(@minus, SByType{1}, nanmedian(SByType{1}(1:round(size(SByType{1},1)/2),:),1));
plot_matrix_smooth(S_1,t_S,f,'n',5); ylim([12 100]); xlim([-5 5]); clim([-0.5 0.5]); colorbar off; hold on;
line([0 0],[0 150],'Color',[0 0 0],'LineWidth',0.5,'LineStyle','--');
title(['4-Hz Fz ' '(n=' num2str(S_size(1)) ')']);
subplot(122)
S_2 = bsxfun(@minus, SByType{2}, nanmedian(SByType{2}(1:round(size(SByType{2},1)/2),:),1));
plot_matrix_smooth(S_2,t_S,f,'n',5); ylim([12 100]); xlim([-5 5]); clim([-0.5 0.5]);; colorbar off; hold on;
line([0 0],[0 150],'Color',[0 0 0],'LineWidth',0.5,'LineStyle','--');
title(['Theta Fz ' '(n=' num2str(S_size(2)) ')']);

% Set figure properties
set(gcf, 'Color', 'white');
set(gcf, 'Position', [100, 500, 450 200]);

% Ploteamos los espectrogramas
figure;
subplot(121)
S_1 = bsxfun(@minus, SByType{1}, nanmedian(SByType{1}(1:round(size(SByType{1},1)/2),:),1));
plot_matrix_smooth(S_1,t_S,f,'n',5); ylim([0 12]); xlim([-5 5]); clim([-0.5 0.5]); colorbar off; hold on;
line([0 0],[0 150],'Color',[0 0 0],'LineWidth',0.5,'LineStyle','--');
title(['4-Hz Fz ' '(n=' num2str(S_size(1)) ')']);
subplot(122)
S_2 = bsxfun(@minus, SByType{2}, nanmedian(SByType{2}(1:round(size(SByType{2},1)/2),:),1));
plot_matrix_smooth(S_2,t_S,f,'n',5); ylim([0 12]); xlim([-5 5]); clim([-0.5 0.5]);; colorbar off; hold on;
line([0 0],[0 150],'Color',[0 0 0],'LineWidth',0.5,'LineStyle','--');
title(['Theta Fz ' '(n=' num2str(S_size(2)) ')']);

% Set figure properties
set(gcf, 'Color', 'white');
set(gcf, 'Position', [100, 500, 450 200]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Behavior Timeseries
% BehaviorTimeSeries = BehaviorTimeSeries(~isnan(BehaviorTimeSeries.Enrich), :);

% Define custom labels for each Type
type_labels = containers.Map([0, 1], {'4Hz Fz', 'Theta Fz'});

% Get unique Types after merging
unique_types = unique(BehaviorTimeSeries.Enrich);

% Initialize array to store nanmean results
mean_acc_per_type = zeros(length(t_S), length(unique_types));

% Loop through each unique Type to calculate the nanmean for each timestamp
for i = 1:length(unique_types)
    % Select rows for the current Type
    type_rows = strcmp(BehaviorTimeSeries.Enrich, unique_types(i));
    
    % Extract Acc data for the current Type
    acc_data_cells = BehaviorTimeSeries.Acc(type_rows);
    
    % Find the maximum length of Acc data across selected rows
    max_length = max(cellfun(@length, acc_data_cells));
    
    % Pad each Acc entry to the maximum length with NaNs
    acc_data_padded = cellfun(@(x) [x(:); NaN(max_length - length(x), 1)], ...
                              acc_data_cells, 'UniformOutput', false);
    
    % Concatenate padded Acc data and calculate nanmean across each timestamp
    acc_data_matrix = cat(2, acc_data_padded{:});
    sem_acc_per_type(:, i) = nansem(acc_data_matrix,2);
    mean_acc_per_type(:, i) = nanmean(acc_data_matrix, 2);
end

% Plot the results
figure;
hold on;
colors = lines(length(unique_types)); % Get distinct colors for each Type

for i = 1:length(unique_types)
    % Extract mean and SEM for the current type
    y = mean_acc_per_type(:, i); % Mean values
    sem = sem_acc_per_type(:, i); % SEM values
    t = t_S; % Time vector

    % Create shaded error region
    curve1 = y + sem; % Upper bound of SEM
    curve2 = y - sem; % Lower bound of SEM
    x2 = [t, fliplr(t)]; % Combine x-coordinates for fill
    inBetween = [curve1', fliplr(curve2')]; % Combine y-coordinates for fill
    p1 = fill(x2, inBetween, colors(i, :), 'FaceAlpha', 0.4, 'EdgeColor', 'none', ...
              'HandleVisibility', 'off'); % Shaded region without legend entry

    % Plot the mean line
    plot(t, y, 'Color', colors(i, :), 'LineWidth', 1.5, ...
         'DisplayName', unique_types{i}); % Line plot with label
end

% Add labels, legend, and title
xlim([-5 5]);
xlabel('Time (s)');
ylabel('Acceleration (cm/s^2)');
legend('show', 'Location', 'eastoutside'); % Places the legend outside on the right
title('');
hold off;

% Set figure properties
set(gcf, 'Color', 'white');
set(gcf, 'Position', [100, 500, 300 200]);