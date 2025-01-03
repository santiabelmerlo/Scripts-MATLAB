%% Fig003: Figura para plotear la potencia de CS1 vs CS2 en los 5 rangos frecuenciales
% Usando los datos zscoreados o los datos normalizados que est�n en los
% sheets

clc
clear all

% Seteamos algunos par�metros para filtrar los datos
Event = {'CS1';'CS2'};
Rat = [11,12,13,17,18,19,20];
Session = 'EXT1';
Region = 'BLA';
Trial = [1:4];
Type = [1,2];
pvalpos = 2.3; % Posici�n del pvalor en y
color1 = colores('Aversivo');
color2 = colores('Control');

% Cargamos datos de los sheets
cd('D:\Doctorado\Analisis\Sheets');
EventsSheet = readtable('EventsSheet.csv');
PowerSheet = readtable('ZPower_Sheet.csv');
% PowerSheet = readtable('NormPower_Sheet.csv');

% Filtramos la tabla de EventsSheet
EventsSheet = EventsSheet(ismember(EventsSheet.Event,Event),:);
EventsSheet = EventsSheet(ismember(EventsSheet.Rat,Rat),:);
EventsSheet = EventsSheet(ismember(EventsSheet.Session,Session),:);
EventsSheet = EventsSheet(ismember(EventsSheet.Trial,Trial),:);
EventsSheet = EventsSheet(ismember(EventsSheet.Type,Type),:);

% Filtramos los eventos ruidosos
% EventsSheet = EventsSheet(EventsSheet.noisy == 0,:);
% EventsSheet = EventsSheet(EventsSheet.Epileptic <= 1,:);
% EventsSheet = EventsSheet(EventsSheet.Flat <= 1,:);

% Mergeamos las dos tablas en base al ID
MergedSheet = join(EventsSheet, PowerSheet, 'Keys', 'ID');

% Ploteamos el boxplot
figure;
dataset = MergedSheet;

group = unique(dataset.Event); % Unique Event values

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Ploteamos para 4Hz
xPositions = [1, 2]; % Aqu� defines las posiciones de los grupos en el eje x
h = boxplot(dataset.(['FourHz_' Region]), dataset.Event, ...
    'color', [color1;color2], ...
    'labels', group, ...
    'symbol', '', ...
    'whisker', 1, ...
    'widths', 0.8,...
    'positions', xPositions);

% Add individual points with jitter
hold on;
jitter_amount = 0.3; % Amount of jitter (adjust as needed)
colors = [color1; color2]; % Generate a colormap
for i = 1:numel(group)
    % Get data for the current group
    group_idx = strcmp(dataset.Event, group(i)) & ~isoutlier(dataset.(['FourHz_' Region]), 'median', 5);
    x = i + jitter_amount * (rand(sum(group_idx), 1) - 0.5); % Add random jitter
    y = dataset.(['FourHz_' Region])(group_idx);   % Y-values (data points)

    % Add scatter points
    scatter(x + xPositions(1)-1, y, 5, colors(i, :), 'filled', 'MarkerFaceAlpha', 0.5); % Small black points with transparency
end

% Hacemos estad�stica GLMM
dataset.(['FourHz_' Region]) = dataset.(['FourHz_' Region]) + abs(min(dataset.(['FourHz_' Region]))) + 1;
formula = [(['FourHz_' Region]), ' ~ Event + (1|Rat)'];
glme = fitglme(dataset,formula, 'Distribution','gamma','Link','log','FitMethod','Laplace');
disp('4-Hz ANOVA');
disp(anova(glme));
[p1, F1, DF11, DF21] = coefTest(glme, [1 0]);
disp(['4-Hz ' 'CS1 vs Baseline ' 'p=' num2str(p1*10) ' F=' num2str(F1) ' DF1=' num2str(DF11) ' DF2=' num2str(DF21)]);
[p2, F2, DF12, DF22] = coefTest(glme, [1 -1]);
disp(['4-Hz ' 'CS2 vs Baseline ' 'p=' num2str(p2*10) ' F=' num2str(F2) ' DF1=' num2str(DF12) ' DF2=' num2str(DF22)]);
[p, F, DF1, DF2] = coefTest(glme, [0 1]);
disp(['4-Hz ' 'CS1 vs CS2 ' 'p=' num2str(p) ' F=' num2str(F) ' DF1=' num2str(DF1) ' DF2=' num2str(DF2)]);

% Si es significativo ploteamos la significancia
y_limits = ylim; ylim([y_limits(1) y_limits(2)+0.08*diff(y_limits)]); y_limits = ylim;
hold on;
if p < 0.05 && p >= 0.01
%     y_line = y_limits(2) - 0.08 * diff(y_limits); % Position for the line
    y_line = pvalpos; % Position for the line
    plot([1, 2], [y_line, y_line], 'k-'); % Horizontal line connecting the groups
    text(1.5, y_line + 0.2, '*', 'HorizontalAlignment', 'center', 'FontSize', 10); % Add the asterisk
elseif p < 0.01 && p >= 0.001
%     y_line = y_limits(2) - 0.08 * diff(y_limits); % Position for the line
    y_line = pvalpos; % Position for the line
    plot([1, 2], [y_line, y_line], 'k-'); % Horizontal line connecting the groups
    text(1.5, y_line + 0.2, '**', 'HorizontalAlignment', 'center', 'FontSize', 10); % Add the asterisk
elseif p < 0.001
%     y_line = y_limits(2) - 0.08 * diff(y_limits); % Position for the line
    y_line = pvalpos; % Position for the line
    plot([1, 2], [y_line, y_line], 'k-'); % Horizontal line connecting the groups
    text(1.5, y_line + 0.2, '***', 'HorizontalAlignment', 'center', 'FontSize', 10); % Add the asterisk
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Ploteamos para Theta
xPositions = [3, 4]; % Aqu� defines las posiciones de los grupos en el eje x
h = boxplot(dataset.(['Theta_' Region]), dataset.Event, ...
    'color', [color1; color2], ...
    'labels', group, ...
    'symbol', '', ...
    'whisker', 1, ...
    'widths', 0.8,...
    'positions', xPositions);

% Add individual points with jitter
hold on;
jitter_amount = 0.3; % Amount of jitter (adjust as needed)
colors = [color1; color2]; % Generate a colormap
for i = 1:numel(group)
    % Get data for the current group
    group_idx = strcmp(dataset.Event, group(i)) & ~isoutlier(dataset.(['Theta_' Region]), 'median', 5);
    x = i + jitter_amount * (rand(sum(group_idx), 1) - 0.5); % Add random jitter
    y = dataset.(['Theta_' Region])(group_idx);   % Y-values (data points)

    % Add scatter points
    scatter(x + xPositions(1)-1, y, 5, colors(i, :), 'filled', 'MarkerFaceAlpha', 0.5); % Small black points with transparency
end

% Hacemos estad�stica GLMM
dataset.(['Theta_' Region]) = dataset.(['Theta_' Region]) + abs(min(dataset.(['Theta_' Region]))) + 1;
formula = [(['Theta_' Region]), ' ~ Event + (1|Rat)'];
glme = fitglme(dataset,formula, 'Distribution','gamma','Link','log','FitMethod','Laplace');
disp(' ');
disp('Theta ANOVA')
disp(anova(glme));
[p1, F1, DF11, DF21] = coefTest(glme, [1 0]);
disp(['Theta ' 'CS1 vs Baseline ' 'p=' num2str(p1*10) ' F=' num2str(F1) ' DF1=' num2str(DF11) ' DF2=' num2str(DF21)]);
[p2, F2, DF12, DF22] = coefTest(glme, [1 -1]);
disp(['Theta ' 'CS2 vs Baseline ' 'p=' num2str(p2*10) ' F=' num2str(F2) ' DF1=' num2str(DF12) ' DF2=' num2str(DF22)]);
[p, F, DF1, DF2] = coefTest(glme, [0 1]);
disp(['Theta ' 'CS1 vs CS2 ' 'p=' num2str(p) ' F=' num2str(F) ' DF1=' num2str(DF1) ' DF2=' num2str(DF2)]);

% Si es significativo ploteamos la significancia
y_limits = ylim; ylim([y_limits(1) y_limits(2)+0.08*diff(y_limits)]); y_limits = ylim;
hold on;
if p < 0.05 && p >= 0.01
%     y_line = y_limits(2) - 0.08 * diff(y_limits); % Position for the line
    y_line = pvalpos; % Position for the line
    plot([3, 4], [y_line, y_line], 'k-'); % Horizontal line connecting the groups
    text(3.5, y_line + 0.2, '*', 'HorizontalAlignment', 'center', 'FontSize', 10); % Add the asterisk
elseif p < 0.01 && p >= 0.001
%     y_line = y_limits(2) - 0.08 * diff(y_limits); % Position for the line
    y_line = pvalpos; % Position for the line
    plot([3, 4], [y_line, y_line], 'k-'); % Horizontal line connecting the groups
    text(3.5, y_line + 0.2, '**', 'HorizontalAlignment', 'center', 'FontSize', 10); % Add the asterisk
elseif p < 0.001
%     y_line = y_limits(2) - 0.08 * diff(y_limits); % Position for the line
    y_line = pvalpos; % Position for the line
    plot([3, 4], [y_line, y_line], 'k-'); % Horizontal line connecting the groups
    text(3.5, y_line + 0.2, '***', 'HorizontalAlignment', 'center', 'FontSize', 10); % Add the asterisk
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Ploteamos para Beta
xPositions = [5, 6]; % Aqu� defines las posiciones de los grupos en el eje x
h = boxplot(dataset.(['Beta_' Region]), dataset.Event, ...
    'color', [color1; color2], ...
    'labels', group, ...
    'symbol', '', ...
    'whisker', 1, ...
    'widths', 0.8,...
    'positions', xPositions);

% Add individual points with jitter
hold on;
jitter_amount = 0.3; % Amount of jitter (adjust as needed)
colors = [color1; color2]; % Generate a colormap
for i = 1:numel(group)
    % Get data for the current group
    group_idx = strcmp(dataset.Event, group(i)) & ~isoutlier(dataset.(['Beta_' Region]), 'median', 5);
    x = i + jitter_amount * (rand(sum(group_idx), 1) - 0.5); % Add random jitter
    y = dataset.(['Beta_' Region])(group_idx);   % Y-values (data points)

    % Add scatter points
    scatter(x + xPositions(1)-1, y, 5, colors(i, :), 'filled', 'MarkerFaceAlpha', 0.5); % Small black points with transparency
end

% Hacemos estad�stica GLMM
dataset.(['Beta_' Region]) = dataset.(['Beta_' Region]) + abs(min(dataset.(['Beta_' Region]))) + 1;
formula = [(['Beta_' Region]), ' ~ Event + (1|Rat)'];
glme = fitglme(dataset,formula, 'Distribution','gamma','Link','log','FitMethod','Laplace');
disp(' ');
disp('Beta ANOVA')
disp(anova(glme));
[p1, F1, DF11, DF21] = coefTest(glme, [1 0]);
disp(['Beta ' 'CS1 vs Baseline ' 'p=' num2str(p1*10) ' F=' num2str(F1) ' DF1=' num2str(DF11) ' DF2=' num2str(DF21)]);
[p2, F2, DF12, DF22] = coefTest(glme, [1 -1]);
disp(['Beta ' 'CS2 vs Baseline ' 'p=' num2str(p2*10) ' F=' num2str(F2) ' DF1=' num2str(DF12) ' DF2=' num2str(DF22)]);
[p, F, DF1, DF2] = coefTest(glme, [0 1]);
disp(['Beta ' 'CS1 vs CS2 ' 'p=' num2str(p) ' F=' num2str(F) ' DF1=' num2str(DF1) ' DF2=' num2str(DF2)]);

% Si es significativo ploteamos la significancia
y_limits = ylim; ylim([y_limits(1) y_limits(2)+0.08*diff(y_limits)]); y_limits = ylim;
hold on;
if p < 0.05 && p >= 0.01
%     y_line = y_limits(2) - 0.08 * diff(y_limits); % Position for the line
    y_line = pvalpos; % Position for the line
    plot([xPositions(1), xPositions(2)], [y_line, y_line], 'k-'); % Horizontal line connecting the groups
    text((xPositions(1)+xPositions(2))/2, y_line + 0.2, '*', 'HorizontalAlignment', 'center', 'FontSize', 10); % Add the asterisk
elseif p < 0.01 && p >= 0.001
%     y_line = y_limits(2) - 0.08 * diff(y_limits); % Position for the line
    y_line = pvalpos; % Position for the line
    plot([xPositions(1), xPositions(2)], [y_line, y_line], 'k-'); % Horizontal line connecting the groups
    text((xPositions(1)+xPositions(2))/2, y_line + 0.2, '**', 'HorizontalAlignment', 'center', 'FontSize', 10); % Add the asterisk
elseif p < 0.001
%     y_line = y_limits(2) - 0.08 * diff(y_limits); % Position for the line
    y_line = pvalpos; % Position for the line
    plot([xPositions(1), xPositions(2)], [y_line, y_line], 'k-'); % Horizontal line connecting the groups
    text((xPositions(1)+xPositions(2))/2, y_line + 0.2, '***', 'HorizontalAlignment', 'center', 'FontSize', 10); % Add the asterisk
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Ploteamos para sGamma
xPositions = [7, 8]; % Aqu� defines las posiciones de los grupos en el eje x
h = boxplot(dataset.(['sGamma_' Region]), dataset.Event, ...
    'color', [color1; color2], ...
    'labels', group, ...
    'symbol', '', ...
    'whisker', 1, ...
    'widths', 0.8,...
    'positions', xPositions);

% Add individual points with jitter
hold on;
jitter_amount = 0.3; % Amount of jitter (adjust as needed)
colors = [color1; color2]; % Generate a colormap
for i = 1:numel(group)
    % Get data for the current group
    group_idx = strcmp(dataset.Event, group(i)) & ~isoutlier(dataset.(['sGamma_' Region]), 'median', 5);
    x = i + jitter_amount * (rand(sum(group_idx), 1) - 0.5); % Add random jitter
    y = dataset.(['sGamma_' Region])(group_idx);   % Y-values (data points)

    % Add scatter points
    scatter(x + xPositions(1)-1, y, 5, colors(i, :), 'filled', 'MarkerFaceAlpha', 0.5); % Small black points with transparency
end

% Hacemos estad�stica GLMM
dataset.(['sGamma_' Region]) = dataset.(['sGamma_' Region]) + abs(min(dataset.(['sGamma_' Region]))) + 1;
formula = [(['sGamma_' Region]), ' ~ Event + (1|Rat)'];
glme = fitglme(dataset,formula, 'Distribution','gamma','Link','log','FitMethod','Laplace');
disp(' ');
disp('sGamma ANOVA')
disp(anova(glme));
[p1, F1, DF11, DF21] = coefTest(glme, [1 0]);
disp(['sGamma ' 'CS1 vs Baseline ' 'p=' num2str(p1*10) ' F=' num2str(F1) ' DF1=' num2str(DF11) ' DF2=' num2str(DF21)]);
[p2, F2, DF12, DF22] = coefTest(glme, [1 -1]);
disp(['sGamma ' 'CS2 vs Baseline ' 'p=' num2str(p2*10) ' F=' num2str(F2) ' DF1=' num2str(DF12) ' DF2=' num2str(DF22)]);
[p, F, DF1, DF2] = coefTest(glme, [0 1]);
disp(['sGamma ' 'CS1 vs CS2 ' 'p=' num2str(p) ' F=' num2str(F) ' DF1=' num2str(DF1) ' DF2=' num2str(DF2)]);

% Si es significativo ploteamos la significancia
y_limits = ylim; ylim([y_limits(1) y_limits(2)+0.08*diff(y_limits)]); y_limits = ylim;
hold on;
if p < 0.05 && p >= 0.01
%     y_line = y_limits(2) - 0.08 * diff(y_limits); % Position for the line
    y_line = pvalpos; % Position for the line
    plot([xPositions(1), xPositions(2)], [y_line, y_line], 'k-'); % Horizontal line connecting the groups
    text((xPositions(1)+xPositions(2))/2, y_line + 0.2, '*', 'HorizontalAlignment', 'center', 'FontSize', 10); % Add the asterisk
elseif p < 0.01 && p >= 0.001
%     y_line = y_limits(2) - 0.08 * diff(y_limits); % Position for the line
    y_line = pvalpos; % Position for the line
    plot([xPositions(1), xPositions(2)], [y_line, y_line], 'k-'); % Horizontal line connecting the groups
    text((xPositions(1)+xPositions(2))/2, y_line + 0.2, '**', 'HorizontalAlignment', 'center', 'FontSize', 10); % Add the asterisk
elseif p < 0.001
%     y_line = y_limits(2) - 0.08 * diff(y_limits); % Position for the line
    y_line = pvalpos; % Position for the line
    plot([xPositions(1), xPositions(2)], [y_line, y_line], 'k-'); % Horizontal line connecting the groups
    text((xPositions(1)+xPositions(2))/2, y_line + 0.2, '***', 'HorizontalAlignment', 'center', 'FontSize', 10); % Add the asterisk
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Ploteamos para fGamma
xPositions = [9, 10]; % Aqu� defines las posiciones de los grupos en el eje x
h = boxplot(dataset.(['fGamma_' Region]), dataset.Event, ...
    'color', [color1; color2], ...
    'labels', group, ...
    'symbol', '', ...
    'whisker', 1, ...
    'widths', 0.8,...
    'positions', xPositions);

% Add individual points with jitter
hold on;
jitter_amount = 0.3; % Amount of jitter (adjust as needed)
colors = [color1; color2]; % Generate a colormap
for i = 1:numel(group)
    % Get data for the current group
    group_idx = strcmp(dataset.Event, group(i)) & ~isoutlier(dataset.(['fGamma_' Region]), 'median', 5);
    x = i + jitter_amount * (rand(sum(group_idx), 1) - 0.5); % Add random jitter
    y = dataset.(['fGamma_' Region])(group_idx);   % Y-values (data points)

    % Add scatter points
    scatter(x + xPositions(1)-1, y, 5, colors(i, :), 'filled', 'MarkerFaceAlpha', 0.5); % Small black points with transparency
end

% Hacemos estad�stica GLMM
dataset.(['fGamma_' Region]) = dataset.(['fGamma_' Region]) + abs(min(dataset.(['fGamma_' Region]))) + 1;
formula = [(['fGamma_' Region]), ' ~ Event + (1|Rat)'];
glme = fitglme(dataset,formula, 'Distribution','gamma','Link','log','FitMethod','Laplace');
disp(' ');
disp('fGamma ANOVA')
disp(anova(glme));
[p1, F1, DF11, DF21] = coefTest(glme, [1 0]);
disp(['fGamma ' 'CS1 vs Baseline ' 'p=' num2str(p1*10) ' F=' num2str(F1) ' DF1=' num2str(DF11) ' DF2=' num2str(DF21)]);
[p2, F2, DF12, DF22] = coefTest(glme, [1 -1]);
disp(['fGamma ' 'CS2 vs Baseline ' 'p=' num2str(p2*10) ' F=' num2str(F2) ' DF1=' num2str(DF12) ' DF2=' num2str(DF22)]);
[p, F, DF1, DF2] = coefTest(glme, [0 1]);
disp(['fGamma ' 'CS1 vs CS2 ' 'p=' num2str(p) ' F=' num2str(F) ' DF1=' num2str(DF1) ' DF2=' num2str(DF2)]);

% Si es significativo ploteamos la significancia
y_limits = ylim; ylim([y_limits(1) y_limits(2)+0.08*diff(y_limits)]); y_limits = ylim;
hold on;
if p < 0.05 && p >= 0.01
%     y_line = y_limits(2) - 0.08 * diff(y_limits); % Position for the line
    y_line = pvalpos; % Position for the line
    plot([xPositions(1), xPositions(2)], [y_line, y_line], 'k-'); % Horizontal line connecting the groups
    text((xPositions(1)+xPositions(2))/2, y_line + 0.2, '*', 'HorizontalAlignment', 'center', 'FontSize', 10); % Add the asterisk
elseif p < 0.01 && p >= 0.001
%     y_line = y_limits(2) - 0.08 * diff(y_limits); % Position for the line
    y_line = pvalpos; % Position for the line
    plot([xPositions(1), xPositions(2)], [y_line, y_line], 'k-'); % Horizontal line connecting the groups
    text((xPositions(1)+xPositions(2))/2, y_line + 0.2, '**', 'HorizontalAlignment', 'center', 'FontSize', 10); % Add the asterisk
elseif p < 0.001
%     y_line = y_limits(2) - 0.08 * diff(y_limits); % Position for the line
    y_line = pvalpos; % Position for the line
    plot([xPositions(1), xPositions(2)], [y_line, y_line], 'k-'); % Horizontal line connecting the groups
    text((xPositions(1)+xPositions(2))/2, y_line + 0.2, '***', 'HorizontalAlignment', 'center', 'FontSize', 10); % Add the asterisk
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

xlim([0.25 10.75]);
ylim([-3 3]);

hold off;

% Set figure properties
set(gca, 'XTick', [1.5 3.5 5.5 7.5 9.5]); % Establecer las posiciones de los xticks
set(gca, 'XTickLabel', {'4-Hz', 'Theta', 'Beta', 'sGamma', 'fGamma'}); % Etiquetas personalizadas
ylabel(['Potencia (z-score)']); % Label for y-axis
set(gca, 'FontSize', 7);
set(gcf, 'Color', 'white');
set(gcf, 'Position', [200, 100, 220 120]);
