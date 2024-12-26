%% Fz Proportions
clc
clear all

% Cargamos los datos
cd('D:\Doctorado\Analisis\Sheets');
EventsSheet = readtable('EventsSheet.csv');
FzType = readtable('FzType_Sheet.csv');
df = join(FzType, EventsSheet, 'Keys', 'ID');

rats = [11,12,13,17,18,19,20]; % Filtro por animales para aversivo.
trials = [1:4]; % Trials que quiero analizar
% trials = [17:20]; % Trials que quiero analizar
session_toinclude = {'EXT1'}; % Filtro por las sesiones
event = 'Movement';
types = 1; % Tipo de evento que quiero filtrar: CS+, CS-, preCS, ITI

% Filtramos la tabla con las distintas condiciones
df = df(ismember(df.Rat, rats), :);
df = df(df.noisy == 0, :);
df = df(df.Epileptic == 0, :);
if ~isempty(types); df = df(df.Type == types, :); end
df = df(ismember(df.Session, session_toinclude), :);
if ~isempty(trials); df = df(ismember(df.Trial, trials), :); end
if ~isempty(event); df = df(ismember(df.Event, event), :); end

df.Ratio = df.FourHz_BLA ./ df.Theta_BLA;
for i = 1:height(df)
    if isnan(df.Ratio(i))
        df.FzType(i) = NaN;
    elseif df.Ratio(i) > 1
        df.FzType(i) = 1;
    elseif df.Ratio(i) <= 1   
        df.FzType(i) = 0;
    end
end

% Calculate counts
count_4Hz = sum(df.FzType == 1); % Number of 4Hz-Fz
count_Theta = sum(df.FzType == 0); % Number of Theta-Fz

% Calculate proportions
total = count_4Hz + count_Theta;
prop_4Hz = count_4Hz / total; % Proportion of 4Hz-Fz
prop_Theta = count_Theta / total; % Proportion of Theta-Fz

% Perform chi-squared test
observed = [count_4Hz, count_Theta];
expected = mean(observed) * ones(size(observed)); % Equal expected proportions
[h, p, stats] = chi2gof(1:2, 'Frequency', observed, 'Expected', expected);

% Plot bars individually with specific colors
figure;
subplot(121);
data = [count_4Hz, count_Theta];
bar(1, data(1), 'FaceColor', [1, 0, 0]); % Red for the first bar
hold on;
bar(2, data(2), 'FaceColor', [18, 183, 211]/255); % Cyan for the second bar
% Customize axes
set(gca, 'XTick', [1, 2], 'XTickLabel', {'4Hz-Mv', 'Theta-Mv'}, 'FontSize', 12);
ylabel('Count');
xlim([0.3, 2.7]);
ylim([0, 80]);

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

subplot(122);
data = [prop_4Hz, prop_Theta];
bar(1, data(1), 'FaceColor', [1, 0, 0]); % Red for the first bar
hold on;
bar(2, data(2), 'FaceColor', [18, 183, 211]/255); % Cyan for the second bar
% Customize axes
set(gca, 'XTick', [1, 2], 'XTickLabel', {'4Hz-Mv', 'Theta-Mv'}, 'FontSize', 12);
ylabel('Proportion');
ylim([0 1]);
xlim([0.3 2.7]);

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

% Set figure properties
set(gcf, 'Color', 'white');
set(gcf, 'Position', [200, 100, 500 300]);