%% Calculamos la potencia de cada evento con el dato de wavelets normalizado a la mediana.
% Guardamos una tabla NormPowerWavelets.csv con los datos de potencia
% normalizada de cada región para cada evento

clc
clear all

rats = [11,12,13,17,18,19,20]; % Filtro por animales para aversivo.
paradigm_toinclude = 'aversive'; % Filtro por el paradigma
session_toinclude = {'EXT1','EXT2','TEST'}; % Filtro por las sesiones

% Calculamos algunas variables que son constantes
PowerWavelets = table();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Define the parent folder containing the 'Rxx' folders
parentFolder = 'D:\Doctorado\Backup Ordenado';

% List all 'Rxx' folders in the parent folder
R_folders = dir(fullfile(parentFolder, 'R*'));

% Cargamos la tabla de EventsSheet
cd('D:\Doctorado\Analisis\Sheets');
EventsSheet = readtable('EventsSheet.csv');

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
        
        if exist(strcat(name,'_sessioninfo.mat')) == 2;
            session_end = [];
            load(strcat(name,'_sessioninfo.mat'));
            if  strcmp(paradigm,paradigm_toinclude) && ...
                any(strcmp(session, session_toinclude))||any(strcmp(session_end, session_toinclude));
                disp(['  All required files exists. Performing action...']);
                
                % Filtramos la tabla para quedarme con los IDs, y los timestamps de inicio y fin.
                filteredTable = EventsSheet(EventsSheet.Rat == r, :);
                filteredTable = filteredTable(strcmp(filteredTable.Name, name), :);
                filteredTable = filteredTable(strcmp(filteredTable.Event, 'Freezing'), :);
                event_ID = filteredTable.ID;
                event_inicio = filteredTable.Inicio;
                event_fin = filteredTable.Fin;

                if exist([name,'_wavelet.mat'])
                    load([name,'_wavelet.mat']);
                    
                    % Zscoreamos las señales
                    if ~isempty(wave_BLA_4Hz)
                        wave_BLA_4Hz = bsxfun(@rdivide, wave_BLA_4Hz, median(wave_BLA_4Hz,2));
                        wave_BLA_Theta = bsxfun(@rdivide, wave_BLA_Theta, median(wave_BLA_Theta,2));
                    end
                    if ~isempty(wave_IL_4Hz)
                        wave_IL_4Hz = bsxfun(@rdivide, wave_PL_4Hz, median(wave_PL_4Hz,2));
                        wave_IL_Theta = bsxfun(@rdivide, wave_PL_Theta, median(wave_PL_Theta,2));
                    end
                    if ~isempty(wave_PL_4Hz)
                        wave_PL_4Hz = bsxfun(@rdivide, wave_IL_4Hz, median(wave_IL_4Hz,2));
                        wave_PL_Theta = bsxfun(@rdivide, wave_IL_Theta, median(wave_IL_Theta,2));
                    end
                    
                    BLA_4Hz = []; BLA_Theta = [];
                    PL_4Hz = []; PL_Theta = [];
                    IL_4Hz = []; IL_Theta = [];
                    
                    for i = 1:size(event_inicio,1);
                        inicio = []; fin = [];
                        inicio = min(find(abs(t-event_inicio(i)) == min(abs(t-event_inicio(i)))));
                        fin = min(find(abs(t-event_fin(i)) == min(abs(t-event_fin(i)))));
                       
                        if ~isempty(wave_BLA_4Hz)
                            BLA_4Hz(i,1) = nanmedian(wave_BLA_4Hz(1,inicio:fin),2);
                            BLA_Theta(i,1) = nanmedian(wave_BLA_Theta(1,inicio:fin),2);
                        else
                            BLA_4Hz(i,1) = NaN; BLA_Theta(i,1) = NaN;
                        end
                        if ~isempty(wave_PL_4Hz)
                            PL_4Hz(i,1) = nanmedian(wave_PL_4Hz(1,inicio:fin),2);
                            PL_Theta(i,1) = nanmedian(wave_PL_Theta(1,inicio:fin),2);
                        else
                            PL_4Hz(i,1) = NaN; PL_Theta(i,1) = NaN;
                        end
                        if ~isempty(wave_IL_4Hz)
                            IL_4Hz(i,1) = nanmedian(wave_IL_4Hz(1,inicio:fin),2);
                            IL_Theta(i,1) = nanmedian(wave_IL_Theta(1,inicio:fin),2);
                        else
                            IL_4Hz(i,1) = NaN; IL_Theta(i,1) = NaN;
                        end             
                    end
                    
                    T = table(event_ID, event_inicio, event_fin, BLA_4Hz, BLA_Theta, PL_4Hz, PL_Theta, IL_4Hz, IL_Theta);
                    PowerWavelets = [PowerWavelets; T];
                    
                    clear BLA_4Hz BLA_Theta PL_4Hz PL_Theta IL_4Hz IL_Theta wave_BLA_4Hz wave_BLA_Theta wave_PL_4Hz wave_PL_Theta ...
                        wave_IL_4Hz wave_IL_Theta
                    
                end
                
            else
                disp(['  Some required file do not exist.']);
                disp(['  Skipping action...']);
            end
        end
    end
    % Go back to the 'Rxx' folder
    cd(current_R_folder);
end

cd(parentFolder);

cd('D:\Doctorado\Analisis\Sheets');
writetable(PowerWavelets,'NormPowerWavelets.csv');

disp('Ready!');