%% Script para backupear los archivos R00D00_freezing.mat
clc;
clear all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% En estas lineas selecciono que animales, paradigma y sesiones quiero analizar
% rats = [10,11,13,14,16,17,18,19]; % Filtro por animales para apetitivo
rats = [11,12,13,17,18,19,20]; % Filtro por animales para aversivo
paradigm_toinclude = 'aversive'; % Filtro por el paradigma
session_toinclude = {'EXT1','EXT2','TEST'}; % Filtro por las sesiones
meantitle = 'Freezing vs. no-Freezing PSD'; % Titulo general que le voy a poner a la figura
region = 'BLA';
remove_50hz = 0; % 1 para limpiar e interpolar 50Hz, 0 para no limpiar.
remove_100hz = 1; % 1 para limpiar e interpolar 100Hz, 0 para no limpiar.
remove_epileptic = 1; % 1 para limpiar los momentos epilépticos de la señal, 0 para no limpiar
window_postonset = 3; % Ventana en segundos post onset del evento para cuantificar el PSD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Define the parent folder containing the 'Rxx' folders
parentFolder = 'D:\Doctorado\Backup Ordenado';

% List all 'Rxx' folders in the parent folder
R_folders = dir(fullfile(parentFolder, 'R*'));

% Inicializo algunas variables
PSD_freezing = [];
PSD_nofreezing = [];
SPG_freezing = [];
SPG_nofreezing = [];

% Seteamos algunos colores para los ploteos
if strcmp(paradigm_toinclude,'appetitive');
    cs1_color = [255 140 0]/255; % Seteo el color para el freezing a un tono de naranja
    cs2_color = [96 96 96]/255; % Seteo el color para el CS-
    behaviour_color = [10 10 10]/255; % Seteo el color para comportamiento
elseif strcmp(paradigm_toinclude,'aversive');
    cs1_color = [255 140 0]/255; % Seteo el color para el freezing a un tono de naranja
    cs2_color = [96 96 96]/255; % Seteo el color para el CS-
    behaviour_color = [10 10 10]/255; % Seteo el color para comportamiento
end

% Iterate through each 'Rxx' folder
k = 1;
for r = rats;
    current_R_folder = fullfile(parentFolder, R_folders(r).name);
    disp(['Processing folder: ' current_R_folder]);
    
    % List all subfolders inside the 'Rxx' folder
    D_folders = dir(fullfile(current_R_folder, 'R*D*'));
    D_folders = D_folders([D_folders.isdir]);
    
    % Iterate through each 'RxDy' folder
    for d = 1:length(D_folders)
        current_D_folder = fullfile(current_R_folder, D_folders(d).name);
        disp(['  Processing subfolder: ' current_D_folder]);
        
        % Change the current folder to the 'RxDy' subfolder
        cd(current_D_folder);
        [~,D,X] = fileparts(current_D_folder); name = D([1:6]);
        
        if exist(strcat(name,'_sessioninfo.mat')) == 2;
            session_end = [];
            load(strcat(name,'_sessioninfo.mat'));
            if strcmp(paradigm,paradigm_toinclude) && (any(strcmp(session, session_toinclude))||any(strcmp(session_end, session_toinclude)));
                disp(['      Session found, including in dataset...']);
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                if exist(strcat(name,'_sessioninfo.mat')) == 2 && ...
                        exist(strcat(name,'_specgram_',region,'LowFreq.mat')) == 2 && ...
                        exist(strcat(name,'_noise.csv')) == 2 && ...
                        exist(strcat(name,'_epileptic.mat')) == 2 && ...
                        exist(strcat(name,'_freezing.mat')) == 2;        
                    
                    load(strcat(name,'_sessioninfo.mat'), 'ch_total'); % Número de canales totales
                    load(strcat(name,'_sessioninfo.mat'), 'paradigm'); % Tipo de paradigma. Appetitive or aversive

                    % Cargo el espectrograma ya calculado
                    disp(['Uploading full band multi-taper spectrogram...']);
                    load(strcat(name,'_specgram_',region,'LowFreq.mat'));

                    % Quitamos las partes del espectrograma que tienen ruido
                    disp(['Removing noise from analysis...']);
                    noise = (unique(csvread(strcat(name,'_noise.csv'))))';
                    % Busco las posiciones en S donde se ubica el ruido
                    clear noise_enS;
                    for i = 1:size(noise,2);
                        noise_enS(i) = find(abs(t-noise(i)) == min(abs(t-noise(i))));
                        if noise_enS(i) <= 5
                            S(noise_enS(1):noise_enS(i)+5,:) = NaN;
                        else
                            S(noise_enS(i)-5:noise_enS(i)+5,:) = NaN;
                        end
                    end

                    % Cargo los tiempos de los tonos
                    load(strcat(name,'_freezing.mat'),'TTL_CS1_inicio','TTL_CS1_fin','TTL_CS2_inicio','TTL_CS2_fin');

                    % Quitamos interpolamos la franja de 100 Hz que es ruidosa
                    if remove_100hz == 1;
                        fmin = find(abs(f-95) == min(abs(f-95)));
                        fmax = find(abs(f-105) == min(abs(f-105)));
                        for i = 1:fmax-fmin;
                            S(:,fmin+i) = S(:,fmin) + i*((S(:,fmax+1)-S(:,fmin-1))/(fmax-fmin));
                        end
                    end
                    
                    % Quitamos interpolamos la franja de 50 Hz que es ruidosa
                    if remove_50hz == 1;
                        fmin = find(abs(f-48) == min(abs(f-48)));
                        fmax = find(abs(f-52) == min(abs(f-52)));
                        for i = 1:fmax-fmin;
                            S(:,fmin+i) = S(:,fmin) + i*((S(:,fmax+1)-S(:,fmin-1))/(fmax-fmin));
                        end
                    end
                    
                    % Normalización del espectrograma
                    S = bsxfun(@times, S, f);                    
                    S = bsxfun(@rdivide, S, nanmedian(nanmedian(S,1)));
                    
                    % Cargamos los eventos de freezing
                    load(strcat(name,'_epileptic.mat'),'inicio_freezing','fin_freezing','inicio_epileptic','fin_epileptic','inicio_sleep','fin_sleep');
                    
                    % Busco las posiciones en S donde inician los freezing
                    j = 1;
                    for i = 1:size(inicio_freezing,2);
                        freezing_inicioenS(j) = min(find(abs(t-inicio_freezing(1,i)) == min(abs(t-inicio_freezing(1,i)))));
                        freezing_finenS(j) = min(find(abs(t-fin_freezing(1,i)) == min(abs(t-fin_freezing(1,i)))));
                        j = j + 1;
                    end
                    j = 1;
                    for i = 1:size(inicio_epileptic,2);
                        epileptic_inicioenS(j) = min(find(abs(t-inicio_epileptic(1,i)) == min(abs(t-inicio_epileptic(1,i)))));
                        epileptic_finenS(j) = min(find(abs(t-fin_epileptic(1,i)) == min(abs(t-fin_epileptic(1,i)))));
                        j = j + 1;
                    end
                    j = 1;
                    for i = 1:size(inicio_sleep,2);
                        sleep_inicioenS(j) = min(find(abs(t-inicio_sleep(1,i)) == min(abs(t-inicio_sleep(1,i)))));
                        sleep_finenS(j) = min(find(abs(t-fin_sleep(1,i)) == min(abs(t-fin_sleep(1,i)))));
                        j = j + 1;
                    end
                    
                    % Elimino los freezing inicio en S que estan cerca del final de S
                    pos1 = freezing_inicioenS > size(S,1) - 12;
                    pos2 = freezing_inicioenS < 12;
                    freezing_inicioenS(pos1) = [];
                    freezing_inicioenS(pos2) = [];
                    freezing_finenS(pos1) = [];
                    freezing_finenS(pos2) = [];
                    
                    % Busco n cantidad de bloques que no sean freezing,epileptic o sleep. La misma cantidad que los eventos de freezing
                    n = size(freezing_inicioenS,2);
                    i = 1;
                    while i <= n;
                        random_time = randi([7, size(S,1)-7]);
                        is_between_freezing = any((random_time >= freezing_inicioenS-7) & (random_time <= freezing_finenS+7));
                        is_between_epileptic = any((random_time >= epileptic_inicioenS-7) & (random_time <= epileptic_finenS+7));
                        is_between_sleep = any((random_time >= sleep_inicioenS-7) & (random_time <= sleep_finenS+7));
                        if is_between_freezing || is_between_epileptic || is_between_sleep;
                            % Do nothing
                        else
                            nofreezing_inicioenS(i) = random_time;
                            i = i + 1;
                        end    
                    end
                    
                    % Metemos todos los pedazos de S durante el CS en una gran matriz y
                    % calculamos la media

                    S_freezing = [];
                    S_nofreezing = [];
                    
                    window = window_postonset*2; % Para el PSD tomo 3 seg despues del onset del freezing

                    for i = 1:size(freezing_inicioenS,2);
                        S_freezing(:,:,i) = S(freezing_inicioenS(1,i):freezing_inicioenS(1,i)+window,:);
                        S_nofreezing(:,:,i) = S(nofreezing_inicioenS(1,i):nofreezing_inicioenS(1,i)+window,:);
                    end
                    
                    S_freezing = nanmedian(S_freezing,1); S_freezing = squeeze(S_freezing); S_freezing = S_freezing';
                    S_nofreezing = nanmedian(S_nofreezing,1); S_nofreezing = squeeze(S_nofreezing); S_nofreezing = S_nofreezing';
                       
                    if size(S_freezing,2) == 1967;
                        PSD_freezing = vertcat(PSD_freezing,S_freezing(:,:));
                        PSD_nofreezing = vertcat(PSD_nofreezing,S_nofreezing(:,:));
                    end 
                end
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            end
        end      
    end      
    % Go back to the 'Rxx' folder
    cd(current_R_folder);
end
cd(parentFolder);

% Creamos el vector de tiempo
if ~isempty(SPG_freezing);
        t1 = 0.5:0.5:size(SPG_freezing,1)*0.5;
        t1 = t1 - t1(window+1);        
end

% Ploteamos PSD
f1 = f;
figure();
smoothing = 20;

% Espectro de potencias para el freezing
S_data = PSD_freezing;
y = (smooth(nanmedian(S_data),smoothing))'; % your mean vector;
x = f1;
 stdem = (smooth(mad(S_data,1)/sqrt(size(S_data,1)),smoothing))';
curve1 = y + stdem;
curve2 = y - stdem;
x2 = [x, fliplr(x)];
inBetween = [curve1, fliplr(curve2)];
p1 = fill(x2, inBetween, cs1_color,'LineStyle','none');
set(p1,'facealpha',.4)
hold on;
plot(x, y, 'Color',cs1_color, 'LineWidth', 1);
hold on;
clear S_data;

% Espectro de potencias para el nofreezing
S_data = PSD_nofreezing;
y = (smooth(nanmedian(S_data),smoothing))'; % your mean vector;
x = f1;
stdem = (smooth(mad(S_data,1)/sqrt(size(S_data,1)),smoothing))';
curve1 = y + stdem;
curve2 = y - stdem;
x2 = [x, fliplr(x)];
inBetween = [curve1, fliplr(curve2)];
p2 = fill(x2, inBetween,cs2_color,'LineStyle','none');
set(p2,'facealpha',.3)
hold on;
plot(x, y, 'Color',cs2_color, 'LineWidth', 1);
hold on;
clear S_data;

xlim([1 12]);
lims = ylim;
ylim1 = lims(1);
ylim2 = lims(2);
xlabel('Frequency (Hz)');
ylabel('Power (dB)');
title(meantitle);
hold on;
set(gca, 'YTick', 0:1:ylim2);
hold on;

set(gcf, 'Color', 'white');
set(gcf, 'Position', [500, 500, 300, 250]);
