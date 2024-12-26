%% Script para backupear los archivos R00D00_freezing.mat
clc;
clear all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% En estas lineas selecciono que animales, paradigma y sesiones quiero analizar
% rats = [10,11,13,14,16,17,18,19]; % Filtro por animales para apetitivo
% rats = [11,12,13,17,18,19,20]; % Filtro por animales para aversivo
rats = [13,17,18,19,20];
% rats = 12;
paradigm_toinclude = 'aversive'; % Filtro por el paradigma
session_toinclude = {'EXT2'}; % Filtro por las sesiones
trials_toinclude = 1:10; % Filtro por los trials
meantitle = ''; % Titulo general que le voy a poner a la figura
region = 'BLA';
remove_50hz = 1; % 1 para limpiar e interpolar 50Hz, 0 para no limpiar.
remove_100hz = 1; % 1 para limpiar e interpolar 100Hz, 0 para no limpiar.
remove_epileptic = 1; % 1 para limpiar los momentos epilépticos de la señal, 0 para no limpiar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Define the parent folder containing the 'Rxx' folders
parentFolder = 'D:\Doctorado\Backup Ordenado';

% List all 'Rxx' folders in the parent folder
R_folders = dir(fullfile(parentFolder, 'R*'));

% Inicializo algunas variables
PSD_CS1 = [];
PSD_CS2 = [];

% Seteamos algunos colores para los ploteos
if strcmp(paradigm_toinclude,'appetitive');
    cs1_color = colores('Apetitivo');
    cs2_color = colores('Control');
    behaviour_color = colores('Negro');
elseif strcmp(paradigm_toinclude,'aversive');
    cs1_color = colores('Aversivo');
    cs2_color = colores('Control');
    behaviour_color = colores('Negro');
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
                    
                    % Quitamos las partes del espectrograma que son epilépticas
                    if remove_epileptic == 1;
                        if exist(strcat(name,'_epileptic.mat')) == 2;
                            load(strcat(name,'_epileptic.mat'),'inicio_epileptic','fin_epileptic');
                            % Buscamos la esta actividad en S
                            j = 1;
                            for i = 1:size(inicio_epileptic,2);
                                ep_inicioenS(j) = find(abs(t-inicio_epileptic(1,i)) == min(abs(t-inicio_epileptic(1,i))));
                                ep_finenS(j) = find(abs(t-fin_epileptic(1,i)) == min(abs(t-fin_epileptic(1,i))));
                                j = j + 1;
                            end
                            % Reemplazamos con Nan donde hay actividad epileptica
                            clear ep_enS;
                            for i = 1:size(ep_inicioenS,2);
                                    S(ep_inicioenS(i):ep_finenS(i),:) = NaN;
                            end
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

                    % Busco las posiciones en S donde inician y finalizan los tonos
                    j = 1;
                    for i = 1:size(TTL_CS1_inicio,1);
                        CS1_inicioenS(j) = min(find(abs(t-TTL_CS1_inicio(i)) == min(abs(t-TTL_CS1_inicio(i)))));
                        CS1_finenS(j) = min(find(abs(t-TTL_CS1_fin(i)) == min(abs(t-TTL_CS1_fin(i)))));
                        CS2_inicioenS(j) = min(find(abs(t-TTL_CS2_inicio(i)) == min(abs(t-TTL_CS2_inicio(i)))));
                        CS2_finenS(j) = min(find(abs(t-TTL_CS2_fin(i)) == min(abs(t-TTL_CS2_fin(i)))));
                        j = j + 1;
                    end

                    % Metemos todos los pedazos de S durante el CS en una gran matriz y
                    % calculamos la media

                    S_CS1 = [];
                    S_CS2 = [];

                    window= round(mean(CS1_finenS - CS1_inicioenS));

                    if CS1_inicioenS(1,end) < size(S,1);
                        for i = 1:size(CS1_inicioenS,2);
                            S_CS1(:,:,i) = S(CS1_inicioenS(1,i):CS1_inicioenS(1,i)+window,:);
                            S_CS2(:,:,i) = S(CS2_inicioenS(1,i):CS2_inicioenS(1,i)+window,:);
                        end
                    else 
                        for i = 1:size(CS1_inicioenS,2);
                            S_CS1(:,:,i) = nan(window+1,size(f,2));
                            S_CS2(:,:,i) = nan(window+1,size(f,2));
                        end
                    end
                    
                    S_CS1 = nanmean(S_CS1,1); S_CS1 = squeeze(S_CS1); S_CS1 = S_CS1';
                    S_CS2 = nanmean(S_CS2,1); S_CS2 = squeeze(S_CS2); S_CS2 = S_CS2';
                       
                    if size(S_CS1,2) == 1967;
                        PSD_CS1 = vertcat(PSD_CS1,S_CS1(trials_toinclude,:));
                        PSD_CS2 = vertcat(PSD_CS2,S_CS2(trials_toinclude,:));
                        k = k + 1;
                        f1 = f;
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

% Figura para espectro completo de 1 a 100 Hz con escala logarítmica
figure();
smoothing = 20;

% Espectro de potencias para el CS+
S_data = PSD_CS1;
y = (smooth(nanmedian(S_data),smoothing))'; % Media suavizada
x = f1; % Frecuencias
stdem = (smooth(mad(S_data,1)/sqrt(size(S_data,1)),smoothing))'; % Error estándar
curve1 = y + stdem;
curve2 = y - stdem;
x2 = [x, fliplr(x)];
inBetween = [curve1, fliplr(curve2)];

% Ploteo CS+
% Filtrado de valores no positivos para evitar problemas en la escala log
validIdx = x > 0; % Indices de valores válidos mayores a cero
x_valid = x(validIdx); % Filtra x
curve1_valid = curve1(validIdx); % Filtra curva superior
curve2_valid = curve2(validIdx); % Filtra curva inferior

% Redefinir x2 e inBetween
x2 = [x_valid, fliplr(x_valid)];
inBetween = [curve1_valid, fliplr(curve2_valid)];

% Ploteo usando fill en escala logarítmica
p1 = fill(x2, inBetween, cs1_color, 'LineStyle', 'none');
set(p1, 'facealpha', .4);
hold on;
plot(x, y, 'Color', cs1_color, 'LineWidth', 0.5);
hold on;
clear S_data;

% Espectro de potencias para el CS2
S_data = PSD_CS2;
y = (smooth(nanmedian(S_data),smoothing))';
stdem = (smooth(mad(S_data,1)/sqrt(size(S_data,1)),smoothing))';
curve1 = y + stdem;
curve2 = y - stdem;
x2 = [x, fliplr(x)];
inBetween = [curve1, fliplr(curve2)];

% Ploteo CS2
% Filtrado de valores no positivos para evitar problemas en la escala log
validIdx = x > 0; % Indices de valores válidos mayores a cero
x_valid = x(validIdx); % Filtra x
curve1_valid = curve1(validIdx); % Filtra curva superior
curve2_valid = curve2(validIdx); % Filtra curva inferior

% Redefinir x2 e inBetween
x2 = [x_valid, fliplr(x_valid)];
inBetween = [curve1_valid, fliplr(curve2_valid)];

% Ploteo usando fill en escala logarítmica
p1 = fill(x2, inBetween, cs2_color, 'LineStyle', 'none');
set(p1, 'facealpha', .4);
hold on;
plot(x, y, 'Color', cs2_color, 'LineWidth', 0.5);
hold on;
clear S_data;

% Configuraciones del gráfico
xlim([1 100]); % Límite del eje x
ylim([0 4]); % Límite del eje y
set(gca, 'XScale', 'log'); % Escala logarítmica en el eje x
set(gca, 'XTick', [1 2 4 8 16 32 64 100],'XTickLabel', {'1','2','4','8','16','32','64','100'}); % Setea los YTicks en los valores deseados
set(gca, 'XMinorTick', 'off'); % Elimina ticks menores automáticos
set(gca, 'YTick', [0:1:10]);
xlabel('Frecuencia (Hz)');
ylabel('Potencia Normalizada');
title(meantitle);

% Personalización adicional
set(gca, 'FontSize', 7);
set(gcf, 'Color', 'white');
set(gcf, 'Position', [400, 400, 200, 120]); % Tamaño de la figura