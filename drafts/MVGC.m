%% Granger Causality Analysis
% Calculamos el GCI entre estructuras durante los momentos de freezing y
% los momentos de no freezing
% Se obtiene el GCI en el dominio de las frecuencias y luego se integra en
% el rango de frecuencias de interés

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
rats = [11,12,13,17,18,19,20]; % Filtro por animales para aversivo. Sacamos el 12
% rats = 20;
paradigm_toinclude = 'aversive'; % Filtro por el paradigma
session_toinclude = {'EXT1'}; % Filtro por las sesiones

% Seteamos algunas variables que van a ser constantes a lo largo de todo el analisis
regions = {'BLA','PL','IL'}; % Regiones del cerebro que voy a analizar
timeww = {'freezing','nofreezing'}; % Ventanas de tiempo que voy a analizar
regmode   = 'LWR';       % VAR model estimation regression mode ('OLS', 'LWR' or empty for default)
icregmode = 'LWR';       % information criteria regression mode ('OLS', 'LWR' or empty for default)
morder    = 'actual';    % model order to use ('actual', 'AIC', 'BIC' or supplied numerical value)
amo       = 13;          % Select a model order if morder is in 'actual'. Default 13 a 250 Hz lo equivale a 50 ms. O 65 en 1250 Hz.
morder    = amo;         % Una vez que fijamos amo, seteamos el morder en 13 (50 ms)
momax     = 100;         % maximum model order for model order estimation
tstat     = '';          % statistical test for MVGC:  'F' for Granger's F-test (default) or 'chi2' for Geweke's chi2 test
alpha     = 0.05;        % significance level for significance test
mhtc      = 'FDR';       % multiple hypothesis test correction (see routine 'significance')
fs        = 250;         % Sample rate (Hz) luego de subsamplear para analizar GCI
Fs        = 1250;        % Sample rate original de la señal (Hz)
fres      = 500;        % Resolución de freq como cantidad de datos que quiero desde 0 a 250 Hz. Este valor es para igualar la resolucion que tengo en los espectrogramas multitaper. 1576 en 250Hz y 8195 en 1250 Hz.
nvars     = 3;           % numero de estructuras que voy a correlacionar. 3 (BLA, PL e IL)
SIGT      = eye(nvars);  % Residuals covariance matrix.
seed      = 0;           % random seed (0 for unseeded)
acmaxlags = [];          % maximum autocovariance lags (empty for automatic calculation)
modelestimation = false; % flag para determinar si calcular el órden del modelo o no

% Calculamos algunas variables que son constantes
lam = sfreqs(fres,fs)'; % Vector de frecuencias de 0 a fs
FF_CS1 = []; % Inicializamos FF
ff_CS1 = []; % Inicializamos ff
FFint_CS1 = []; % Inicializamos FFint
FF_CS2 = []; % Inicializamos FF
ff_CS2 = []; % Inicializamos ff
FFint_CS2 = []; % Inicializamos FFint
rat_fz = []; % Guardamos un vector que me dice de que animal viene cada dato
rat_nofz = []; % Guardamos un vector que me dice de que animal viene cada dato

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Define the parent folder containing the 'Rxx' folders
parentFolder = 'D:\Doctorado\Backup Ordenado';

% List all 'Rxx' folders in the parent folder
R_folders = dir(fullfile(parentFolder, 'R*'));

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
                    exist(strcat(name, '_epileptic.mat')) && ...
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

                % Cargamos los timestamps de los TTL
                load(strcat(name,'_freezing.mat'),'TTL_CS1_inicio','TTL_CS1_fin','TTL_CS2_inicio','TTL_CS2_fin');

                % Cargamos los eventos de freezing
                load(strcat(name,'_epileptic.mat'),'inicio_freezing','fin_freezing','inicio_epileptic','fin_epileptic','inicio_sleep','fin_sleep');
                duracion_freezing = fin_freezing - inicio_freezing;
                
                % Busco n cantidad de bloques que no sean freezing,epileptic o sleep. La misma cantidad que los eventos de freezing
                n = size(inicio_freezing,2);
                i = 1;
                while i <= n;
                    random_time = randi([0, round(t(end)-60)]);
                    random_duracion = randi([3,6]);
                    random_fin = random_time + random_duracion;
                    is_between_freezing = any((random_time >= inicio_freezing) & (random_time <= fin_freezing));
                    is_between_epileptic = any((random_time >= inicio_epileptic) & (random_time <= fin_epileptic));
                    is_between_sleep = any((random_time >= inicio_sleep) & (random_time <= fin_sleep));
                    finis_between_freezing = any((random_fin >= inicio_freezing) & (random_fin <= fin_freezing));
                    finis_between_epileptic = any((random_fin >= inicio_epileptic) & (random_fin <= fin_epileptic));
                    finis_between_sleep = any((random_fin >= inicio_sleep) & (random_fin <= fin_sleep));
                    if is_between_freezing || is_between_epileptic || is_between_sleep || finis_between_freezing || finis_between_epileptic || finis_between_sleep;
                        % Do nothing
                    else
                        inicio_nofreezing(i) = random_time;
                        duracion_nofreezing(i) = random_duracion;
                        fin_nofreezing(i) = random_fin;
                        i = i + 1;
                    end    
                end
                
                % Elimino los eventos de freezing y no freezing que están muy cerca del final de la señal
                pos1 = fin_freezing > t(end) - 10; % Aquellos eventos de freezing que terminen dentro de los últimos 10 seg de señal
                pos2 = fin_nofreezing > t(end) - 10; % Aquellos eventos de no freezing que terminen dentro de los últimos 10 seg de señal
                inicio_freezing(pos1) = [];
                fin_freezing(pos1) = [];
                duracion_freezing(pos1) = [];
                inicio_nofreezing(pos2) = [];
                fin_nofreezing(pos2) = [];
                duracion_nofreezing(pos2) = [];
                
                % The file exists, do something
                ch_BLA = BLA_mainchannel;
                ch_PL = PL_mainchannel;
                ch_IL = IL_mainchannel;

                % BLA
                if ~isempty(ch_BLA)
                    % Cargamos la señal de BLA
                    lfp_BLA = LoadBinary(strcat(name,'_lfp.dat'), ch_BLA, ch_total); % Cargamos la señal
                    lfp_BLA = lfp_BLA * 0.195; % Convertir un canal de registro de bits a microvolts (uV)
                    lfp_BLA = zpfilt(lfp_BLA,1250,1,300); % Filtramos la señal entre 0.1 y 300
                    lfp_BLA = zpnotch(lfp_BLA, 1250, 100, 30); % Filtramos la señal de linea en 100 hz.
                    lfp_BLA = zpnotch(lfp_BLA, 1250, 50, 30); % Filtramos la señal de linea en 100 hz.
                    lfp_BLA = downsample(lfp_BLA,5); % Lo downsampleamos a 250 Hz.
                    lfp_BLA = zscorem(lfp_BLA); % Lo normalizamos con zscore
                end

                % PL
                if ~isempty(ch_PL)
                    % Cargamos la señal del PL
                    lfp_PL = LoadBinary(strcat(name,'_lfp.dat'), ch_PL, ch_total);
                    lfp_PL = lfp_PL * 0.195; % Convertir un canal de registro de bits a microvolts (uV).
                    lfp_PL = zpfilt(lfp_PL,1250,1,300); % Filtramos la señal entre 0.1 y 300
                    lfp_PL = zpnotch(lfp_PL, 1250, 100, 30); % Filtramos la señal de linea en 100 hz.
                    lfp_PL = zpnotch(lfp_PL, 1250, 50, 30); % Filtramos la señal de linea en 100 hz.
                    lfp_PL = downsample(lfp_PL,5);
                    lfp_PL = zscorem(lfp_PL); % Lo Normalizamos con Zscore
                end
                
                % IL
                if ~isempty(ch_IL)
                    % Cargamos la señal del PL
                    lfp_IL = LoadBinary(strcat(name,'_lfp.dat'), ch_IL, ch_total);
                    lfp_IL = lfp_IL * 0.195; % Convertir un canal de registro de bits a microvolts (uV).
                    lfp_IL = zpfilt(lfp_IL,1250,1,300); % Filtramos la señal entre 0.1 y 300
                    lfp_IL = zpnotch(lfp_IL, 1250, 100, 30); % Filtramos la señal de linea en 100 hz.
                    lfp_IL = zpnotch(lfp_IL, 1250, 50, 30); % Filtramos la señal de linea en 100 hz.
                    lfp_IL = downsample(lfp_IL,5);
                    lfp_IL = zscorem(lfp_IL); % Lo Normalizamos con Zscore
                end
               
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % Analizamos GCI solo si tenemos las tres señales
                if exist('lfp_BLA') && exist('lfp_PL') && exist('lfp_IL')
                    
                    % Detectamos ruido en las tres señales, y excluimos los segmentos que presentan ruido
                    noise_BLA = isoutlier(lfp_BLA, 'median', 6); % Buscamos los ruidos en BLA
                    noise_PL = isoutlier(lfp_PL, 'median', 6); % Buscamos los ruidos en PL
                    noise_IL = isoutlier(lfp_IL, 'median', 6); % Buscamos los ruidos en IL
                    noise = extend_noise((noise_BLA|noise_PL|noise_IL), 1, 250); % Combinamos los 3 y extendemos

                    % Eliminamos los eventos de freezing que tienen un evento de ruido en el medio
                    to_remove = false(1, length(inicio_freezing));
                    for i = 1:length(inicio_freezing) % Recorrer cada evento de freezing
                        idx_start = find(t >= inicio_freezing(i), 1, 'first'); % Encontrar los índices correspondientes en t
                        idx_end = find(t <= fin_freezing(i), 1, 'last');
                        if any(noise(idx_start:idx_end)) % Verificar si hay ruido en medio del evento de freezing
                            to_remove(i) = true; % Marcar el evento para eliminar
                        end
                    end       
                    inicio_freezing(to_remove) = []; % Eliminar los eventos de freezing que tienen ruido
                    duracion_freezing(to_remove) = [];
                    fin_freezing(to_remove) = [];
                    clear to_remove;
                    
                    % Nos quedamos solo con los eventos de freezing que duran más de 3 seg
                    inicio_freezing = inicio_freezing(duracion_freezing >= 3);
                    fin_freezing = fin_freezing(duracion_freezing >= 3);
                    duracion_freezing = duracion_freezing(duracion_freezing >= 3);
                    
                    % Eliminamos los eventos de no freezing que tienen un evento de ruido en el medio
                    to_remove = false(1, length(inicio_nofreezing));
                    for i = 1:length(inicio_nofreezing) % Recorrer cada evento de freezing
                        idx_start = find(t >= inicio_nofreezing(i), 1, 'first'); % Encontrar los índices correspondientes en t
                        idx_end = find(t <= fin_nofreezing(i), 1, 'last');
                        if any(noise(idx_start:idx_end)) % Verificar si hay ruido en medio del evento de freezing
                            to_remove(i) = true; % Marcar el evento para eliminar
                        end
                    end       
                    inicio_nofreezing(to_remove) = []; % Eliminar los eventos de freezing que tienen ruido
                    duracion_nofreezing(to_remove) = [];
                    fin_nofreezing(to_remove) = [];
                    clear to_remove;
                   
                    % Generamos los segmentos por evento de freezing
                    for i = 1:size(inicio_freezing,2)
                        samples = ceil(((inicio_freezing(i)+3)-inicio_freezing(i))*fs);
                        [SEG(1,:),SEG(2,:),SEG(3,:)] = extract_segments(lfp_BLA, lfp_PL, lfp_IL, t, inicio_freezing(i), inicio_freezing(i)+3,1250);
                        X1(:,:,i) = SEG(:,1:750);
                        clear SEG
                    end

                    % Generamos los segmentos por evento de noFreezing
                    for i = 1:size(inicio_nofreezing,2)
                        samples = ceil(((inicio_nofreezing(i)+3)-inicio_nofreezing(i))*fs);
                        [SEG(1,:),SEG(2,:),SEG(3,:)] = extract_segments(lfp_BLA, lfp_PL, lfp_IL, t, inicio_nofreezing(i), inicio_nofreezing(i)+3,1250);
                        X2(:,:,i) = SEG(:,1:750);
                        clear SEG
                    end
                    
                    % Freezing
                    X = X1;
                    % Calculamos el AIC y BIC si el flag 'modelestimation' es true
                    if modelestimation
                        [AIC,BIC,moAIC,moBIC] = tsdata_to_infocrit(X,momax,icregmode);
                        figure(); clf;
                        plot_tsdata([AIC BIC]',{'AIC','BIC'},(1/fs)*1000);
                        title('Estimación del órden del modelo');
                        ylabel('AIC/BIC score');
                        xlabel('Tiempo (ms)');
                    end
                    % Computamos el GCI
                    clear nobs A SIG G info F f Fint
                    nobs = size(X,2); % numero de observaciones del trial
                    [A,SIG] = tsdata_to_var(X,morder,regmode);
                    [G,info] = var_to_autocov(A,SIG,0,1e-8,true);
                    F = autocov_to_pwcgc(G);
                    f = autocov_to_spwcgc(G,fres);
                    Fint = smvgc_to_mvgc(f);
                    % k es el número trial (1,2,3,etc) y m es el tipo de trial (CS1,CS2,etc)
                    if ~isempty(F) && ~isempty(f) && ~isempty(Fint)
                        FF_CS1 = cat(3,FF_CS1,F);
                        ff_CS1 = cat(4,ff_CS1,f);
                        FFint_CS1 = cat(3,FFint_CS1,Fint);
                    end

                    clear X
                    rat_fz = cat(1,rat_fz,r); % Guardamos la rata de cada uno de los valores que obtuvimos
                    disp(strcat('  Processing Fz events'));
                    
                    % noFreezing
                    X = X2;
                    % Calculamos el AIC y BIC si el flag 'modelestimation' es true
                    if modelestimation
                        [AIC,BIC,moAIC,moBIC] = tsdata_to_infocrit(X,momax,icregmode);
                        figure(); clf;
                        plot_tsdata([AIC BIC]',{'AIC','BIC'},(1/fs)*1000);
                        title('Estimación del órden del modelo');
                        ylabel('AIC/BIC score');
                        xlabel('Tiempo (ms)');
                    end
                    % Computamos el GCI
                    clear nobs A SIG G info F f Fint
                    nobs = size(X,2); % numero de observaciones del trial
                    [A,SIG] = tsdata_to_var(X,morder,regmode);
                    [G,info] = var_to_autocov(A,SIG,0,1e-8,true);
                    F = autocov_to_pwcgc(G);
                    f = autocov_to_spwcgc(G,fres);
                    Fint = smvgc_to_mvgc(f);
                    % k es el número trial (1,2,3,etc) y m es el tipo de trial (CS1,CS2,etc)
                    if ~isempty(F) && ~isempty(f) && ~isempty(Fint)
                        FF_CS2 = cat(3,FF_CS2,F);
                        ff_CS2 = cat(4,ff_CS2,f);
                        FFint_CS2 = cat(3,FFint_CS2,Fint);
                    end
                    clear X
                    rat_nofz = cat(1,rat_nofz,r); % Guardamos la rata de cada uno de los valores que obtuvimos
                    disp(strcat('  Processing noFz events'));
                    
                end
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                clear lfp_BLA lfp_PL lfp_IL X1 X2 inicio_freezing fin_freezing...
                    inicio_nofreezing fin_nofreezing duracion_nofreezing duracion_freezing
                
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
disp('Done!');
cd(parentFolder);

% Calculamos algunas ultimas cosas de los resultados

session = 'Early Extinction 1';

B1 = [2/(fs/2) 5.3/(fs/2)]; % Rango para integrar GC en 4Hz
B2 = [5.3/(fs/2) 9.6/(fs/2)]; % Rango para integrar GC en theta
B3 = [13/(fs/2) 30/(fs/2)]; % Rango para integrar GC en beta
B4 = [43/(fs/2) 60/(fs/2)]; % Rango para integrar GC en sgamma
B5 = [60/(fs/2) 98/(fs/2)]; % Rango para integrar GC en fgamma

for i = 1:size(ff_CS1,4);
    % Integramos para el freezing en todos los rangos frecuenciales
    FF1_CS1(:,:,i) = smvgc_to_mvgc(ff_CS1(:,:,:,i),B1);
    FF2_CS1(:,:,i) = smvgc_to_mvgc(ff_CS1(:,:,:,i),B2);
    FF3_CS1(:,:,i) = smvgc_to_mvgc(ff_CS1(:,:,:,i),B3);
    FF4_CS1(:,:,i) = smvgc_to_mvgc(ff_CS1(:,:,:,i),B4);
    FF5_CS1(:,:,i) = smvgc_to_mvgc(ff_CS1(:,:,:,i),B5);
end

for i = 1:size(ff_CS2,4);
    % Integramos para el nofreezing en todos los rangos frecuenciales
    FF1_CS2(:,:,i) = smvgc_to_mvgc(ff_CS2(:,:,:,i),B1);
    FF2_CS2(:,:,i) = smvgc_to_mvgc(ff_CS2(:,:,:,i),B2);
    FF3_CS2(:,:,i) = smvgc_to_mvgc(ff_CS2(:,:,:,i),B3);
    FF4_CS2(:,:,i) = smvgc_to_mvgc(ff_CS2(:,:,:,i),B4);
    FF5_CS2(:,:,i) = smvgc_to_mvgc(ff_CS2(:,:,:,i),B5);
end

% Ploteamos los resultados
% Ploteamos Freezing
plot_GCf(ff_CS1,lam,[1,100]);
plot_GCf(ff_CS1,lam,[0,30]);
% Ploteamos noFreezing
plot_GCf(ff_CS2,lam,[1,100]);
plot_GCf(ff_CS2,lam,[0,30]);

% Ploteamos los GC en el dominio del tiempo integrado para cada frecuencia
figure();
subplot(2,5,1); plot_GCt(FF1_CS1,'CS+ 4-Hz');
subplot(2,5,2); plot_GCt(FF2_CS1,'CS+ Theta');
subplot(2,5,3); plot_GCt(FF3_CS1,'CS+ Beta');
subplot(2,5,4); plot_GCt(FF4_CS1,'CS+ sGamma');
subplot(2,5,5); plot_GCt(FF5_CS1,'CS+ fGamma');

subplot(2,5,6); plot_GCt(FF1_CS2,'CS- 4-Hz');
subplot(2,5,7); plot_GCt(FF2_CS2,'CS- Theta');
subplot(2,5,8); plot_GCt(FF3_CS2,'CS- Beta');
subplot(2,5,9); plot_GCt(FF4_CS2,'CS- sGamma');
subplot(2,5,10); plot_GCt(FF5_CS2,'CS- fGamma');

set(gcf, 'Position', [100, 0, 1200, 500]);

aleluya();