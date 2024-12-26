%% Comparaciones de los eventos de freezing en diferentes condiciones
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc
clear all

rats = [11,12,13,17,18,19,20]; % Filtro por animales para aversivo.
paradigm_toinclude = 'aversive'; % Filtro por el paradigma
session_toinclude = {'EXT1','EXT2','TEST'}; % Filtro por las sesiones
region = 'BLA'; % Región cerebral que quiero analizar: BLA, PL, IL, EO.
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

% Calculamos el ratio 4-hz:Theta
PowerSheet.FzType_BLA = NaN(size(PowerSheet.FourHz_BLA));
for i = 1:size(PowerSheet.FourHz_BLA)
    if ~isnan(PowerSheet.FourHz_BLA(i)) && ~isnan(PowerSheet.Theta_BLA(i))
        PowerSheet.FzType_BLA(i) = PowerSheet.FourHz_BLA(i) ./ PowerSheet.Theta_BLA(i);
    end
end

PowerSheet.FzType_PL = NaN(size(PowerSheet.FourHz_PL));
for i = 1:size(PowerSheet.FourHz_PL)
    if ~isnan(PowerSheet.FourHz_PL(i)) && ~isnan(PowerSheet.Theta_PL(i))
        PowerSheet.FzType_PL(i) = PowerSheet.FourHz_PL(i) ./ PowerSheet.Theta_PL(i);
    end
end

PowerSheet.FzType_IL = NaN(size(PowerSheet.FourHz_IL));
for i = 1:size(PowerSheet.FourHz_IL)
    if ~isnan(PowerSheet.FourHz_IL(i)) && ~isnan(PowerSheet.Theta_IL(i))
        PowerSheet.FzType_IL(i) = PowerSheet.FourHz_IL(i) ./ PowerSheet.Theta_IL(i);
    end
end

% Juntamos ambos set de datos por ID
MergedSheet = join(PowerSheet, EventsSheet, 'Keys', 'ID');

% Filtramos solo los eventos de freezing
MergedSheet = MergedSheet(ismember(MergedSheet.Event, event), :);