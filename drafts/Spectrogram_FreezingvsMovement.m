%% Script para backupear los archivos R00D00_freezing.mat
clc;
% clear all;
clearvars -except A B

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% En estas lineas selecciono que animales, paradigma y sesiones quiero analizar
% rats = [10,11,13,14,16,17,18,19]; % Filtro por animales para apetitivo
rats = [11,12,13,17,18,19,20]; % Filtro por animales para aversivo
paradigm_toinclude = 'aversive'; % Filtro por el paradigma
session_toinclude = {'EXT1','EXT2','TEST'}; % Filtro por las sesiones
% session_toinclude = {'EXT1'}; % Filtro por las sesiones
trials_toinclude = []; % Qué trials me interesa incluir. Si quiero incluir todos los fz dejar vacío.
meantitle = 'Freezing vs. Movement during Aversive'; % Titulo general que le voy a poner a la figura
region = 'BLA';
remove_50hz = 0; % 1 para limpiar e interpolar 50Hz, 0 para no limpiar.
remove_100hz = 1; % 1 para limpiar e interpolar 100Hz, 0 para no limpiar.
remove_epileptic = 1; % 1 para limpiar los momentos epilépticos de la señal, 0 para no limpiar
trigger = 'onset'; % Trigerrear al 'onset' o al 'offset'
fr_dur_1 = 1; % Duración de freezing minimo con la que me quedo
fr_dur_2 = 100; % Duración de freezing máximo con la que me quedo
clim = [-0.5,0.5]; % Limite de la escala en z del espectrograma
lim_y = [1 12]; % Limites en el eje y 
frange = 1; % Determinar qué rango de frecuencias quiero analizar (1 a 5; 4Hz,Theta,Beta,sGamma,fGamma)
select_CS = []; % Elegimos si queremos quedarnos con los freezing que caen en CS1, CS2 o ITI (1,2,3). Sino dejar vacío [].
normalization = 2; % Elegimos que tipo de normalización queremos en los datos. 1 para hacer z-score y 2 para hacer Normalized Power

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
freezing_id = [];
freezing_when = [];

% Inicializo algunas variables para la tabla
event1 = [];
event2 = [];
rat1 = [];
rat2 = [];
name1 = [];
name2 = [];
session1 = [];
session2 = [];
type1 = [];
type2 = [];
trial1 = [];
trial2 = [];
inicio1 = [];
inicio2 = [];
fin1 = [];
fin2 = [];
duracion1 = [];
duracion2 = [];

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
m = 1;
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
                    % Filtramos los trials que me interesan
                    if ~isempty(trials_toinclude)
                        TTL_CS1_inicio = TTL_CS1_inicio(trials_toinclude,:);
                        TTL_CS1_fin = TTL_CS1_fin(trials_toinclude,:);
                        TTL_CS2_inicio = TTL_CS2_inicio(trials_toinclude,:);
                        TTL_CS2_fin = TTL_CS2_fin(trials_toinclude,:);
                    end
                    
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

                    if normalization == 1
                        % Calculate the z-score using median and MAD
                        for i = 1:size(S,2);
                            S(:,i) = (S(:,i) - nanmedian(S(:,i))) / nanmedian(abs(S(:,i) - nanmedian(S(:,i))));
                        end 
                    elseif normalization == 2
                          S = bsxfun(@times, S, f);                    
                          S = bsxfun(@rdivide, S, nanmedian(nanmedian(S,1)));
%                         S = bsxfun(@rdivide, S, nanmedian(S,1));
                    end
                    
                    % Cargamos los eventos de freezing
                    load(strcat(name,'_epileptic.mat'));
                    duracion_freezing = fin_freezing - inicio_freezing;

                    % Nos quedamos con los freezing y movement que duran tanto tiempo
                    inicio_freezing = inicio_freezing(duracion_freezing>=fr_dur_1 & duracion_freezing<=fr_dur_2);
                    fin_freezing = fin_freezing(duracion_freezing>=fr_dur_1 & duracion_freezing<=fr_dur_2);
                    duracion_freezing = duracion_freezing(duracion_freezing>=fr_dur_1 & duracion_freezing<=fr_dur_2);                    
                    inicio_movement = inicio_movement(duracion_movement>=fr_dur_1 & duracion_movement<=fr_dur_2);
                    fin_movement = fin_movement(duracion_movement>=fr_dur_1 & duracion_movement<=fr_dur_2);
                    duracion_movement = duracion_movement(duracion_movement>=fr_dur_1 & duracion_movement<=fr_dur_2);
                    
                    % Divide freezing by onset in CS1, CS2 or ITI
                    freezing_type = [];
                    for i = 1:size(inicio_freezing,2);
                        if any((inicio_freezing(i) >= TTL_CS1_inicio) .* (inicio_freezing(i) < TTL_CS1_fin));
                            freezing_type(1,i) = 1; % Type 1 for freezing onset during CS1
                        elseif any((inicio_freezing(i) >= TTL_CS2_inicio) .* (inicio_freezing(i) < TTL_CS2_fin));
                            freezing_type(1,i) = 2; % Type 2 for freezing onset during CS2
                        elseif any((inicio_freezing(i) >= TTL_CS1_inicio - 60) .* (inicio_freezing(i) < TTL_CS1_inicio));
                            freezing_type(1,i) = 3; % Type 3 for freezing onset during preCS
                        else
                            freezing_type(1,i) = 4; % Cualquier otro momento
                        end
                    end
                    
                    % Divide movement by onset in CS1, CS2 or ITI
                    movement_type = [];
                    for i = 1:size(inicio_movement,2);
                        if any((inicio_movement(i) >= TTL_CS1_inicio) .* (inicio_movement(i) < TTL_CS1_fin));
                            movement_type(1,i) = 1; % Type 1 for freezing onset during CS1
                        elseif any((inicio_movement(i) >= TTL_CS2_inicio) .* (inicio_movement(i) < TTL_CS2_fin));
                            movement_type(1,i) = 2; % Type 2 for freezing onset during CS2
                        elseif any((inicio_movement(i) >= TTL_CS1_inicio - 60) .* (inicio_movement(i) < TTL_CS1_inicio));
                            movement_type(1,i) = 3; % Type 3 for freezing onset during preCS
                        else
                            movement_type(1,i) = 4; % Cualquier otro momento
                        end
                    end
                    
                    % Trial number for each freezing event
                    freezing_trial = [];
                    for i = 1:size(inicio_freezing,2);
                        for j = 1:size(TTL_CS1_inicio,1);
                            if inicio_freezing(i) >= TTL_CS1_inicio(j) && inicio_freezing(i) < TTL_CS1_fin(j)
                                freezing_trial(i) = j;
                            elseif inicio_freezing(i) >= TTL_CS2_inicio(j) && inicio_freezing(i) < TTL_CS2_fin(j)
                                freezing_trial(i) = j;
                            end
                        end
                        if size(freezing_trial,2) < i
                            freezing_trial(i) = NaN;
                        end
                    end
                    
                    % Trial number for each movement event
                    movement_trial = [];
                    for i = 1:size(inicio_movement,2);
                        for j = 1:size(TTL_CS1_inicio,1);
                            if inicio_movement(i) >= TTL_CS1_inicio(j) && inicio_movement(i) < TTL_CS1_fin(j)
                                movement_trial(i) = j;
                            elseif inicio_movement(i) >= TTL_CS2_inicio(j) && inicio_movement(i) < TTL_CS2_fin(j)
                                movement_trial(i) = j;
                            end
                        end
                        if size(movement_trial,2) < i
                            movement_trial(i) = NaN;
                        end
                    end
                    
                    % Busco las posiciones en S donde inician los freezing
                    % y los movement
                    clear freezing_inicioenS freezing_finenS movement_inicioenS movement_finenS
                    j = 1;
                    for i = 1:size(inicio_freezing,2);
                        freezing_inicioenS(j) = min(find(abs(t-inicio_freezing(1,i)) == min(abs(t-inicio_freezing(1,i)))));
                        freezing_finenS(j) = min(find(abs(t-fin_freezing(1,i)) == min(abs(t-fin_freezing(1,i)))));
                        j = j + 1;
                    end
                    j = 1;
                    for i = 1:size(inicio_movement,2);
                        movement_inicioenS(j) = min(find(abs(t-inicio_movement(1,i)) == min(abs(t-inicio_movement(1,i)))));
                        movement_finenS(j) = min(find(abs(t-fin_movement(1,i)) == min(abs(t-fin_movement(1,i)))));
                        j = j + 1;
                    end
                    
                    % Elimino los freezing inicio en S que estan cerca del final de S
                    pos1 = freezing_inicioenS > size(S,1) - 50;
                    pos2 = freezing_inicioenS < 50;
                    freezing_inicioenS(pos1) = [];
                    freezing_inicioenS(pos2) = [];
                    freezing_finenS(pos1) = [];
                    freezing_finenS(pos2) = [];
                    inicio_freezing(pos1) = [];
                    inicio_freezing(pos2) = [];
                    fin_freezing(pos1) = [];
                    fin_freezing(pos2) = [];
                    duracion_freezing(pos1) = [];
                    duracion_freezing(pos2) = [];
                    freezing_type(pos1) = [];
                    freezing_type(pos2) = [];
                    freezing_trial(pos1) = [];
                    freezing_trial(pos2) = [];
                    
                    % Elimino los movement inicio en S que estan cerca del final de S
                    pos1 = movement_inicioenS > size(S,1) - 50;
                    pos2 = movement_inicioenS < 50;
                    movement_inicioenS(pos1) = [];
                    movement_inicioenS(pos2) = [];
                    movement_finenS(pos1) = [];
                    movement_finenS(pos2) = [];
                    inicio_movement(pos1) = [];
                    inicio_movement(pos2) = [];
                    fin_movement(pos1) = [];
                    fin_movement(pos2) = [];
                    duracion_movement(pos1) = [];
                    duracion_movement(pos2) = [];
                    movement_type(pos1) = [];
                    movement_type(pos2) = [];
                    movement_trial(pos1) = [];
                    movement_trial(pos2) = [];

                    % Me quedo solo con los freezing que estan dentro de los CS o en el ITI
                    if ~isempty(select_CS)
                        freezing_inicioenS = freezing_inicioenS(freezing_type == select_CS);
                        freezing_finenS = freezing_finenS(freezing_type == select_CS);
                        duracion_freezing = duracion_freezing(freezing_type == select_CS);
                    end     
                    
                    % Me quedo solo con los movement que estan dentro de los CS o en el ITI
                    if ~isempty(select_CS)
                        movement_inicioenS = movement_inicioenS(movement_type == select_CS);
                        movement_finenS = movement_finenS(movement_type == select_CS);
                        duracion_movement = duracion_movement(movement_type == select_CS);
                    end  

                    % Metemos todos los pedazos de S durante el CS en una gran matriz y
                    % calculamos la media

                    S_freezing = [];
                    S_nofreezing = [];
                    
                    window = 20; % Son 6 ventanas de 0.5 seg antes del freezing y 6 ventanas despues del freezing

                    for i = 1:size(freezing_inicioenS,2);
                        if strcmp(trigger,'onset');
                            S_freezing(:,:,i) = S(freezing_inicioenS(1,i)-window:freezing_inicioenS(1,i)+window,:);
                        elseif strcmp(trigger,'offset');
                            S_freezing(:,:,i) = S(freezing_finenS(1,i)-window:freezing_finenS(1,i)+window,:);
                        end
                    end
                    
                    for i = 1:size(movement_inicioenS,2);
                        if strcmp(trigger,'onset');
                            S_nofreezing(:,:,i) = S(movement_inicioenS(1,i)-window:movement_inicioenS(1,i)+window,:);
                        elseif strcmp(trigger,'offset');
                            S_nofreezing(:,:,i) = S(movement_finenS(1,i)-window:movement_finenS(1,i)+window,:);
                        end                       
                    end                
                    
                    if size(S_freezing,2) == 1967 && size(S_freezing,1) == 41; % 41 para un window de 20 y 13 para un window de 6
                        SPG_freezing = cat(3,SPG_freezing,S_freezing(:,:,:));
                        SPG_nofreezing = cat(3,SPG_nofreezing,S_nofreezing(:,:,:));
                        freezing_dist = cat(2,freezing_dist,duracion_freezing);
                        freezing_id = cat(2,freezing_id,repmat(m,[1,size(duracion_freezing,2)]));
                        freezing_when = cat(2,freezing_when,freezing_type);
                        f1 = f;
                        
                        % Guardamos variables para la tabla
                        event1 = cat(1,event1,repmat('Freezing',size(S_freezing,3),1));
                        event2 = cat(1,event2,repmat('Movement',size(S_nofreezing,3),1));
                        rat1 = cat(1,rat1,repmat(r,size(S_freezing,3),1));
                        rat2 = cat(1,rat2,repmat(r,size(S_nofreezing,3),1));
                        name1 = cat(1,name1,repmat(name,size(S_freezing,3),1));
                        name2 = cat(1,name2,repmat(name,size(S_nofreezing,3),1));
                        session1 = cat(1,session1,repmat(session,size(S_freezing,3),1));
                        session2 = cat(1,session2,repmat(session,size(S_nofreezing,3),1));
                        type1 = cat(1,type1,freezing_type');
                        type2 = cat(1,type2,movement_type');
                        trial1 = cat(1,trial1,freezing_trial');
                        trial2 = cat(1,trial2,movement_trial');
                        inicio1 = cat(1,inicio1,inicio_freezing');
                        inicio2 = cat(1,inicio2,inicio_movement');
                        fin1 = cat(1,fin1,fin_freezing');
                        fin2 = cat(1,fin2,fin_movement');
                        duracion1 = cat(1,duracion1,duracion_freezing');
                        duracion2 = cat(1,duracion2,duracion_movement');
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
    m = m + 1; % Contador de las distintas ratas para guardar el id de cada rata en las duraciones de freezing
end
cd(parentFolder);

% Creamos el vector de tiempo
if ~isempty(SPG_freezing);
        t1 = 0.5:0.5:size(SPG_freezing,1)*0.5;
        t1 = t1 - t1(window+1);        
end

% Nos quedamos con los que superan 1 seg
SPG_freezing = SPG_freezing(:,:, (freezing_dist >= fr_dur_1) & (freezing_dist <= fr_dur_2));

% Cuantificamos cuantos eventos tengo de cada cosa
n1 = size(SPG_freezing,3);
n2 = size(SPG_nofreezing,3);

% Guarmamos los espectrogramas antes de promediar
SPGG_freezing = SPG_freezing;
SPGG_nofreezing = SPG_nofreezing;

% Para calcular los enriquecidos en 4-Hz de los enriquecidos en Theta
clear SPG_freezing SPG_nofreezing
SPG_freezing = SPGG_freezing(:,:,A);
SPG_nofreezing = SPGG_freezing(:,:,B);
n1 = size(SPG_freezing,3);
n2 = size(SPG_nofreezing,3);

% Promediamos espectrogramas
SPG_freezing = nanmedian(SPG_freezing,3);
SPG_nofreezing = nanmedian(SPG_nofreezing,3);

if normalization == 1;
    if strcmp(trigger,'onset');
        SPG_freezing = bsxfun(@minus, SPG_freezing, nanmedian(SPG_freezing(1:round(size(SPG_freezing,1)/2),:),1));
        SPG_nofreezing = bsxfun(@minus, SPG_nofreezing, nanmedian(SPG_nofreezing(1:round(size(SPG_nofreezing,1)/2),:),1));
    elseif strcmp(trigger,'offset');
        SPG_freezing = bsxfun(@minus, SPG_freezing, nanmedian(SPG_freezing(round(size(SPG_freezing,1)/2):round(size(SPG_freezing,1)),:),1));
        SPG_nofreezing = bsxfun(@minus, SPG_nofreezing, nanmedian(SPG_nofreezing(round(size(SPG_freezing,1)/2):round(size(SPG_nofreezing,1)),:),1));
    end  
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Ploteamos Espectrogramas
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
ylim([lim_y(1) lim_y(2)]);
xlim([-5 5]);
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
title(strcat(region,' Movement',' Mean Spectrogram',' n= ', num2str(n2)));
colormap(ax2,jet);    
hcb2 = colorbar; hcb2.YLabel.String = 'Power (Z-Scored)'; hcb2.FontSize = 10;
caxis([clim1 clim2]);
ylim([lim_y(1) lim_y(2)]);
xlim([-5 5]);
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
set(gcf, 'Position', [100, 100, 1200, 300]);

% Obtenemos las posiciones de las figuras
pos_ax1 = get(ax1, 'Position');
pos_ax2 = get(ax2, 'Position');
pos_ax1c = get(hcb1, 'Position');
pos_ax2c = get(hcb2, 'Position');

% Seteamos la posición de la barra de color
set(hcb1, 'Position', [pos_ax1c(1) 0.42 pos_ax1c(3) 0.2]);
set(hcb2, 'Position', [pos_ax2c(1) 0.42 pos_ax2c(3) 0.2]);

% Seteamos la posición de la figura
set(ax1, 'Position', [0.13 0.18 0.16 0.7]);
set(ax2, 'Position', [0.41 0.18 0.16 0.7]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cuantificación de las potencias pre-onset, post-onset o pre-offset y post-offset
figure();

val_t_post = [1 3];
val_t_pre = [-3 -1]; 
if frange == 1; val_f = [1.5 3]; freq_label = '4-Hz'; % 4-Hz
elseif frange == 2; val_f = [6 8]; freq_label = 'Theta'; % Theta
elseif frange == 3; val_f = [13 30]; freq_label = 'Beta'; % Beta
elseif frange == 4; val_f = [47 52]; freq_label = 'sGamma'; % sGamma [43 60] Rango original
elseif frange == 5; val_f = [60 98]; freq_label = 'fGamma'; %fGamma
end

data = SPGG_freezing;
val = val_t_post(1); t_1 = find(abs(t1 - val) == min(abs(t1 - val)));
val = val_t_post(2); t_2 = find(abs(t1 - val) == min(abs(t1 - val)));
val = val_f(1); f_1 = find(abs(f1 - val) == min(abs(f1 - val)));
val = val_f(2); f_2 = find(abs(f1 - val) == min(abs(f1 - val)));
data_t = nanmedian(data(:,f_1:f_2,:),2); data_t = squeeze(data_t);
if strcmp(trigger,'onset');
    val = val_t_post(1); t_1 = find(abs(t1 - val) == min(abs(t1 - val)));
    val = val_t_post(2); t_2 = find(abs(t1 - val) == min(abs(t1 - val)));
%     data_t = bsxfun(@minus, data_t, nanmedian(nanmedian(data_t(1:round(size(data_t,1)/2),:),1)));
    data = nanmedian(data_t(t_1:t_2,:,:),1); data = squeeze(data);
elseif strcmp(trigger,'offset');
    val = val_t_pre(1); t_1 = find(abs(t1 - val) == min(abs(t1 - val)));
    val = val_t_pre(2); t_2 = find(abs(t1 - val) == min(abs(t1 - val)));
%     data_t = bsxfun(@minus, data_t, nanmedian(nanmedian(data_t(round(size(data_t,1)/2):round(size(data_t,1)),:),1)));
    data = nanmedian(data_t(t_1:t_2,:,:),1); data = squeeze(data);
end 
data_t_1 = data_t;
data_1 = data;

data = SPGG_nofreezing;
val = val_t_post(1); t_1 = find(abs(t1 - val) == min(abs(t1 - val)));
val = val_t_post(2); t_2 = find(abs(t1 - val) == min(abs(t1 - val)));
val = val_f(1); f_1 = find(abs(f1 - val) == min(abs(f1 - val)));
val = val_f(2); f_2 = find(abs(f1 - val) == min(abs(f1 - val)));
data_t = nanmedian(data(:,f_1:f_2,:),2); data_t = squeeze(data_t);
if strcmp(trigger,'onset');
    val = val_t_post(1); t_1 = find(abs(t1 - val) == min(abs(t1 - val)));
    val = val_t_post(2); t_2 = find(abs(t1 - val) == min(abs(t1 - val)));
%     data_t = bsxfun(@minus, data_t, nanmedian(nanmedian(data_t(1:round(size(data_t,1)/2),:),1)));
    data = nanmedian(data_t(t_1:t_2,:,:),1); data = squeeze(data);
elseif strcmp(trigger,'offset');
    val = val_t_pre(1); t_1 = find(abs(t1 - val) == min(abs(t1 - val)));
    val = val_t_pre(2); t_2 = find(abs(t1 - val) == min(abs(t1 - val)));
%     data_t = bsxfun(@minus, data_t, nanmedian(nanmedian(data_t(round(size(data_t,1)/2):round(size(data_t,1)),:),1)));
    data = nanmedian(data_t(t_1:t_2,:,:),1); data = squeeze(data);
end   
data_t_2 = data_t;
data_2 = data;

data = SPGG_freezing;
val = val_t_pre(1); t_1 = find(abs(t1 - val) == min(abs(t1 - val)));
val = val_t_pre(2) ; t_2 = find(abs(t1 - val) == min(abs(t1 - val)));
val = val_f(1); f_1 = find(abs(f1 - val) == min(abs(f1 - val)));
val = val_f(2); f_2 = find(abs(f1 - val) == min(abs(f1 - val)));
data_t = nanmedian(data(:,f_1:f_2,:),2); data_t = squeeze(data_t);
if strcmp(trigger,'onset');
    val = val_t_pre(1); t_1 = find(abs(t1 - val) == min(abs(t1 - val)));
    val = val_t_pre(2); t_2 = find(abs(t1 - val) == min(abs(t1 - val)));
%     data_t = bsxfun(@minus, data_t, nanmedian(nanmedian(data_t(1:round(size(data_t,1)/2),:),1)));
    data = nanmedian(data_t(t_1:t_2,:,:),1); data = squeeze(data);
elseif strcmp(trigger,'offset');
    val = val_t_post(1); t_1 = find(abs(t1 - val) == min(abs(t1 - val)));
    val = val_t_post(2); t_2 = find(abs(t1 - val) == min(abs(t1 - val)));
%     data_t = bsxfun(@minus, data_t, nanmedian(nanmedian(data_t(round(size(data_t,1)/2):round(size(data_t,1)),:),1)));
    data = nanmedian(data_t(t_1:t_2,:,:),1); data = squeeze(data);
end 
data_t_3 = data_t;
data_3 = data;

plot_zcurve_fz(data_t_1,data_t_2,t1,region,freq_label);
ylim([-0.5 0.5]);
xlim([-5 5]);

set(gcf, 'Color', 'white');
set(gcf, 'Position', [100, 100, 300, 250]);

% Ploteamos potencia 
figure()
if strcmp(trigger,'onset');
    plot_boxplot_fz(data_3,data_1,data_2,region,paradigm_toinclude,freq_label);
    set(gca,'xtick',[1:3],'xticklabel',{'Pre-Fz'; 'Fz'; 'Mov'})
elseif strcmp(trigger,'offset');
    plot_boxplot_fz(data_3,data_1,data_2,region,paradigm_toinclude,freq_label);
    set(gca,'xtick',[1:3],'xticklabel',{'Post-Fz'; 'Fz'; 'Mov'})
    
end  
ylim([-0.5 0.5])

set(gcf, 'Color', 'white');
set(gcf, 'Position', [100, 100, 200, 250]);

% Creamos la tabla para guardar los datos
% Concatenate variables vertically
event = [event1; event2];
rat = [rat1; rat2];
name = [name1; name2];
session = [session1; session2];
type = [type1; type2];
trial = [trial1; trial2];
inicio = [inicio1; inicio2];
fin = [fin1; fin2];
duracion = [duracion1; duracion2];
data = [data_1'; data_2']; % Ensure data is column-wise

% Create the table with the concatenated variables
T = table(event, rat, name, session, type, trial, inicio, fin, duracion, data, ...
    'VariableNames', {'Event', 'Rat', 'Name', 'Session', 'Type', 'Trial', 'Inicio', 'Fin', 'Duracion', 'Data'});

% Display the table
disp(T);

%%
cd('C:\Users\santi\Desktop')
writetable(T, 'ThetaPw.csv');

%% Ploteamos PSD
f1 = f;
figure();
clear smooth
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
p1 = fill(x2, inBetween, [255 140 0]/255,'LineStyle','none');
set(p1,'facealpha',.4)
hold on;
plot(x, y, 'Color',[255 140 0]/255, 'LineWidth', 1);
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

aleluya();