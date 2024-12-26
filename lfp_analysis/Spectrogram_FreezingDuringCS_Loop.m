%% Script para calcular un espectrograma promedio de todos los animales y todas las sesiones seleccionadas
% Espectrograma centrado al freezing que ocurre durante el tono CS, 20 segundos antes y 20 segundos después
% OUTPUT: Figura de 3 subplots con el espectrograma al CS+, espectrograma al CS- y delta CS+/CS-
clear all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% En estas lineas selecciono que animales, paradigma y sesiones quiero analizar
% rats = [10,11,13,14,16,17,18,19]; % Filtro por animales para apetitivo
rats = [11,12,13,17,18,19,20]; % Filtro por animales para aversivo
paradigm_toinclude = 'aversive'; % Filtro por el paradigma
session_toinclude = {'EXT1'}; % Filtro por las sesiones
trials_toinclude = 1:20; % Filtro por los trials que quiero incluir de la sesión
meantitle = 'Late Training BLA Spectrogram'; % Titulo general que le voy a poner a la figura
region = 'BLA'; % Región que quiero analizar: BLA, PL, IL.
remove_50hz = 0; % 1 para limpiar e interpolar 50Hz, 0 para no limpiar.
remove_100hz = 1; % 1 para limpiar e interpolar 100Hz, 0 para no limpiar.
remove_epileptic = 1; % 1 para limpiar los momentos epilépticos de la señal, 0 para no limpiar
kernel = 5; % Tamaño del kernel para hacer un smoothing en los espectrogramas (5 app, 20 av)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Define the parent folder containing the 'Rxx' folders
parentFolder = 'D:\Doctorado\Backup Ordenado';

% List all 'Rxx' folders in the parent folder
R_folders = dir(fullfile(parentFolder, 'R*'));

% Inicializo algunas variables
SPG_CS1 = [];
SPG_CS2 = [];

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
                        exist(strcat(name,'_behavior_timeseries.mat')) == 2 && ...
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
                        fmin = find(abs(f-98) == min(abs(f-98)));
                        fmax = find(abs(f-102) == min(abs(f-102)));
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
                        S(:,i) = S(:,i) - nanmedian(nanmedian(abs(S(:,i) - nanmedian(S(:,i)))));
                    end

                    % Busco las posiciones en S donde inician y finalizan los tonos
                    j = 1;
                    for i = 1:size(TTL_CS1_inicio,1);
                        CS1_inicioenS(j) = min(find(abs(t-TTL_CS1_inicio(i)) == min(abs(t-TTL_CS1_inicio(i)))));
                        CS1_finenS(j) = min(find(abs(t-TTL_CS1_fin(i)) == min(abs(t-TTL_CS1_fin(i)))));
                        CS2_inicioenS(j) = min(find(abs(t-TTL_CS2_inicio(i)) == min(abs(t-TTL_CS2_inicio(i)))));
                        CS2_finenS(j) = min(find(abs(t-TTL_CS2_fin(i)) == min(abs(t-TTL_CS2_fin(i)))));
                        j = j + 1;
                    end
                    
                    % Cargamos behavior_timeseries.mat freezing y tt
                    % time_step = 0.5
                    load(strcat(name,'_behavior_timeseries.mat'),'freezing','tt');
                    onset = find(tt == 0);
                    offset = find(tt == 60);
                    freezing_duringCS = freezing(onset:offset,:);
                    freezing_duringCS = diff(freezing_duringCS,1,1) == 1;
                    
                    % Metemos todos los pedazos de S durante el CS en una gran matriz y
                    % calculamos la media

                    S_CS1 = [];
                    S_CS2 = [];
                    
                    if strcmp(paradigm_toinclude,'appetitive');
                        % Do nothing
                    elseif strcmp(paradigm_toinclude,'aversive');
                        window = 120; % Porque dentro del tono son 120 ventanas de 0.5 seg.
                        if CS1_inicioenS(1,end) < size(S,1) && round(mean(CS1_finenS - CS1_inicioenS)) == 120;
                            for i = 1:size(CS1_inicioenS,2);
                                if any(freezing_duringCS(:,i) == 1);
                                    pos = min(find(freezing_duringCS(:,i) == 1))-1;
                                    S_CS1(:,:,i) = S(CS1_inicioenS(1,i)+pos-(window):CS1_inicioenS(1,i)+pos+(window)-1,:);
                                    S_CS2(:,:,i) = S(CS2_inicioenS(1,i)+pos-(window):CS2_inicioenS(1,i)+pos+(window)-1,:);
                                else
                                    S_CS1(:,:,i) = nan(window*2,size(f,2));
                                    S_CS2(:,:,i) = nan(window*2,size(f,2));                                    
                                end
                            end
                        else 
                            for j = 1:size(CS1_inicioenS,2);
                                S_CS1(:,:,j) = nan(window*2,size(f,2));
                                S_CS2(:,:,j) = nan(window*2,size(f,2));
                            end
                        end                        
                        
                        if size(S_CS1,2) == 1967 && size(S_CS1,1) == 240;
                            SPG_CS1 = cat(3,SPG_CS1,S_CS1(:,:,trials_toinclude));
                            SPG_CS2 = cat(3,SPG_CS2,S_CS2(:,:,trials_toinclude));
                            k = k + 1;
                            f1 = f;
                        end
                        
                    end
                end
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            end
        end      
    end      
    % Go back to the 'Rxx' folder
    cd(current_R_folder);
    
    if ~isempty(SPG_CS1);
        if strcmp(paradigm_toinclude,'appetitive');
            % Do nothing
        elseif strcmp(paradigm_toinclude,'aversive');
            t1 = 0.5:0.5:size(SPG_CS1,1)*0.5;
            t1 = t1 - t1(window) - 0.25;        
        end
    end
    
end
cd(parentFolder);

% Promediamos espectrogramas
SPG_CS1 = nanmedian(SPG_CS1,3);
SPG_CS2 = nanmedian(SPG_CS2,3);

SPG_CS1 = SPG_CS1 - median(median(SPG_CS1,1));
SPG_CS2 = SPG_CS2 - median(median(SPG_CS2,1));

% Ploteamos Espectrogramas
figure();

smooth = 10;

if strcmp(paradigm_toinclude,'appetitive');
    clim1 = -1;
    clim2 = 1; 
elseif strcmp(paradigm_toinclude,'aversive');
    clim1 = -1;
    clim2 = 1;       
end

% Define a Gaussian kernel para smoothear el espectrograma
kernel_size = kernel;
sigma = 2;
[x, y] = meshgrid(linspace(-2, 2, kernel_size));
gaussian_kernel = exp(-(x.^2 + y.^2) / (2 * sigma^2));
gaussian_kernel = gaussian_kernel / sum(gaussian_kernel(:));

% Suavizamos los espectrogramas
SPG_CS1_smooth = conv2(SPG_CS1, gaussian_kernel, 'same');
SPG_CS2_smooth = conv2(SPG_CS2, gaussian_kernel, 'same');

ax1 = subplot(1,3,1);
plot_matrix_smooth(SPG_CS1_smooth,t1,f1,'n',smooth);
ylabel(['Frequency (Hz)']);
xlabel('Time (sec.)');
title(strcat(region,' Freezing Onset During CS+'));
colormap(ax1,jet);    
hcb1 = colorbar; hcb1.YLabel.String = 'Power (Z-Scored)'; hcb1.FontSize = 10;
caxis([clim1 clim2]);
ylim([1 150]);
xlim([-20 20]);
hold on
line([0 0],[0 150],'Color',behaviour_color,'LineWidth',0.5,'LineStyle','--');
hold off

ax2 = subplot(1,3,2);
plot_matrix_smooth(SPG_CS2_smooth,t1,f1,'n',smooth);
ylabel(['Frequency (Hz)']);
xlabel('Time (sec.)');
title(strcat(region,' Freezing Onset During CS-'));
colormap(ax2,jet);    
hcb2 = colorbar; hcb2.YLabel.String = 'Power (Z-Scored)'; hcb2.FontSize = 10;
caxis([clim1 clim2]);
ylim([1 150]);
xlim([-20 20]);
hold on
line([0 0],[0 150],'Color',behaviour_color,'LineWidth',0.5,'LineStyle','--');
hold off

ax3 = subplot(1,3,3);
plot_matrix_smooth(SPG_CS1_smooth - SPG_CS2_smooth,t1,f1,'n',smooth);
ylabel(['Frequency (Hz)']);
xlabel('Time (sec.)');
title(strcat(region,' Freezing Onset Delta CS'));
colormap(ax3,bluered);
hcb3 = colorbar; hcb3.YLabel.String = 'Delta Power (Z-Scored)'; hcb3.FontSize = 10;
caxis([clim1 clim2]);
ylim([1 150]);
xlim([-20 20]);
hold on
line([0 0],[0 150],'Color',behaviour_color,'LineWidth',0.5,'LineStyle','--');
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
