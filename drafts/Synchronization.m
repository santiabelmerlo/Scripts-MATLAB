%% Análisis de la sincronización usando la planilla de eventos y los datos de:
% PLV, maxCCG, Lag, AUC y MVGC.
clc
clear all

% Cargamos los datos
cd('D:\Doctorado\Analisis\Sheets');
EventsSheet = readtable('EventsSheet.csv');
AUC = readtable('AUC_Sheet.csv');
Lag = readtable('Lag_Sheet.csv');
maxCCG = readtable('maxCCG_Sheet.csv');
PLV = readtable('PLV_Sheet.csv');
MVGC = readtable('MVGC_Sheet.csv');
Coherence = readtable('Coherence_Sheet.csv');
PowerSheet = readtable('Power_Sheet2.csv');

rats = [11,12,13,17,18,19,20]; % Filtro por animales para aversivo.
% trials = [1:4];
trials = [1:10]; % Trials que quiero analizar
% trials = [10:20]; % Trials que quiero analizar
session_toinclude = {'EXT1'}; % Filtro por las sesiones
% event = 'CS1'; % Evento que quiero filtrar
event = 'Movement';
fztype = []; % Si quiero separar por tipo de freezing, definir acá como 1 para '4Hz' o 0 para 'Theta' o [];
% event = 'Movement';
types = 1; % Tipo de evento que quiero filtrar: CS+, CS-, preCS, ITI
freq = 'Beta'; % 4Hz, Theta, Beta, sGamma, fGamma
outlr = 20; % Límite para cortar outliers

% Filtramos la tabla con las distintas condiciones
EventsSheet = EventsSheet(ismember(EventsSheet.Rat, rats), :);
EventsSheet = EventsSheet(EventsSheet.noisy == 0, :);
EventsSheet = EventsSheet(EventsSheet.Epileptic == 0, :);
if ~isempty(types); EventsSheet = EventsSheet(EventsSheet.Type == types, :); end
EventsSheet = EventsSheet(ismember(EventsSheet.Session, session_toinclude), :);
if ~isempty(trials); EventsSheet = EventsSheet(ismember(EventsSheet.Trial, trials), :); end
if ~isempty(event); EventsSheet = EventsSheet(ismember(EventsSheet.Event, event), :); end

% Filtramos los eventos de freezing por el tipo de freezing, si fztype no
% está vacío.
if ~isempty(fztype); 
    PowerSheet.Ratio = PowerSheet.FourHz_BLA ./ PowerSheet.Theta_BLA;
    for i = 1:height(PowerSheet)
        if isnan(PowerSheet.Ratio(i))
            PowerSheet.FzType(i) = NaN;
        elseif PowerSheet.Ratio(i) > 1
            PowerSheet.FzType(i) = 1;
        elseif PowerSheet.Ratio(i) <= 1   
            PowerSheet.FzType(i) = 0;
        end
    end
    [~, unique_idx] = unique(PowerSheet.ID, 'stable'); % Find unique IDs
    PowerSheet = PowerSheet(unique_idx, :);            % Keep only unique rows
    EventsSheet = join(EventsSheet, PowerSheet(:, {'ID', 'FzType'}), 'Keys', 'ID');
    EventsSheet = EventsSheet(EventsSheet.FzType == fztype, :); 
end

% Buscamos los IDs de los eventos Freezing y Movement
ID_Freezing = EventsSheet.ID(strcmp(EventsSheet.Event,event));

% Add Event column to each dataset based on the ID values in EventsSheet
datasets = {AUC, Lag, maxCCG, PLV, MVGC,Coherence};  % List of datasets to update
dataset_names = {'AUC', 'Lag', 'maxCCG', 'PLV', 'MVGC', 'Coherence'};  % Names of datasets for assignment

for i = 1:numel(datasets)
    % Get the current dataset
    dataset = datasets{i};
    
    % Find matching Event values based on ID
    dataset.Event = repmat({''}, height(dataset), 1);
    dataset.Event(ismember(dataset.ID, ID_Freezing)) = {event};

    dataset = dataset(ismember(dataset.Event,event),:);

    % Update the dataset with the new Event column
    assignin('base', dataset_names{i}, dataset);
end

% Specify the columns to stack
if strcmp(freq,'4Hz')
    columnsToStack = {'FourHz_BLAPL', 'FourHz_BLAIL'};
elseif strcmp(freq,'Theta')
    columnsToStack = {'Theta_BLAPL', 'Theta_BLAIL'};
elseif strcmp(freq,'Beta')
    columnsToStack = {'Beta_BLAPL', 'Beta_BLAIL'};
elseif strcmp(freq,'sGamma')
    columnsToStack = {'sGamma_BLAPL', 'sGamma_BLAIL'};
elseif strcmp(freq,'fGamma')
    columnsToStack = {'fGamma_BLAPL', 'fGamma_BLAIL'};
end

% Add Rat info to each df
AUC = join(AUC, EventsSheet, 'Keys', 'ID');
PLV = join(PLV, EventsSheet, 'Keys', 'ID');
maxCCG = join(maxCCG, EventsSheet, 'Keys', 'ID');
Lag = join(Lag, EventsSheet, 'Keys', 'ID');
Coherence = join(Coherence, EventsSheet, 'Keys', 'ID');
MVGC = join(MVGC, EventsSheet, 'Keys', 'ID');

% Stack the columns into a long format
AUC = stack(AUC, columnsToStack, 'NewDataVariableName', 'Value', 'IndexVariableName', ['Type' 'Rat']);  AUC.Properties.VariableNames{'TypeRat'} = 'Group';
PLV = stack(PLV, columnsToStack, 'NewDataVariableName', 'Value', 'IndexVariableName', ['Type' 'Rat']);  PLV.Properties.VariableNames{'TypeRat'} = 'Group';
maxCCG = stack(maxCCG, columnsToStack, 'NewDataVariableName', 'Value', 'IndexVariableName', ['Type' 'Rat']);  maxCCG.Properties.VariableNames{'TypeRat'} = 'Group';
Lag = stack(Lag, columnsToStack, 'NewDataVariableName', 'Value', 'IndexVariableName', ['Type' 'Rat']);  Lag.Properties.VariableNames{'TypeRat'} = 'Group';
Coherence = stack(Coherence, columnsToStack, 'NewDataVariableName', 'Value', 'IndexVariableName', ['Type' 'Rat']); Coherence.Properties.VariableNames{'TypeRat'} = 'Group';

% Stack for MVGC
if strcmp(freq,'4Hz')
    columnsToStack = {'BLAtoPL_4hz', 'PLtoBLA_4hz', 'BLAtoIL_4hz', 'ILtoBLA_4hz'};
elseif strcmp(freq,'Theta')
    columnsToStack = {'BLAtoPL_theta', 'PLtoBLA_theta', 'BLAtoIL_theta', 'ILtoBLA_theta'};
elseif strcmp(freq,'Beta')
    columnsToStack = {'BLAtoPL_beta', 'PLtoBLA_beta', 'BLAtoIL_beta', 'ILtoBLA_beta'};
elseif strcmp(freq,'sGamma')
    columnsToStack = {'BLAtoPL_sgamma', 'PLtoBLA_sgamma', 'BLAtoIL_sgamma', 'ILtoBLA_sgamma'};
elseif strcmp(freq,'fGamma')
    columnsToStack = {'BLAtoPL_fgamma', 'PLtoBLA_fgamma', 'BLAtoIL_fgamma', 'ILtoBLA_fgamma'};
end
MVGC = stack(MVGC, columnsToStack, 'NewDataVariableName', 'Value', 'IndexVariableName', ['Type' 'Rat']); MVGC.Properties.VariableNames{'TypeRat'} = 'Group';

% Ploteamos los boxplot de duración
figure; % Create a new figure
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ax1 = subplot(231)
dataset = AUC;
h = boxplot(dataset.Value(~isoutlier(dataset.Value, 'median', outlr)), dataset.Group(~isoutlier(dataset.Value, 'median', outlr)), ...
    'color', lines, ...
    'labels', {'BLA-PL', 'BLA-IL'}, ...
    'symbol', '', ...
    'whisker', 1, ...
    'widths', 0.8); 
ylabel([freq ' CCG AUC (a.u.)']); % Label for y-axis
ax1.FontSize = 7;

% Add individual points with jitter
hold on;
group_vals = unique(dataset.Group(~isoutlier(dataset.Value, 'median', outlr))); % Unique group values
jitter_amount = 0.3; % Amount of jitter (adjust as needed)
colors = lines(numel(group_vals)); % Generate a colormap
for i = 1:numel(group_vals)
    % Get data for the current group
    group_idx = dataset.Group == group_vals(i) & ~isoutlier(dataset.Value, 'median', outlr);
    x = i + jitter_amount * (rand(sum(group_idx), 1) - 0.5); % Add random jitter
    y = dataset.Value(group_idx);   % Y-values (data points)

    % Add scatter points
    scatter(x, y, 10, colors(i, :), 'filled', 'MarkerFaceAlpha', 0.2); % Small black points with transparency
end

% Hacemos estadística GLMM
dataset.Value = dataset.Value + abs(min(dataset.Value)) + 1;
glme = fitglme(dataset,'Value ~ Group + (1|Rat)', 'Distribution','gamma','Link','log','FitMethod','Laplace');
[p, F, DF1, DF2] = coefTest(glme, [0 1]);

% Si es significativo ploteamos la significancia
y_limits = ylim; ylim([y_limits(1) y_limits(2)+0.08*diff(y_limits)]); y_limits = ylim;
hold on;
if p < 0.05 && p >= 0.01
    y_line = y_limits(2) - 0.08 * diff(y_limits); % Position for the line
    plot([1, 2], [y_line, y_line], 'k-'); % Horizontal line connecting the groups
    text(1.5, y_line + 0.02 * diff(y_limits), '*', 'HorizontalAlignment', 'center', 'FontSize', 14); % Add the asterisk
elseif p < 0.01 && p >= 0.001
    y_line = y_limits(2) - 0.08 * diff(y_limits); % Position for the line
    plot([1, 2], [y_line, y_line], 'k-'); % Horizontal line connecting the groups
    text(1.5, y_line + 0.02 * diff(y_limits), '**', 'HorizontalAlignment', 'center', 'FontSize', 14); % Add the asterisk
elseif p < 0.001
    y_line = y_limits(2) - 0.08 * diff(y_limits); % Position for the line
    plot([1, 2], [y_line, y_line], 'k-'); % Horizontal line connecting the groups
    text(1.5, y_line + 0.02 * diff(y_limits), '***', 'HorizontalAlignment', 'center', 'FontSize', 14); % Add the asterisk
end
hold off;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ax2 = subplot(232)
dataset = Lag;
h = boxplot(dataset.Value(~isoutlier(dataset.Value, 'median', outlr)), dataset.Group(~isoutlier(dataset.Value, 'median', outlr)), ...
    'color', lines, ...
    'labels', {'BLA-PL', 'BLA-IL'}, ...
    'symbol', '', ...
    'whisker', 1, ...
    'widths', 0.8); 
ylabel([freq ' Lag (ms)']); % Label for y-axis
% ylim([-35 35]);
ax2.FontSize = 7;

% Add individual points with jitter
hold on;
group_vals = unique(dataset.Group(~isoutlier(dataset.Value, 'median', outlr))); % Unique group values
jitter_amount = 0.3; % Amount of jitter (adjust as needed)
colors = lines(numel(group_vals)); % Generate a colormap
for i = 1:numel(group_vals)
    % Get data for the current group
    group_idx = dataset.Group == group_vals(i) & ~isoutlier(dataset.Value, 'median', outlr);
    x = i + jitter_amount * (rand(sum(group_idx), 1) - 0.5); % Add random jitter
    y = dataset.Value(group_idx);   % Y-values (data points)

    % Hacemos un test contra cero
    p_cero(i) = signrank(y);

    % Add scatter points
    scatter(x, y, 10, colors(i, :), 'filled', 'MarkerFaceAlpha', 0.2); % Small black points with transparency
end

% Hacemos estadística GLMM
dataset.Value = dataset.Value + abs(min(dataset.Value)) + 1;
glme = fitglme(dataset,'Value ~ Group + (1|Rat)', 'Distribution','gamma','Link','log','FitMethod','Laplace');
[p, F, DF1, DF2] = coefTest(glme, [0 1]);

% Si es significativo ploteamos la significancia
y_limits = ylim; ylim([y_limits(1) y_limits(2)+0.08*diff(y_limits)]); y_limits = ylim;
hold on;
if p < 0.05 && p >= 0.01
    y_line = y_limits(2) - 0.08 * diff(y_limits); % Position for the line
    plot([1, 2], [y_line, y_line], 'k-'); % Horizontal line connecting the groups
    text(1.5, y_line + 0.02 * diff(y_limits), '*', 'HorizontalAlignment', 'center', 'FontSize', 14); % Add the asterisk
elseif p < 0.01 && p >= 0.001
    y_line = y_limits(2) - 0.08 * diff(y_limits); % Position for the line
    plot([1, 2], [y_line, y_line], 'k-'); % Horizontal line connecting the groups
    text(1.5, y_line + 0.02 * diff(y_limits), '**', 'HorizontalAlignment', 'center', 'FontSize', 14); % Add the asterisk
elseif p < 0.001
    y_line = y_limits(2) - 0.08 * diff(y_limits); % Position for the line
    plot([1, 2], [y_line, y_line], 'k-'); % Horizontal line connecting the groups
    text(1.5, y_line + 0.02 * diff(y_limits), '***', 'HorizontalAlignment', 'center', 'FontSize', 14); % Add the asterisk
end

if p_cero(1) < 0.05 && p_cero(1) >= 0.01
    y_line = y_limits(2) - 0.08 * diff(y_limits); % Position for the line
    text(1, y_line - 0.1 * diff(y_limits), '*', 'HorizontalAlignment', 'center', 'FontSize', 14); % Add the asterisk
elseif p_cero(1) < 0.01 && p_cero(1) >= 0.001
    y_line = y_limits(2) - 0.08 * diff(y_limits); % Position for the line
    text(1, y_line - 0.1 * diff(y_limits), '**', 'HorizontalAlignment', 'center', 'FontSize', 14); % Add the asterisk
elseif p_cero(1) < 0.001
    y_line = y_limits(2) - 0.08 * diff(y_limits); % Position for the line
    text(1, y_line - 0.1 * diff(y_limits), '***', 'HorizontalAlignment', 'center', 'FontSize', 14); % Add the asterisk
end

if p_cero(2) < 0.05 && p_cero(2) >= 0.01
    y_line = y_limits(2) - 0.08 * diff(y_limits); % Position for the line
    text(2, y_line - 0.1 * diff(y_limits), '*', 'HorizontalAlignment', 'center', 'FontSize', 14); % Add the asterisk
elseif p_cero(2) < 0.01 && p_cero(2) >= 0.001
    y_line = y_limits(2) - 0.08 * diff(y_limits); % Position for the line
    text(2, y_line - 0.1 * diff(y_limits), '**', 'HorizontalAlignment', 'center', 'FontSize', 14); % Add the asterisk
elseif p_cero(2) < 0.001
    y_line = y_limits(2) - 0.08 * diff(y_limits); % Position for the line
    text(2, y_line - 0.1 * diff(y_limits), '***', 'HorizontalAlignment', 'center', 'FontSize', 14); % Add the asterisk
end

hold off;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ax3 = subplot(233)
dataset = maxCCG;
h = boxplot(dataset.Value(~isoutlier(dataset.Value, 'median', outlr)), dataset.Group(~isoutlier(dataset.Value, 'median', outlr)), ...
    'color', lines, ...
    'labels', {'BLA-PL', 'BLA-IL'}, ...
    'symbol', '', ...
    'whisker', 1, ...
    'widths', 0.8); 
ylabel([freq ' Max XCorr']); % Label for y-axis
ax3.FontSize = 7;

% Add individual points with jitter
hold on;
group_vals = unique(dataset.Group(~isoutlier(dataset.Value, 'median', outlr))); % Unique group values
jitter_amount = 0.3; % Amount of jitter (adjust as needed)
colors = lines(numel(group_vals)); % Generate a colormap
for i = 1:numel(group_vals)
    % Get data for the current group
    group_idx = dataset.Group == group_vals(i) & ~isoutlier(dataset.Value, 'median', outlr);
    x = i + jitter_amount * (rand(sum(group_idx), 1) - 0.5); % Add random jitter
    y = dataset.Value(group_idx);   % Y-values (data points)

    % Add scatter points
    scatter(x, y, 10, colors(i, :), 'filled', 'MarkerFaceAlpha', 0.2); % Small black points with transparency
end

% Hacemos estadística GLMM
dataset.Value = dataset.Value + abs(min(dataset.Value)) + 1;
glme = fitglme(dataset,'Value ~ Group + (1|Rat)', 'Distribution','gamma','Link','log','FitMethod','Laplace');
[p, F, DF1, DF2] = coefTest(glme, [0 1]);

% Si es significativo ploteamos la significancia
y_limits = ylim; ylim([y_limits(1) y_limits(2)+0.08*diff(y_limits)]); y_limits = ylim;
hold on;
if p < 0.05 && p >= 0.01
    y_line = y_limits(2) - 0.08 * diff(y_limits); % Position for the line
    plot([1, 2], [y_line, y_line], 'k-'); % Horizontal line connecting the groups
    text(1.5, y_line + 0.02 * diff(y_limits), '*', 'HorizontalAlignment', 'center', 'FontSize', 14); % Add the asterisk
elseif p < 0.01 && p >= 0.001
    y_line = y_limits(2) - 0.08 * diff(y_limits); % Position for the line
    plot([1, 2], [y_line, y_line], 'k-'); % Horizontal line connecting the groups
    text(1.5, y_line + 0.02 * diff(y_limits), '**', 'HorizontalAlignment', 'center', 'FontSize', 14); % Add the asterisk
elseif p < 0.001
    y_line = y_limits(2) - 0.08 * diff(y_limits); % Position for the line
    plot([1, 2], [y_line, y_line], 'k-'); % Horizontal line connecting the groups
    text(1.5, y_line + 0.02 * diff(y_limits), '***', 'HorizontalAlignment', 'center', 'FontSize', 14); % Add the asterisk
end
hold off;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ax4 = subplot(234)
dataset = PLV;
h = boxplot(dataset.Value(~isoutlier(dataset.Value, 'median', outlr)), dataset.Group(~isoutlier(dataset.Value, 'median', outlr)), ...
    'color', lines, ...
    'labels', {'BLA-PL', 'BLA-IL'}, ...
    'symbol', '', ...
    'whisker', 1, ...
    'widths', 0.8); 
ylabel([freq ' PLV']); % Label for y-axis
ax4.FontSize = 7;

% Add individual points with jitter
hold on;
group_vals = unique(dataset.Group(~isoutlier(dataset.Value, 'median', outlr))); % Unique group values
jitter_amount = 0.3; % Amount of jitter (adjust as needed)
colors = lines(numel(group_vals)); % Generate a colormap
for i = 1:numel(group_vals)
    % Get data for the current group
    group_idx = dataset.Group == group_vals(i) & ~isoutlier(dataset.Value, 'median', outlr);
    x = i + jitter_amount * (rand(sum(group_idx), 1) - 0.5); % Add random jitter
    y = dataset.Value(group_idx);   % Y-values (data points)

    % Add scatter points
    scatter(x, y, 10, colors(i, :), 'filled', 'MarkerFaceAlpha', 0.2); % Small black points with transparency
end

% Hacemos estadística GLMM
dataset.Value = dataset.Value + abs(min(dataset.Value)) + 1;
glme = fitglme(dataset,'Value ~ Group + (1|Rat)', 'Distribution','gamma','Link','log','FitMethod','Laplace');
[p, F, DF1, DF2] = coefTest(glme, [0 1]);

% Si es significativo ploteamos la significancia
y_limits = ylim; ylim([y_limits(1) y_limits(2)+0.08*diff(y_limits)]); y_limits = ylim;
hold on;
if p < 0.05 && p >= 0.01
    y_line = y_limits(2) - 0.08 * diff(y_limits); % Position for the line
    plot([1, 2], [y_line, y_line], 'k-'); % Horizontal line connecting the groups
    text(1.5, y_line + 0.02 * diff(y_limits), '*', 'HorizontalAlignment', 'center', 'FontSize', 14); % Add the asterisk
elseif p < 0.01 && p >= 0.001
    y_line = y_limits(2) - 0.08 * diff(y_limits); % Position for the line
    plot([1, 2], [y_line, y_line], 'k-'); % Horizontal line connecting the groups
    text(1.5, y_line + 0.02 * diff(y_limits), '**', 'HorizontalAlignment', 'center', 'FontSize', 14); % Add the asterisk
elseif p < 0.001
    y_line = y_limits(2) - 0.08 * diff(y_limits); % Position for the line
    plot([1, 2], [y_line, y_line], 'k-'); % Horizontal line connecting the groups
    text(1.5, y_line + 0.02 * diff(y_limits), '***', 'HorizontalAlignment', 'center', 'FontSize', 14); % Add the asterisk
end
hold off;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ax5 = subplot(235)
dataset = MVGC;
h = boxplot(dataset.Value(~isoutlier(dataset.Value, 'median', outlr)), dataset.Group(~isoutlier(dataset.Value, 'median', outlr)), ...
    'color', lines, ...
    'labels', {'BLA to PL', 'PL to BLA', 'BLA to IL', 'IL to BLA'}, ...
    'symbol', '', ...
    'whisker', 1, ...
    'widths', 0.8); 
ylabel([freq ' GCI']); % Label for y-axis
% ylim([-0.05 0.6]);
ax5.XTickLabelRotation = 45;
ax5.FontSize = 7;

% Add individual points with jitter
hold on;
group_vals = unique(dataset.Group(~isoutlier(dataset.Value, 'median', outlr))); % Unique group values
jitter_amount = 0.3; % Amount of jitter (adjust as needed)
colors = lines(numel(group_vals)); % Generate a colormap
for i = 1:numel(group_vals)
    % Get data for the current group
    group_idx = dataset.Group == group_vals(i) & ~isoutlier(dataset.Value, 'median', outlr);
    x = i + jitter_amount * (rand(sum(group_idx), 1) - 0.5); % Add random jitter
    y = dataset.Value(group_idx);   % Y-values (data points)

    % Add scatter points
    scatter(x, y, 10, colors(i, :), 'filled', 'MarkerFaceAlpha', 0.2); % Small black points with transparency
end

% Hacemos estadística GLMM
dataset.Value = dataset.Value + abs(min(dataset.Value)) + 1;
glme = fitglme(dataset,'Value ~ Group + (1|Rat)', 'Distribution','gamma','Link','log','FitMethod','Laplace');
[p1, F1, DF11, DF21] = coefTest(glme, [0 1 0 0]);
[p2, F2, DF12, DF22] = coefTest(glme, [0 0 1 -1]);

% Si es significativo ploteamos la significancia
y_limits = ylim; ylim([y_limits(1) y_limits(2)+0.08*diff(y_limits)]); y_limits = ylim;
hold on;
if p1 < 0.05 && p1 >= 0.01
    y_line = y_limits(2) - 0.08 * diff(y_limits); % Position for the line
    plot([1, 2], [y_line, y_line], 'k-'); % Horizontal line connecting the groups
    text(1.5, y_line + 0.02 * diff(y_limits), '*', 'HorizontalAlignment', 'center', 'FontSize', 14); % Add the asterisk
elseif p1 < 0.01 && p1 >= 0.001
    y_line = y_limits(2) - 0.08 * diff(y_limits); % Position for the line
    plot([1, 2], [y_line, y_line], 'k-'); % Horizontal line connecting the groups
    text(1.5, y_line + 0.02 * diff(y_limits), '**', 'HorizontalAlignment', 'center', 'FontSize', 14); % Add the asterisk
elseif p1 < 0.001
    y_line = y_limits(2) - 0.08 * diff(y_limits); % Position for the line
    plot([1, 2], [y_line, y_line], 'k-'); % Horizontal line connecting the groups
    text(1.5, y_line + 0.02 * diff(y_limits), '***', 'HorizontalAlignment', 'center', 'FontSize', 14); % Add the asterisk
end
if p2 < 0.05 && p2 >= 0.01
    y_line = y_limits(2) - 0.08 * diff(y_limits); % Position for the line
    plot([3, 4], [y_line, y_line], 'k-'); % Horizontal line connecting the groups
    text(3.5, y_line + 0.02 * diff(y_limits), '*', 'HorizontalAlignment', 'center', 'FontSize', 14); % Add the asterisk
elseif p2 < 0.01 && p2 >= 0.001
    y_line = y_limits(2) - 0.08 * diff(y_limits); % Position for the line
    plot([3, 4], [y_line, y_line], 'k-'); % Horizontal line connecting the groups
    text(3.5, y_line + 0.02 * diff(y_limits), '**', 'HorizontalAlignment', 'center', 'FontSize', 14); % Add the asterisk
elseif p2 < 0.001
    y_line = y_limits(2) - 0.08 * diff(y_limits); % Position for the line
    plot([3, 4], [y_line, y_line], 'k-'); % Horizontal line connecting the groups
    text(3.5, y_line + 0.02 * diff(y_limits), '***', 'HorizontalAlignment', 'center', 'FontSize', 14); % Add the asterisk
end
hold off;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ax6 = subplot(236)
dataset = Coherence;
h = boxplot(dataset.Value(~isoutlier(dataset.Value, 'median', outlr)), dataset.Group(~isoutlier(dataset.Value, 'median', outlr)), ...
    'color', lines, ...
    'labels', {'BLA-PL', 'BLA-IL'}, ...
    'symbol', '', ...
    'whisker', 1, ...
    'widths', 0.8); 
ylabel([freq ' Coherence']); % Label for y-axis
ax6.FontSize = 7;

% Add individual points with jitter
hold on;
group_vals = unique(dataset.Group(~isoutlier(dataset.Value, 'median', outlr))); % Unique group values
jitter_amount = 0.3; % Amount of jitter (adjust as needed)
colors = lines(numel(group_vals)); % Generate a colormap
for i = 1:numel(group_vals)
    % Get data for the current group
    group_idx = dataset.Group == group_vals(i) & ~isoutlier(dataset.Value, 'median', outlr);
    x = i + jitter_amount * (rand(sum(group_idx), 1) - 0.5); % Add random jitter
    y = dataset.Value(group_idx);   % Y-values (data points)

    % Add scatter points
    scatter(x, y, 10, colors(i, :), 'filled', 'MarkerFaceAlpha', 0.2); % Small black points with transparency
end

% Hacemos estadística GLMM
dataset.Value = dataset.Value + abs(min(dataset.Value)) + 1;
glme = fitglme(dataset,'Value ~ Group + (1|Rat)', 'Distribution','gamma','Link','log','FitMethod','Laplace');
[p, F, DF1, DF2] = coefTest(glme, [0 1]);

% Si es significativo ploteamos la significancia
y_limits = ylim; ylim([y_limits(1) y_limits(2)+0.08*diff(y_limits)]); y_limits = ylim;
hold on;
if p < 0.05 && p >= 0.01
    y_line = y_limits(2) - 0.08 * diff(y_limits); % Position for the line
    plot([1, 2], [y_line, y_line], 'k-'); % Horizontal line connecting the groups
    text(1.5, y_line + 0.02 * diff(y_limits), '*', 'HorizontalAlignment', 'center', 'FontSize', 14); % Add the asterisk
elseif p < 0.01 && p >= 0.001
    y_line = y_limits(2) - 0.08 * diff(y_limits); % Position for the line
    plot([1, 2], [y_line, y_line], 'k-'); % Horizontal line connecting the groups
    text(1.5, y_line + 0.02 * diff(y_limits), '**', 'HorizontalAlignment', 'center', 'FontSize', 14); % Add the asterisk
elseif p < 0.001
    y_line = y_limits(2) - 0.08 * diff(y_limits); % Position for the line
    plot([1, 2], [y_line, y_line], 'k-'); % Horizontal line connecting the groups
    text(1.5, y_line + 0.02 * diff(y_limits), '***', 'HorizontalAlignment', 'center', 'FontSize', 14); % Add the asterisk
end
hold off;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set figure properties
set(gcf, 'Color', 'white');
set(gcf, 'Position', [200, 100, 500 500]);