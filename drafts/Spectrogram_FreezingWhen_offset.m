%% Script para backupear los archivos R00D00_freezing.mat
clc;
clearvars -except freezing_dist_ext1 freezing_dist_ext2 freezing_dist_rein;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% En estas lineas selecciono que animales, paradigma y sesiones quiero analizar
% rats = [10,11,13,14,16,17,18,19]; % Filtro por animales para apetitivo
rats = [11,12,13,17,18,19,20]; % Filtro por animales para aversivo
paradigm_toinclude = 'aversive'; % Filtro por el paradigma
% session_toinclude = {'EXT1','EXT2','TEST'}; % Filtro por las sesiones
session_toinclude = {'EXT1'}; % Filtro por las sesiones
meantitle = 'Freezing vs. Movility during Aversive'; % Titulo general que le voy a poner a la figura
region = 'IL';
remove_50hz = 0; % 1 para limpiar e interpolar 50Hz, 0 para no limpiar.
remove_100hz = 1; % 1 para limpiar e interpolar 100Hz, 0 para no limpiar.
remove_epileptic = 1; % 1 para limpiar los momentos epilépticos de la señal, 0 para no limpiar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Define the parent folder containing the 'Rxx' folders
parentFolder = 'D:\Doctorado\Backup Ordenado';

% List all 'Rxx' folders in the parent folder
R_folders = dir(fullfile(parentFolder, 'R*'));

% Inicializo algunas variables
PSD_freezing_CS1 = [];
PSD_freezing_CS2 = [];
PSD_freezing_ITI = [];
PSD_nofreezing = [];
SPG_freezing_CS1 = [];
SPG_freezing_CS2 = [];
SPG_freezing_ITI = [];
SPG_freezing = [];
SPG_nofreezing = [];
freezing_dist = [];
freezing_when = [];

% Seteamos algunos colores para los ploteos
if strcmp(paradigm_toinclude,'appetitive');
    cs1_color = [0 128 0]/255; % Seteo el color para el CS+ apetitivo
    cs2_color = [96 96 96]/255; % Seteo el color para el CS-
    behaviour_color = [10 10 10]/255; % Seteo el color para comportamiento
elseif strcmp(paradigm_toinclude,'aversive');
    cs1_color = [118 6 154]/255; % Seteo el color para el CS+ aversivo
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

                    % Calculate the z-score using median and MAD
                    for i = 1:size(S,2);
                        S(:,i) = (S(:,i) - nanmedian(S(:,i))) / nanmedian(abs(S(:,i) - nanmedian(S(:,i))));
%                         S(:,i) = S(:,i) - nanmedian(nanmedian(abs(S(:,i) - nanmedian(S(:,i)))));
                    end                
                    
                    % Cargamos los eventos de freezing
                    load(strcat(name,'_epileptic.mat'),'inicio_freezing','fin_freezing','inicio_epileptic','fin_epileptic','inicio_sleep','fin_sleep');
                    duracion_freezing = fin_freezing - inicio_freezing;
                    
                    % Divide freezing by onset in CS1, CS2 or ITI
                    freezing_type = [];
                    for i = 1:size(inicio_freezing,2);
                        if any((inicio_freezing(i) >= TTL_CS1_inicio) .* (inicio_freezing(i) < TTL_CS1_fin));
                            freezing_type(1,i) = 1; % Type 1 for freezing onset during CS1
                        elseif any((inicio_freezing(i) >= TTL_CS2_inicio) .* (inicio_freezing(i) < TTL_CS2_fin));
                            freezing_type(1,i) = 2; % Type 2 for freezing onset during CS2
                        else
                            freezing_type(1,i) = 3; % Type 3 for freezing onset during ITI
                        end
                    end
                    % tabulate(freezing_type);
                    
                    % Busco las posiciones en S donde inician los freezing
                    clear freezing_inicioenS freezing_finenS epileptic_inicioenS epileptic_finenS sleep_inicioenS sleep_finenS
                    j = 1;
                    for i = 1:size(inicio_freezing,2);
                        freezing_inicioenS(j) = min(find(abs(t-fin_freezing(1,i)) == min(abs(t-fin_freezing(1,i)))));
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
                    pos1 = freezing_inicioenS > size(S,1) - 50;
                    pos2 = freezing_inicioenS < 50;
                    freezing_inicioenS(pos1) = [];
                    freezing_inicioenS(pos2) = [];
                    freezing_finenS(pos1) = [];
                    freezing_finenS(pos2) = [];
                    duracion_freezing(pos1) = [];
                    duracion_freezing(pos2) = [];
                    freezing_type(pos1) = [];
                    freezing_type(pos2) = [];
                    
                    % Metemos todos los pedazos de S durante el CS en una gran matriz y
                    % calculamos la media

                    S_freezing = [];
                    
                    window = 20; % Son 6 ventanas de 0.5 seg antes del freezing y 6 ventanas despues del freezing

                    for i = 1:size(freezing_inicioenS,2);
                        S_freezing(:,:,i) = S(freezing_inicioenS(1,i)-window:freezing_inicioenS(1,i)+window,:);
                    end
                    
                    if size(S_freezing,2) == 1967 && size(S_freezing,1) == 41;
                        freezing_dist = cat(2,freezing_dist,duracion_freezing);
                        freezing_when = cat(2,freezing_when,freezing_type);
                        for i = 1:size(S_freezing,3)
                            if freezing_when(1,i) == 1;
                                SPG_freezing_CS1 = cat(3,SPG_freezing_CS1,S_freezing(:,:,i));
                                SPG_freezing = cat(3,SPG_freezing,S_freezing(:,:,i));
                            elseif freezing_when(1,i) == 2;
                                SPG_freezing_CS2 = cat(3,SPG_freezing_CS2,S_freezing(:,:,i));
                                SPG_freezing = cat(3,SPG_freezing,S_freezing(:,:,i));
                            elseif freezing_when(1,i) == 3;
                                SPG_freezing_ITI = cat(3,SPG_freezing_ITI,S_freezing(:,:,i));
                                SPG_freezing = cat(3,SPG_freezing,S_freezing(:,:,i));
                            end
                        end 
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

% Creamos el vector de tiempo
if ~isempty(SPG_freezing_CS1);
        t1 = 0.5:0.5:size(SPG_freezing_CS1,1)*0.5;
        t1 = t1 - t1(window+1);        
end

n1 = size(SPG_freezing_CS1,3);
n2 = size(SPG_freezing_CS2,3);
n3 = size(SPG_freezing_ITI,3);

% Promediamos espectrogramas
SPG_freezing_CS1 = nanmedian(SPG_freezing_CS1,3);
SPG_freezing_CS2 = nanmedian(SPG_freezing_CS2,3);
SPG_freezing_ITI = nanmedian(SPG_freezing_ITI,3);

% Normalizamos a la actividad 
SPG_freezing_CS1 = bsxfun(@minus, SPG_freezing_CS1, mean(SPG_freezing_CS1(end/2:end,:),1));
SPG_freezing_CS2 = bsxfun(@minus, SPG_freezing_CS2, mean(SPG_freezing_CS2(end/2:end,:),1));
SPG_freezing_ITI = bsxfun(@minus, SPG_freezing_ITI, mean(SPG_freezing_ITI(end/2:end,:),1));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Ploteamos Espectrogramas
figure();

smooth = 10;

clim1 = -1;
clim2 = 1; 

ax1 = subplot(1,3,1);
plot_matrix_smooth(SPG_freezing_CS1,t1,f1,'n',smooth);
ylabel(['Frequency (Hz)']);
xlabel('Time (sec.)');
title(strcat(region,' Freezing',' n= ', num2str(n1),',CS+'));
colormap(ax1,jet);    
hcb1 = colorbar; hcb1.YLabel.String = 'Power (Z-Scored)'; hcb1.FontSize = 10;
caxis([clim1 clim2]);
ylim([0 12]);
xlim([-3 3]);
hold on
line([0 0],[0 150],'Color',behaviour_color,'LineWidth',0.5,'LineStyle','--');
if strcmp(paradigm_toinclude,'appetitive');
    line([10 10],[0 150],'Color',behaviour_color,'LineWidth',0.5,'LineStyle','--');
elseif strcmp(paradigm_toinclude,'aversive');
    line([60 60],[0 150],'Color',behaviour_color,'LineWidth',0.5,'LineStyle','--');
end
hold off

ax2 = subplot(1,3,2);
plot_matrix_smooth(SPG_freezing_CS2,t1,f1,'n',smooth);
ylabel(['Frequency (Hz)']);
xlabel('Time (sec.)');
title(strcat(region,' Freezing',' n= ', num2str(n2),',CS-'));
colormap(ax1,jet);    
hcb2 = colorbar; hcb2.YLabel.String = 'Power (Z-Scored)'; hcb2.FontSize = 10;
caxis([clim1 clim2]);
ylim([0 12]);
xlim([-3 3]);
hold on
line([0 0],[0 150],'Color',behaviour_color,'LineWidth',0.5,'LineStyle','--');
if strcmp(paradigm_toinclude,'appetitive');
    line([10 10],[0 150],'Color',behaviour_color,'LineWidth',0.5,'LineStyle','--');
elseif strcmp(paradigm_toinclude,'aversive');
    line([60 60],[0 150],'Color',behaviour_color,'LineWidth',0.5,'LineStyle','--');
end
hold off

ax3 = subplot(1,3,3);
plot_matrix_smooth(SPG_freezing_ITI,t1,f1,'n',smooth);
ylabel(['Frequency (Hz)']);
xlabel('Time (sec.)');
title(strcat(region,' Freezing',' n= ', num2str(n3),',ITI'));
colormap(ax1,jet);    
hcb3 = colorbar; hcb3.YLabel.String = 'Power (Z-Scored)'; hcb3.FontSize = 10;
caxis([clim1 clim2]);
ylim([0 12]);
xlim([-3 3]);
hold on
line([0 0],[0 150],'Color',behaviour_color,'LineWidth',0.5,'LineStyle','--');
if strcmp(paradigm_toinclude,'appetitive');
    line([10 10],[0 150],'Color',behaviour_color,'LineWidth',0.5,'LineStyle','--');
elseif strcmp(paradigm_toinclude,'aversive');
    line([60 60],[0 150],'Color',behaviour_color,'LineWidth',0.5,'LineStyle','--');
end
hold off

% Link axes
linkaxes([ax1 ax2 ax3],'xy');

% Set figure properties
set(gcf, 'Color', 'white');
set(gcf, 'Position', [100, 600, 1200, 300]);

% Obtenemos las posiciones de las figuras
pos_ax1 = get(ax1, 'Position');
pos_ax2 = get(ax2, 'Position');
pos_ax3 = get(ax3, 'Position');
pos_ax1c = get(hcb1, 'Position');
pos_ax2c = get(hcb2, 'Position');
pos_ax3c = get(hcb3, 'Position');

% Seteamos la posición de la barra de color
set(hcb1, 'Position', [pos_ax1c(1) 0.42 pos_ax1c(3) 0.2]);
set(hcb2, 'Position', [pos_ax2c(1) 0.42 pos_ax2c(3) 0.2]);
set(hcb3, 'Position', [pos_ax3c(1) 0.42 pos_ax3c(3) 0.2]);

% Seteamos la posición de la figura
set(ax1, 'Position', [0.13 0.18 0.16 0.7]);
set(ax2, 'Position', [0.41 0.18 0.16 0.7]);
set(ax3, 'Position', [0.69 0.18 0.16 0.7]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
