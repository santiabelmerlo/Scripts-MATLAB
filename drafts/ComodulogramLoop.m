%%
clc
clear all;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rats = [11];
% rats = [10,11,13,14,16,17,18,19]; % Filtro por animales para apetitivo
% rats = [11,12,13,17,18,19,20]; % Filtro por animales para aversivo
session_toinclude = {'TR5','EXT1'}; 
% session_toinclude = {'TR1','TR2','TR3','TR4','TR5','TR6','TR7','TR8','EXT1','EXT2'}; % Filtro por las sesiones apetitivas
paradigm_toinclude = 'appetitive'; % Filtro por el paradigma
num_trials = 60; % Numero de trials que tiene que tener una sesión para incluirla
region = 'IL'; % Región que quiero analizar: BLA, PL, IL.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PhaseF = '4hz'; % Colocar que rango de frecuencias quiero promediar como '4hz', 'theta' o 'beta'
AmpF = 'sgamma'; % Colocar que rango de frecuencias quiero promediar como 'sgamma' o 'fgamma'
SD = [-5,5];
shift = 0; % Whether to calculate shift predictor or not.
npick = 20; % How many segments to pick per session
amp_normalization = 1; % 0 para normalizar la amplitud por la media, 1 para normalizar por la mediana. Default: 0
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Define the parent folder containing the 'Rxx' folders
parentFolder = 'D:\Doctorado\Backup Ordenado';

% List all 'Rxx' folders in the parent folder
R_folders = dir(fullfile(parentFolder, 'R*'));

% Iniciamos algunas variables
mod = [];
amp = [];

% Iterate through each Rxx folder
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
        disp(['Processing subfolder: ' current_D_folder]);
        
        % Change the current folder to the 'RxDy' subfolder
        cd(current_D_folder);
        [~,D,X] = fileparts(current_D_folder); name = D([1:6]);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if exist(strcat(name,'_sessioninfo.mat')) == 2;
            load(strcat(name,'_sessioninfo.mat'));
            if strcmp(paradigm,paradigm_toinclude) && any(strcmp(session, session_toinclude));
                disp(['Session found, including in dataset...']);
                if exist(strcat(name,'_sessioninfo.mat')) == 2 && ...
                    ~isempty(strcat(region,'_mainchannel')) && ...
                    exist(strcat(name,'_freezing.mat')) == 2;
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    clear H pos posiciones NormAmp;
                    Fs = 1250; % Frecuencia de sampleo
                    ch = eval(strcat(region,'_mainchannel'));

                    load(strcat(name,'_sessioninfo.mat'), 'ch_total'); % Número de canales totales
                    load(strcat(name,'_sessioninfo.mat'), 'paradigm'); % Tipo de paradigma. Appetitive or aversive

                    % Cargo los tiempos de los tonos
                    load(strcat(name,'_freezing.mat'),'TTL_CS1_inicio','TTL_CS1_fin','TTL_CS2_inicio','TTL_CS2_fin');

                    % Cargamos los datos del amplificador
%                     amplifier_timestamps = readNPY(strcat(name,'_timestamps.npy')); % Cargamos el estado de cada input del IO Board.
%                     amplifier_timestamps = double(amplifier_timestamps(1):1:amplifier_timestamps(end)); % Hay que hacer esto porque amplifier.timestamps devuelve distinto número de tiempos que de registro.
%                     amplifier_timestamps_lfp = double(amplifier_timestamps(1):24:amplifier_timestamps(end)); % Hay que hacer esto porque amplifier.timestamps devuelve distinto número de tiempos que de registro.
%                     t = (amplifier_timestamps_lfp - amplifier_timestamps(1))/30000; % Le restamos el primer timestamp y lo pasamos a segundos.

                    % Cargamos un canal LFP del amplificador
                    disp(['Loading LFP signal...']);
                    [lfp] = LoadBinary(strcat(name,'_lfp.dat'), ch, ch_total);
                    lfp = lfp * 0.195; % Convertir un canal de registro de bits a microvolts (uV).
                    clear amplifier_timestamps amplifier_timestamps_lfp;

                    % Filtramos la señal
                    disp(['Filtering LFP signal...']);
                    highpass = 0.1; lowpass = 300; % Frecuencias de corte del filtro. Corte pasabajos en nyquist frequency.
                    data = lfp; % Señal que queremos filtrar
                    samplePeriod = 1/1250; % Frecuencia de muestreo de la señal subsampleada
                    % Aplicamos un filtro pasa altos con corte en 0.1 Hz
                    filtHPF = (2*highpass)/(1/samplePeriod);
                    [b, a] = butter(4, filtHPF, 'high');
                    data_hp = filtfilt(b, a, data);
                    % Aplicamos un filtro pasa bajos con corte en 300 Hz
                    filtLPF = (2*lowpass)/(1/samplePeriod);
                    [b, a] = butter(4, filtLPF, 'low');
                    data_hlp = filtfilt(b, a, data_hp); %señal de mag de acel filtrada
                    lfp = data_hlp; % Guardamos la señal filtrada como "amplifier_BLA_downsample_filt"
                    clear data_hlp a b data filtHPF data_hp filtLPF highpass lowpass samplePeriod;% Borramos las variables que no me sirven más

                    data_length = length(lfp);
                    srate = 1250;
                    dt = 1/srate;

                    % Busco las posiciones en S donde inician y finalizan los tonos
%                     j = 1;
%                     if size(TTL_CS1_inicio,1) == num_trials
%                         for i = 1:size(TTL_CS1_inicio,1);
%                             CS1_inicioenS(j) = min(find(abs(t-TTL_CS1_inicio(i)) == min(abs(t-TTL_CS1_inicio(i)))));
%                             CS1_finenS(j) = min(find(abs(t-TTL_CS1_fin(i)) == min(abs(t-TTL_CS1_fin(i)))));
%                             CS2_inicioenS(j) = min(find(abs(t-TTL_CS2_inicio(i)) == min(abs(t-TTL_CS2_inicio(i)))));
%                             CS2_finenS(j) = min(find(abs(t-TTL_CS2_fin(i)) == min(abs(t-TTL_CS2_fin(i)))));
%                             j = j + 1;
%                         end 
%                     end
                    
                    % Determinamos en que rango vamos a filtrar
                    if strcmp(PhaseF,'4hz')
                        PhaseFreq_Band = [2,5.3];
                    elseif strcmp(PhaseF,'theta')
                        PhaseFreq_Band = [5.3,9.6];
                    elseif strcmp(PhaseF,'beta')
                        PhaseFreq_Band = [13,30];
                    end

                    theta = eegfilt(lfp,srate,PhaseFreq_Band(1),PhaseFreq_Band(2));
                    theta = abs(hilbert(theta));
                    theta = zscorem(theta,2);

                    pos = 1:srate*10:size(theta,2);

                    for i = 1:size(pos,2)-1
                        H(i) = median(theta(1,pos(1,i):pos(1,i+1))); %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Ver esto: mean or median. Default: median
                    end
                    
                    if amp_normalization == 1; % Normalizar por la mediana
                        H = zscorem(H,2); % Use zscore or zscorem si quiero normalizar la amplitud de la hilbert segun la media o la mediana. La primera opcion es más sensible a los ruidos.
                    elseif amp_normalization == 0; % Normalizar por la media    
                        H = zscore(H,1,2); % Use zscore or zscorem si quiero normalizar la amplitud de la hilbert segun la media o la mediana. La primera opcion es más sensible a los ruidos.
                    end
                    
                    clear C_CS1 Comodulogram Comodulograms Modulation NormAmp2 NormAmp NormampP
                    posiciones = pos(H >= SD(1) & H <= SD(2));
                    NormAmp = (H(H >= SD(1) & H <= SD(2)))';

                    % Comodulogram Phase(Degree) vs. Frequency(Hz) in Normalized Power Units
                    colorlim = ([-0.35 0.35]);
                    vertlim = ([35 100]);

                    j = 1; % Inicializamos el valor k

                    pick = randperm(size(posiciones,2), npick);

                    for l = 1:size(pick,2)
                        i = pick(1,l);
                        if posiciones(1,i)+srate*30 > size(lfp,2)
                            % Do nothing
                        else
                            % Calculamos la modulacion para los CSs
                            lfp_CS1 = lfp(1,posiciones(1,i):posiciones(1,i) + (srate*10));

                            % Calculamos la modulación para los shift predictors
                            k = 1250 * randi(20,1); % Corrimiento de la fase de 1 a 20 seg.
                            lfp_CS1_shift = lfp(1,posiciones(1,i)+k:posiciones(1,i)+(srate*10)+k);

                            % Compute the comodulogram
                            [C_CS1(:,:,j),P] = ComodulogramDegAmp(lfp_CS1, lfp_CS1, srate, PhaseFreq_Band);
                            if shift == 0;
                                Comodulogram(:,:,j) = comodulogram_faster(lfp_CS1);
                                NormAmp2(j,1) = NormAmp(i,1);
                            elseif shift == 1;
                                Comodulogram(:,:,j) = comodulogram_shift(lfp_CS1,lfp_CS1_shift); 
                            end
                            j = j + 1; % Le sumamos 1 a j.
                        end
                    end

                    PhaseFreqVector = 0:1:30;
                    AmpFreqVector = 10:5:200;
                    PhaseFreq_BandWidth = 1;
                    AmpFreq_BandWidth = 20;

                    Comodulogram_phase = PhaseFreqVector+PhaseFreq_BandWidth/2;
                    Comodulogram_amp = AmpFreqVector+AmpFreq_BandWidth/2;

                    % Determinamos en que rango promediar de acuerdo al valor que toma PhaseF
                    if strcmp(PhaseF,'4hz')
                        range1 = [2:5];
                    elseif strcmp(PhaseF,'theta')
                        range1 = [6:10];
                    elseif strcmp(PhaseF,'beta')
                        range1 = [14:30];
                    end

                    % Determinamos en que rango promediar de acuerdo al valor que toma PhaseF
                    if strcmp(AmpF,'sgamma')
                        range2 = [6:9];
                    elseif strcmp(AmpF,'fgamma')
                        range2 = [10:17];
                    end

                    Modulation = Comodulogram(range1,range2,:);
%                     Modulation = median(Modulation,1);
%                     Modulation = median(Modulation,2);
                    Modulation = max(Modulation,[],1);
                    Modulation = max(Modulation,[],2);
                    Modulation = squeeze(Modulation);
                    
                    disp('Adding data to dataset...')
                    mod = cat(1,mod,Modulation);
                    amp = cat(1,amp,NormAmp2);
                end
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
    end      
    % Go back to the 'Rxx' folder
    cd(current_R_folder);
end
cd(parentFolder);

OUTPUT = [amp,mod];