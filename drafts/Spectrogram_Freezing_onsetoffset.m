%% Script para backupear los archivos R00D00_freezing.mat
clc;
clear all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% En estas lineas selecciono que animales, paradigma y sesiones quiero analizar
% rats = [10,11,13,14,16,17,18,19]; % Filtro por animales para apetitivo
rats = [11,12,13,17,18,19,20]; % Filtro por animales para aversivo
paradigm_toinclude = 'aversive'; % Filtro por el paradigma
session_toinclude = {'EXT1','EXT2','TEST'}; % Filtro por las sesiones
meantitle = 'Freezing vs. no-Freezing during Aversive'; % Titulo general que le voy a poner a la figura
region = 'BLA';
remove_50hz = 0; % 1 para limpiar e interpolar 50Hz, 0 para no limpiar.
remove_100hz = 1; % 1 para limpiar e interpolar 100Hz, 0 para no limpiar.
remove_epileptic = 1; % 1 para limpiar los momentos epil�pticos de la se�al, 0 para no limpiar
trigger = 'onset' % Trigerrear al onset o al offset
clim = [-0.75,0.75];
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
freezing_dist = [];

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
                    
                    load(strcat(name,'_sessioninfo.mat'), 'ch_total'); % N�mero de canales totales
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
                    end 
                    
                    % Cargamos los eventos de freezing
                    load(strcat(name,'_epileptic.mat'),'inicio_freezing','fin_freezing','inicio_epileptic','fin_epileptic','inicio_sleep','fin_sleep');
                    duracion_freezing = fin_freezing - inicio_freezing;

                    % Busco las posiciones en S donde inician los freezing
                    clear freezing_inicioenS freezing_finenS epileptic_inicioenS epileptic_finenS sleep_inicioenS sleep_finenS
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
                    pos1 = freezing_inicioenS > size(S,1) - 50;
                    pos2 = freezing_inicioenS < 50;
                    freezing_inicioenS(pos1) = [];
                    freezing_inicioenS(pos2) = [];
                    freezing_finenS(pos1) = [];
                    freezing_finenS(pos2) = [];
                    duracion_freezing(pos1) = [];
                    duracion_freezing(pos2) = [];
                    
                    % Busco n cantidad de bloques que no sean freezing,epileptic o sleep. La misma cantidad que los eventos de freezing
                    n = size(freezing_inicioenS,2);
                    i = 1;
                    while i <= n;
                        random_time = randi([100, size(S,1)-100]);
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
                    
                    % Elimino los freezing inicio en S que estan cerca del final de S
                    pos1 = nofreezing_inicioenS > size(S,1) - 50;
                    pos2 = nofreezing_inicioenS < 50;
                    nofreezing_inicioenS(pos1) = [];
                    nofreezing_inicioenS(pos2) = [];
                    
                    % Metemos todos los pedazos de S durante el CS en una gran matriz y
                    % calculamos la media

                    S_freezing = [];
                    S_nofreezing = [];
                    
                    window = 20; % Son 6 ventanas de 0.5 seg antes del freezing y 6 ventanas despues del freezing

                    for i = 1:size(freezing_inicioenS,2);
                        S_freezing(:,:,i) = S(freezing_inicioenS(1,i)-window:freezing_inicioenS(1,i)+window,:);
%                         S_freezing(:,:,i) = S(freezing_finenS(1,i)-window:freezing_finenS(1,i)+window,:);
                    end
                    
                    for i = 1:size(nofreezing_inicioenS,2);
                        S_nofreezing(:,:,i) = S(nofreezing_inicioenS(1,i)-window:nofreezing_inicioenS(1,i)+window,:);
                    end
                    
                    if size(S_freezing,2) == 1967 && size(S_freezing,1) == 41;
                        SPG_freezing = cat(3,SPG_freezing,S_freezing(:,:,:));
                        SPG_nofreezing = cat(3,SPG_nofreezing,S_nofreezing(:,:,:));
                        freezing_dist = cat(2,freezing_dist,duracion_freezing);
                        f1 = f;
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

n1 = size(SPG_freezing,3);
n2 = size(SPG_nofreezing,3);

SPGG_freezing = SPG_freezing;
SPGG_nofreezing = SPG_nofreezing;

% Nos quedamos con los que superan 1 seg
SPF_freezing = SPG_freezing(:,:,freezing_dist >= 1);

% Promediamos espectrogramas
SPG_freezing = nanmedian(SPG_freezing,3);
SPG_nofreezing = nanmedian(SPG_nofreezing,3);

SPG_freezing = bsxfun(@minus, SPG_freezing, nanmedian(SPG_freezing(1:end/2,:),1));
SPG_nofreezing = bsxfun(@minus, SPG_nofreezing, nanmedian(SPG_nofreezing(1:end/2,:),1));

%% Ploteamos Espectrogramas
figure();

smooth = 10;

clim1 = clim(1);
clim2 = clim(2); 

ax1 = subplot(1,3,1);
plot_matrix_smooth(SPG_freezing,t1,f1,'n',smooth);
ylabel(['Frequency (Hz)']);
xlabel('Time (sec.)');
title(strcat(region,' Freezing',' Mean Spectrogram',' n= ', num2str(n1)));
colormap(ax1,jet);    
hcb1 = colorbar; hcb1.YLabel.String = 'Power (Z-Scored)'; hcb1.FontSize = 10;
caxis([clim1 clim2]);
ylim([0 12]);
xlim([-3 3]);
set(gca, 'XTick', -3:1:3);
hold on
line([0 0],[0 150],'Color',behaviour_color,'LineWidth',0.5,'LineStyle','--');
if strcmp(paradigm_toinclude,'appetitive');
    line([10 10],[0 150],'Color',behaviour_color,'LineWidth',0.5,'LineStyle','--');
elseif strcmp(paradigm_toinclude,'aversive');
    line([60 60],[0 150],'Color',behaviour_color,'LineWidth',0.5,'LineStyle','--');
end
hold off

ax2 = subplot(1,3,2);
plot_matrix_smooth(SPG_nofreezing,t1,f1,'n',smooth);
ylabel(['Frequency (Hz)']);
xlabel('Time (sec.)');
title(strcat(region,' no Freezing',' Mean Spectrogram',' n= ', num2str(n2)));
colormap(ax2,jet);    
hcb2 = colorbar; hcb2.YLabel.String = 'Power (Z-Scored)'; hcb2.FontSize = 10;
caxis([clim1 clim2]);
ylim([0 12]);
xlim([-3 3]);
set(gca, 'XTick', -3:1:3);
hold on
line([0 0],[0 150],'Color',behaviour_color,'LineWidth',0.5,'LineStyle','--');
if strcmp(paradigm_toinclude,'appetitive');
    line([10 10],[0 150],'Color',behaviour_color,'LineWidth',0.5,'LineStyle','--');
elseif strcmp(paradigm_toinclude,'aversive');
    line([60 60],[0 150],'Color',behaviour_color,'LineWidth',0.5,'LineStyle','--');
end
hold off

% Link axes
linkaxes([ax1 ax2],'xy');

% Set figure properties
set(gcf, 'Color', 'white');
set(gcf, 'Position', [100, 600, 1200, 300]);

% Obtenemos las posiciones de las figuras
pos_ax1 = get(ax1, 'Position');
pos_ax2 = get(ax2, 'Position');
pos_ax1c = get(hcb1, 'Position');
pos_ax2c = get(hcb2, 'Position');

% Seteamos la posici�n de la barra de color
set(hcb1, 'Position', [pos_ax1c(1) 0.42 pos_ax1c(3) 0.2]);
set(hcb2, 'Position', [pos_ax2c(1) 0.42 pos_ax2c(3) 0.2]);

% Seteamos la posici�n de la figura
set(ax1, 'Position', [0.13 0.18 0.16 0.7]);
set(ax2, 'Position', [0.41 0.18 0.16 0.7]);