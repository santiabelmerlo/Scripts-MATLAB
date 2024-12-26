%% Script para calcular espectrograma promedio de CS1 y CS2 en un grupo de 
% sesiones y animales en particular
% Primera celda: calculamos el espectrograma promedio
% Segunda celda: calculamos la zcurva del apetitivo en cada frecuencia
% Tercera celda: calculamos la zcurva del aversivo en cada frecuencia
clc;
clear all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% En estas lineas selecciono que animales, paradigma y sesiones quiero analizar
% rats = [10,11,13,14,16,17,18,19]; % Filtro por animales para apetitivo
% rats = [11,12,13,17,18,19,20]; % Filtro por animales para aversivo
rats = [11,13,17]; % Filtro por animales para aversivo, TEST. Animales que reinstalan
paradigm_toinclude = 'aversive'; % Filtro por el paradigma
session_toinclude = {'TEST'}; % Filtro por las sesiones
trials_toinclude = 1:4; % Filtro por los trials que quiero incluir de la sesión
meantitle = 'Reinstatement IL Spectrogram'; % Titulo general que le voy a poner a la figura
region = 'IL'; % Región que quiero analizar: BLA, PL, IL.
remove_50hz = 1; % 1 para limpiar e interpolar 50Hz, 0 para no limpiar.
remove_100hz = 1; % 1 para limpiar e interpolar 100Hz, 0 para no limpiar.
remove_epileptic = 1; % 1 para limpiar los momentos epilépticos de la señal, 0 para no limpiar
zscore_third = 0; % Si quiero zscorear el espectrograma por el primer tercio de la sesion pongo 1, 
                  % si lo quiero por toda la sesión va 0, si lo quiero por la tercer parte va 3

% Parámetros para suavizar los espectrogramas
if strcmp(paradigm_toinclude,'appetitive');
    kernel_x = 50; % Tamaño del kernel para hacer un smoothing en los espectrogramas. Suaviza en Y. kernel_x = 50 para el apetitivo, 20 para el aversivo.
elseif strcmp(paradigm_toinclude,'aversive');
    kernel_x = 20; % Tamaño del kernel para hacer un smoothing en los espectrogramas. Suaviza en Y. kernel_x = 50 para el apetitivo, 20 para el aversivo.
end
kernel_y = 10; % Tamaño del kernel para hacer un smoothing en los espectrogramas. Suaviza en X. kernel_y = 10 para el apetitivo, 10 para el aversivo.
smooth_final = 1; % Suavizamos el espectrograma promedio final. No afecta la cuantificación, es solo visualización
smooth_each = 1; % Suavizamos cada uno de los espectrogramas de cada trial. Afecta la cuantificación de potencia

% Qué porcion de los trials voy a cuantificar ?
portion = 'all';
% portion = 'early&late';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Define the parent folder containing the 'Rxx' folders
parentFolder = 'D:\Doctorado\Backup Ordenado';

% List all 'Rxx' folders in the parent folder
R_folders = dir(fullfile(parentFolder, 'R*'));

% Inicializo algunas variables
SPG_CS1 = [];
SPG_CS2 = [];
CS1_prog = [];
CS2_prog = [];

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
                        window = 20; % Porque dentro del tono son 20 ventanas de 0.5 seg.
                        if CS1_inicioenS(1,end) < size(S,1) && round(mean(CS1_finenS - CS1_inicioenS)) == 20;
                            for i = 1:size(CS1_inicioenS,2);
                                S_CS1(:,:,i) = S(CS1_inicioenS(1,i)-(window/2):CS1_inicioenS(1,i)+(window*3)-1,:);
                                S_CS2(:,:,i) = S(CS2_inicioenS(1,i)-(window/2):CS2_inicioenS(1,i)+(window*3)-1,:);
                            end
                        else 
                            for i = 1:size(CS1_inicioenS,2);
                                S_CS1(:,:,i) = nan(window*3.5,size(f,2));
                                S_CS2(:,:,i) = nan(window*3.5,size(f,2));
                            end
                        end
                        
                        if size(S_CS1,2) == 1967 && size(S_CS1,1) == 70;
                            SPG_CS1 = cat(3,SPG_CS1,S_CS1(:,:,trials_toinclude));
                            SPG_CS2 = cat(3,SPG_CS2,S_CS2(:,:,trials_toinclude));
                            CS1_prog(:,:,1:size(S_CS1,3),k) = S_CS1;
                            CS2_prog(:,:,1:size(S_CS2,3),k) = S_CS2;
                            k = k + 1;
                            f1 = f;
                        end
                        
                    elseif strcmp(paradigm_toinclude,'aversive');
                        window = 120; % Porque dentro del tono son 120 ventanas de 0.5 seg.
                        if CS1_inicioenS(1,end) < size(S,1) && round(mean(CS1_finenS - CS1_inicioenS)) == 120;
                            for i = trials_toinclude;
                                S_CS1(:,:,i) = S(CS1_inicioenS(1,i)-(window/3):CS1_inicioenS(1,i)+(window*(4/3))-1,:);
                                S_CS2(:,:,i) = S(CS2_inicioenS(1,i)-(window/3):CS2_inicioenS(1,i)+(window*(4/3))-1,:);
                            end
                        else 
                            for i = trials_toinclude;
                                S_CS1(:,:,i) = nan(window*2,size(f,2));
                                S_CS2(:,:,i) = nan(window*2,size(f,2));
                            end
                        end                        
                        
                        if size(S_CS1,2) == 1967 && size(S_CS1,1) == 200;
                            SPG_CS1 = cat(3,SPG_CS1,S_CS1(:,:,trials_toinclude));
                            SPG_CS2 = cat(3,SPG_CS2,S_CS2(:,:,trials_toinclude));
                            CS1_prog(:,:,1:size(S_CS1,3),k) = S_CS1;
                            CS2_prog(:,:,1:size(S_CS2,3),k) = S_CS2;
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
            t1 = 0.5:0.5:size(SPG_CS1,1)*0.5;
            t1 = t1 - t1(window/2) - 0.25;
        elseif strcmp(paradigm_toinclude,'aversive');
            t1 = 0.5:0.5:size(SPG_CS1,1)*0.5;
            t1 = t1 - t1(window/3) - 0.25;        
        end
    end
    
end
cd(parentFolder);

% Nos guardamos los espectrogramas con los distintos trials.
SPGG_CS1 = SPG_CS1;
SPGG_CS2 = SPG_CS2;

% Nos guardamos el n
n_CS1 = size(SPG_CS1,3);
n_CS2 = size(SPG_CS2,3);

% Suavizamos los espectrogamas pero cada uno de los trials individualmente
if smooth_each == 1;
    % Define different kernel sizes for x and y axes
    kernel_size_x = kernel_x;
    kernel_size_y = kernel_y;
    sigma = 2;

    % Create meshgrid with different ranges for x and y
    [x, y] = meshgrid(linspace(-2, 2, kernel_size_x), linspace(-2, 2, kernel_size_y));

    % Define a Gaussian kernel for smoothing
    gaussian_kernel = exp(-(x.^2 + y.^2) / (2 * sigma^2));
    gaussian_kernel = gaussian_kernel / sum(gaussian_kernel(:));

    for i = 1:size(SPG_CS1,3);
        % Smooth the spectrograms
        SPG_CS1_smooth(:,:,i) = conv2(SPG_CS1(:,:,i), gaussian_kernel, 'same');
        SPG_CS2_smooth(:,:,i) = conv2(SPG_CS2(:,:,i), gaussian_kernel, 'same');
    end
    
    for i = 1:size(CS1_prog,3);
      for k = 1:size(CS1_prog,4);  
            CS1_prog(:,:,i,k) = conv2(CS1_prog(:,:,i,k), gaussian_kernel, 'same');
            CS2_prog(:,:,i,k) = conv2(CS2_prog(:,:,i,k), gaussian_kernel, 'same');
      end
    end
else
    SPG_CS1_smooth = SPG_CS1;
    SPG_CS2_smooth = SPG_CS2;
end

% Promediamos espectrogramas en la dimensión trials
SPG_CS1_smooth2 = nanmedian(SPG_CS1_smooth,3);
SPG_CS2_smooth2 = nanmedian(SPG_CS2_smooth,3);

fin = min(find(abs(t1) == min(abs(t1))));

% Suavizamos el espectrograma final si la condicion es 1. Es solo
% visualizacion y no afecta la cuantificación
if smooth_final == 1; 
    % Define different kernel sizes for x and y axes
    kernel_size_x = kernel_x;
    kernel_size_y = kernel_y;
    sigma = 2;

    % Create meshgrid with different ranges for x and y
    [x, y] = meshgrid(linspace(-2, 2, kernel_size_x), linspace(-2, 2, kernel_size_y));

    % Define a Gaussian kernel for smoothing
    gaussian_kernel = exp(-(x.^2 + y.^2) / (2 * sigma^2));
    gaussian_kernel = gaussian_kernel / sum(gaussian_kernel(:));

    % Smooth the spectrograms
    SPG_CS1_smooth2 = conv2(SPG_CS1_smooth2, gaussian_kernel, 'same');
    SPG_CS2_smooth2 = conv2(SPG_CS2_smooth2, gaussian_kernel, 'same');
else
    SPG_CS1_smooth2 = SPG_CS1_smooth2;
    SPG_CS2_smooth2 = SPG_CS2_smooth2;
end

% Seleccionar los primeros 6 trials si se trata de la sesion 'TEST' de 'aversive'
if strcmp(paradigm_toinclude,'aversive') && strcmp(session_toinclude,'TEST') == 1;
    CS1_prog = CS1_prog(:,:,1:4,:);
    CS2_prog = CS2_prog(:,:,1:4,:);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculamos y ploteamos la potencia de la oscilación en función de los trials
disp('Processing ans plotting power quantification in each trial...');
fourhzlegend = '4-Hz (2 a 5 Hz)';
fmin = 2; fmax= 5.3;
f_4hz1 = find(abs(f1-fmin) == min(abs(f1-fmin)));
f_4hz2 = find(abs(f1-fmax) == min(abs(f1-fmax)));
f_4hz = f1(1,f_4hz1:f_4hz2);

thetalegend = 'Theta (5 a 10 Hz)'; % Antes era de 6 a 12 Hz.
fmin = 5.3; fmax= 9.6;
f_theta1 = find(abs(f1-fmin) == min(abs(f1-fmin)));
f_theta2 = find(abs(f1-fmax) == min(abs(f1-fmax)));
f_theta = f1(1,f_theta1:f_theta2);

betalegend = 'Beta (13 a 30 Hz)'; % Antes era de 13 a 25 Hz.
fmin = 13; fmax= 30;
f_beta1 = find(abs(f1-fmin) == min(abs(f1-fmin)));
f_beta2 = find(abs(f1-fmax) == min(abs(f1-fmax)));
f_beta = f1(1,f_beta1:f_beta2);

sgammalegend = 'S-Gamma (40 a 60 Hz)'; % Antes era 45 a 60 Hz.
fmin = 43; fmax= 60;
f_slowgamma1 = find(abs(f1-fmin) == min(abs(f1-fmin)));
f_slowgamma2 = find(abs(f1-fmax) == min(abs(f1-fmax)));
f_slowgamma = f1(1,f_slowgamma1:f_slowgamma2);

fgammalegend = 'F-Gamma (60 a 100 Hz)'; % Antes era de 70 a 90 Hz.
fmin = 60; fmax= 98;
f_fastgamma1 = find(abs(f1-fmin) == min(abs(f1-fmin)));
f_fastgamma2 = find(abs(f1-fmax) == min(abs(f1-fmax)));
f_fastgamma = f1(1,f_fastgamma1:f_fastgamma2);

fhighfreqlegend = 'HFO (100 a 150 Hz)';fmin = 102; fmax= 150;
f_highfreq1 = find(abs(f1-fmin) == min(abs(f1-fmin)));
f_highfreq2 = find(abs(f1-fmax) == min(abs(f1-fmax)));
f_highfreq = f1(1,f_highfreq1:f_highfreq2);

if strcmp(paradigm_toinclude,'aversive') && strcmp(session_toinclude,'TEST') == 0;
    t_1 = 40;       %40
    t_2 = 160;      %160
    cs_1 = 1;       %1
    cs_2 = 4;       %4
    cs_3 = 17;      %17
    cs_4 = 20;      %20
    reshape1 = 2;   %2
    reshape2 = 10;  %10
elseif strcmp(paradigm_toinclude,'aversive') && strcmp(session_toinclude,'TEST') == 1;
    t_1 = 40;       %40
    t_2 = 160;      %160
    cs_1 = 1;       %1
    cs_2 = 4;       %4
    cs_3 = 17;      %17
    cs_4 = 20;      %20
    reshape1 = 1;   %1
    reshape2 = 4;   %4
elseif strcmp(paradigm_toinclude,'appetitive');
    t_1 = 10;       %10
    t_2 = 30;       %30
    cs_1 = 1;       %1
    cs_2 = 20;      %20
    cs_3 = 41;      %41
    cs_4 = 60;      %60
    reshape1 = 2;   %2
    reshape2 = 30;  %30
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cuantificamos 4-Hz SNR

% Ploteamos promedio de toda la sesión (all) o early&late (early&late)
figure();

if strcmp(portion,'all');
    % Calculamos 4-Hz
    frecuencia = fourhzlegend; 
    CS1_progg = CS1_prog(t_1:t_2,f_4hz1:f_4hz2,1:end,:); CS1_progg = nanmedian(CS1_progg,2); CS1_progg = nanmedian(CS1_progg,1); CS1_progg = squeeze(CS1_progg); CS1_progg = reshape(CS1_progg, [], 1);
    CS2_progg = CS2_prog(t_1:t_2,f_4hz1:f_4hz2,1:end,:); CS2_progg = nanmedian(CS2_progg,2); CS2_progg = nanmedian(CS2_progg,1); CS2_progg = squeeze(CS2_progg); CS2_progg = reshape(CS2_progg, [], 1);
    CS1_progg1 = CS1_progg;
    CS2_progg1 = CS2_progg;
    
    % Calculamos 8 Hz
    frecuencia = thetalegend; 
    CS1_progg = CS1_prog(t_1:t_2,f_theta1:f_theta2,1:end,:); CS1_progg = nanmedian(CS1_progg,2); CS1_progg = nanmedian(CS1_progg,1); CS1_progg = squeeze(CS1_progg); CS1_progg = reshape(CS1_progg, [], 1);
    CS2_progg = CS2_prog(t_1:t_2,f_theta1:f_theta2,1:end,:); CS2_progg = nanmedian(CS2_progg,2); CS2_progg = nanmedian(CS2_progg,1); CS2_progg = squeeze(CS2_progg); CS2_progg = reshape(CS2_progg, [], 1);
    CS1_progg2 = CS1_progg;
    CS2_progg2 = CS2_progg;
    
    % Calculamos y ploteamos 4-Hz SNR
    CS1_progg = bsxfun(@rdivide, CS1_progg1, CS1_progg2);
    CS2_progg = bsxfun(@rdivide, CS2_progg1, CS2_progg2);
    frecuencia = '4-Hz SNR';
    plot_SNR(CS1_progg,CS2_progg,region,frecuencia,paradigm_toinclude,'Entire Session');
    ylim([0 8]);
    
    % Set figure properties
    set(gcf, 'Color', 'white');
    set(gcf, 'Position', [500, 500, 200, 200]);

elseif strcmp(portion,'early&late');
    % Ploteamos 4-Hz early
    frecuencia = fourhzlegend; 
    CS1_progg = CS1_prog(t_1:t_2,f_4hz1:f_4hz2,cs_1:cs_2,:); CS1_progg = nanmedian(CS1_progg,2); CS1_progg = nanmedian(CS1_progg,1); CS1_progg = squeeze(CS1_progg); CS1_progg = reshape(CS1_progg, [], 1);
    CS2_progg = CS2_prog(t_1:t_2,f_4hz1:f_4hz2,cs_1:cs_2,:); CS2_progg = nanmedian(CS2_progg,2); CS2_progg = nanmedian(CS2_progg,1); CS2_progg = squeeze(CS2_progg); CS2_progg = reshape(CS2_progg, [], 1);
    CS1_progg1 = CS1_progg;
    CS2_progg1 = CS2_progg;
    
    % Ploteamos 4-Hz Late
    frecuencia = fourhzlegend; 
    CS1_progg = CS1_prog(t_1:t_2,f_4hz1:f_4hz2,cs_3:cs_4,:); CS1_progg = nanmedian(CS1_progg,2); CS1_progg = nanmedian(CS1_progg,1); CS1_progg = squeeze(CS1_progg); CS1_progg = reshape(CS1_progg, [], 1);
    CS2_progg = CS2_prog(t_1:t_2,f_4hz1:f_4hz2,cs_3:cs_4,:); CS2_progg = nanmedian(CS2_progg,2); CS2_progg = nanmedian(CS2_progg,1); CS2_progg = squeeze(CS2_progg); CS2_progg = reshape(CS2_progg, [], 1);
    CS1_progg2 = CS1_progg;
    CS2_progg2 = CS2_progg;
    
    % Ploteamos theta Early
    frecuencia = thetalegend; 
    CS1_progg = CS1_prog(t_1:t_2,f_theta1:f_theta2,cs_1:cs_2,:); CS1_progg = nanmedian(CS1_progg,2); CS1_progg = nanmedian(CS1_progg,1); CS1_progg = squeeze(CS1_progg); CS1_progg = reshape(CS1_progg, [], 1);
    CS2_progg = CS2_prog(t_1:t_2,f_theta1:f_theta2,cs_1:cs_2,:); CS2_progg = nanmedian(CS2_progg,2); CS2_progg = nanmedian(CS2_progg,1); CS2_progg = squeeze(CS2_progg); CS2_progg = reshape(CS2_progg, [], 1);
    CS1_progg3 = CS1_progg;
    CS2_progg3 = CS2_progg;    
    
    % Ploteamos theta Late
    frecuencia = thetalegend; 
    CS1_progg = CS1_prog(t_1:t_2,f_theta1:f_theta2,cs_3:cs_4,:); CS1_progg = nanmedian(CS1_progg,2); CS1_progg = nanmedian(CS1_progg,1); CS1_progg = squeeze(CS1_progg); CS1_progg = reshape(CS1_progg, [], 1);
    CS2_progg = CS2_prog(t_1:t_2,f_theta1:f_theta2,cs_3:cs_4,:); CS2_progg = nanmedian(CS2_progg,2); CS2_progg = nanmedian(CS2_progg,1); CS2_progg = squeeze(CS2_progg); CS2_progg = reshape(CS2_progg, [], 1);
    CS1_progg4 = CS1_progg;
    CS2_progg4 = CS2_progg;    

    % Calculamos y ploteamos 4-Hz SNR
    CS1_progg = bsxfun(@rdivide, CS1_progg1, CS1_progg3);
    CS2_progg = bsxfun(@rdivide, CS2_progg1, CS2_progg3);
    frecuencia = '4-Hz SNR';
    ax1 = subplot(2,1,1);
    plot_SNR(CS1_progg,CS2_progg,region,frecuencia,paradigm_toinclude,'Early');
    ylim([0 8]);
    
    CS1_progg = bsxfun(@rdivide, CS1_progg2, CS1_progg4);
    CS2_progg = bsxfun(@rdivide, CS2_progg2, CS2_progg4);
    frecuencia = '4-Hz SNR';
    ax1 = subplot(2,1,2);
    plot_SNR(CS1_progg,CS2_progg,region,frecuencia,paradigm_toinclude,'Late');
    ylim([0 8]);

    % Set figure properties
    set(gcf, 'Color', 'white');
    set(gcf, 'Position', [500, 500, 150, 400]);
end
    