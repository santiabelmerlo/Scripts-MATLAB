%% Comparamos distribuciuones de potencia y de power ratio
clc
clear all

cd('D:\Doctorado\Analisis\Sheets');
EventsSheet = readtable('EventsSheet.csv');
FzTypeSheet = readtable('NormPower_Sheet.csv');

% Eliminar las filas con ID repetido
[~, uniqueIdx] = unique(FzTypeSheet.ID, 'stable');  % 'stable' mantiene el orden original
FzTypeSheet = FzTypeSheet(uniqueIdx, :);  % Selecciona solo las filas únicas

% Calculamos la media entre los ratios de BLA, PL e IL
FzTypeSheet.Ratio = nanmean([FzTypeSheet.FourHz_BLA ./ FzTypeSheet.Theta_BLA, FzTypeSheet.FourHz_PL ./ FzTypeSheet.Theta_PL, FzTypeSheet.FourHz_IL ./ FzTypeSheet.Theta_IL], 2);

% Inicializar la columna 'Enrich' como un array de tipo cell de char
FzTypeSheet.Enrich = cell(height(FzTypeSheet), 1); % Llena toda la columna con celdas vacías

% Asignar 'NaN' a las filas donde Ratio es NaN
FzTypeSheet.Enrich(isnan(FzTypeSheet.Ratio)) = {'NaN'};  % Usar una celda con el valor 'NaN'

% Asignar '4Hz' a las filas donde Ratio > 1
FzTypeSheet.Enrich(FzTypeSheet.Ratio > 1) = {'4Hz'};  % Usar una celda con el valor '4Hz'

% Asignar 'Theta' a las filas donde Ratio <= 1
FzTypeSheet.Enrich(FzTypeSheet.Ratio <= 1) = {'Theta'};  % Usar una celda con el valor 'Theta'

% Unir las tablas EventsSheet y FzTypeSheet usando 'ID' como clave
MergedSheet = join(EventsSheet, FzTypeSheet(:, {'ID', 'Ratio', 'Enrich'}), 'Keys', 'ID');

writetable(MergedSheet, 'EventsSheet.csv'); % Normalizando a la mediana de cada frecuencia

disp('Ready!');
