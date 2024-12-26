%% Baseline Sheet: creamos una tabla que contiene todos los baseline de las sesiones
% Calculados a partir del espectrograma interpolando primero las franjas de
% 50 y 100 Hz y luego haciendo nanmedian de toda la sesión.

clc
clear all

rats = 10:20;
paradigm_toinclude = {'aversive'}; % Filtro por el paradigma
session_toinclude = {'EXT1','EXT2','TEST'}; % Filtro por las sesiones

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Define the parent folder containing the 'Rxx' folders
parentFolder = 'D:\Doctorado\Backup Ordenado';

% List all 'Rxx' folders in the parent folder
R_folders = dir(fullfile(parentFolder, 'R*'));

Baseline_Sheet = table();

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
                disp(['  All required files exist. Performing action...']);
                
                % Process each region (BLA, PL, IL)
                regions = {'BLA', 'PL', 'IL'};
                for regIdx = 1:length(regions)
                    region = regions{regIdx};
                    specFile = strcat(name,'_specgram_',region,'LowFreq.mat');
                    
                    if exist(specFile, 'file') == 2
                        % Load spectrogram
                        load(specFile);
                        
                        % Interpolate noisy frequencies (100 Hz and 50 Hz bands)
                        noisyBands = [98 102; 48 52];
                        for band = 1:size(noisyBands, 1)
                            fmin = find(abs(f - noisyBands(band, 1)) == min(abs(f - noisyBands(band, 1))));
                            fmax = find(abs(f - noisyBands(band, 2)) == min(abs(f - noisyBands(band, 2))));
                            for i = 1:fmax - fmin
                                S(:, fmin + i) = S(:, fmin) + i * ((S(:, fmax + 1) - S(:, fmin - 1)) / (fmax - fmin));
                            end
                        end
                        
                        % Normalize for PSD and Power
                        S1 = bsxfun(@times, S, f);
                        S1 = bsxfun(@rdivide, S1, median(median(S1, 1)));
                        baseline = nanmedian(S1, 1); % Baseline values
                        clear S1 S;
                        
                        % Append data to Baseline_Sheet
                        Baseline_Sheet = [Baseline_Sheet; ...
                            table(r, {name}, {session}, {paradigm}, {region}, {baseline}, {f}, ...
                            'VariableNames', {'Rat', 'Name', 'Session', 'Paradigm', 'Region', 'Baseline', 'Frequency'})];
                    end
                end
            else
                disp(['  Some required files do not exist.']);
                disp(['  Skipping action...']);
            end
        end
    end
    % Go back to the 'Rxx' folder
    cd(current_R_folder);
end

% Go back to the parent folder
cd(parentFolder);

% Guardamos ambos datos
cd('D:\Doctorado\Analisis\Sheets');
save('Baseline_Sheet.mat','Baseline_Sheet');

disp('Ready!');