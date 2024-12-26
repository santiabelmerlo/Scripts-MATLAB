%% Script para calcular espectrograma promedio de CS1 y CS2 en un grupo de 
% sesiones y animales en particular
% Primera celda: calculamos el espectrograma promedio
% Segunda celda: calculamos la zcurva del apetitivo en cada frecuencia
% Tercera celda: calculamos la zcurva del aversivo en cada frecuencia
clc;
clear all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% En estas lineas selecciono que animales, paradigma y sesiones quiero analizar
rats = [10,11,13,14,16,17,18,19]; % Filtro por animales para apetitivo
% rats = [11,12,13,17,18,19,20]; % Filtro por animales para aversivo
paradigm_toinclude = 'appetitive'; % Filtro por el paradigma
session_toinclude = {'EXT1'}; % Filtro por las sesiones
trials_toinclude = 1:60; % Filtro por los trials que quiero incluir de la sesión
meantitle = 'Extinction 1 BLA Spectrogram'; % Titulo general que le voy a poner a la figura
region = 'BLA'; % Región que quiero analizar: BLA, PL, IL.
remove_epileptic = 1; % 1 para limpiar los momentos epilépticos de la señal, 0 para no limpiar
freqpass = [60 98]; % Rango de frecuencias que voy a analizar
Fs = 1250; % Frecuencia de sampleo

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Define the parent folder containing the 'Rxx' folders
parentFolder = 'D:\Doctorado\Backup Ordenado';

% List all 'Rxx' folders in the parent folder
R_folders = dir(fullfile(parentFolder, 'R*'));

% Inicializo algunas variables
SPG_CS1 = [];
SPG_CS2 = [];
names = [];

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
                        exist(strcat(name,'_lfp.dat')) == 2 && ...
                        exist(strcat(name,'_noise.csv')) == 2 && ...
                        exist(strcat(name,'_freezing.mat')) == 2 && ...
                        exist(strcat(name,'_specgram_',region,'LowFreq.mat')) == 2;
                    
                    % Guardamos las sesiones que contibuyeron al análisis
                    names{1,m} = name; 
                    m = m + 1;
                    
                    % Cargo la señal del amplificador
                    if strcmp(region,'BLA');
                        load(strcat(name,'_sessioninfo.mat'), 'BLA_mainchannel'); ch = BLA_mainchannel; clear BLA_mainchannel; % Canal a levantar
                    elseif strcmp(region,'PL');
                        load(strcat(name,'_sessioninfo.mat'), 'PL_mainchannel'); ch = PL_mainchannel; clear PL_mainchannel; % Canal a levantar
                    elseif strcmp(region,'IL');
                        load(strcat(name,'_sessioninfo.mat'), 'IL_mainchannel'); ch = IL_mainchannel; clear IL_mainchannel; % Canal a levantar
                    end
                    [amplifier_lfp] = LoadBinary(strcat(name,'_lfp.dat'), ch, ch_total);
                    amplifier_lfp = amplifier_lfp * 0.195; % Convertir un canal de registro de bits a microvolts (uV).
                    amplifier_lfp = zscore(amplifier_lfp);
                    
                    % Buscamos los momentos de ruido y los guardamos en noise_pos
                    noise = abs(amplifier_lfp) > 5;
                    noise_pos = find(diff(noise) == 1);
                    noise_pos = noise_pos';
                    
                    % Cargamos los datos del amplificador
                    amplifier_timestamps = readNPY(strcat(name,'_timestamps.npy')); % Cargamos el estado de cada input del IO Board.
                    amplifier_timestamps = double(amplifier_timestamps(1):1:amplifier_timestamps(end)); % Hay que hacer esto porque amplifier.timestamps devuelve distinto número de tiempos que de registro.
                    amplifier_timestamps_lfp = double(amplifier_timestamps(1):24:amplifier_timestamps(end)); % Hay que hacer esto porque amplifier.timestamps devuelve distinto número de tiempos que de registro.
                    t = (amplifier_timestamps_lfp - amplifier_timestamps(1))/30000; % Le restamos el primer timestamp y lo pasamos a segundos. 

                    % Filtramos la señal
                    highpass = freqpass(1); lowpass = freqpass(2); % Frecuencias de corte del filtro. Corte pasabajos en nyquist frequency.
                    data = amplifier_lfp; % Señal que queremos filtrar
                    samplePeriod = 1/1250; % Frecuencia de muestreo de la señal subsampleada
                    % Aplicamos un filtro pasa altos con corte en 0.1 Hz
                    filtHPF = (2*highpass)/(1/samplePeriod);
                    [b, a] = butter(4, filtHPF, 'high');
                    data_hp = filtfilt(b, a, data);
                    % Aplicamos un filtro pasa bajos con corte en 300 Hz
                    filtLPF = (2*lowpass)/(1/samplePeriod);
                    [b, a] = butter(4, filtLPF, 'low');
                    data_hlp = filtfilt(b, a, data_hp); %señal de mag de acel filtrada
                    amplifier_lfp = data_hlp; % Guardamos la señal filtrada como "amplifier_BLA_downsample_filt"
                    clear data_hlp a b data filtHPF data_hp filtLPF highpass lowpass samplePeriod;% Borramos las variables que no me sirven más

                    % Calculamos el zscore de la señal filtrada
                    amplifier_lfp = zscore(amplifier_lfp);

                    % Apply Hilbert transform to get instantaneous amplitude
                    hilbert_transform = hilbert(amplifier_lfp);
                    instantaneous_amplitude = abs(hilbert_transform);
                    
                    % Quitamos los momentos de ruido de la amplitud de hilbert
                    if any(noise_pos);
                        for i = 1:size(noise_pos,1);
                            if noise_pos(i) < Fs*3;
                                instantaneous_amplitude(1,1:noise_pos(i)+(Fs*2.5)) = nan;
                            elseif noise_pos(i) > size(instantaneous_amplitude,2) - Fs*3;
                                instantaneous_amplitude(1,noise_pos(i)-(Fs*2.5):end) = nan;
                            else
                                instantaneous_amplitude(1,noise_pos(i)-(Fs*2.5):noise_pos(i)+(Fs*2.5)) = nan;
                            end
                        end
                    end
                    
                    % Quitamos las partes del espectrograma que son epilépticas
                    if remove_epileptic == 1;
                        if exist(strcat(name,'_epileptic.mat')) == 2;
                            load(strcat(name,'_epileptic.mat'),'inicio_epileptic','fin_epileptic');
                            % Buscamos la esta actividad en S
                            j = 1;
                            for i = 1:size(inicio_epileptic,2);
                                ep_inicio(j) = find(abs(t-inicio_epileptic(1,i)) == min(abs(t-inicio_epileptic(1,i))));
                                ep_fin(j) = find(abs(t-fin_epileptic(1,i)) == min(abs(t-fin_epileptic(1,i))));
                                j = j + 1;
                            end
                            % Reemplazamos con Nan donde hay actividad epileptica
                            for i = 1:size(ep_inicio,2);
                                    instantaneous_amplitude(1,ep_inicio(i):ep_fin(i)) = NaN;
                            end
                        end
                    end

                    % Normalizamos a la amplitud media de la señal
                    instantaneous_amplitude = instantaneous_amplitude/nanmean(instantaneous_amplitude);

                    % Cargo los tiempos de los tonos
                    load(strcat(name,'_freezing.mat'),'TTL_CS1_inicio','TTL_CS1_fin','TTL_CS2_inicio','TTL_CS2_fin');

                    % Busco las posiciones en S donde inician y finalizan los tonos
                    j = 1;
                    for i = 1:size(TTL_CS1_inicio,1);
                        CS1_inicioenS(j) = min(find(abs(t-TTL_CS1_inicio(i)) == min(abs(t-TTL_CS1_inicio(i)))));
                        CS1_finenS(j) = min(find(abs(t-TTL_CS1_fin(i)) == min(abs(t-TTL_CS1_fin(i)))));
                        CS2_inicioenS(j) = min(find(abs(t-TTL_CS2_inicio(i)) == min(abs(t-TTL_CS2_inicio(i)))));
                        CS2_finenS(j) = min(find(abs(t-TTL_CS2_fin(i)) == min(abs(t-TTL_CS2_fin(i)))));
                        j = j + 1;
                    end

                    if CS1_finenS(end) < size(amplifier_lfp,2) && CS2_finenS(end) < size(amplifier_lfp,2);
                    
                        % Metemos todos los pedazos de S durante el CS en una gran matriz y
                        % calculamos la media

                        S_CS1 = [];
                        S_CS2 = [];

%                         if strcmp(paradigm_toinclude,'appetitive');
%                             for i = trials_toinclude;
%                                 S_CS1(:,i) = instantaneous_amplitude(1,CS1_inicioenS(1,i):CS1_inicioenS(1,i)+Fs*10-1);
%                                 S_CS2(:,i) = instantaneous_amplitude(1,CS2_inicioenS(1,i):CS2_inicioenS(1,i)+Fs*10-1);
%                             end
%                         elseif strcmp(paradigm_toinclude,'aversive');
%                             for i = trials_toinclude;
%                                 S_CS1(:,i) = instantaneous_amplitude(1,CS1_inicioenS(1,i):CS1_inicioenS(1,i)+Fs*60-1);
%                                 S_CS2(:,i) = instantaneous_amplitude(1,CS2_inicioenS(1,i):CS2_inicioenS(1,i)+Fs*60-1);
%                             end
%                         end
                        
                        if strcmp(paradigm_toinclude,'appetitive');
                            for i = trials_toinclude;
                                S_CS1(:,i) = instantaneous_amplitude(1,CS1_inicioenS(1,i):CS1_inicioenS(1,i)+Fs*10-1);
                                S_CS2(:,i) = instantaneous_amplitude(1,CS2_inicioenS(1,i):CS2_inicioenS(1,i)+Fs*10-1);
                            end
                        elseif strcmp(paradigm_toinclude,'aversive');
                            for i = trials_toinclude;
                                S_CS1(:,i) = instantaneous_amplitude(1,CS1_inicioenS(1,i):CS1_inicioenS(1,i)+Fs*60-1);
                                S_CS2(:,i) = instantaneous_amplitude(1,CS2_inicioenS(1,i):CS2_inicioenS(1,i)+Fs*60-1);
                            end
                        end

                        S_CS1 = nanmean(S_CS1,1); S_CS1 = S_CS1';
                        S_CS2 = nanmean(S_CS2,1); S_CS2 = S_CS2';

                        S_CS1 = S_CS1(trials_toinclude);
                        S_CS2 = S_CS2(trials_toinclude);

                        SPG_CS1 = cat(2,SPG_CS1,S_CS1);
                        SPG_CS2 = cat(2,SPG_CS2,S_CS2);
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

% Hacemos un smoothing de los datos promediando de a 10 trials
% for i = 1:size(SPG_CS1,2); 
%     SPGG_CS1(:,i) = smooth(SPG_CS1(:,i),10);
%     SPGG_CS2(:,i) = smooth(SPG_CS2(:,i),10);
% end

% Define the smoothing window size
windowSize = 20;
% Calculate the padding size
padSize = floor(windowSize / 2);

% Extend and smooth each column
for i = 1:size(SPG_CS1, 2)
    % Extend SPG_CS1
    extended_CS1 = [flipud(SPG_CS1(1:padSize, i)); SPG_CS1(:, i); flipud(SPG_CS1(end-padSize+1:end, i))];
    % Smooth the extended data
    smoothed_CS1 = smooth(extended_CS1, windowSize);
    % Truncate back to original size
    SPGG_CS1(:, i) = smoothed_CS1(padSize+1:end-padSize);

    % Extend SPG_CS2
    extended_CS2 = [flipud(SPG_CS2(1:padSize, i)); SPG_CS2(:, i); flipud(SPG_CS2(end-padSize+1:end, i))];
    % Smooth the extended data
    smoothed_CS2 = smooth(extended_CS2, windowSize);
    % Truncate back to original size
    SPGG_CS2(:, i) = smoothed_CS2(padSize+1:end-padSize);
end

figure()
subplot(1,3,1:2);
plot_power(SPGG_CS1,SPGG_CS2,region,strcat(' Frequency: ', num2str(freqpass)),paradigm_toinclude);
xlim([0.5 size(SPGG_CS1,1)+0.5]);
subplot(1,3,3);
plot_power_boxplot(SPGG_CS1,SPGG_CS2,region,paradigm_toinclude);

% Set figure properties
set(gcf, 'Color', 'white');
set(gcf, 'Position', [100, 200, 800, 400]);
