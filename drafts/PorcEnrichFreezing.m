%% Comparacion del porcentaje de tiempo enriquecido en 4Hz
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc
clear all

rats = [11,12,13,17,18,19,20]; % Filtro por animales para aversivo.
paradigm_toinclude = 'aversive'; % Filtro por el paradigma
session_toinclude = {'EXT1','EXT2','TEST'}; % Filtro por las sesiones

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Cargamos los datos
% cd('D:\Doctorado\Analisis\Sheets');
cd('D:\Sheets');
EventsSheet = readtable('EventsSheet.csv');
EnrichSheet = readtable('PorcEnrich_Sheet.csv');

% Borramos aquellas filas en donde se repite el ID
[~, uniqueIdx] = unique(EnrichSheet.ID, 'first');
EnrichSheet = EnrichSheet(uniqueIdx, :); clear uniqueIdx;

% Mergeamos ambas tablas en EventsSheet
MergedSheet = join(EnrichSheet, EventsSheet, 'Keys', 'ID');

% Filtramos la tabla con las distintas condiciones
MergedSheet = MergedSheet(ismember(MergedSheet.Rat,rats), :);
MergedSheet = MergedSheet(ismember(MergedSheet.Session, session_toinclude), :);
MergedSheet = MergedSheet(ismember(MergedSheet.Event, 'Freezing'), :);
MergedSheet = MergedSheet(MergedSheet.noisy == 0, :); % Solo me quedo con los eventos no ruidosos
MergedSheet = MergedSheet(MergedSheet.Epileptic <= 5, :); % Tolerancia de 5% del evento con evento epiléptico
MergedSheet = MergedSheet(MergedSheet.Flat <= 0.1, :); % Tolerancia de 0.1% del evento con evento Flat

% Porcentaje del tiempo haciendo 4Hz Freezing
figure;
dataset = MergedSheet;

group_vals = flip(unique(dataset.Enrich(~isoutlier(dataset.FourHz_Enrich, 'median', 20)))); % Unique Enrich values

h = boxplot(dataset.FourHz_Enrich(~isoutlier(dataset.FourHz_Enrich, 'median', 20)), dataset.Enrich(~isoutlier(dataset.FourHz_Enrich, 'median', 20)), ...
    'color', lines, ...
    'labels', group_vals, ...
    'symbol', '', ...
    'whisker', 1, ...
    'widths', 0.8); 
ylabel(['% time 4Hz Enriched']); % Label for y-axis

% Add individual points with jitter
hold on;

jitter_amount = 0.3; % Amount of jitter (adjust as needed)
colors = lines(numel(group_vals)); % Generate a colormap
for i = 1:numel(group_vals)
    % Get data for the current group
    group_idx = strcmp(dataset.Enrich, group_vals(i)) & ~isoutlier(dataset.FourHz_Enrich, 'median', 20);
    x = i + jitter_amount * (rand(sum(group_idx), 1) - 0.5); % Add random jitter
    y = dataset.FourHz_Enrich(group_idx);   % Y-values (data points)

    % Add scatter points
    scatter(x, y, 10, colors(i, :), 'filled', 'MarkerFaceAlpha', 0.2); % Small black points with transparency
end

% Hacemos estadística GLMM
dataset.FourHz_Enrich = dataset.FourHz_Enrich + abs(min(dataset.FourHz_Enrich)) + 1;
glme = fitglme(dataset,'FourHz_Enrich ~ Enrich + (1|Rat)', 'Distribution','gamma','Link','log','FitMethod','Laplace');
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

% Set figure properties
set(gcf, 'Color', 'white');
set(gcf, 'Position', [200, 100, 200 200]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Porcentaje del tiempo haciendo Theta Freezing
figure;
dataset = MergedSheet;

group_vals = flip(unique(dataset.Enrich(~isoutlier(dataset.Theta_Enrich, 'median', 20)))); % Unique Enrich values

h = boxplot(dataset.Theta_Enrich(~isoutlier(dataset.Theta_Enrich, 'median', 20)), dataset.Enrich(~isoutlier(dataset.Theta_Enrich, 'median', 20)), ...
    'color', lines, ...
    'labels', group_vals, ...
    'symbol', '', ...
    'whisker', 1, ...
    'widths', 0.8); 
ylabel(['% time Theta Enriched']); % Label for y-axis
ax4.FontSize = 7;

% Add individual points with jitter
hold on;
jitter_amount = 0.3; % Amount of jitter (adjust as needed)
colors = lines(numel(group_vals)); % Generate a colormap
for i = 1:numel(group_vals)
    % Get data for the current group
    group_idx = strcmp(dataset.Enrich, group_vals(i)) & ~isoutlier(dataset.Theta_Enrich, 'median', 20);
    x = i + jitter_amount * (rand(sum(group_idx), 1) - 0.5); % Add random jitter
    y = dataset.Theta_Enrich(group_idx);   % Y-values (data points)

    % Add scatter points
    scatter(x, y, 10, colors(i, :), 'filled', 'MarkerFaceAlpha', 0.2); % Small black points with transparency
end

% Hacemos estadística GLMM
dataset.Theta_Enrich = dataset.Theta_Enrich + abs(min(dataset.Theta_Enrich)) + 1;
glme = fitglme(dataset,'Theta_Enrich ~ Enrich + (1|Rat)', 'Distribution','gamma','Link','log','FitMethod','Laplace');
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

% Set figure properties
set(gcf, 'Color', 'white');
set(gcf, 'Position', [200, 100, 200 200]);

%% Analizo si hay alguna estructura desde el inicio del freezing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc;
clear all;

% Definir los animales, paradigma y sesiones
rats = [11,12,13,17,18,19,20];
paradigm_toinclude = 'aversive';
session_toinclude = {'EXT1', 'EXT2', 'TEST'};

% Cargar los datos
cd('D:\Sheets');
EventsSheet = readtable('EventsSheet.csv');
load('PowerEnrich_Sheet.mat');

% Filtrar las condiciones
EventsSheet = EventsSheet(ismember(EventsSheet.Rat, rats), :);
EventsSheet = EventsSheet(ismember(EventsSheet.Session, session_toinclude), :);
EventsSheet = EventsSheet(ismember(EventsSheet.Event, 'Freezing'), :);
EventsSheet = EventsSheet(EventsSheet.noisy == 0, :); % Solo eventos no ruidosos
EventsSheet = EventsSheet(EventsSheet.Epileptic <= 5, :); % Tolerancia 5% evento epiléptico
EventsSheet = EventsSheet(EventsSheet.Flat <= 0.1, :); % Tolerancia 0.1% evento Flat

% Filtrar los IDs por '4Hz' y 'Theta'
ID_4hz = EventsSheet.ID(ismember(EventsSheet.Enrich, '4Hz'), :);
ID_Theta = EventsSheet.ID(ismember(EventsSheet.Enrich, 'Theta'), :);

% Separar EnrichSeries en base a los IDs filtrados
EnrichSeries_4Hz = EnrichSeries(ismember(ID, ID_4hz));
EnrichSeries_Theta = EnrichSeries(ismember(ID, ID_Theta));

% Encontrar el tamaño máximo de las series en EnrichSeries
maxLength = max(cellfun(@numel, EnrichSeries));
t = 0:0.5:(maxLength-1)*0.5;

% Crear la matriz de NaNs (el tamaño máximo de las series)
NaNMatrix_4Hz = NaN(maxLength, numel(EnrichSeries_4Hz));
NaNMatrix_Theta = NaN(maxLength, numel(EnrichSeries_Theta));

% Rellenar las matrices de NaNs con los valores de EnrichSeries
for i = 1:numel(EnrichSeries_4Hz)
    seriesLength = numel(EnrichSeries_4Hz{i});
    NaNMatrix_4Hz(1:seriesLength, i) = EnrichSeries_4Hz{i};
end

for i = 1:numel(EnrichSeries_Theta)
    seriesLength = numel(EnrichSeries_Theta{i});
    NaNMatrix_Theta(1:seriesLength, i) = EnrichSeries_Theta{i};
end

Fz_4Hz = NaNMatrix_4Hz';
Fz_Theta = NaNMatrix_Theta';
%%
% Plot the results
data = Fz_4Hz; % Assumes Fz_4Hz is the data you're working with
figure;
hold on;

% Assuming colores is a function that returns color based on a string input
color = colores('Magenta'); 

% Calculate median and standard error of the mean (SEM)
y = nanmedian(data, 1); % Median values across rows (axis 1)
sem = nansem(data, 1); % Standard error of the mean
y = y(~isnan(y));
sem = sem(~isnan(sem));
t_S = t(1:size(sem,2));

% Create shaded error region
curve1 = y + sem; % Upper bound of SEM
curve2 = y - sem; % Lower bound of SEM
x2 = [t_S, fliplr(t_S)]; % Combine x-coordinates for fill
inBetween = [curve1, fliplr(curve2)]; % Combine y-coordinates for fill
p1 = fill(x2, inBetween, color, 'FaceAlpha', 0.4, 'EdgeColor', 'none', ...
          'HandleVisibility', 'off'); % Shaded region without legend entry

% Plot the mean line
plot(t_S, y, 'Color', color, 'LineWidth', 1.5, ...
     'DisplayName', '4Hz Fz'); % Line plot with label

hold on;

% Plot the results
data = Fz_Theta; % Assumes Fz_4Hz is the data you're working with

% Assuming colores is a function that returns color based on a string input
color = colores('Cyan'); 

% Calculate median and standard error of the mean (SEM)
y = nanmedian(data, 1); % Median values across rows (axis 1)
sem = nansem(data, 1); % Standard error of the mean
y = y(~isnan(y));
sem = sem(~isnan(sem));
t_S = t(1:size(sem,2));

% Create shaded error region
curve1 = y + sem; % Upper bound of SEM
curve2 = y - sem; % Lower bound of SEM
x2 = [t_S, fliplr(t_S)]; % Combine x-coordinates for fill
inBetween = [curve1, fliplr(curve2)]; % Combine y-coordinates for fill
p1 = fill(x2, inBetween, color, 'FaceAlpha', 0.4, 'EdgeColor', 'none', ...
          'HandleVisibility', 'off'); % Shaded region without legend entry

% Plot the mean line
plot(t_S, y, 'Color', color, 'LineWidth', 1.5, ...
     'DisplayName', 'Theta Fz'); % Line plot with label
 
hold off;

ylim([0.5 1.8]);
xlim([0 25]);
ylabel('4Hz:Theta Ratio');
xlabel('Time (sec.)');

line([0 25],[1 1],'Color',[0 0 0],'LineWidth',0.5,'LineStyle','--');

% Set figure properties
set(gcf, 'Color', 'white');
set(gcf, 'Position', [100, 500, 300 200]);

%%
%%%%%%%%%%%


% Plot the results
data = Fz_4Hz;
figure;
hold on;
colores('magenta'); % Get distinct colors for each Type
y = nanmedian(data,1); % Mean values
sem = nansem(data,1); % SEM values

% Create shaded error region
curve1 = y + sem; % Upper bound of SEM
curve2 = y - sem; % Lower bound of SEM
x2 = [t; fliplr(t)]; % Combine x-coordinates for fill
inBetween = [curve1; fliplr(curve2)]; % Combine y-coordinates for fill
p1 = fill(x2, inBetween, colores('magenta'), 'FaceAlpha', 0.4, 'EdgeColor', 'none', ...
          'HandleVisibility', 'off'); % Shaded region without legend entry
plot(t, y, 'Color', colores('magenta'), 'LineWidth', 1.5); % Line plot with label

% Add labels, legend, and title
xlim([-5 5]);
xlabel('Time (s)');
ylabel('Acceleration (cm/s^2)');
legend('show', 'Location', 'eastoutside'); % Places the legend outside on the right
title('');
hold off;




%%



clc
clear all

rats = [11,12,13,17,18,19,20]; % Filtro por animales para aversivo.
paradigm_toinclude = 'aversive'; % Filtro por el paradigma
session_toinclude = {'EXT1','EXT2','TEST'}; % Filtro por las sesiones

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Cargamos los datos
% cd('D:\Doctorado\Analisis\Sheets');
cd('D:\Sheets');
EventsSheet = readtable('EventsSheet.csv');
load('PowerEnrich_Sheet.mat');

% Filtramos la tabla con las distintas condiciones
EventsSheet = EventsSheet(ismember(EventsSheet.Rat,rats), :);
EventsSheet = EventsSheet(ismember(EventsSheet.Session, session_toinclude), :);
EventsSheet = EventsSheet(ismember(EventsSheet.Event, 'Freezing'), :);
EventsSheet = EventsSheet(EventsSheet.noisy == 0, :); % Solo me quedo con los eventos no ruidosos
EventsSheet = EventsSheet(EventsSheet.Epileptic <= 5, :); % Tolerancia de 5% del evento con evento epiléptico
EventsSheet = EventsSheet(EventsSheet.Flat <= 0.1, :); % Tolerancia de 0.1% del evento con evento Flat

ID_4hz = EventsSheet.ID(ismember(EventsSheet.Enrich, '4Hz'), :);
ID_Theta = EventsSheet.ID(ismember(EventsSheet.Enrich, 'Theta'), :);

% Borramos aquellas filas en donde se repite el ID
[~, uniqueIdx] = unique(EnrichSheet.ID, 'first');
EnrichSheet = EnrichSheet(uniqueIdx, :); clear uniqueIdx;

% Mergeamos ambas tablas en EventsSheet
MergedSheet = join(EnrichSheet, EventsSheet, 'Keys', 'ID');

% Filtramos la tabla con las distintas condiciones
MergedSheet = MergedSheet(ismember(MergedSheet.Rat,rats), :);
MergedSheet = MergedSheet(ismember(MergedSheet.Session, session_toinclude), :);
MergedSheet = MergedSheet(ismember(MergedSheet.Event, 'Freezing'), :);
MergedSheet = MergedSheet(MergedSheet.noisy == 0, :); % Solo me quedo con los eventos no ruidosos
MergedSheet = MergedSheet(MergedSheet.Epileptic <= 5, :); % Tolerancia de 5% del evento con evento epiléptico
MergedSheet = MergedSheet(MergedSheet.Flat <= 0.1, :); % Tolerancia de 0.1% del evento con evento Flat