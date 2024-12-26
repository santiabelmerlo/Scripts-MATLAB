%% Fig002: PSD comparando CS+ y CS- en un momento de la sesión
% Ploteamos PSDs de CS+ y CS- en bajas frecuencias y en altas.

clc
clear all

% Seteamos algunos parámetros para filtrar los datos
Event = {'CS1';'CS2'};
Rat = [11,12,13,17,18,19,20];
Session = 'EXT2';
Region = 'BLA';
Trial = [10:20];
Type = [1,2];
smoothing = 20; % Nivel de smoothing que quiero aplicarle a la curva de PSD

% Cargamos datos de los sheets
cd('D:\Doctorado\Analisis\Sheets');
load('PSD_Sheet.mat');
EventsSheet = readtable('EventsSheet.csv');

% Filtramos la tabla de EventsSheet
EventsSheet = EventsSheet(ismember(EventsSheet.Event,Event),:);
EventsSheet = EventsSheet(ismember(EventsSheet.Rat,Rat),:);
EventsSheet = EventsSheet(ismember(EventsSheet.Session,Session),:);
EventsSheet = EventsSheet(ismember(EventsSheet.Trial,Trial),:);
EventsSheet = EventsSheet(ismember(EventsSheet.Type,Type),:);

% Filtramos los eventos ruidosos
EventsSheet = EventsSheet(EventsSheet.noisy == 0,:);
EventsSheet = EventsSheet(EventsSheet.Epileptic <= 1,:);
EventsSheet = EventsSheet(EventsSheet.Flat <= 1,:);

% Buscamos las columnas que nos interesan de PSD_Sheet
column_a = find(strcmp(column_names,'ID'));
column_b = find(strcmp(column_names,Region));
A = PSD_Sheet(:,[column_a,column_b]);

% Filtro los PSD según los grupos que quiero obtener
ID1 = EventsSheet.ID(ismember(EventsSheet.Event, Event(1)));
ID2 = EventsSheet.ID(ismember(EventsSheet.Event, Event(2)));

% Extraer los IDs del cell array PSD_Sheet (primera columna)
PSD1 = cell2mat(PSD_Sheet(ismember(cell2mat(PSD_Sheet(:,column_a)), ID1), column_b));
PSD2 = cell2mat(PSD_Sheet(ismember(cell2mat(PSD_Sheet(:,column_a)), ID2), column_b));

% Ahora ploteo lineas de con barras de error
% Plot the results
figure;
hold on;

% Plot para CS+
y = smooth(nanmedian(PSD1, 1), smoothing)'; % Valores medios
error = smooth(mad(PSD1, 0, 1) / sqrt(size(PSD1, 1)), smoothing)'; % SEM
error(error >= 0.3) = 0.3;
curve1 = y + error; % Límite superior
curve2 = y - error; % Límite inferior
validIdx = f > 0; % Filtrar valores no válidos
f_valid = f(validIdx); % Filtrar frecuencias válidas
curve1_valid = curve1(validIdx);
curve2_valid = curve2(validIdx);
y = y(validIdx);
x2 = [f_valid, fliplr(f_valid)];
inBetween = [curve1_valid, fliplr(curve2_valid)];
p1 = fill(x2, inBetween, colores('Aversivo'), 'FaceAlpha', 0.4, 'EdgeColor', 'none', 'HandleVisibility', 'off');
plot(f_valid, y, 'Color', colores('Aversivo'), 'LineWidth', 1.5, 'DisplayName', 'CS+');

% Plot para CS-
y = smooth(nanmedian(PSD2, 1), smoothing)'; % Valores medios
error = smooth(mad(PSD2, 0, 1) / sqrt(size(PSD2, 1)), smoothing)'; % SEM
error(error >= 0.3) = 0.3;
curve1 = y + error; % Límite superior
curve2 = y - error; % Límite inferior
curve1_valid = curve1(validIdx);
curve2_valid = curve2(validIdx);
y = y(validIdx);
x2 = [f_valid, fliplr(f_valid)];
inBetween = [curve1_valid, fliplr(curve2_valid)];
p2 = fill(x2, inBetween, colores('Control'), 'FaceAlpha', 0.4, 'EdgeColor', 'none', 'HandleVisibility', 'off');
plot(f_valid, y, 'Color', colores('Control'), 'LineWidth', 1.5, 'DisplayName', 'CS-');

% Configuraciones del gráfico
xlim([1 100]);
ylim([0 6]);
set(gca, 'XScale', 'log'); % Escala logarítmica en eje X
set(gca, 'XTick', [1 2 4 8 16 32 64 100], 'XTickLabel', {'1', '2', '4', '8', '16', '32', '64', '100'});
set(gca, 'XMinorTick', 'off');
set(gca, 'YTick', [0:1:6]);
xlabel('Frecuencia (Hz)');
ylabel('Potencia Normalizada');
legend('hide');
title('');

% Personalización de la figura
set(gca, 'FontSize', 7);
set(gcf, 'Color', 'white');
set(gcf, 'Position', [100, 500, 150, 120]);

hold off;