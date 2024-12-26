%% CCG (Cross-Correlograms) with xcorr.m para freezing vs. no freezing
% Output de este script:
% CCG: Valores de cross-correlación para cada par de regiones: BLA-PL,
% BLA-IL y PL-IL y para los eventos de freezing y no freezing. Estas
% matrices de CCG tienen N x lags datos
% lags: vector de lags para plotear en el eje X.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc
clear all

% En estas lineas selecciono que animales, paradigma y sesiones quiero analizar
% rats = [10,11,13,14,16,17,18,19]; % Filtro por animales para apetitivo
rats = [11,12,13,17,18,19,20]; % Filtro por animales para aversivo.
paradigm_toinclude = 'aversive'; % Filtro por el paradigma
session_toinclude = {'EXT1'}; % Filtro por las sesiones
trials_toinclude = 1:20;% Filtro por los trials
frange = 1; % Filtro por el rango de frecuencias que quiero analizar. Valor de 1 a 5 (4Hz,theta,beta,sgamma,fgamma)

% Seteamos algunas variables que van a ser constantes a lo largo de todo el analisis
timeww = {'freezing','nofreezing'}; % Ventanas de tiempo que voy a analizar
ntrials   = 1; % El número de trials o series temporales que va a analizar el modelo por vez
Fs        = 1250; % Sample rate original de la señal (Hz)

% Calculamos algunas variables que son constantes
CCG1_fz = [];
CCG2_fz = [];
CCG3_fz = [];
lag1_fz = []; 
lag2_fz = [];
lag3_fz = [];
CCG1_nofz = [];
CCG2_nofz = [];
CCG3_nofz = [];
lag1_nofz = []; 
lag2_nofz = [];
lag3_nofz = [];

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
                    fin_nofreezing(to_remove) = [];
                    clear to_remove;
                    
                    % Generamos los segmentos por evento de freezing
                    for i = 1:size(inicio_freezing,2)
                        samples = ceil(duracion_freezing(i)*Fs);
                        [SEG(1,:),SEG(2,:),SEG(3,:)] = extract_segments(filt_BLA(frange,:), filt_PL(frange,:), filt_IL(frange,:), t, inicio_freezing(i), fin_freezing(i), samples);
                        X1{i} = SEG;
                        clear SEG
                    end

                    % Generamos los segmentos por evento de noFreezing
                    for i = 1:size(inicio_nofreezing,2)
                        samples = ceil(duracion_nofreezing(i)*Fs);
                        [SEG(1,:),SEG(2,:),SEG(3,:)] = extract_segments(filt_BLA(frange,:), filt_PL(frange,:), filt_IL(frange,:), t, inicio_nofreezing(i), fin_nofreezing(i), samples);
                        X2{i} = SEG;
                        clear SEG
                    end
                    
                    % Freezing
                    for i = 1:size(X1,2)
                        X = X1{i};                      
                        [c1, lags1] = xcorr(X(1,:),X(2,:), 1*Fs, 'coeff'); % Cross-correlación entre BLA y PL. Lags positivos es que lidera PL
                        [c2, lags2] = xcorr(X(1,:),X(3,:), 1*Fs, 'coeff'); % Cross-correlación entre BLA e IL. Lags positivos es que lidera IL
                        [c3, lags3] = xcorr(X(2,:),X(3,:), 1*Fs, 'coeff'); % Cross-correlación entre PL e IL. Lags positivos es que lidera IL
                        CCG1_fz = cat(1,CCG1_fz,c1); 
                        CCG2_fz = cat(1,CCG2_fz,c2); 
                        CCG3_fz = cat(1,CCG3_fz,c3); 
                        lag1_fz = cat(1,lag1_fz,lags1); 
                        lag2_fz = cat(1,lag2_fz,lags2); 
                        lag3_fz = cat(1,lag3_fz,lags3); 
                        clear X c1 c2 c3 lags1 lags2 lags3
                        disp(strcat('  Processing Fz event N°= ',num2str(i)));
                    end
                    
                    % noFreezing
                    for i = 1:size(X2,2)
                        X = X2{i};
                        [c1, lags1] = xcorr(X(1,:),X(2,:), 1*Fs, 'coeff'); % Cross-correlación entre BLA y PL. Lags positivos es que lidera PL
                        [c2, lags2] = xcorr(X(1,:),X(3,:), 1*Fs, 'coeff'); % Cross-correlación entre BLA e IL. Lags positivos es que lidera IL
                        [c3, lags3] = xcorr(X(2,:),X(3,:), 1*Fs, 'coeff'); % Cross-correlación entre PL e IL. Lags positivos es que lidera IL
                        CCG1_nofz = cat(1,CCG1_nofz,c1); 
                        CCG2_nofz = cat(1,CCG2_nofz,c2); 
                        CCG3_nofz = cat(1,CCG3_nofz,c3); 
                        lag1_nofz = cat(1,lag1_nofz,lags1); 
                        lag2_nofz = cat(1,lag2_nofz,lags2); 
                        lag3_nofz = cat(1,lag3_nofz,lags3); 
                        clear X c1 c2 c3 lags1 lags2 lags3
                        clear X
                        disp(strcat('  Processing noFz event N°= ',num2str(i)));
                    end
                    
                end
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                clear lfp_BLA lfp_PL lfp_IL X1 X2 filt_BLA filt_PL filt_IL inicio_freezing fin_freezing...
                    inicio_nofreezing fin_nofreezing duracion_nofreezing duracion_freezing
                
                % Generamos una sola variable lag y eliminamos las demas
                lag = lag1_fz(1,:);
                
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

% Buscamos los lags para cada trial y lo guardamos en una variable
for i = 1:size(CCG1_fz,1)
    peakccg = islocalmax(CCG1_fz(i,:));
    values = lag(peakccg);
    [~, index] = min(abs(values)); % Encontrar el índice del valor más cercano a cero
    peak_CCG1_fz(i) = values(index); % Obtener el valor más cercano a cero
    clear peakccg values index
end

for i = 1:size(CCG1_nofz,1)
    peakccg = islocalmax(CCG1_nofz(i,:));
    values = lag(peakccg);
    [~, index] = min(abs(values)); % Encontrar el índice del valor más cercano a cero
    peak_CCG1_nofz(i) = values(index); % Obtener el valor más cercano a cero
    clear peakccg values index
end

for i = 1:size(CCG2_fz,1)
    peakccg = islocalmax(CCG2_fz(i,:));
    values = lag(peakccg);
    [~, index] = min(abs(values)); % Encontrar el índice del valor más cercano a cero
    peak_CCG2_fz(i) = values(index); % Obtener el valor más cercano a cero
    clear peakccg values index
end

for i = 1:size(CCG2_nofz,1)
    peakccg = islocalmax(CCG2_nofz(i,:));
    values = lag(peakccg);
    [~, index] = min(abs(values)); % Encontrar el índice del valor más cercano a cero
    peak_CCG2_nofz(i) = values(index); % Obtener el valor más cercano a cero
    clear peakccg values index
end

for i = 1:size(CCG3_fz,1)
    peakccg = islocalmax(CCG3_fz(i,:));
    values = lag(peakccg);
    [~, index] = min(abs(values)); % Encontrar el índice del valor más cercano a cero
    peak_CCG3_fz(i) = values(index); % Obtener el valor más cercano a cero
    clear peakccg values index
end

for i = 1:size(CCG3_nofz,1)
    peakccg = islocalmax(CCG3_nofz(i,:));
    values = lag(peakccg);
    [~, index] = min(abs(values)); % Encontrar el índice del valor más cercano a cero
    peak_CCG3_nofz(i) = values(index); % Obtener el valor más cercano a cero
    clear peakccg values index
end

% Calculamos algunas ultimas cosas de los resultados
fz_color = [255 140 0]/255; % Seteo el color para el freezing a un tono de naranja
nofz_color = [96 96 96]/255; % Seteo el color para el no freezing

% Ploteamos los lags con una escala de tiempo grande
figure()
subplot(131)
plot_curve(lag, CCG1_fz, 'mean', fz_color, 1); hold on;
plot_curve(lag, CCG1_nofz, 'mean', nofz_color, 1); hold off;
line([mean(peak_CCG1_fz) mean(peak_CCG1_fz)],[-1 1],'Color',fz_color,'LineWidth',0.5,'LineStyle','--');
line([mean(peak_CCG1_nofz) mean(peak_CCG1_nofz)],[-1 1],'Color',nofz_color,'LineWidth',0.5,'LineStyle','--');
xlabel('Tiempo (ms)'); ylabel('CCG'); title('BLA Lead - PL Lead');
ylim([-1 1]); xlim([-200 200]);

subplot(132)
plot_curve(lag, CCG2_fz, 'mean', fz_color, 1); hold on;
plot_curve(lag, CCG2_nofz, 'mean', nofz_color, 1); hold off;
line([mean(peak_CCG2_fz) mean(peak_CCG2_fz)],[-1 1],'Color',fz_color,'LineWidth',0.5,'LineStyle','--');
line([mean(peak_CCG2_nofz) mean(peak_CCG2_nofz)],[-1 1],'Color',nofz_color,'LineWidth',0.5,'LineStyle','--');
xlabel('Tiempo (ms)'); ylabel('CCG'); title('BLA Lead - IL Lead');
ylim([-1 1]); xlim([-200 200]);

subplot(133)
plot_curve(lag, CCG3_fz, 'mean', fz_color, 1); hold on;
plot_curve(lag, CCG3_nofz, 'mean', nofz_color, 1); hold off;
line([mean(peak_CCG3_fz) mean(peak_CCG3_fz)],[-1 1],'Color',fz_color,'LineWidth',0.5,'LineStyle','--');
line([mean(peak_CCG3_nofz) mean(peak_CCG3_nofz)],[-1 1],'Color',nofz_color,'LineWidth',0.5,'LineStyle','--');
xlabel('Tiempo (ms)'); ylabel('CCG'); title('PL Lead - IL Lead');
ylim([-1 1]); xlim([-200 200]);

set(gcf, 'Color', 'white');
set(gcf, 'Position', [400, 400, 900, 250]);

% Ploteamos los lags pero con una escala de tiempo más chica
figure()
subplot(131)
plot_curve(lag, CCG1_fz, 'mean', fz_color, 1); hold on;
plot_curve(lag, CCG1_nofz, 'mean', nofz_color, 1); hold off;
line([mean(peak_CCG1_fz) mean(peak_CCG1_fz)],[-1 1],'Color',fz_color,'LineWidth',0.5,'LineStyle','--');
line([mean(peak_CCG1_nofz) mean(peak_CCG1_nofz)],[-1 1],'Color',nofz_color,'LineWidth',0.5,'LineStyle','--');
xlabel('Tiempo (ms)'); ylabel('CCG'); title('BLA Lead - PL Lead');
ylim([-1 1]); xlim([-50 50]);

subplot(132)
plot_curve(lag, CCG2_fz, 'mean', fz_color, 1); hold on;
plot_curve(lag, CCG2_nofz, 'mean', nofz_color, 1); hold off;
line([mean(peak_CCG2_fz) mean(peak_CCG2_fz)],[-1 1],'Color',fz_color,'LineWidth',0.5,'LineStyle','--');
line([mean(peak_CCG2_nofz) mean(peak_CCG2_nofz)],[-1 1],'Color',nofz_color,'LineWidth',0.5,'LineStyle','--');
xlabel('Tiempo (ms)'); ylabel('CCG'); title('BLA Lead - IL Lead');
ylim([-1 1]); xlim([-50 50]);

subplot(133)
plot_curve(lag, CCG3_fz, 'mean', fz_color, 1); hold on;
plot_curve(lag, CCG3_nofz, 'mean', nofz_color, 1); hold off;
line([mean(peak_CCG3_fz) mean(peak_CCG3_fz)],[-1 1],'Color',fz_color,'LineWidth',0.5,'LineStyle','--');
line([mean(peak_CCG3_nofz) mean(peak_CCG3_nofz)],[-1 1],'Color',nofz_color,'LineWidth',0.5,'LineStyle','--');
xlabel('Tiempo (ms)'); ylabel('CCG'); title('PL Lead - IL Lead');
ylim([-1 1]); xlim([-50 50]);

set(gcf, 'Color', 'white');
set(gcf, 'Position', [400, 400, 900, 250]);

% Ploteamos Gráfico de barras
figure()
subplot(131)
plot_lags(peak_CCG1_fz,peak_CCG1_nofz);
title('BLA-PL');
subplot(132)
plot_lags(peak_CCG2_fz,peak_CCG2_nofz);
title('BLA-IL');
subplot(133)
plot_lags(peak_CCG3_fz,peak_CCG3_nofz);
title('PL-IL');

set(gcf, 'Color', 'white');
set(gcf, 'Position', [400, 400, 500, 250]);

aleluya();