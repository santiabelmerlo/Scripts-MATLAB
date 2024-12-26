%% Phase Locking Value (PLV) durante todos los eventos de EventsSheet.csv
% Me guarda una tabla llamada PLV_Sheet.csv con los valores de PLV para
% cada frecuencia y cada par de regiones cerebrales.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc
clear all

rats = 10:20;
% rats = [11,12,13,17,18,19,20]; % Filtro por animales para aversivo.
paradigm_toinclude = 'aversive'; % Filtro por el paradigma
session_toinclude = {'EXT1','EXT2','TEST'}; % Filtro por las sesiones
fs = 1250; % Sample rate original de la señal (Hz)

% Calculamos algunas variables que son constantes
plv = [];
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
                
                % Cargamos los datos del timestamps del amplificador
                amplifier_timestamps = readNPY(strcat(name,'_timestamps.npy')); % Cargamos el estado de cada input del IO Board.
                amplifier_timestamps = double(amplifier_timestamps(1):1:amplifier_timestamps(end)); % Hay que hacer esto porque amplifier.timestamps devuelve distinto número de tiempos que de registro.
                amplifier_timestamps_lfp = double(amplifier_timestamps(1):24:amplifier_timestamps(end)); % Subsampleamos a 1250
                t = (amplifier_timestamps_lfp - amplifier_timestamps(1))/30000; % Le restamos el primer timestamp y lo pasamos a segundos.
                clear amplifier_timestamps amplifier_timestamps_lfp
                
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
                end

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % Analizamos GCI solo si tenemos las tres señales
                if exist('lfp_BLA') && exist('lfp_PL') && exist('lfp_IL')
                     
                    
                    % Comenzamos el análisis de PLV
                    disp(['  Calculating Phase Locking Value...']);
                    for frange = 1:5;
                        for i = 1:size(event_inicio,1)
                            disp(['  Processing event: ' num2str(i) ' of ' num2str(size(event_inicio,1))]);
                            if ~isempty(event_inicio)
                                max_samples = ceil(median(event_fin(i) - event_inicio(i)) * fs);
                                [X1(1,:), X1(2,:), X1(3,:)] = extract_segments(filt_BLA(frange,:), filt_PL(frange,:), filt_IL(frange,:), t, event_inicio(i), event_fin(i), max_samples);
                            end                            
                            plvv(i,frange,1) = plv_lfp(X1(1,:),X1(2,:)); % BLA & PL
                            plvv(i,frange,2) = plv_lfp(X1(1,:),X1(3,:)); % BLA & IL
                            plvv(i,frange,3) = plv_lfp(X1(2,:),X1(3,:)); % BLA & PL
                            clear X1;                   
                        end
                    end
                    plv = cat(1,plv,plvv);
                    ID = vertcat(ID,event_ID);
                    clear plvv;
                end
                
                clear lfp_BLA lfp_PL lfp_IL X1 X2 filt_BLA filt_PL filt_IL
                
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

% Creamos la tabla final y guardamos
frequency_labels = {'FourHz', 'Theta', 'Beta', 'sGamma', 'fGamma'}; % Labels for the 5 frequencies
region_labels = {'BLAPL', 'BLAIL', 'PLIL'}; % Labels for the 3 regions

% Initialize an empty cell to store column names
column_names = cell(1, 15);

% Create the column names using the frequency and region labels
col_index = 1;
for freq = 1:5
    for region = 1:3
        column_names{col_index} = [frequency_labels{freq} '_' region_labels{region}];
        col_index = col_index + 1;
    end
end

% Reshape the plv matrix to have 981 rows and 15 columns (combine dimensions 2 and 3)
plv_reshaped = reshape(plv, [size(plv, 1), 15]);

% Create the table with ID as the first column and the reshaped plv data in the next 15 columns
T = table(ID, plv_reshaped(:,1), plv_reshaped(:,2), plv_reshaped(:,3), plv_reshaped(:,4), ...
          plv_reshaped(:,5), plv_reshaped(:,6), plv_reshaped(:,7), plv_reshaped(:,8), ...
          plv_reshaped(:,9), plv_reshaped(:,10), plv_reshaped(:,11), plv_reshaped(:,12), ...
          plv_reshaped(:,13), plv_reshaped(:,14), plv_reshaped(:,15), ...
          'VariableNames', [{'ID'}, column_names]);

T = sortrows(T, 'ID'); % Ordenamos por ID
      
cd('D:\Doctorado\Analisis\Sheets');
writetable(T, 'PLV_Sheet.csv'); % Guardamos la tabla

cd(parentFolder);
disp('Ready!');