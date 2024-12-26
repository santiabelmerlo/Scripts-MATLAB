%% Coherence for BLA, PL and IL during CS+ and CS-
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc
clear all

% En estas lineas selecciono que animales, paradigma y sesiones quiero analizar
% rats = [10,11,13,14,16,17,18,19]; % Filtro por animales para apetitivo
rats = [11,12,13,17,18,19,20]; % Filtro por animales para aversivo.
paradigm_toinclude = 'aversive'; % Filtro por el paradigma
session_toinclude = {'EXT1'}; % Filtro por las sesiones
trials_toinclude = 17:20; % Filtro por los trials
remove_epileptic = 1; % Flag para remover epileptic o no.
remove_100hz = 1; % Flag para remover los 100 Hz e interpolar
remove_50hz = 1; % Flag para remover los 50 Hz e interpolar

% Seteamos algunas variables que van a ser constantes a lo largo de todo el analisis
Fs = 1250; % Sample rate original de la señal (Hz)

% Calculamos algunas variables que son constantes
C1_CS1_cat = [];
C1_CS2_cat = [];
C2_CS1_cat = [];
C2_CS2_cat = [];
SC1_CS1_cat = [];
SC1_CS2_cat = [];
SC2_CS1_cat = [];
SC2_CS2_cat = [];

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
                t_lfp = (amplifier_timestamps_lfp - amplifier_timestamps(1))/30000; % Le restamos el primer timestamp y lo pasamos a segundos.
                t = t_lfp;
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
                end

                % PL
                if ~isempty(ch_PL)
                    % Cargamos la señal del PL
                    lfp_PL = LoadBinary(strcat(name,'_lfp.dat'), ch_PL, ch_total);
                    lfp_PL = lfp_PL * 0.195; % Convertir un canal de registro de bits a microvolts (uV).
                    lfp_PL = zpfilt(lfp_PL,1250,0.1,300); % Filtramos la señal entre 0.1 y 300
                end

                % IL
                if ~isempty(ch_IL)
                    % Cargamos la señal del PL
                    lfp_IL = LoadBinary(strcat(name,'_lfp.dat'), ch_IL, ch_total);
                    lfp_IL = lfp_IL * 0.195; % Convertir un canal de registro de bits a microvolts (uV).
                    lfp_IL = zpfilt(lfp_IL,1250,0.1,300); % Filtramos la señal entre 0.1 y 300
                end

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % Analizamos GCI solo si tenemos las tres señales
                if exist('lfp_BLA') && exist('lfp_PL') && exist('lfp_IL')
                    
                    % Detectamos ruido en las tres señales, y excluimos los segmentos que presentan ruido
                    noise_BLA = isoutlier(lfp_BLA, 'median', 10); % Buscamos los ruidos en BLA
                    noise_PL = isoutlier(lfp_PL, 'median', 10); % Buscamos los ruidos en PL
                    noise_IL = isoutlier(lfp_IL, 'median', 10); % Buscamos los ruidos en IL
                    extended_noise = (noise_BLA|noise_PL|noise_IL); % Combinamos los 3 ruidos
                    
                    % Calculamos la coherencia con cohgramc
                    clear t;
                    params.Fs = 1250; 
                    params.err = [2 0.05]; 
                    params.tapers = [3 5]; 
                    params.pad = 2; 
                    params.fpass = [0 150];
                    movingwin = [3 0.5];
                    disp(['Analizing coherence between BLA and PL...']);
                    [C_1,phi,S12_1,S1,S2,t,f] = cohgramc(lfp_BLA',lfp_PL',movingwin,params);
                    clear phi S1 S2; S12_1 = abs(S12_1);
                    S12_1 = zscorem(S12_1,1); % Zscoreamos el escectrograma cruzado
                    disp(['Analizing coherence between BLA and IL...']);
                    [C_2,phi,S12_2,S1,S2,t,f] = cohgramc(lfp_BLA',lfp_IL',movingwin,params);
                    clear phi S1 S2; S12_2 = abs(S12_2);
                    S12_2 = zscorem(S12_2,1); % Zscoreamos el escectrograma cruzado
                    
                    % Quitamos las partes del espectrograma que tienen ruido
                    noise = t_lfp(extended_noise);
                    % Busco las posiciones en S donde se ubica el ruido
                    clear noise_enS;
                    for i = 1:size(noise,2);
                        noise_enS(i) = find(abs(t-noise(i)) == min(abs(t-noise(i))));
                        if noise_enS(i) <= 5
                            C_1(noise_enS(1):noise_enS(i)+5,:) = NaN;
                            C_2(noise_enS(1):noise_enS(i)+5,:) = NaN;
                            S12_1(noise_enS(1):noise_enS(i)+5,:) = NaN;
                            S12_2(noise_enS(1):noise_enS(i)+5,:) = NaN;
                        else
                            C_1(noise_enS(i)-5:noise_enS(i)+5,:) = NaN;
                            C_2(noise_enS(i)-5:noise_enS(i)+5,:) = NaN;
                            S12_1(noise_enS(i)-5:noise_enS(i)+5,:) = NaN;
                            S12_2(noise_enS(i)-5:noise_enS(i)+5,:) = NaN;
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
                            for i = 1:size(ep_inicioenS,2);
                                    C_1(ep_inicioenS(i):ep_finenS(i),:) = NaN;
                                    C_2(ep_inicioenS(i):ep_finenS(i),:) = NaN;
                                    S12_1(ep_inicioenS(i):ep_finenS(i),:) = NaN;
                                    S12_2(ep_inicioenS(i):ep_finenS(i),:) = NaN;
                            end
                        end
                    end

                    % Quitamos interpolamos la franja de 100 Hz que es ruidosa
                    if remove_100hz == 1;
                        fmin = find(abs(f-98) == min(abs(f-98)));
                        fmax = find(abs(f-102) == min(abs(f-102)));
                        for i = 1:fmax-fmin;
                            C_1(:,fmin+i) = C_1(:,fmin) + i*((C_1(:,fmax+1)-C_1(:,fmin-1))/(fmax-fmin));
                            C_2(:,fmin+i) = C_2(:,fmin) + i*((C_2(:,fmax+1)-C_2(:,fmin-1))/(fmax-fmin));
                            S12_1(:,fmin+i) = S12_1(:,fmin) + i*((S12_1(:,fmax+1)-S12_1(:,fmin-1))/(fmax-fmin));
                            S12_2(:,fmin+i) = S12_2(:,fmin) + i*((S12_2(:,fmax+1)-S12_2(:,fmin-1))/(fmax-fmin));
                        end
                    end
                    
                    % Quitamos interpolamos la franja de 50 Hz que es ruidosa
                    if remove_50hz == 1;
                        fmin = find(abs(f-48) == min(abs(f-48)));
                        fmax = find(abs(f-52) == min(abs(f-52)));
                        for i = 1:fmax-fmin;
                            C_1(:,fmin+i) = C_1(:,fmin) + i*((C_1(:,fmax+1)-C_1(:,fmin-1))/(fmax-fmin));
                            C_2(:,fmin+i) = C_2(:,fmin) + i*((C_2(:,fmax+1)-C_2(:,fmin-1))/(fmax-fmin));
                            S12_1(:,fmin+i) = S12_1(:,fmin) + i*((S12_1(:,fmax+1)-S12_1(:,fmin-1))/(fmax-fmin));
                            S12_2(:,fmin+i) = S12_2(:,fmin) + i*((S12_2(:,fmax+1)-S12_2(:,fmin-1))/(fmax-fmin));
                        end
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
                    
                    
                    % Metemos todos los pedazos de S durante el CS en una gran matriz y
                    % calculamos la media

                    S_CS1 = [];
                    S_CS2 = [];
                    
                    if strcmp(paradigm_toinclude,'appetitive');
                        % No hacer nada por el momento
                    elseif strcmp(paradigm_toinclude,'aversive');
                        window = 120; % Porque dentro del tono son 120 ventanas de 0.5 seg.
                        if CS1_inicioenS(1,end) < size(C_1,1) && round(mean(CS1_finenS - CS1_inicioenS)) == 120;
                            j = 1;
                            for i = trials_toinclude;
                                C1_CS1(:,:,j) = C_1(CS1_inicioenS(1,i)-(window/3):CS1_inicioenS(1,i)+(window*(4/3))-1,:);
                                C1_CS2(:,:,j) = C_1(CS2_inicioenS(1,i)-(window/3):CS2_inicioenS(1,i)+(window*(4/3))-1,:);
                                C2_CS1(:,:,j) = C_2(CS1_inicioenS(1,i)-(window/3):CS1_inicioenS(1,i)+(window*(4/3))-1,:);
                                C2_CS2(:,:,j) = C_2(CS2_inicioenS(1,i)-(window/3):CS2_inicioenS(1,i)+(window*(4/3))-1,:);
                                SC1_CS1(:,:,j) = S12_1(CS1_inicioenS(1,i)-(window/3):CS1_inicioenS(1,i)+(window*(4/3))-1,:);
                                SC1_CS2(:,:,j) = S12_1(CS2_inicioenS(1,i)-(window/3):CS2_inicioenS(1,i)+(window*(4/3))-1,:);
                                SC2_CS1(:,:,j) = S12_2(CS1_inicioenS(1,i)-(window/3):CS1_inicioenS(1,i)+(window*(4/3))-1,:);
                                SC2_CS2(:,:,j) = S12_2(CS2_inicioenS(1,i)-(window/3):CS2_inicioenS(1,i)+(window*(4/3))-1,:);
                                j = j + 1;
                            end
                        else 
                            j = 1;
                            for i = trials_toinclude;
                                C1_CS1(:,:,j) = nan(window*2,size(f,2));
                                C1_CS2(:,:,j) = nan(window*2,size(f,2));
                                C2_CS1(:,:,j) = nan(window*2,size(f,2));
                                C2_CS2(:,:,j) = nan(window*2,size(f,2));
                                SC1_CS1(:,:,j) = nan(window*2,size(f,2));
                                SC1_CS2(:,:,j) = nan(window*2,size(f,2));
                                SC2_CS1(:,:,j) = nan(window*2,size(f,2));
                                SC2_CS2(:,:,j) = nan(window*2,size(f,2));
                                j = j + 1;
                            end
                        end                        
                        
                        if size(C1_CS1,2) == 1967 && size(C1_CS1,1) == 200;
                            C1_CS1_cat = cat(3,C1_CS1_cat,C1_CS1);
                            C1_CS2_cat = cat(3,C1_CS2_cat,C1_CS2);
                            C2_CS1_cat = cat(3,C2_CS1_cat,C2_CS1);
                            C2_CS2_cat = cat(3,C2_CS2_cat,C2_CS2);
                            SC1_CS1_cat = cat(3,SC1_CS1_cat,SC1_CS1);
                            SC1_CS2_cat = cat(3,SC1_CS2_cat,SC1_CS2);
                            SC2_CS1_cat = cat(3,SC2_CS1_cat,SC2_CS1);
                            SC2_CS2_cat = cat(3,SC2_CS2_cat,SC2_CS2);
                        end
                        
                        clear C1_CS1 C1_CS2 C2_CS1 C2_CS2 SC1_CS1 SC1_CS2 SC2_CS1 SC2_CS2
                         
                    end
                    
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    
                end
   
                clear lfp_BLA lfp_PL lfp_IL inicio_freezing fin_freezing...
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

if ~isempty(C1_CS1_cat);
    if strcmp(paradigm_toinclude,'appetitive');
        t1 = 0.5:0.5:size(C1_CS1_cat,1)*0.5;
        t1 = t1 - t1(window/2) - 0.25;
    elseif strcmp(paradigm_toinclude,'aversive');
        t1 = 0.5:0.5:size(C1_CS1_cat,1)*0.5;
        t1 = t1 - t1(window/3) - 0.25;        
    end
end

% Hacemos un smoothing de los trials antes de hacer el promedio
% Define different kernel sizes for x and y axes
kernel_x = 20; % Tamaño del kernel para hacer un smoothing en los espectrogramas. Suaviza en Y. kernel_x = 50 para el apetitivo, 20 para el aversivo.
kernel_y = 10; % Tamaño del kernel para hacer un smoothing en los espectrogramas. Suaviza en X.
kernel_size_x = kernel_x;
kernel_size_y = kernel_y;
sigma = 2;
% Create meshgrid with different ranges for x and y
[x, y] = meshgrid(linspace(-2, 2, kernel_size_x), linspace(-2, 2, kernel_size_y));

% Define a Gaussian kernel for smoothing
gaussian_kernel = exp(-(x.^2 + y.^2) / (2 * sigma^2));
gaussian_kernel = gaussian_kernel / sum(gaussian_kernel(:));

for i = 1:size(C1_CS1_cat,3);
    % Smooth the spectrograms
    C1_CS1_cat(:,:,i) = conv2(C1_CS1_cat(:,:,i), gaussian_kernel, 'same');
    C1_CS2_cat(:,:,i) = conv2(C1_CS2_cat(:,:,i), gaussian_kernel, 'same');
    C2_CS1_cat(:,:,i) = conv2(C2_CS1_cat(:,:,i), gaussian_kernel, 'same');
    C2_CS2_cat(:,:,i) = conv2(C2_CS2_cat(:,:,i), gaussian_kernel, 'same');
end 

% Ploteamos la coherencia
cs1_color = [118 6 154]/255; % Seteo el color para el CS+ aversivo
cs2_color = [96 96 96]/255; % Seteo el color para el CS-
fz_color = [255 140 0]/255; % Seteo el color para el freezing a un tono de naranja
nofz_color = [96 96 96]/255; % Seteo el color para el no freezing

% Ploteamos los espectros de coherencia
figure()
smoothing = 10;
ax1 = subplot(221);
plot_matrix_smooth(nanmean(C1_CS1_cat,3),t1,f,'n',smoothing);
clim([0.4 1]);
ylim([1 100]); xlim([-10 70]);
line([0 0],[0 150],'Color',[0 0 0],'LineWidth',0.5,'LineStyle','--');
line([60 60],[0 150],'Color',[0 0 0],'LineWidth',0.5,'LineStyle','--');
cb = colorbar; cb.YLabel.String = 'Coherence'; cb.FontSize = 10;
a = get(cb); a = a.Position;
b = get(ax1); b = b.Position;
set(cb,'Position',[a(1) a(2)+0.12 0.02 0.1]);
set(ax1,'Position',[b(1) b(2) b(3)-0.001 b(4)]);
title('BLA-PL Coherence CS+');

ax2 = subplot(222);
plot_matrix_smooth(nanmean(C1_CS2_cat,3),t1,f,'n',smoothing);
clim([0.4 1]);
ylim([1 100]); xlim([-10 70]);
line([0 0],[0 150],'Color',[0 0 0],'LineWidth',0.5,'LineStyle','--');
line([60 60],[0 150],'Color',[0 0 0],'LineWidth',0.5,'LineStyle','--');
cb = colorbar; cb.YLabel.String = 'Coherence'; cb.FontSize = 10;
a = get(cb); a = a.Position;
b = get(ax2); b = b.Position;
set(cb,'Position',[a(1) a(2)+0.12 0.02 0.1]);
set(ax2,'Position',[b(1) b(2) b(3)-0.001 b(4)]);
title('BLA-PL Coherence CS-');

ax3 = subplot(223);
plot_matrix_smooth(nanmean(C2_CS1_cat,3),t1,f,'n',smoothing);
clim([0.4 1]);
ylim([1 100]); xlim([-10 70]);
line([0 0],[0 150],'Color',[0 0 0],'LineWidth',0.5,'LineStyle','--');
line([60 60],[0 150],'Color',[0 0 0],'LineWidth',0.5,'LineStyle','--');
cb = colorbar; cb.YLabel.String = 'Coherence'; cb.FontSize = 10;
a = get(cb); a = a.Position;
b = get(ax3); b = b.Position;
set(cb,'Position',[a(1) a(2)+0.12 0.02 0.1]);
set(ax3,'Position',[b(1) b(2) b(3)-0.001 b(4)]);
title('BLA-IL Coherence CS+');

ax4 = subplot(224);
plot_matrix_smooth(nanmean(C2_CS2_cat,3),t1,f,'n',smoothing);
clim([0.4 1]);
ylim([1 100]); xlim([-10 70]);
line([0 0],[0 150],'Color',[0 0 0],'LineWidth',0.5,'LineStyle','--');
line([60 60],[0 150],'Color',[0 0 0],'LineWidth',0.5,'LineStyle','--');
cb = colorbar; cb.YLabel.String = 'Coherence'; cb.FontSize = 10;
a = get(cb); a = a.Position;
b = get(ax4); b = b.Position;
set(cb,'Position',[a(1) a(2)+0.12 0.02 0.1]);
set(ax4,'Position',[b(1) b(2) b(3)-0.001 b(4)]);
title('BLA-IL Coherence CS-');

% Set figure properties
set(gcf, 'Color', 'white');
set(gcf, 'Position', [100, 100, 1000, 600]);
hold off

% Preparamos las frecuencias
fourhzlegend = '4-Hz Oscillation (2 a 5 Hz)';
fmin = 2; fmax= 5.3;
f_4hz1 = find(abs(f-fmin) == min(abs(f-fmin)));
f_4hz2 = find(abs(f-fmax) == min(abs(f-fmax)));
f_4hz = f(1,f_4hz1:f_4hz2);

thetalegend = 'Theta (5 a 10 Hz)'; % Antes era de 6 a 12 Hz.
fmin = 5.3; fmax= 9.6;
f_theta1 = find(abs(f-fmin) == min(abs(f-fmin)));
f_theta2 = find(abs(f-fmax) == min(abs(f-fmax)));
f_theta = f(1,f_theta1:f_theta2);

betalegend = 'Beta (13 a 30 Hz)'; % Antes era de 13 a 25 Hz.
fmin = 13; fmax= 30;
f_beta1 = find(abs(f-fmin) == min(abs(f-fmin)));
f_beta2 = find(abs(f-fmax) == min(abs(f-fmax)));
f_beta = f(1,f_beta1:f_beta2);

sgammalegend = 'Slow Gamma (40 a 60 Hz)'; % Antes era 45 a 60 Hz.
fmin = 43; fmax= 60;
f_slowgamma1 = find(abs(f-fmin) == min(abs(f-fmin)));
f_slowgamma2 = find(abs(f-fmax) == min(abs(f-fmax)));
f_slowgamma = f(1,f_slowgamma1:f_slowgamma2);

fgammalegend = 'Fast Gamma (60 a 100 Hz)'; % Antes era de 70 a 90 Hz.
fmin = 60; fmax= 98;
f_fastgamma1 = find(abs(f-fmin) == min(abs(f-fmin)));
f_fastgamma2 = find(abs(f-fmax) == min(abs(f-fmax)));
f_fastgamma = f(1,f_fastgamma1:f_fastgamma2);

% Curva de coherencia
figure()
plot_curve(f,(squeeze(nanmean(C2_CS2_cat(41:160,:,:),1)))', 'median', cs2_color, 200,'dis'); hold on;
plot_curve(f,(squeeze(nanmean(C2_CS1_cat(41:160,:,:),1)))', 'median', cs1_color, 200,'dis'); hold on;
plot_curve(f,(squeeze(nanmean(C1_CS2_cat(41:160,:,:),1)))', 'median', cs2_color, 200,'cont'); hold on;
plot_curve(f,(squeeze(nanmean(C1_CS1_cat(41:160,:,:),1)))', 'median', cs1_color, 200,'cont'); hold on;
hCurve = findobj(gca, 'Type', 'Line');
legend(hCurve, {'BLA-PL; CS+','BLA-PL; CS-','BLA-IL; CS+','BLA-IL; CS-'},'Location','NorthEastOutside');

ylim([0.5 0.9]); xlim([1 100]);
ylabel('Coherence'); xlabel('Frequency (Hz)');

% Set figure properties
set(gcf, 'Color', 'white');
set(gcf, 'Position', [100, 100, 500, 300]);

% Ploteamos las barras con estadística
figure()
subplot(151)
plot_coh(C1_CS1_cat,C1_CS2_cat,C2_CS1_cat,C2_CS2_cat,f,1,1);
subplot(152)
plot_coh(C1_CS1_cat,C1_CS2_cat,C2_CS1_cat,C2_CS2_cat,f,2,1);
subplot(153)
plot_coh(C1_CS1_cat,C1_CS2_cat,C2_CS1_cat,C2_CS2_cat,f,3,1);
subplot(154)
plot_coh(C1_CS1_cat,C1_CS2_cat,C2_CS1_cat,C2_CS2_cat,f,4,1);
subplot(155)
plot_coh(C1_CS1_cat,C1_CS2_cat,C2_CS1_cat,C2_CS2_cat,f,5,1);
set(gcf, 'Position', [400, 400, 1000, 250]);

aleluya()