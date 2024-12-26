%% Comparaciones de los eventos de freezing en diferentes condiciones
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc
clear all

rats = [11,12,13,17,18,19,20]; % Filtro por animales para aversivo.
paradigm_toinclude = 'aversive'; % Filtro por el paradigma
session_toinclude = {'EXT1','EXT2'}; % Filtro por las sesiones
region = 'IL'; % Región cerebral que quiero analizar: BLA, PL, IL, EO.
fband = 'fGamma'; % Banda frecuencial que quiero analizar: FourHz, Theta, Beta, sGamma, fGamma.
event = 'Freezing'; % Evento que quiero filtrar
Fs = 1250; % Sample rate original de la señal (Hz)
onlyCS1 = 0; % Flag para quedarse solo con los eventos en CS+ o con todos los eventos

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Define the parent folder containing the 'Rxx' folders
parentFolder = 'D:\Doctorado\Backup Ordenado';

% List all 'Rxx' folders in the parent folder
R_folders = dir(fullfile(parentFolder, 'R*'));

% Cargamos los datos
cd('D:\Doctorado\Analisis\Sheets');
EventsSheet = readtable('EventsSheet.csv');
PowerSheet = readtable('Power_Sheet.csv');

% Filtramos la tabla PowerSheet y la mergeamos con la de EventsSheet
column = strcat(fband,'_',region);
PowerSheet = table(PowerSheet.ID,PowerSheet.(column),'VariableNames',{'ID','Power'});
% Borramos aquellas filas en donde se repite el ID
[~, uniqueIdx] = unique(PowerSheet.ID, 'first');
PowerSheet = PowerSheet(uniqueIdx, :); clear uniqueIdx;

% Mergeamos ambas tablas en EventsSheet
MergedSheet = join(EventsSheet, PowerSheet, 'Keys', 'ID');

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
               MergedTable = MergedTable(~isnan(MergedTable.Power), :);
               event_ID = MergedTable.ID;
               event_type = MergedTable.Type;
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

                    data = table(event_ID, event_type, Sstack,'VariableNames',{'ID','Type','S'});
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
                        BehaviorSeries = table(event_ID, event_type, behavior_segments, ...
                                               'VariableNames', {'ID', 'Type', 'Acc'});
                                   
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

% Creamos los grupos que vamos a comparar luego de early y late en PowerData
% Nos quedamos solo con los que caen en CS+ si el flag onlyCS1 is 1
if onlyCS1 == 1
    PowerData = PowerData(PowerData.Type == 1,:);
end

% Initialize a new column for the group labels
PowerData.Group = cell(height(PowerData), 1);

% Group 1: E-Ext1 (Session = 'EXT1' and Trials 1 to 4)
PowerData.Group(strcmp(PowerData.Session, 'EXT1') & PowerData.Trial >= 1 & PowerData.Trial <= 4) = {'E-Ext1'};
PowerData.Group(strcmp(PowerData.Session, 'EXT1') & PowerData.Trial >= 17 & PowerData.Trial <= 20) = {'L-Ext1'};
PowerData.Group(strcmp(PowerData.Session, 'EXT2') & PowerData.Trial >= 1 & PowerData.Trial <= 4) = {'E-Ext2'};
PowerData.Group(strcmp(PowerData.Session, 'EXT2') & PowerData.Trial >= 17 & PowerData.Trial <= 20) = {'L-Ext2'};

PowerData = PowerData(~cellfun('isempty', PowerData.Group), :);

SpecData = join(PowerData,SpecData, 'Keys', 'ID');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Ploteamos los boxplot
figure; % Create a new figure
h = boxplot(PowerData.Power, PowerData.Group, ...
    'color', lines, ...
    'labels', {'E-E1', 'L-E1', 'E-E2', 'L-E2'}, ...
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

% hold on; line([1 2],[6.5 6.5],'Color',[0 0 0],'LineWidth',0.5,'LineStyle','-');
% hold on; line([1 4],[7 7],'Color',[0 0 0],'LineWidth',0.5,'LineStyle','-');

% Set figure properties
set(gcf, 'Color', 'white');
set(gcf, 'Position', [100, 500, 200 200]);

% Extract data for each condition
CS_plus = PowerData.Power(strcmp(PowerData.Group,'E-Ext1'));
CS_minus = PowerData.Power(strcmp(PowerData.Group,'L-Ext1'));
preCS = PowerData.Power(strcmp(PowerData.Group,'E-Ext2'));
ITI = PowerData.Power(strcmp(PowerData.Group,'L-Ext2'));

% Define pairs of groups for comparison
groupPairs = {CS_plus, CS_minus; CS_plus, preCS; CS_plus, ITI; ...
              CS_minus, preCS; CS_minus, ITI; preCS, ITI};

% Perform pairwise comparisons with ranksum
pValues = zeros(size(groupPairs, 1), 1); % Initialize p-value array

for i = 1:length(groupPairs)
    % Wilcoxon rank-sum test between pairs
    pValues(i) = ranksum(groupPairs{i, 1}, groupPairs{i, 2});
end

pValues = pValues*5;
% Display results
disp('Power Statistics:');
disp(array2table(pValues, 'VariableNames', {'pValues'}));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Ploteamos los boxplot de duración
figure; % Create a new figure
h = boxplot(PowerData.Duracion, PowerData.Group, ...
    'color', lines, ...
    'labels', {'E-E1', 'L-E1', 'E-E2', 'L-E2'}, ...
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
CS_plus = PowerData.Power(strcmp(PowerData.Group,'E-Ext1'));
CS_minus = PowerData.Power(strcmp(PowerData.Group,'L-Ext1'));
preCS = PowerData.Power(strcmp(PowerData.Group,'E-Ext2'));
ITI = PowerData.Power(strcmp(PowerData.Group,'L-Ext2'));

% Define pairs of groups for comparison
groupPairs = {CS_plus, CS_minus; CS_plus, preCS; CS_plus, ITI; ...
              CS_minus, preCS; CS_minus, ITI; preCS, ITI};

% Perform pairwise comparisons with ranksum
pValues = zeros(size(groupPairs, 1), 1); % Initialize p-value array

for i = 1:length(groupPairs)
    % Wilcoxon rank-sum test between pairs
    pValues(i) = ranksum(groupPairs{i, 1}, groupPairs{i, 2});
end
pValues = pValues*5;
% Display results
disp('Event Duration Statistics:');
disp(array2table(pValues, 'VariableNames', {'pValues'}));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculamos los espectrogramas
% Initialize a cell array to store the results for each Type
uniqueTypes = unique(SpecData.Group);  % Get unique values in 'Type' column
nanMediansByType = cell(length(uniqueTypes), 1);  % Store the nanmedians per type

% Loop over each unique type and compute the nanmedian of 'S' matrices
for i = 1:length(uniqueTypes)
    % Find rows corresponding to the current Type value
    currentTypeRows = strcmp(SpecData.Group,uniqueTypes(i)); 
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
subplot(141)
S_1 = bsxfun(@minus, SByType{1}, nanmedian(SByType{1}(1:round(size(SByType{1},1)/2),:),1));
plot_matrix_smooth(S_1,t_S,f,'n',5); ylim([0 12]); xlim([-5 5]); clim([-0.5 0.5]); colorbar off; hold on;
line([0 0],[0 150],'Color',[0 0 0],'LineWidth',0.5,'LineStyle','--');
title(['E-Ext1 ' '(n=' num2str(S_size(1)) ')']);
subplot(142)
S_2 = bsxfun(@minus, SByType{2}, nanmedian(SByType{2}(1:round(size(SByType{2},1)/2),:),1));
plot_matrix_smooth(S_2,t_S,f,'n',5); ylim([0 12]); xlim([-5 5]); clim([-0.5 0.5]);; colorbar off; hold on;
line([0 0],[0 150],'Color',[0 0 0],'LineWidth',0.5,'LineStyle','--');
title(['L-Ext1 ' '(n=' num2str(S_size(2)) ')']);
subplot(143)
S_3 = bsxfun(@minus, SByType{3}, nanmedian(SByType{3}(1:round(size(SByType{3},1)/2),:),1));
plot_matrix_smooth(S_3,t_S,f,'n',5); ylim([0 12]); xlim([-5 5]); clim([-0.5 0.5]); colorbar off; hold on;
line([0 0],[0 150],'Color',[0 0 0],'LineWidth',0.5,'LineStyle','--');
title(['E-Ext2 ' '(n=' num2str(S_size(3)) ')']);
subplot(144)
S_4 = bsxfun(@minus, SByType{4}, nanmedian(SByType{4}(1:round(size(SByType{4},1)/2),:),1));
plot_matrix_smooth(S_4,t_S,f,'n',5); ylim([0 12]); xlim([-5 5]); clim([-0.5 0.5]); colorbar off; hold on;
line([0 0],[0 150],'Color',[0 0 0],'LineWidth',0.5,'LineStyle','--');
title(['L-Ext2 ' '(n=' num2str(S_size(4)) ')']);

% Set figure properties
set(gcf, 'Color', 'white');
set(gcf, 'Position', [100, 500, 900 200]);

% Ploteamos los espectrogramas
figure;
subplot(141)
S_1 = bsxfun(@minus, SByType{1}, nanmedian(SByType{1}(1:round(size(SByType{1},1)/2),:),1));
plot_matrix_smooth(S_1,t_S,f,'n',5); ylim([30 100]); xlim([-5 5]); clim([-0.5 0.5]); colorbar off; hold on;
line([0 0],[0 150],'Color',[0 0 0],'LineWidth',0.5,'LineStyle','--');
title(['E-Ext1 ' '(n=' num2str(S_size(1)) ')']);
subplot(142)
S_2 = bsxfun(@minus, SByType{2}, nanmedian(SByType{2}(1:round(size(SByType{2},1)/2),:),1));
plot_matrix_smooth(S_2,t_S,f,'n',5); ylim([30 100]); xlim([-5 5]); clim([-0.5 0.5]);; colorbar off; hold on;
line([0 0],[0 150],'Color',[0 0 0],'LineWidth',0.5,'LineStyle','--');
title(['L-Ext1 ' '(n=' num2str(S_size(2)) ')']);
subplot(143)
S_3 = bsxfun(@minus, SByType{3}, nanmedian(SByType{3}(1:round(size(SByType{3},1)/2),:),1));
plot_matrix_smooth(S_3,t_S,f,'n',5); ylim([30 100]); xlim([-5 5]); clim([-0.5 0.5]); colorbar off; hold on;
line([0 0],[0 150],'Color',[0 0 0],'LineWidth',0.5,'LineStyle','--');
title(['E-Ext2 ' '(n=' num2str(S_size(3)) ')']);
subplot(144)
S_4 = bsxfun(@minus, SByType{4}, nanmedian(SByType{4}(1:round(size(SByType{4},1)/2),:),1));
plot_matrix_smooth(S_4,t_S,f,'n',5); ylim([30 100]); xlim([-5 5]); clim([-0.5 0.5]); colorbar off; hold on;
line([0 0],[0 150],'Color',[0 0 0],'LineWidth',0.5,'LineStyle','--');
title(['L-Ext2 ' '(n=' num2str(S_size(4)) ')']);

% Set figure properties
set(gcf, 'Color', 'white');
set(gcf, 'Position', [100, 500, 900 200]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Merge PowerData and BehaviorTimeSeries based on 'ID'
BehaviorTimeSeries = join(PowerData, BehaviorTimeSeries, 'Keys', 'ID');

% Define custom labels for each group
group_labels = containers.Map({ 'E-Ext1', 'L-Ext1', 'E-Ext2', 'L-Ext2' }, ...
    { 'E-E1', 'L-E1', 'E-E2', 'L-E2' });

% Assign custom groups based on Session and Trial
BehaviorTimeSeries.Group = cell(size(BehaviorTimeSeries, 1), 1);
for i = 1:size(BehaviorTimeSeries, 1)
    session = BehaviorTimeSeries.Session{i};
    trial = BehaviorTimeSeries.Trial(i);
    
    if strcmp(session, 'EXT1')
        if trial >= 1 && trial <= 4
            BehaviorTimeSeries.Group{i} = 'E-Ext1';
        elseif trial >= 17 && trial <= 20
            BehaviorTimeSeries.Group{i} = 'L-Ext1';
        end
    elseif strcmp(session, 'EXT2')
        if trial >= 1 && trial <= 4
            BehaviorTimeSeries.Group{i} = 'E-Ext2';
        elseif trial >= 17 && trial <= 20
            BehaviorTimeSeries.Group{i} = 'L-Ext2';
        end
    end
end

% Get unique Groups (custom groups E-Ext1, L-Ext1, E-Ext2, L-Ext2)
unique_groups = unique(BehaviorTimeSeries.Group);
unique_types = unique_groups;

% Define custom labels for each Type
type_labels = {'E-Ext1', 'L-Ext1','E-Ext2','L-Ext2'};

% Initialize array to store nanmean results
mean_acc_per_group = zeros(length(t_S), length(unique_groups));

% Loop through each unique group to calculate the nanmean for each timestamp
for i = 1:length(unique_groups)
    % Select rows for the current group
    group_rows = strcmp(BehaviorTimeSeries.Group, unique_groups{i});
    
    % Extract Acc data for the current group and calculate nanmean across each timestamp
    acc_data = cat(2, BehaviorTimeSeries.Acc{group_rows});
    sem_acc_per_type(:, i) = nansem(acc_data,2);
    mean_acc_per_type(:, i) = nanmean(acc_data, 2);
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
         'DisplayName', type_labels{i}); % Line plot with label
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