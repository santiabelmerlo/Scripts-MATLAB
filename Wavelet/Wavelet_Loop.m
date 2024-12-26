%% Wavelet Loop
% Loop para calcular la wavelet, cuantificar en 4Hz y Theta y guardar el vector en cada carpeta
% Usamos las funciones cwt()

clc
clear all

rats = [11,12,13,17,18,19,20]; % Filtro por animales para aversivo.
paradigm_toinclude = 'aversive'; % Filtro por el paradigma
session_toinclude = {'EXT1','EXT2','TEST'}; % Filtro por las sesiones

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Define the parent folder containing the 'Rxx' folders
parentFolder = 'D:\Doctorado\Backup Ordenado';

% List all 'Rxx' folders in the parent folder
R_folders = dir(fullfile(parentFolder, 'R*'));

for r = rats % Iterate through each 'Rxx' folder
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
            if  strcmp(paradigm,paradigm_toinclude) && ...
                any(strcmp(session, session_toinclude))||any(strcmp(session_end, session_toinclude));
                disp(['  All required files exists. Performing action...']);
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                Fs = 1250; % Frecuencia de sampleo

                % Iniciamos algunas variables vacías
                wave_BLA_4Hz = [];
                wave_BLA_Theta = [];
                wave_PL_4Hz = [];
                wave_PL_Theta = [];
                wave_IL_4Hz = [];
                wave_IL_Theta = [];
                f = [];
                t = [];

                % BLA
                if ~isempty(BLA_mainchannel)
                    disp('    Loading BLA Channel...')
                    % Cargamos la señal de BLA
                    lfp_BLA = LoadBinary(strcat(name,'_lfp.dat'), BLA_mainchannel, ch_total); % Cargamos la señal
                    lfp_BLA = lfp_BLA * 0.195; % Convertir un canal de registro de bits a microvolts (uV)
                    lfp_BLA = zpfilt(lfp_BLA,1250,0.1,300); % Filtramos la señal entre 0.1 y 300
                    lfp_BLA = zscorem(lfp_BLA); % Lo normalizamos con zscore
                    t = 1/Fs:1/Fs:size(lfp_BLA,2)/Fs;
                    % Calculamos el wavelet
                    disp('      Computing Wavelet from BLA Channel...')
                    clear y f coi;
                    % Wavelet con función wavelet
                    % [wavelet,period] = wavelet(lfp_BLA,1/Fs,Pad,log2(((1/LowFreq)/(1/HighFreq)))/NumBands,1/HighFreq,NumBands);
                    [y,p] = wavelet(lfp_BLA,1/Fs,1,log2(16)/32,1/16,32);
                    wave_BLA = log(abs(y).^2);
                    f = 1./p;
                    save([name,'_wavelet.mat'],'wave_BLA','f','t');
                    % Frecuencias de interés
                    FourHz_idx = f >= 2 & f <= 5.3;
                    Theta_idx = f >= 5.3 & f <= 9.6;
                    wave_BLA_4Hz = nanmedian(wave_BLA(FourHz_idx,:),1);
                    wave_BLA_Theta = nanmedian(wave_BLA(Theta_idx,:),1);
                    % Borramos lo que no nos interesa
                    clear lfp_BLA y coi wave_BLA;
                end

                % PL
                if ~isempty(PL_mainchannel)
                    disp('    Loading PL Channel...')
                    % Cargamos la señal de PL
                    lfp_PL = LoadBinary(strcat(name,'_lfp.dat'), PL_mainchannel, ch_total); % Cargamos la señal
                    lfp_PL  = lfp_PL  * 0.195; % Convertir un canal de registro de bits a microvolts (uV)
                    lfp_PL  = zpfilt(lfp_PL ,1250,0.1,300); % Filtramos la señal entre 0.1 y 300
                    lfp_PL  = zscorem(lfp_PL); % Lo normalizamos con zscore
                    t = 1/Fs:1/Fs:size(lfp_PL ,2)/Fs;
                    % Calculamos el wavelet
                    disp('      Computing Wavelet from PL Channel...')
                    clear y f coi;
                    % Wavelet con función wavelet
                    % [wavelet,period] = wavelet(lfp_PL,1/Fs,Pad,log2(((1/LowFreq)/(1/HighFreq)))/NumBands,1/HighFreq,NumBands);
                    [y,p] = wavelet(lfp_PL,1/Fs,1,log2(16)/32,1/16,32);
                    wave_PL = log(abs(y).^2);
                    f = 1./p;
                    save([name,'_wavelet.mat'],'wave_PL','-append');
                    % Frecuencias de interés
                    FourHz_idx = f >= 2 & f <= 5.3;
                    Theta_idx = f >= 5.3 & f <= 9.6;
                    wave_PL_4Hz = nanmedian(wave_PL(FourHz_idx,:),1);
                    wave_PL_Theta = nanmedian(wave_PL(Theta_idx,:),1);
                    % Borramos lo que no nos interesa
                    clear lfp_PL y coi wave_PL;
                end

                % IL
                if ~isempty(IL_mainchannel)
                    disp('    Loading IL Channel...')
                    % Cargamos la señal de IL
                    lfp_IL = LoadBinary(strcat(name,'_lfp.dat'), IL_mainchannel, ch_total); % Cargamos la señal
                    lfp_IL  = lfp_IL  * 0.195; % Convertir un canal de registro de bits a microvolts (uV)
                    lfp_IL  = zpfilt(lfp_IL ,1250,0.1,300); % Filtramos la señal entre 0.1 y 300
                    lfp_IL  = zscorem(lfp_IL); % Lo normalizamos con zscore
                    t = 1/Fs:1/Fs:size(lfp_IL ,2)/Fs;
                    % Calculamos el wavelet
                    disp('      Computing Wavelet from IL Channel...')
                    clear y f coi;
                    % Wavelet con función wavelet
                    % [wavelet,period] = wavelet(lfp_IL,1/Fs,Pad,log2(((1/LowFreq)/(1/HighFreq)))/NumBands,1/HighFreq,NumBands);
                    [y,p] = wavelet(lfp_IL,1/Fs,1,log2(16)/32,1/16,32);
                    wave_IL = log(abs(y).^2);
                    f = 1./p;
                    save([name,'_wavelet.mat'],'wave_IL','-append');
                    % Frecuencias de interés
                    FourHz_idx = f >= 2 & f <= 5.3;
                    Theta_idx = f >= 5.3 & f <= 9.6;
                    wave_IL_4Hz = nanmedian(wave_IL(FourHz_idx,:),1);
                    wave_IL_Theta = nanmedian(wave_IL(Theta_idx,:),1);
                    % Borramos lo que no nos interesa
                    clear lfp_IL y coi wave_IL;
                end

                save(strcat(name,'_wavelet.mat'),...
                    'wave_BLA_4Hz','wave_BLA_Theta','wave_PL_4Hz','wave_PL_Theta',...
                    'wave_IL_4Hz','wave_IL_Theta','-append');
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            else
                disp(['  Some required file do not exist.']);
                disp(['  Skipping action...']);
            end
        end
    end
    % Go back to the 'Rxx' folder
    cd(current_R_folder);
end

cd(parentFolder);

disp('Ready!');