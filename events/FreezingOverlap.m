%% Accelerometer and Bonsai Freezing Overlap
% Chequeamos cuanto overlap hay entre el freezing detectado con el acelerómetro y el freezing detectado con el bonsai 
% Este script no es el bueno. Correr OverlapFreezing en su lugar

clc;
clear all;

rats = 10:20;

% Define the parent folder containing the 'Rxx' folders
parentFolder = 'D:\Doctorado\Backup Ordenado';

% List all 'Rxx' folders in the parent folder
R_folders = dir(fullfile(parentFolder, 'R*'));

% Initialize arrays to store the overlap in seconds for each folder
overlap_freezing_in_bonsai_seconds = [];
overlap_bonsai_in_freezing_seconds = [];

% Initialize arrays to store total durations for each folder
total_freezing_duration = [];
total_freezing_bonsai_duration = [];

% Iterate through each 'Rxx' folder
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
        
        % Check if the necessary files exist
        file_path1 = strcat(name, '_epileptic.mat');
        file_path2 = strcat(name, '_sessioninfo.mat');

        if exist(file_path1, 'file') && exist(file_path2, 'file') == 2
            load(strcat(name,'_sessioninfo.mat'));
            if strcmp(paradigm,'aversive')
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                disp(['     File found. Processing data...']);
                load(strcat(name,'_epileptic.mat'),'inicio_freezing','fin_freezing','inicio_freezing_bonsai','fin_freezing_bonsai');

                % Calculate total durations for freezing and freezing_bonsai events
                freezing_durations = fin_freezing - inicio_freezing;
                freezing_bonsai_durations = fin_freezing_bonsai - inicio_freezing_bonsai;

                total_freezing_duration(end+1) = sum(freezing_durations);
                total_freezing_bonsai_duration(end+1) = sum(freezing_bonsai_durations);

                % Initialize overlap durations for this folder
                overlap_freezing_in_bonsai = 0;
                overlap_bonsai_in_freezing = 0;

                % Compute overlap in seconds
                for i = 1:length(inicio_freezing)
                    for j = 1:length(inicio_freezing_bonsai)
                        % Calculate the overlap interval in seconds
                        overlap_start = max(inicio_freezing(i), inicio_freezing_bonsai(j));
                        overlap_end = min(fin_freezing(i), fin_freezing_bonsai(j));

                        if overlap_start < overlap_end
                            % Accumulate overlap for freezing events
                            overlap_freezing_in_bonsai = overlap_freezing_in_bonsai + (overlap_end - overlap_start);
                        end
                    end
                end

                for j = 1:length(inicio_freezing_bonsai)
                    for i = 1:length(inicio_freezing)
                        % Calculate the overlap interval in seconds
                        overlap_start = max(inicio_freezing(i), inicio_freezing_bonsai(j));
                        overlap_end = min(fin_freezing(i), fin_freezing_bonsai(j));

                        if overlap_start < overlap_end
                            % Accumulate overlap for bonsai freezing events
                            overlap_bonsai_in_freezing = overlap_bonsai_in_freezing + (overlap_end - overlap_start);
                        end
                    end
                end

                % Store overlap durations
                overlap_freezing_in_bonsai_seconds(end+1) = overlap_freezing_in_bonsai;
                overlap_bonsai_in_freezing_seconds(end+1) = overlap_bonsai_in_freezing;

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            end
        end
        
        % Go back to the 'Rxx' folder
        cd(current_R_folder);        
    end
end

% Compute mean percentages
mean_percent_freezing_in_bonsai = (sum(overlap_freezing_in_bonsai_seconds) / sum(total_freezing_duration)) * 100;
mean_percent_bonsai_in_freezing = (sum(overlap_bonsai_in_freezing_seconds) / sum(total_freezing_bonsai_duration)) * 100;

% Define custom colors for the pie charts
color_bonsai = [0.2, 0.6, 0.8]; % RGB for Bonsai Freezing (e.g., blue)
color_no_bonsai = [0.9, 0.9, 0.9]; % RGB for no Bonsai Freezing (e.g., gray)
color_freezing = [0.8, 0.4, 0.2]; % RGB for Freezing (e.g., orange)
color_no_freezing = [0.9, 0.9, 0.9]; % RGB for no Freezing (e.g., light gray)

% Plot pie charts
figure;

% First pie chart (Bonsai Freezing)
subplot(121)
p1 = pie([mean_percent_bonsai_in_freezing 100 - mean_percent_bonsai_in_freezing], ...
    {'Fz video', 'no Fz video'});
title('Freezing from accelerometer');

% Change colors for the first pie chart
p1(1).FaceColor = color_bonsai; % Bonsai Freezing
p1(3).FaceColor = color_no_bonsai; % no Bonsai Freezing

% Move labels closer to the center for the first pie chart
% p1(2) and p1(4) correspond to the text objects (labels)
for k = 2:2:length(p1)
    p1(k).Position = p1(k).Position * 0.45; % Adjust the label position (closer to the center)
end

% Second pie chart (Freezing)
subplot(122)
p2 = pie([mean_percent_freezing_in_bonsai 100 - mean_percent_freezing_in_bonsai], ...
    {'Fz Acc.', 'No Fz Acc.'});
title('Freezing from video');

% Change colors for the second pie chart
p2(1).FaceColor = color_freezing; % Freezing
p2(3).FaceColor = color_no_freezing; % no Freezing

% Move labels closer to the center for the second pie chart
for k = 2:2:length(p2)
    p2(k).Position = p2(k).Position * 0.45; % Adjust the label position (closer to the center)
end

disp('Done!');
cd(parentFolder);

