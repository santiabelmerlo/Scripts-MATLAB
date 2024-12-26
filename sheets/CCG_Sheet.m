%% CCG durante todos los eventos de EventsSheet.csv
% Me calcula y guarda la cross-correlación (CCG), el lag de máxima correlación (lag),
% los tiempos del vector de cross-correlación (t) y los nombres de las
% columbas (column_names).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc
clear all

% rats = 10:20;
rats = [11,12,13,17,18,19,20]; % Filtro por animales para aversivo.
paradigm_toinclude = 'aversive'; % Filtro por el paradigma
session_toinclude = {'EXT1','EXT2','TEST'}; % Filtro por las sesiones
Fs = 1250; % Sample rate original de la señal (Hz)

% Calculamos algunas variables que son constantes
LAG1 = [];
LAG2 = [];
LAG3 = [];
MAXCCG1 = [];
MAXCCG2 = [];
MAXCCG3 = [];
CCG1 = {};
CCG2 = {};
CCG3 = {};
t_CCG = {};
ID = [];

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
            if exist(strcat(name, '_lfp.dat')) && ...
                    exist(strcat(name, '_timestamps.npy')) && ...
                    exist(strcat(name, '_freezing.mat')) && ...
                    exist(strcat(name, '_epileptic.mat')) && ...
                    strcmp(paradigm,paradigm_toinclude) && ...
                    any(strcmp(session, session_toinclude))||any(strcmp(session_end, session_toinclude));
                disp(['  All required files exists. Performing action...']);
                
                % Filtramos la tabla para quedarme con los IDs, y los timestamps de inicio y fin.
                filteredTable = EventsSheet(EventsSheet.Rat == r, :);
                filteredTable = filteredTable(strcmp(filteredTable.Name, name), :);
                event_ID = filteredTable.ID;
                event_inicio = filteredTable.Inicio;
                event_fin = filteredTable.Fin;
                
                % The file exists, do something
                ch_BLA = BLA_mainchannel;
                ch_PL = PL_mainchannel;
                ch_IL = IL_mainchannel;

                % BLA
                if ~isempty(ch_BLA)
                    % Cargamos la señal de BLA
                    lfp_BLA = LoadBinary(strcat(name,'_lfp.dat'), ch_BLA, ch_total); % Cargamos la señal
                    lfp_BLA = lfp_BLA * 0.195; % Convertir un canal de registro de bits a microvolts (uV)
                    lfp_BLA = zpfilt(lfp_BLA,1250,0.1,300); % Filtramos la señal entre 0.1 y 300
                    lfp_BLA = zscorem(lfp_BLA); % Lo normalizamos con zscore
                    filt_BLA(1,:) = zpfilt(lfp_BLA,1250,2,5.3); % Filtramos la señal en 4-Hz
                    filt_BLA(2,:) = zpfilt(lfp_BLA,1250,5.3,9.6); % Filtramos la señal en theta
                    filt_BLA(3,:) = zpfilt(lfp_BLA,1250,13,30); % Filtramos la señal en beta
                    filt_BLA(4,:) = zpfilt(lfp_BLA,1250,43,60); % Filtramos la señal en sgamma
                    filt_BLA(5,:) = zpfilt(lfp_BLA,1250,60,98); % Filtramos la señal en fgamma
                    t = 1/Fs_lfp:1/Fs_lfp:size(lfp_BLA,2)/Fs_lfp;
                end

                % PL
                if ~isempty(ch_PL)
                    % Cargamos la señal del PL
                    lfp_PL = LoadBinary(strcat(name,'_lfp.dat'), ch_PL, ch_total);
                    lfp_PL = lfp_PL * 0.195; % Convertir un canal de registro de bits a microvolts (uV).
                    lfp_PL = zpfilt(lfp_PL,1250,0.1,300); % Filtramos la señal entre 0.1 y 300
                    lfp_PL = zscorem(lfp_PL); % Lo Normalizamos con Zscore
                    filt_PL(1,:) = zpfilt(lfp_PL,1250,2,5.3); % Filtramos la señal en 4-Hz
                    filt_PL(2,:) = zpfilt(lfp_PL,1250,5.3,9.6); % Filtramos la señal en theta
                    filt_PL(3,:) = zpfilt(lfp_PL,1250,13,30); % Filtramos la señal en beta
                    filt_PL(4,:) = zpfilt(lfp_PL,1250,43,60); % Filtramos la señal en sgamma
                    filt_PL(5,:) = zpfilt(lfp_PL,1250,60,98); % Filtramos la señal en fgamma
                    t = 1/Fs_lfp:1/Fs_lfp:size(lfp_PL,2)/Fs_lfp;
                end

                % IL
                if ~isempty(ch_IL)
                    % Cargamos la señal del PL
                    lfp_IL = LoadBinary(strcat(name,'_lfp.dat'), ch_IL, ch_total);
                    lfp_IL = lfp_IL * 0.195; % Convertir un canal de registro de bits a microvolts (uV).
                    lfp_IL = zpfilt(lfp_IL,1250,0.1,300); % Filtramos la señal entre 0.1 y 300
                    lfp_IL = zscorem(lfp_IL); % Lo Normalizamos con Zscore
                    filt_IL(1,:) = zpfilt(lfp_IL,1250,2,5.3); % Filtramos la señal en 4-Hz
                    filt_IL(2,:) = zpfilt(lfp_IL,1250,5.3,9.6); % Filtramos la señal en theta
                    filt_IL(3,:) = zpfilt(lfp_IL,1250,13,30); % Filtramos la señal en beta
                    filt_IL(4,:) = zpfilt(lfp_IL,1250,43,60); % Filtramos la señal en sgamma
                    filt_IL(5,:) = zpfilt(lfp_IL,1250,60,98); % Filtramos la señal en fgamma
                    t = 1/Fs_lfp:1/Fs_lfp:size(lfp_IL,2)/Fs_lfp;
                end

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % Analizamos GCI solo si tenemos las tres señales
                if exist('lfp_BLA') && exist('lfp_PL') && exist('lfp_IL')
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    
                    % Comenzamos el análisis de PLV
                    disp(['  Calculating Cross Correlogram...']);
                    for frange = 1:5;
                        for i = 1:size(event_inicio,1)
                            disp(['  Processing event: ' num2str(i) ' of ' num2str(size(event_inicio,1)) ' from rat ' num2str(r) ' and session ' name]);
                            if ~isempty(event_inicio)
                                max_samples = ceil(median(event_fin(i) - event_inicio(i)) * Fs);
                                [X1(1,:), X1(2,:), X1(3,:)] = extract_segments(filt_BLA(frange,:), filt_PL(frange,:), filt_IL(frange,:), t, event_inicio(i), event_fin(i), max_samples);
                            end                            

                            [c1, lag] = xcorr(X1(1,:),X1(2,:), Fs, 'coeff');
                            [c2, lag] = xcorr(X1(1,:),X1(3,:), Fs, 'coeff');
                            [c3, lag] = xcorr(X1(2,:),X1(3,:), Fs, 'coeff');
                            lag = (lag/1250)*1000; % Transformamos los lags a ms
                            lag1(i,frange) = lag(find(c1 == max(c1))); % lag BLA-PL
                            lag2(i,frange) = lag(find(c2 == max(c2))); % lag BLA-IL
                            lag3(i,frange) = lag(find(c3 == max(c3))); % lag PL-IL
                            maxccg1(i,frange) = max(max(c1)); % Máxima cross-correlación BLA-PL
                            maxccg2(i,frange) = max(max(c2)); % Máxima cross-correlación BLA-IL
                            maxccg3(i,frange) = max(max(c3)); % Máxima cross-correlación PL-IL
                            ccg1{i,frange} = c1; % Correlación BLA-PL
                            ccg2{i,frange} = c2; % Correlación BLA-IL
                            ccg3{i,frange} = c3; % Correlación PL-IL
                            t_ccg{i,1} = lag; % Tiempos de la crosscorrelación

                            clear c1 c2 c3 lag X1;                   
                        end
                    end
                    LAG1 = cat(1,LAG1,lag1);
                    LAG2 = cat(1,LAG2,lag2);
                    LAG3 = cat(1,LAG3,lag3);
                    CCG1 = cat(1,CCG1,ccg1);
                    CCG2 = cat(1,CCG2,ccg2);
                    CCG3 = cat(1,CCG3,ccg3);
                    MAXCCG1 = cat(1,MAXCCG1,maxccg1);
                    MAXCCG2 = cat(1,MAXCCG2,maxccg2);
                    MAXCCG3 = cat(1,MAXCCG3,maxccg3);
                    t_CCG = cat(1,t_CCG,t_ccg);
                    ID = vertcat(ID,event_ID);
                    clear lag1 lag2 lag3 ccg1 ccg2 ccg3 t_ccg maxccg1 maxccg2 maxccg3;
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                end
                
                clear lfp_BLA lfp_PL lfp_IL X1 filt_BLA filt_PL filt_IL
                
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

% Etiquetas de frecuencias y regiones
frequency_labels = {'FourHz', 'Theta', 'Beta', 'sGamma', 'fGamma'}; % Labels for the 5 frequencies
region_labels = {'BLAPL', 'BLAIL', 'PLIL'}; % Labels for the 3 regions

% Inicializamos una celda vacía para almacenar los nombres de las columnas
column_names = cell(1, 15);

% Crear los nombres de las columnas siguiendo el orden deseado
col_index = 1;
% Primero las columnas para BLAPL
for freq = 1:5
    column_names{col_index} = [frequency_labels{freq} '_' region_labels{1}]; % BLAPL
    col_index = col_index + 1;
end
% Luego las columnas para BLAIL
for freq = 1:5
    column_names{col_index} = [frequency_labels{freq} '_' region_labels{2}]; % BLAIL
    col_index = col_index + 1;
end
% Finalmente las columnas para PLIL
for freq = 1:5
    column_names{col_index} = [frequency_labels{freq} '_' region_labels{3}]; % PLIL
    col_index = col_index + 1;
end

% Combine all data into a single matrix
CCG = [num2cell(ID), CCG1, CCG2, CCG3];
maxCCG = [ID, MAXCCG1, MAXCCG2, MAXCCG3];
lag = [ID, LAG1, LAG2, LAG3];
t = [num2cell(ID), t_CCG];
t = t{1,2};

% Create a table with the first column as ID and the rest from the combined data
column_names = [{'ID'}, column_names];

clearvars -except CCG lag t column_names parentFolder maxCCG

Lag_Sheet = array2table(lag, 'VariableNames', column_names);
maxCCG_Sheet = array2table(maxCCG, 'VariableNames', column_names);

cd(parentFolder);
disp('Ready!');

% Save the table as a CSV file
cd('D:\Doctorado\Analisis\Sheets');
writetable(Lag_Sheet, 'Lag_Sheet.csv'); % Guardamos la tabla
writetable(maxCCG_Sheet, 'maxCCG_Sheet.csv'); % Guardamos la tabla
save('CCG_Sheet.mat', 'CCG','lag','t','maxCCG','column_names','-v7.3');