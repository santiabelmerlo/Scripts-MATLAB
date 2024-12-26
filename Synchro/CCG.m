%% CCG (Cross-Correlograms) with xcorr.m para CS+ vs CS-
% Output de este script:
% CCG: Valores de cross-correlación para cada par de regiones: BLA-PL,
% BLA-IL y PL-IL y para los eventos de CS+ y CS-. Estas
% matrices de CCG tienen N x lags datos
% lags: vector de lags para plotear en el eje X.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc
clear all

% En estas lineas selecciono que animales, paradigma y sesiones quiero analizar
% rats = [10,11,13,14,16,17,18,19]; % Filtro por animales para apetitivo
rats = [11,12,13,17,18,19,20]; % Filtro por animales para aversivo.
paradigm_toinclude = 'aversive'; % Filtro por el paradigma
session_toinclude = {'EXT2'}; % Filtro por las sesiones
trials_toinclude = 1:10; % Filtro por los trials
frange = 5; % Filtro por el rango de frecuencias que quiero analizar. Valor de 1 a 5 (4Hz,theta,beta,sgamma,fgamma)

% Seteamos algunas variables que van a ser constantes a lo largo de todo el analisis
ntrials   = 1;           % El número de trials o series temporales que va a analizar el modelo por vez
Fs        = 1250;        % Sample rate original de la señal (Hz)
ww        = Fs*3;        % Ventana para calcular el CCG 
step      = Fs*0.5;      % Step para calcular el CCG

% Calculamos algunas variables que son constantes
CCG1= []; 
CCG2 = [];
CCG3 = [];

CCG1_all = []; 
CCG2_all = [];
CCG3_all = [];

lags_CCG1_CS1 = [];
lags_CCG2_CS1 = [];
lags_CCG3_CS1 = [];
lags_CCG1_CS2 = [];
lags_CCG2_CS2 = [];
lags_CCG3_CS2 = [];

alllags_CCG1_CS1 = [];
alllags_CCG2_CS1 = [];
alllags_CCG3_CS1 = [];

alllags_CCG1_CS2 = [];
alllags_CCG2_CS2 = [];
alllags_CCG3_CS2 = [];

lags_CCG1_fz = [];
lags_CCG2_fz = [];
lags_CCG3_fz = [];

lags_CCG1_nofz = [];
lags_CCG2_nofz = [];
lags_CCG3_nofz = [];

alllags_CCG1_fz = [];
alllags_CCG2_fz = [];
alllags_CCG3_fz = [];

alllags_CCG1_nofz = [];
alllags_CCG2_nofz = [];
alllags_CCG3_nofz = [];

cake_CCG1_CS1 = [];
cake_CCG2_CS1 = [];
cake_CCG3_CS1 = [];
cake_CCG1_CS2 = [];
cake_CCG2_CS2 = [];
cake_CCG3_CS2 = [];
cake_CCG1_fz = [];
cake_CCG2_fz = [];
cake_CCG3_fz = [];
cake_CCG1_nofz = [];
cake_CCG2_nofz = [];
cake_CCG3_nofz = [];

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
                clear amplifier_timestamps amplifier_timestamps_lfp

                % Cargamos los timestamps de los TTL
                load(strcat(name,'_freezing.mat'),'TTL_CS1_inicio','TTL_CS1_fin','TTL_CS2_inicio','TTL_CS2_fin');
                
                % Cargamos los eventos de freezing
                load(strcat(name,'_epileptic.mat'),'inicio_freezing','fin_freezing','inicio_epileptic','fin_epileptic','inicio_sleep','fin_sleep');
                duracion_freezing = fin_freezing - inicio_freezing;
                                
                % Nos quedamos solo con los eventos de freezing que duran más de 3 seg
                inicio_freezing = inicio_freezing(duracion_freezing >= 3);
                fin_freezing = fin_freezing(duracion_freezing >= 3);
                duracion_freezing = duracion_freezing(duracion_freezing >= 3);
                
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
                    lfp_BLA = zpfilt(lfp_BLA,1250,0.1,300); % Filtramos la señal entre 0.1 y 300
                    lfp_BLA = zpnotch(lfp_BLA, 1250, 100, 30); % Filtramos la señal de linea en 100 hz.
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
                    lfp_PL = zpnotch(lfp_PL, 1250, 100, 30); % Filtramos la señal de linea en 100 hz.
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
                    lfp_IL = zpnotch(lfp_IL, 1250, 100, 30); % Filtramos la señal de linea en 100 hz.
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
                    
                    % Detectamos ruido en las tres señales, y excluimos los segmentos que presentan ruido
                    noise_BLA = isoutlier(lfp_BLA, 'median', 6); % Buscamos los ruidos en BLA
                    noise_PL = isoutlier(lfp_PL, 'median', 6); % Buscamos los ruidos en PL
                    noise_IL = isoutlier(lfp_IL, 'median', 6); % Buscamos los ruidos en IL
                    noise = extend_noise((noise_BLA|noise_PL|noise_IL), 1, 1250); % Combinamos los 3 y extendemos

                    % Computamos la cross corelación
                    X1(1,:,:) = filt_BLA(frange,:);
                    X1(2,:,:) = filt_PL(frange,:);
                    X1(3,:,:) = filt_IL(frange,:);
                    X1 = squeeze(X1);
                    
                    m = 1;
                    for i = 1:step:(size(X1,2))-step
                        [c1, lag] = xcorr(X1(1,i:i+step),X1(2,i:i+step), Fs, 'coeff');
                        [c2, lag] = xcorr(X1(1,i:i+step),X1(3,i:i+step), Fs, 'coeff');
                        [c3, lag] = xcorr(X1(2,i:i+step),X1(3,i:i+step), Fs, 'coeff');
                        CCG1(m) = lag(find(c1 == max(c1))); % Correlación BLA-PL
                        CCG2(m) = lag(find(c2 == max(c2))); % Correlación BLA-IL
                        CCG3(m) = lag(find(c3 == max(c3))); % Correlación PL-IL
                        CCG1_all(m,:) = c1; % Correlación BLA-PL
                        CCG2_all(m,:) = c2; % Correlación BLA-IL
                        CCG3_all(m,:) = c3; % Correlación PL-IL
                        tt(m) = t(1,i);
                        m = m + 1;
                        clear c1 c2 c3
                    end
                    
                    % Eliminamos los lags que caen dentro de un ruido.
                    cambios_ruido = diff([0 noise 0]); % Añadimos ceros al inicio y final para captar cambios en los bordes
                    noise_inicio = t(cambios_ruido == 1); % Timestamps de inicio de ruido
                    if cambios_ruido(end) == -1
                        cambios_ruido(end-1) = -1;
                        cambios_ruido(end) = [];
                    end
                    noise_fin = t(cambios_ruido == -1);   % Timestamps de fin de ruido        
                    is_noise = false(size(tt)); % Inicializar un índice lógico para valores que no están en eventos de ruido
                    % Revisar cada evento de ruido
                    for i = 1:length(tt)
                        is_noise(i) = any(tt(i) >= noise_inicio & tt(i) <= noise_fin);
                    end
                    % Filtrar los valores de correlación
                    CCG1(is_noise) = NaN;
                    CCG2(is_noise) = NaN;
                    CCG3(is_noise) = NaN;
                    CCG1_all(is_noise, :) = nan(sum(is_noise), length(lag));
                    CCG2_all(is_noise, :) = nan(sum(is_noise), length(lag));
                    CCG3_all(is_noise, :) = nan(sum(is_noise), length(lag));
                    
                    % Eliminamos outliers que superan los 10 desvios
                    CCG1_all(isoutlier(CCG1,'median',10),:) = nan(sum(isoutlier(CCG1,'median',10)),length(lag));
                    CCG2_all(isoutlier(CCG2,'median',10),:) = nan(sum(isoutlier(CCG2,'median',10)),length(lag));
                    CCG3_all(isoutlier(CCG3,'median',10),:) = nan(sum(isoutlier(CCG3,'median',10)),length(lag));   
                    CCG1(isoutlier(CCG1,'median',10)) = NaN;
                    CCG2(isoutlier(CCG2,'median',10)) = NaN;
                    CCG3(isoutlier(CCG3,'median',10)) = NaN;

                    for i = trials_toinclude
                        % CS+
                        indices_CS1 = (tt >= TTL_CS1_inicio(i)) & (tt <= TTL_CS1_fin(i));
                        cake_CCG1_CS1 = cat(2,cake_CCG1_CS1,CCG1(indices_CS1));
                        cake_CCG2_CS1 = cat(2,cake_CCG2_CS1,CCG2(indices_CS1));
                        cake_CCG3_CS1 = cat(2,cake_CCG3_CS1,CCG3(indices_CS1));
                        lags_CCG1_CS1 = cat(1,lags_CCG1_CS1,nanmedian(CCG1(indices_CS1)));
                        lags_CCG2_CS1 = cat(1,lags_CCG2_CS1,nanmedian(CCG2(indices_CS1)));
                        lags_CCG3_CS1 = cat(1,lags_CCG3_CS1,nanmedian(CCG3(indices_CS1)));
                        alllags_CCG1_CS1 = cat(1,alllags_CCG1_CS1,nanmedian(CCG1_all(indices_CS1,:),1));
                        alllags_CCG2_CS1 = cat(1,alllags_CCG2_CS1,nanmedian(CCG2_all(indices_CS1,:),1));
                        alllags_CCG3_CS1 = cat(1,alllags_CCG3_CS1,nanmedian(CCG3_all(indices_CS1,:),1));
                        % CS-
                        indices_CS2 = (tt >= TTL_CS2_inicio(i)) & (tt <= TTL_CS2_fin(i));
                        cake_CCG1_CS2 = cat(2,cake_CCG1_CS2,CCG1(indices_CS2));
                        cake_CCG2_CS2 = cat(2,cake_CCG2_CS2,CCG2(indices_CS2));
                        cake_CCG3_CS2 = cat(2,cake_CCG3_CS2,CCG3(indices_CS2));
                        lags_CCG1_CS2 = cat(1,lags_CCG1_CS2,nanmedian(CCG1(indices_CS2)));
                        lags_CCG2_CS2 = cat(1,lags_CCG2_CS2,nanmedian(CCG2(indices_CS2)));
                        lags_CCG3_CS2 = cat(1,lags_CCG3_CS2,nanmedian(CCG3(indices_CS2)));
                        alllags_CCG1_CS2 = cat(1,alllags_CCG1_CS2,nanmedian(CCG1_all(indices_CS2,:),1));
                        alllags_CCG2_CS2 = cat(1,alllags_CCG2_CS2,nanmedian(CCG2_all(indices_CS2,:),1));
                        alllags_CCG3_CS2 = cat(1,alllags_CCG3_CS2,nanmedian(CCG3_all(indices_CS2,:),1));
                    end
                    
                    for i = 1:length(inicio_freezing)
                        % Freezing
                        indices_fz = (tt >= inicio_freezing(i)) & (tt <= fin_freezing(i));
                        cake_CCG1_fz = cat(2,cake_CCG1_fz,CCG1(indices_fz));
                        cake_CCG2_fz = cat(2,cake_CCG2_fz,CCG2(indices_fz));
                        cake_CCG3_fz = cat(2,cake_CCG3_fz,CCG3(indices_fz));                        
                        lags_CCG1_fz = cat(1,lags_CCG1_fz,nanmedian(CCG1(indices_fz)));
                        lags_CCG2_fz = cat(1,lags_CCG2_fz,nanmedian(CCG2(indices_fz)));
                        lags_CCG3_fz = cat(1,lags_CCG3_fz,nanmedian(CCG3(indices_fz)));
                        alllags_CCG1_fz = cat(1,alllags_CCG1_fz,nanmedian(CCG1_all(indices_fz,:),1));
                        alllags_CCG2_fz = cat(1,alllags_CCG2_fz,nanmedian(CCG2_all(indices_fz,:),1));
                        alllags_CCG3_fz = cat(1,alllags_CCG3_fz,nanmedian(CCG3_all(indices_fz,:),1));
                    end
                    
                    for i = 1:length(inicio_nofreezing)
                        % No Freezing
                        indices_nofz = (tt >= inicio_nofreezing(i)) & (tt <= fin_nofreezing(i));
                        cake_CCG1_nofz = cat(2,cake_CCG1_nofz,CCG1(indices_nofz));
                        cake_CCG2_nofz = cat(2,cake_CCG2_nofz,CCG2(indices_nofz));
                        cake_CCG3_nofz = cat(2,cake_CCG3_nofz,CCG3(indices_nofz));                        
                        lags_CCG1_nofz = cat(1,lags_CCG1_nofz,nanmedian(CCG1(indices_nofz)));
                        lags_CCG2_nofz = cat(1,lags_CCG2_nofz,nanmedian(CCG2(indices_nofz)));
                        lags_CCG3_nofz = cat(1,lags_CCG3_nofz,nanmedian(CCG3(indices_nofz)));
                        alllags_CCG1_nofz = cat(1,alllags_CCG1_nofz,nanmedian(CCG1_all(indices_nofz,:),1));
                        alllags_CCG2_nofz = cat(1,alllags_CCG2_nofz,nanmedian(CCG2_all(indices_nofz,:),1));
                        alllags_CCG3_nofz = cat(1,alllags_CCG3_nofz,nanmedian(CCG3_all(indices_nofz,:),1));
                    end
                    
                end
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                clear lfp_BLA lfp_PL lfp_IL X1 X2 filt_BLA filt_PL filt_IL inicio_freezing fin_freezing...
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

% Ploteamos todo
cs1_color = [118 6 154]/255; % Seteo el color para el CS+ aversivo
cs2_color = [96 96 96]/255; % Seteo el color para el CS-
fz_color = [255 140 0]/255; % Seteo el color para el freezing a un tono de naranja
nofz_color = [96 96 96]/255; % Seteo el color para el no freezing
    
% Todos los CS que incluí en trials_toinclude
figure()
subplot(131)
plot_lags(lags_CCG1_CS1,lags_CCG1_CS2,'CS');
title('BLA-PL');
subplot(132)
plot_lags(lags_CCG2_CS1,lags_CCG2_CS2,'CS');
title('BLA-IL');
subplot(133)
plot_lags(lags_CCG3_CS1,lags_CCG3_CS2,'CS');
title('PL-IL');

set(gcf, 'Color', 'white');
set(gcf, 'Position', [400, 400, 500, 250]);

% Todos los eventos de freezing y no freezing de la sesión
figure()
subplot(131)
plot_lags(lags_CCG1_fz,lags_CCG1_nofz,'fz');
title('BLA-PL');
subplot(132)
plot_lags(lags_CCG2_fz,lags_CCG2_nofz,'fz');
title('BLA-IL');
subplot(133)
plot_lags(lags_CCG3_fz,lags_CCG3_nofz,'fz');
title('PL-IL');

set(gcf, 'Color', 'white');
set(gcf, 'Position', [400, 400, 500, 250]);

% Ploteamos los lags con una escala de tiempo grande para los CSs
figure()
subplot(131)
plot_curve(lag, alllags_CCG1_CS2, 'mean', cs2_color, 1,'cont'); hold on;
plot_curve(lag, alllags_CCG1_CS1, 'mean', cs1_color, 1,'cont'); hold off;
line([nanmean(lags_CCG1_CS1) nanmean(lags_CCG1_CS1)],[-1 1],'Color',cs1_color,'LineWidth',0.5,'LineStyle','--');
line([nanmean(lags_CCG1_CS2) nanmean(lags_CCG1_CS2)],[-1 1],'Color',cs2_color,'LineWidth',0.5,'LineStyle','--');
line([0 0],[-1 1],'Color',[0 0 0],'LineWidth',0.5,'LineStyle','--');
xlabel('Tiempo (ms)'); ylabel('CCG'); title('BLA Lead - PL Lead');
ylim([-1 1]); xlim([-625 625]);

subplot(132)
plot_curve(lag, alllags_CCG2_CS2, 'mean', cs2_color, 1,'cont'); hold on;
plot_curve(lag, alllags_CCG2_CS1, 'mean', cs1_color, 1,'cont'); hold off;
line([nanmean(lags_CCG2_CS1) nanmean(lags_CCG2_CS1)],[-1 1],'Color',cs1_color,'LineWidth',0.5,'LineStyle','--');
line([nanmean(lags_CCG2_CS2) nanmean(lags_CCG2_CS2)],[-1 1],'Color',cs2_color,'LineWidth',0.5,'LineStyle','--');
line([0 0],[-1 1],'Color',[0 0 0],'LineWidth',0.5,'LineStyle','--');
xlabel('Tiempo (ms)'); ylabel('CCG'); title('BLA Lead - IL Lead');
ylim([-1 1]); xlim([-625 625]);

subplot(133)
plot_curve(lag, alllags_CCG3_CS2, 'mean', cs2_color, 1,'cont'); hold on;
plot_curve(lag, alllags_CCG3_CS1, 'mean', cs1_color, 1,'cont'); hold off;
line([nanmean(lags_CCG3_CS1) nanmean(lags_CCG3_CS1)],[-1 1],'Color',cs1_color,'LineWidth',0.5,'LineStyle','--');
line([nanmean(lags_CCG3_CS2) nanmean(lags_CCG3_CS2)],[-1 1],'Color',cs2_color,'LineWidth',0.5,'LineStyle','--');
line([0 0],[-1 1],'Color',[0 0 0],'LineWidth',0.5,'LineStyle','--');
xlabel('Tiempo (ms)'); ylabel('CCG'); title('PL Lead - IL Lead');
ylim([-1 1]); xlim([-625 625]);

set(gcf, 'Color', 'white');
set(gcf, 'Position', [400, 400, 900, 250]);

% Ploteamos los lags pero con una escala de tiempo más chica
figure()
subplot(131)
plot_curve(lag, alllags_CCG1_CS2, 'mean', cs2_color, 1,'cont'); hold on;
plot_curve(lag, alllags_CCG1_CS1, 'mean', cs1_color, 1,'cont'); hold off;
line([nanmean(lags_CCG1_CS1) nanmean(lags_CCG1_CS1)],[-1 1],'Color',cs1_color,'LineWidth',0.5,'LineStyle','--');
line([nanmean(lags_CCG1_CS2) nanmean(lags_CCG1_CS2)],[-1 1],'Color',cs2_color,'LineWidth',0.5,'LineStyle','--');
line([0 0],[-1 1],'Color',[0 0 0],'LineWidth',0.5,'LineStyle','--');
xlabel('Tiempo (ms)'); ylabel('CCG'); title('BLA Lead - PL Lead');
ylim([0 1]); xlim([-50 50]);

subplot(132)
plot_curve(lag, alllags_CCG2_CS2, 'mean', cs2_color, 1,'cont'); hold on;
plot_curve(lag, alllags_CCG2_CS1, 'mean', cs1_color, 1,'cont'); hold off;
line([nanmean(lags_CCG2_CS1) nanmean(lags_CCG2_CS1)],[-1 1],'Color',cs1_color,'LineWidth',0.5,'LineStyle','--');
line([nanmean(lags_CCG2_CS2) nanmean(lags_CCG2_CS2)],[-1 1],'Color',cs2_color,'LineWidth',0.5,'LineStyle','--');
line([0 0],[-1 1],'Color',[0 0 0],'LineWidth',0.5,'LineStyle','--');
xlabel('Tiempo (ms)'); ylabel('CCG'); title('BLA Lead - IL Lead');
ylim([0 1]); xlim([-50 50]);

subplot(133)
plot_curve(lag, alllags_CCG3_CS2, 'mean', cs2_color, 1,'cont'); hold on;
plot_curve(lag, alllags_CCG3_CS1, 'mean', cs1_color, 1,'cont'); hold off;
line([nanmean(lags_CCG3_CS1) nanmean(lags_CCG3_CS1)],[-1 1],'Color',cs1_color,'LineWidth',0.5,'LineStyle','--');
line([nanmean(lags_CCG3_CS2) nanmean(lags_CCG3_CS2)],[-1 1],'Color',cs2_color,'LineWidth',0.5,'LineStyle','--');
line([0 0],[-1 1],'Color',[0 0 0],'LineWidth',0.5,'LineStyle','--');
xlabel('Tiempo (ms)'); ylabel('CCG'); title('PL Lead - IL Lead');
ylim([0 1]); xlim([-50 50]);

set(gcf, 'Color', 'white');
set(gcf, 'Position', [400, 400, 900, 250]);

% Ploteamos los lags con una escala de tiempo grande para los CSs
figure()
subplot(131)
plot_curve(lag, alllags_CCG1_nofz, 'mean', nofz_color, 1,'cont'); hold on;
plot_curve(lag, alllags_CCG1_fz, 'mean', fz_color, 1,'cont'); hold off;
line([nanmean(lags_CCG1_fz) nanmean(lags_CCG1_fz)],[-1 1],'Color',fz_color,'LineWidth',0.5,'LineStyle','--');
line([nanmean(lags_CCG1_nofz) nanmean(lags_CCG1_nofz)],[-1 1],'Color',nofz_color,'LineWidth',0.5,'LineStyle','--');
line([0 0],[-1 1],'Color',[0 0 0],'LineWidth',0.5,'LineStyle','--');
xlabel('Tiempo (ms)'); ylabel('CCG'); title('BLA Lead - PL Lead');
ylim([-1 1]); xlim([-625 625]);

subplot(132)
plot_curve(lag, alllags_CCG2_nofz, 'mean', nofz_color, 1,'cont'); hold on;
plot_curve(lag, alllags_CCG2_fz, 'mean', fz_color, 1,'cont'); hold off;
line([nanmean(lags_CCG2_fz) nanmean(lags_CCG2_fz)],[-1 1],'Color',fz_color,'LineWidth',0.5,'LineStyle','--');
line([nanmean(lags_CCG2_nofz) nanmean(lags_CCG2_nofz)],[-1 1],'Color',nofz_color,'LineWidth',0.5,'LineStyle','--');
line([0 0],[-1 1],'Color',[0 0 0],'LineWidth',0.5,'LineStyle','--');
xlabel('Tiempo (ms)'); ylabel('CCG'); title('BLA Lead - IL Lead');
ylim([-1 1]); xlim([-625 625]);

subplot(133)
plot_curve(lag, alllags_CCG3_nofz, 'mean', nofz_color, 1,'cont'); hold on;
plot_curve(lag, alllags_CCG3_fz, 'mean', fz_color, 1,'cont'); hold off;
line([nanmean(lags_CCG3_fz) nanmean(lags_CCG3_fz)],[-1 1],'Color',fz_color,'LineWidth',0.5,'LineStyle','--');
line([nanmean(lags_CCG3_nofz) nanmean(lags_CCG3_nofz)],[-1 1],'Color',nofz_color,'LineWidth',0.5,'LineStyle','--');
line([0 0],[-1 1],'Color',[0 0 0],'LineWidth',0.5,'LineStyle','--');
xlabel('Tiempo (ms)'); ylabel('CCG'); title('PL Lead - IL Lead');
ylim([-1 1]); xlim([-625 625]);

set(gcf, 'Color', 'white');
set(gcf, 'Position', [400, 400, 900, 250]);

% Ploteamos los lags pero con una escala de tiempo más chica
figure()
subplot(131)
plot_curve(lag, alllags_CCG1_nofz, 'mean', nofz_color, 1,'cont'); hold on;
plot_curve(lag, alllags_CCG1_fz, 'mean', fz_color, 1,'cont'); hold off;
line([nanmean(lags_CCG1_fz) nanmean(lags_CCG1_fz)],[-1 1],'Color',fz_color,'LineWidth',0.5,'LineStyle','--');
line([nanmean(lags_CCG1_nofz) nanmean(lags_CCG1_nofz)],[-1 1],'Color',nofz_color,'LineWidth',0.5,'LineStyle','--');
line([0 0],[-1 1],'Color',[0 0 0],'LineWidth',0.5,'LineStyle','--');
xlabel('Tiempo (ms)'); ylabel('CCG'); title('BLA Lead - PL Lead');
ylim([0 1]); xlim([-50 50]);

subplot(132)
plot_curve(lag, alllags_CCG2_nofz, 'mean', nofz_color, 1,'cont'); hold on;
plot_curve(lag, alllags_CCG2_fz, 'mean', fz_color, 1,'cont'); hold off;
line([nanmean(lags_CCG2_fz) nanmean(lags_CCG2_fz)],[-1 1],'Color',fz_color,'LineWidth',0.5,'LineStyle','--');
line([nanmean(lags_CCG2_nofz) nanmean(lags_CCG2_nofz)],[-1 1],'Color',nofz_color,'LineWidth',0.5,'LineStyle','--');
line([0 0],[-1 1],'Color',[0 0 0],'LineWidth',0.5,'LineStyle','--');
xlabel('Tiempo (ms)'); ylabel('CCG'); title('BLA Lead - IL Lead');
ylim([0 1]); xlim([-50 50]);

subplot(133)
plot_curve(lag, alllags_CCG3_nofz, 'mean', nofz_color, 1,'cont'); hold on;
plot_curve(lag, alllags_CCG3_fz, 'mean', fz_color, 1,'cont'); hold off;
line([nanmean(lags_CCG3_fz) nanmean(lags_CCG3_fz)],[-1 1],'Color',fz_color,'LineWidth',0.5,'LineStyle','--');
line([nanmean(lags_CCG3_nofz) nanmean(lags_CCG3_nofz)],[-1 1],'Color',nofz_color,'LineWidth',0.5,'LineStyle','--');
line([0 0],[-1 1],'Color',[0 0 0],'LineWidth',0.5,'LineStyle','--');
xlabel('Tiempo (ms)'); ylabel('CCG'); title('PL Lead - IL Lead');
ylim([0 1]); xlim([-50 50]);

set(gcf, 'Color', 'white');
set(gcf, 'Position', [400, 400, 900, 250]);

% Ploteamos los gráficos de torta
figure()
subplot(121); leadplot(cake_CCG1_CS1,'PL','BLA','CS+');
subplot(122); leadplot(cake_CCG1_CS2,'PL','BLA','CS-');
p = leadtest(cake_CCG1_CS1,cake_CCG1_CS2); p = round(p,3);
if p >= 0.001; pres = strcat('p = ', sprintf('%.4f', p));
else pres = 'p < 0.001'; end
annotation('textbox',[0.46,0.5, 0.6, 0.05],'String',pres,'HorizontalAlignment','left','EdgeColor','none','FontSize',10);
    
figure()
subplot(121); leadplot(cake_CCG2_CS1,'IL','BLA','CS+');
subplot(122); leadplot(cake_CCG2_CS2,'IL','BLA','CS-');
p = leadtest(cake_CCG2_CS1,cake_CCG2_CS2); p = round(p,3);
if p >= 0.001; pres = strcat('p = ', sprintf('%.4f', p));
else pres = 'p < 0.001'; end
annotation('textbox',[0.46,0.5, 0.6, 0.05],'String',pres,'HorizontalAlignment','left','EdgeColor','none','FontSize',10);

figure()
subplot(121); leadplot(cake_CCG3_CS1,'IL','PL','CS+');
subplot(122); leadplot(cake_CCG3_CS2,'IL','PL','CS-');
p = leadtest(cake_CCG3_CS1,cake_CCG3_CS2); p = round(p,3);
if p >= 0.001; pres = strcat('p = ', sprintf('%.4f', p));
else pres = 'p < 0.001'; end
annotation('textbox',[0.46,0.5, 0.6, 0.05],'String',pres,'HorizontalAlignment','left','EdgeColor','none','FontSize',10);

figure()
subplot(121); leadplot(cake_CCG1_fz,'PL','BLA','Freezing');
subplot(122); leadplot(cake_CCG1_nofz,'PL','BLA','no Freezing');
p = leadtest(cake_CCG1_fz,cake_CCG1_nofz); p = round(p,3);
if p >= 0.001; pres = strcat('p = ', sprintf('%.4f', p));
else pres = 'p < 0.001'; end
annotation('textbox',[0.46,0.5, 0.6, 0.05],'String',pres,'HorizontalAlignment','left','EdgeColor','none','FontSize',10);
    
figure()
subplot(121); leadplot(cake_CCG2_fz,'IL','BLA','Freezing');
subplot(122); leadplot(cake_CCG2_nofz,'IL','BLA','no Freezing');
p = leadtest(cake_CCG2_fz,cake_CCG2_nofz); p = round(p,3);
if p >= 0.001; pres = strcat('p = ', sprintf('%.4f', p));
else pres = 'p < 0.001'; end
annotation('textbox',[0.46,0.5, 0.6, 0.05],'String',pres,'HorizontalAlignment','left','EdgeColor','none','FontSize',10);

figure()
subplot(121); leadplot(cake_CCG3_fz,'IL','PL','Freezing');
subplot(122); leadplot(cake_CCG3_nofz,'IL','PL','no Freezing');
p = leadtest(cake_CCG3_fz,cake_CCG3_nofz); p = round(p,3);
if p >= 0.001; pres = strcat('p = ', sprintf('%.4f', p));
else pres = 'p < 0.001'; end
annotation('textbox',[0.46,0.5, 0.6, 0.05],'String',pres,'HorizontalAlignment','left','EdgeColor','none','FontSize',10);

aleluya();