%% MVGC (Multivariate Granger Causality Analysis) para todos los eventos de la tabla EventsSheet que tengan 
% registro en simultáneo de BLA, PL e IL. 
% Me crea una nueva tabla llamada EventsSheet_MVGC.csv que va a tener
% nuevas columnas con los valores de GC.
% Nuevas columnas: BLAtoPL_4hz, PLtoBLA_4hz, BLAtoIL_4hz, ILtoBLA_4hz,
% PLtoIL_4hz, ILtoPL_4hz, etc.

% Funciones del toolbox que voy a usar y sus utilidades:
% tsdata_to_infocrit: a partir de la serie temporal (X) busco algun criterio (AIC o BIC) para establecer un orden del modelo (morder). Una vez establecido fijarlo para todos mis análisis.
% tsdata_to_var: Estimamos el modelo VAR a partir de la serie temporal (X) y obtengo A y SIG
% var_to_autocov: Estimamos la secuencia de autocovarianza (G,info) a partir del modelo VAR (A,SIG)
% autocov_to_pwcgc: Calculamos el GCI en el dominio del tiempo (F) a partir de la autocovarianza (G)
% autocov_to_spwcgc: Calculamos el GCI en el dominio de frecuencias (f) para la combinación de las 3 estructuras y a partir de la autocovarianza (G)
% autocov_to_smvgc: Calculamos el GCI en el dominio de frecuencias (f) para un par de estructuras determinado y a partir de la autocovarianza (G)
% smvgc_to_mvgc: Integramos el GCI espectral en el tiempo y en un rango de frecuencias determinado (Fint) a partir de f

% Output de este script:
% lam: vector de frecuencias 
% regions: matriz de 3 valores conteniendo strings con la region cerebral
% timeww: matriz de n valores conteniendo strings con la ventana de tiempo analizada: Ej: 'preCS', 'CS1', 'CS2', 'postCS'
% FFint: una para cada banda frecuencial conteniendo (3x3xnxtimeww) valores de GCI
% FF: matriz (3x3xnxtimeww) conteniendo los valores GCI de todo el rango frecuencial
% ff: matriz (3x3xfresxnxtimeww) conteniendo los GCI en el dominio de las frecuencias
% n: es el número de trials que estoy incluyendo total en el análisis, sumando todos los animales y sesiones que entraron en el análisis

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc
clear all

% En estas lineas selecciono que animales, paradigma y sesiones quiero analizar
% rats = [10,11,13,14,16,17,18,19]; % Filtro por animales para apetitivo
% rats = [11,12,13,17,18,19,20]; % Filtro por animales para aversivo.

% Animales listos: 10,11,13,14,15,16,17,18,19,20
% rats = [11,13,17,18,19,20];
% rats = [10,12,14,15,16];
rats = 12;

paradigm_toinclude = 'aversive'; % Filtro por el paradigma
% session_toinclude = {'EXT1','EXT2','TEST'}; % Filtro por las sesiones
session_toinclude = {'EXT2'}; % Filtro por las sesiones

% Seteamos algunas variables que van a ser constantes a lo largo de todo el analisis
regions = {'BLA','PL','IL'}; % Regiones del cerebro que voy a analizar
ntrials   = 1;           % El número de trials o series temporales que va a analizar el modelo por vez
regmode   = 'LWR';       % VAR model estimation regression mode ('OLS', 'LWR' or empty for default)
icregmode = 'LWR';       % information criteria regression mode ('OLS', 'LWR' or empty for default)
morder    = 'actual';    % model order to use ('actual', 'AIC', 'BIC' or supplied numerical value)
amo       = 8;          % Select a model order if morder is in 'actual'. Default 13 a 250 Hz lo equivale a 50 ms. O 65 en 1250 Hz.
morder    = amo;         % Una vez que fijamos amo, seteamos el morder en 13 (50 ms)
momax     = 100;         % maximum model order for model order estimation
tstat     = '';          % statistical test for MVGC:  'F' for Granger's F-test (default) or 'chi2' for Geweke's chi2 test
alpha     = 0.05;        % significance level for significance test
mhtc      = 'FDR';       % multiple hypothesis test correction (see routine 'significance')
fs        = 250;         % Sample rate (Hz) luego de subsamplear para analizar GCI
Fs        = 1250;        % Sample rate original de la señal (Hz)
fres      = fs*50;       % Resolución de freq como cantidad de datos que quiero desde 0 a 250 Hz. Este valor es para igualar la resolucion que tengo en los espectrogramas multitaper. 1576 en 250Hz y 8195 en 1250 Hz.
nvars     = 3;           % numero de estructuras que voy a correlacionar. 3 (BLA, PL e IL)
SIGT      = eye(nvars);  % Residuals covariance matrix.
seed      = 0;           % random seed (0 for unseeded)
acmaxlags = [];          % maximum autocovariance lags (empty for automatic calculation)
modelestimation = false; % flag para determinar si calcular el órden del modelo o no

% Calculamos algunas variables que son constantes
lam = sfreqs(fres,fs)'; % Vector de frecuencias de 0 a fs
ID_stack = []; % Inicializamos ID_stack
f_stack = []; % Inicializamos f_stack
noisy_stack = []; % Inicializamos noisy_stack

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Define the parent folder containing the 'Rxx' folders
parentFolder = 'D:\Doctorado\Backup Ordenado';

% List all 'Rxx' folders in the parent folder
R_folders = dir(fullfile(parentFolder, 'R*'));

% Cargamos la tabla de EventsSheet
cd('D:\Doctorado\Analisis\Sheets');
EventsSheet_MVGC = readtable('EventsSheet.csv');

% Iterate through each 'Rxx' folder
k = 1;
for r = rats
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
                    strcmp(paradigm,paradigm_toinclude) && ...
                    any(strcmp(session, session_toinclude))||any(strcmp(session_end, session_toinclude));
                disp(['  All required files exists. Performing action...']);
                
                % Cargamos los datos del timestamps del amplificador
                amplifier_timestamps = readNPY(strcat(name,'_timestamps.npy')); % Cargamos el estado de cada input del IO Board.
                amplifier_timestamps = double(amplifier_timestamps(1):1:amplifier_timestamps(end)); % Hay que hacer esto porque amplifier.timestamps devuelve distinto número de tiempos que de registro.
                amplifier_timestamps_lfp = double(amplifier_timestamps(1):24:amplifier_timestamps(end)); % Subsampleamos a 1250
                t = (amplifier_timestamps_lfp - amplifier_timestamps(1))/30000; % Le restamos el primer timestamp y lo pasamos a segundos.
                t = downsample(t,5); % Lo downsampleamos a 250 Hz.
                clear amplifier_timestamps amplifier_timestamps_lfp

                % Filtramos la tabla para quedarme con los IDs, y los timestamps de inicio y fin.
                filteredTable = EventsSheet_MVGC(EventsSheet_MVGC.Rat == r, :);
                filteredTable = filteredTable(strcmp(filteredTable.Name, name), :);
                event_ID = filteredTable.ID;
                event_inicio = filteredTable.Inicio;
                event_fin = filteredTable.Fin;
                
                % The file exists, do something
                ch_BLA = BLA_mainchannel;
                ch_PL = PL_mainchannel;
                ch_IL = IL_mainchannel;

                disp(['  Loading LFP signals...']);
                % BLA
                if ~isempty(ch_BLA)
                    % Cargamos la señal de BLA
                    lfp_BLA = LoadBinary(strcat(name,'_lfp.dat'), ch_BLA, ch_total); % Cargamos la señal
                    lfp_BLA = lfp_BLA * 0.195; % Convertir un canal de registro de bits a microvolts (uV)
                    lfp_BLA = zpfilt(lfp_BLA,1250,1,300); % Filtramos la señal entre 0.1 y 300
                    lfp_BLA = downsample(lfp_BLA,5); % Lo downsampleamos a 250 Hz.
                    lfp_BLA = zscorem(lfp_BLA); % Lo normalizamos con zscore
                end

                % PL
                if ~isempty(ch_PL)
                    % Cargamos la señal del PL
                    lfp_PL = LoadBinary(strcat(name,'_lfp.dat'), ch_PL, ch_total);
                    lfp_PL = lfp_PL * 0.195; % Convertir un canal de registro de bits a microvolts (uV).
                    lfp_PL = zpfilt(lfp_PL,1250,1,300); % Filtramos la señal entre 0.1 y 300
                    lfp_PL = downsample(lfp_PL,5);
                    lfp_PL = zscorem(lfp_PL); % Lo Normalizamos con Zscore
                end

                % IL
                if ~isempty(ch_IL)
                    % Cargamos la señal del PL
                    lfp_IL = LoadBinary(strcat(name,'_lfp.dat'), ch_IL, ch_total);
                    lfp_IL = lfp_IL * 0.195; % Convertir un canal de registro de bits a microvolts (uV).
                    lfp_IL = zpfilt(lfp_IL,1250,1,300); % Filtramos la señal entre 0.1 y 300
                    lfp_IL = downsample(lfp_IL,5);
                    lfp_IL = zscorem(lfp_IL); % Lo Normalizamos con Zscore
                end
               
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % Analizamos GCI solo si tenemos las tres señales
                if exist('lfp_BLA') && exist('lfp_PL') && exist('lfp_IL')
                    
                    % Ver esto. Agregamos una columna llamada 'noisy' si el evento tiene un registro muy ruidoso
                    disp(['  Checking noise in the signal...']);
                    % Creamos una variable 'event_noisy' inicializada como falso
                    event_noisy = false(1, length(event_inicio)); 
                    
                    % Detectamos ruido en las tres señales, y excluimos los segmentos que presentan ruido
                    noise_BLA = isoutlier(lfp_BLA, 'median', 10); % Detectar ruido en BLA
                    noise_PL = isoutlier(lfp_PL, 'median', 10); % Detectar ruido en PL
                    noise_IL = isoutlier(lfp_IL, 'median', 10); % Detectar ruido en IL

                    % Combinamos los ruidos detectados en las tres señales
                    noise = extend_noise((noise_BLA | noise_PL | noise_IL), 1, 1250); % Combinar ruido y extender

                    % Recorrer cada evento y verificar si está afectado por el ruido
                    for i = 1:length(event_inicio)
                        idx_start = find(t >= event_inicio(i), 1, 'first'); % Encontrar índice de inicio en 't'
                        idx_end = find(t <= event_fin(i), 1, 'last'); % Encontrar índice de fin en 't'

                        % Verificar si hay ruido entre el inicio y fin del evento
                        if any(noise(idx_start:idx_end)) 
                            event_noisy(i) = true; % Marcar el evento como ruidoso
                        end
                    end

                    % Comenzamos el analisis de MVGC
                    disp(['  Calculating Granger Causality...']);
                    for i = 1:size(event_inicio,1)
                        disp(['  Processing event: ' num2str(i) ' of ' num2str(size(event_inicio,1))]);
                        if ~isempty(event_inicio)
                            max_samples = ceil(median(event_fin(i) - event_inicio(i)) * fs);
                            [X1(1,:,:), X1(2,:,:), X1(3,:,:)] = extract_segments(lfp_BLA, lfp_PL, lfp_IL, t, event_inicio(i), event_fin(i), max_samples);
                        end
                            X = X1;
                            % Computamos el GCI
                            clear nobs A SIG G info F f Fint
                            nobs = size(X,2); % numero de observaciones del trial
                            try 
                                [A,SIG] = tsdata_to_var(X,morder,regmode);
                                [G,info] = var_to_autocov(A,SIG,0,1e-8,true);
                                f = autocov_to_spwcgc(G,fres);
                            catch ME
                                f = NaN(3,3,fres+1);
                            end
                            
                            if ~isempty(f)
                                f_stack = cat(4,f_stack,f);
                            else 
                                f_stack = cat(4,f_stack,NaN(3,3,fres+1));
                            end
                            
                            clear X X1;
                    end  
                    ID_stack = vertcat(ID_stack,event_ID);
                    noisy_stack = vertcat(noisy_stack,event_noisy');
                end
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                clear lfp_BLA lfp_PL lfp_IL X1 X2 X3
                
            else
                disp(['  Some required file do not exist.']);
                disp(['  Skipping action...']);
            end
        else
            disp(['  File sessioninfo does not exist.']);
            disp(['  Skipping action...']);
        end
        % Go back to the 'Rxx' folder
        cd(current_R_folder);
    end
end

cd(parentFolder);

clearvars -except ID_stack f_stack EventsSheet_MVGC fs noisy_stack fres lam;
disp('Done!');

% Calculamos el GC para cada frecuencia
ff1_stack = [];
ff2_stack = [];
ff3_stack = [];
ff4_stack = [];
ff5_stack = [];

B1 = [2/(fs/2) 5.3/(fs/2)]; % Rango para integrar GC en 4Hz
B2 = [5.3/(fs/2) 9.6/(fs/2)]; % Rango para integrar GC en theta
B3 = [13/(fs/2) 30/(fs/2)]; % Rango para integrar GC en beta
B4 = [45/(fs/2) 60/(fs/2)]; % Rango para integrar GC en sgamma
B5 = [60/(fs/2) 98/(fs/2)]; % Rango para integrar GC en fgamma
N = size(f_stack,4); % N de trials que tengo para analizar

for i = 1:N
    % Integramos para el CS+ en todos los rangos frecuenciales
    ff1_stack(:,:,i) = smvgc_to_mvgc(f_stack(:,:,:,i),B1);
    ff2_stack(:,:,i) = smvgc_to_mvgc(f_stack(:,:,:,i),B2);
    ff3_stack(:,:,i) = smvgc_to_mvgc(f_stack(:,:,:,i),B3);
    ff4_stack(:,:,i) = smvgc_to_mvgc(f_stack(:,:,:,i),B4);
    ff5_stack(:,:,i) = smvgc_to_mvgc(f_stack(:,:,:,i),B5);
end

% Creamos una tabla con los datos de GC
table_GC = table();
table_GC.ID = ID_stack;

% GC para 4 Hz
table_GC.BLAtoPL_4hz = squeeze(ff1_stack(2,1,:));
table_GC.PLtoBLA_4hz = squeeze(ff1_stack(1,2,:));
table_GC.BLAtoIL_4hz = squeeze(ff1_stack(3,1,:));
table_GC.ILtoBLA_4hz = squeeze(ff1_stack(1,3,:));
table_GC.PLtoIL_4hz = squeeze(ff1_stack(3,2,:));
table_GC.ILtoPL_4hz = squeeze(ff1_stack(2,3,:));

% GC para Theta
table_GC.BLAtoPL_theta = squeeze(ff2_stack(2,1,:));
table_GC.PLtoBLA_theta = squeeze(ff2_stack(1,2,:));
table_GC.BLAtoIL_theta = squeeze(ff2_stack(3,1,:));
table_GC.ILtoBLA_theta = squeeze(ff2_stack(1,3,:));
table_GC.PLtoIL_theta = squeeze(ff2_stack(3,2,:));
table_GC.ILtoPL_theta = squeeze(ff2_stack(2,3,:));

% GC para Beta
table_GC.BLAtoPL_beta = squeeze(ff3_stack(2,1,:));
table_GC.PLtoBLA_beta = squeeze(ff3_stack(1,2,:));
table_GC.BLAtoIL_beta = squeeze(ff3_stack(3,1,:));
table_GC.ILtoBLA_beta = squeeze(ff3_stack(1,3,:));
table_GC.PLtoIL_beta = squeeze(ff3_stack(3,2,:));
table_GC.ILtoPL_beta = squeeze(ff3_stack(2,3,:));

% GC para sGamma
table_GC.BLAtoPL_sgamma = squeeze(ff4_stack(2,1,:));
table_GC.PLtoBLA_sgamma = squeeze(ff4_stack(1,2,:));
table_GC.BLAtoIL_sgamma = squeeze(ff4_stack(3,1,:));
table_GC.ILtoBLA_sgamma = squeeze(ff4_stack(1,3,:));
table_GC.PLtoIL_sgamma = squeeze(ff4_stack(3,2,:));
table_GC.ILtoPL_sgamma = squeeze(ff4_stack(2,3,:));

% GC para fgamma
table_GC.BLAtoPL_fgamma = squeeze(ff5_stack(2,1,:));
table_GC.PLtoBLA_fgamma = squeeze(ff5_stack(1,2,:));
table_GC.BLAtoIL_fgamma = squeeze(ff5_stack(3,1,:));
table_GC.ILtoBLA_fgamma = squeeze(ff5_stack(1,3,:));
table_GC.PLtoIL_fgamma = squeeze(ff5_stack(3,2,:));
table_GC.ILtoPL_fgamma = squeeze(ff5_stack(2,3,:));

cd('D:\Doctorado\Analisis\Sheets')
MVGC_Sheet = readtable('MVGC_Sheet.csv');

% Eliminamos aquellos eventos que esten repetidos en la tabla
combined_table = [MVGC_Sheet; table_GC];
[unique_ids, ~, idx] = unique(combined_table.ID, 'stable');
rows_to_keep = false(height(combined_table), 1);
for i = 1:length(unique_ids)
    first_occurrence_index = find(combined_table.ID == unique_ids(i), 1, 'first');
    rows_to_keep(first_occurrence_index) = true;
end
MVGC_Sheet = combined_table(rows_to_keep, :);

writetable(MVGC_Sheet, 'MVGC_Sheet.csv');

%% Agregamos las columnas de los valores de GC al EventsSheet y lo guardamos en una nueva sheet
% Creamos una tabla nueva que copie EventsSheet
EventsSheet_MVGC = EventsSheet;

% Agregamos la columna noisy
EventsSheet_MVGC.noisy = zeros(height(EventsSheet_MVGC),1);

% GC para 4 Hz
EventsSheet_MVGC.BLAtoPL_4hz = NaN(height(EventsSheet_MVGC),1);
EventsSheet_MVGC.PLtoBLA_4hz = NaN(height(EventsSheet_MVGC),1);
EventsSheet_MVGC.BLAtoIL_4hz = NaN(height(EventsSheet_MVGC),1);
EventsSheet_MVGC.ILtoBLA_4hz = NaN(height(EventsSheet_MVGC),1);
EventsSheet_MVGC.PLtoIL_4hz = NaN(height(EventsSheet_MVGC),1);
EventsSheet_MVGC.ILtoPL_4hz = NaN(height(EventsSheet_MVGC),1);

% GC para Theta
EventsSheet_MVGC.BLAtoPL_theta = NaN(height(EventsSheet_MVGC),1);
EventsSheet_MVGC.PLtoBLA_theta = NaN(height(EventsSheet_MVGC),1);
EventsSheet_MVGC.BLAtoIL_theta = NaN(height(EventsSheet_MVGC),1);
EventsSheet_MVGC.ILtoBLA_theta = NaN(height(EventsSheet_MVGC),1);
EventsSheet_MVGC.PLtoIL_theta = NaN(height(EventsSheet_MVGC),1);
EventsSheet_MVGC.ILtoPL_theta = NaN(height(EventsSheet_MVGC),1);

% GC para Beta
EventsSheet_MVGC.BLAtoPL_beta = NaN(height(EventsSheet_MVGC),1);
EventsSheet_MVGC.PLtoBLA_beta = NaN(height(EventsSheet_MVGC),1);
EventsSheet_MVGC.BLAtoIL_beta = NaN(height(EventsSheet_MVGC),1);
EventsSheet_MVGC.ILtoBLA_beta = NaN(height(EventsSheet_MVGC),1);
EventsSheet_MVGC.PLtoIL_beta = NaN(height(EventsSheet_MVGC),1);
EventsSheet_MVGC.ILtoPL_beta = NaN(height(EventsSheet_MVGC),1);

% GC para sGamma
EventsSheet_MVGC.BLAtoPL_sgamma = NaN(height(EventsSheet_MVGC),1);
EventsSheet_MVGC.PLtoBLA_sgamma = NaN(height(EventsSheet_MVGC),1);
EventsSheet_MVGC.BLAtoIL_sgamma = NaN(height(EventsSheet_MVGC),1);
EventsSheet_MVGC.ILtoBLA_sgamma = NaN(height(EventsSheet_MVGC),1);
EventsSheet_MVGC.PLtoIL_sgamma = NaN(height(EventsSheet_MVGC),1);
EventsSheet_MVGC.ILtoPL_sgamma = NaN(height(EventsSheet_MVGC),1);

% GC para fgamma
EventsSheet_MVGC.BLAtoPL_fgamma = NaN(height(EventsSheet_MVGC),1);
EventsSheet_MVGC.PLtoBLA_fgamma = NaN(height(EventsSheet_MVGC),1);
EventsSheet_MVGC.BLAtoIL_fgamma = NaN(height(EventsSheet_MVGC),1);
EventsSheet_MVGC.ILtoBLA_fgamma = NaN(height(EventsSheet_MVGC),1);
EventsSheet_MVGC.PLtoIL_fgamma = NaN(height(EventsSheet_MVGC),1);
EventsSheet_MVGC.ILtoPL_fgamma = NaN(height(EventsSheet_MVGC),1);

cd('D:\Doctorado\Analisis\Sheets')
save('EventsSheet_MVGC.mat', 'EventsSheet_MVGC');
writetable(EventsSheet_MVGC, 'EventsSheet_MVGC.csv');