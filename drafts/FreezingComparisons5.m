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
parentFolder = 'D:\Doctorado\Backup Ordenado';

% List all 'Rxx' folders in the parent folder
R_folders = dir(fullfile(parentFolder, 'R*'));

% Cargamos los datos
cd('D:\Doctorado\Analisis\Sheets');
EventsSheet = readtable('EventsSheet.csv');
PowerSheet = readtable('Power_Sheet.csv');

% Calculamos el ratio 4-hz:Theta y guardamos como 0 o 1 si son 4hz o theta
% enriched
PowerSheet.FzType_BLA = NaN(size(PowerSheet.FourHz_BLA));
for i = 1:size(PowerSheet.FourHz_BLA)
    if ~isnan(PowerSheet.FourHz_BLA(i)) && ~isnan(PowerSheet.Theta_BLA(i))
        PowerSheet.FzType_BLA(i) = ~(PowerSheet.FourHz_BLA(i) >= PowerSheet.Theta_BLA(i));
    end
end

PowerSheet.FzType_PL = NaN(size(PowerSheet.FourHz_PL));
for i = 1:size(PowerSheet.FourHz_PL)
    if ~isnan(PowerSheet.FourHz_PL(i)) && ~isnan(PowerSheet.Theta_PL(i))
        PowerSheet.FzType_PL(i) = ~(PowerSheet.FourHz_PL(i) >= PowerSheet.Theta_PL(i));
    end
end

PowerSheet.FzType_IL = NaN(size(PowerSheet.FourHz_IL));
for i = 1:size(PowerSheet.FourHz_IL)
    if ~isnan(PowerSheet.FourHz_IL(i)) && ~isnan(PowerSheet.Theta_IL(i))
        PowerSheet.FzType_IL(i) = ~(PowerSheet.FourHz_IL(i) >= PowerSheet.Theta_IL(i));
    end
end

% Inicializamos las variables para guardar los resultados
numRows = size(PowerSheet, 1);
sameValue = 0; % Filas con el mismo valor (1 o 0) en las tres columnas (excluyendo NaN)
twoValues = 0; % Filas con el mismo valor en dos de las tres columnas
oneValue = 0; % Filas con solo un valor válido

% Iteramos por cada fila para calcular los casos
for i = 1:numRows
    if isnan(PowerSheet.FzType_BLA(i)) && isnan(PowerSheet.FzType_PL(i)) && isnan(PowerSheet.FzType_IL(i))
    else
        if PowerSheet.FzType_BLA(i) == PowerSheet.FzType_PL(i) && PowerSheet.FzType_BLA(i) == PowerSheet.FzType_IL(i) && PowerSheet.FzType_IL(i) == PowerSheet.FzType_PL(i)
            sameValue = sameValue + 1;
        elseif PowerSheet.FzType_BLA(i) ~= PowerSheet.FzType_PL(i) && PowerSheet.FzType_BLA(i) ~= PowerSheet.FzType_IL(i) && PowerSheet.FzType_IL(i) ~= PowerSheet.FzType_PL(i)
            oneValue = oneValue + 1;
        else
            twoValues = twoValues + 1;
        end
    end
end

% Calculamos los porcentajes
totalValidRows = sameValue + twoValues + oneValue;
percentSameValue = (sameValue / totalValidRows) * 100;
percentTwoValues = (twoValues / totalValidRows) * 100;
percentOneValue = (oneValue / totalValidRows) * 100;

% Mostramos los resultados
fprintf('Porcentaje con el mismo valor en las tres columnas: %.2f%%\n', percentSameValue);
fprintf('Porcentaje con el mismo valor en dos columnas: %.2f%%\n', percentTwoValues);
fprintf('Porcentaje con el mismo valor en una sola columna: %.2f%%\n', percentOneValue);

% Graficamos los resultados
figure;
pie([percentSameValue, percentTwoValues, percentOneValue], ...
    {'Tres regiones', 'Dos regiones', 'Una región'});
title('Consistencia en la detección');
