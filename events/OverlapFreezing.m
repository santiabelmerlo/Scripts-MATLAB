%% Accelerometer and Bonsai Freezing Overlap
% Chequeamos cuanto overlap hay entre el freezing detectado con el acelerómetro y el freezing detectado con el bonsai
% Hay otro script que se llama FreezingOverlap pero está mal. Este es el que da los valores correctos
clc;
clear all;

% Define animals, paradigm, sessions, etc.
% rats = 10:20;
rats = [11,12,13,17,18,19,20]; % Filtro por animales para aversivo.
paradigm_toinclude = 'aversive'; 
session_toinclude = {'EXT1','EXT2','TEST'};

% Parent folder path
parentFolder = 'D:\Doctorado\Backup Ordenado';

% List all 'Rxx' folders
R_folders = dir(fullfile(parentFolder, 'R*'));

% Initialize the variable to store overlap data
overlap_results = table();

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
        [~,D,X] = fileparts(current_D_folder); 
        name = D([1:6]);
        
        if exist(strcat(name,'_sessioninfo.mat'), 'file') == 2
            load(strcat(name,'_sessioninfo.mat'));
            
                % Check if the relevant file exists
                if exist(strcat(name,'_epileptic.mat'), 'file') == 2 && ...
                        strcmp(paradigm_toinclude,paradigm) && ...
                        any(strcmp(session_toinclude,session))
                        
                    % Load the relevant file
                    load(strcat(name,'_epileptic.mat'));

                    % Calculate total durations
                    total_freezing = sum(fin_freezing - inicio_freezing);
                    total_freezing_bonsai = sum(fin_freezing_bonsai - inicio_freezing_bonsai);

                    % Calculate overlap
                    overlap = 0;
                    for i = 1:length(inicio_freezing)
                        for j = 1:length(inicio_freezing_bonsai)
                            overlap_start = max(inicio_freezing(i), inicio_freezing_bonsai(j));
                            overlap_end = min(fin_freezing(i), fin_freezing_bonsai(j));
                            if overlap_end > overlap_start
                                overlap = overlap + (overlap_end - overlap_start);
                            end
                        end
                    end

                    % Calculate percentages
                    overlap_percentage_freezing = (overlap / total_freezing) * 100;
                    overlap_percentage_freezing_bonsai = (overlap / total_freezing_bonsai) * 100;

                    % Store the results in a table
                    overlap_data = table({name}, overlap, overlap_percentage_freezing, overlap_percentage_freezing_bonsai, ...
                                         'VariableNames', {'Folder', 'Overlap_Seconds', 'Overlap_Percentage_Freezing', 'Overlap_Percentage_FreezingBonsai'});
                    overlap_results = [overlap_results; overlap_data]; % Append the result for this folder
                else
                    disp(['  File not found: ', strcat(name,'_epileptic.mat')]);
                end
            
        end
    end
end

% Display the final overlap results table
disp(overlap_results);

mean_percent_bonsai_in_freezing = mean(overlap_results.Overlap_Percentage_Freezing);
mean_percent_freezing_in_bonsai = mean(overlap_results.Overlap_Percentage_FreezingBonsai);

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

%% Si luego quiero plotear algún ejemplo de eventos de freezing para mostrar el overlap
figure;
line([inicio_freezing' fin_freezing'],[1 1],'LineWidth',10,'Color',[0 0 0]);
line([inicio_freezing_bonsai' fin_freezing_bonsai'],[1.1 1.1],'LineWidth',10,'Color',[0 0 0]);
ylim([0.5 1.5]);
axis off;

%% Ahora miramos el número de eventos superpuestos (expresado en pocentaje) y no el % de tiempo superpuesto
clc;
clear all;

% Define animals, paradigm, sessions, etc.
% rats = 10:20;
rats = [11,12,13,17,18,19,20]; % Filtro por animales para aversivo.
paradigm_toinclude = 'aversive'; 
session_toinclude = {'EXT1','EXT2','TEST'};

% Parent folder path
parentFolder = 'D:\Doctorado\Backup Ordenado';

% List all 'Rxx' folders
R_folders = dir(fullfile(parentFolder, 'R*'));

% Initialize the variable to store overlap data
overlap_results = table();

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
        [~,D,X] = fileparts(current_D_folder); 
        name = D([1:6]);
        
        if exist(strcat(name,'_sessioninfo.mat'), 'file') == 2
            load(strcat(name,'_sessioninfo.mat'));
            
            if exist(strcat(name,'_epileptic.mat'), 'file') == 2 && ...
                    strcmp(paradigm_toinclude,paradigm) && ...
                    any(strcmp(session_toinclude,session))
                
                % Load the relevant file
                load(strcat(name,'_epileptic.mat'));
                
                % Count total events
                total_events_freezing = length(inicio_freezing);
                total_events_freezing_bonsai = length(inicio_freezing_bonsai);
                
                % Check for event overlap
                event_overlap = 0;
                for i = 1:length(inicio_freezing)
                    for j = 1:length(inicio_freezing_bonsai)
                        if max(inicio_freezing(i), inicio_freezing_bonsai(j)) < ...
                                min(fin_freezing(i), fin_freezing_bonsai(j))
                            event_overlap = event_overlap + 1;
                            break; % Break inner loop if overlap found for this event
                        end
                    end
                end
                
                % Calculate overlap percentages
                overlap_percentage_events_freezing = (event_overlap / total_events_freezing) * 100;
                overlap_percentage_events_freezing_bonsai = (event_overlap / total_events_freezing_bonsai) * 100;

                % Store the results in a table
                overlap_data = table({name}, event_overlap, total_events_freezing, total_events_freezing_bonsai, ...
                                     overlap_percentage_events_freezing, overlap_percentage_events_freezing_bonsai, ...
                                     'VariableNames', {'Folder', 'Event_Overlap', 'Total_Freezing_Events', ...
                                                       'Total_Bonsai_Events', 'Overlap_Percentage_Freezing', ...
                                                       'Overlap_Percentage_FreezingBonsai'});
                overlap_results = [overlap_results; overlap_data];
            else
                disp(['  File not found: ', strcat(name,'_epileptic.mat')]);
            end
            
        end
    end
end

% Display the final overlap results table
disp(overlap_results);

mean_percent_bonsai_in_freezing_events = mean(overlap_results.Overlap_Percentage_Freezing);
mean_percent_freezing_in_bonsai_events = mean(overlap_results.Overlap_Percentage_FreezingBonsai);

% Define custom colors for the pie charts
color_bonsai = [0.2, 0.6, 0.8]; % RGB for Bonsai Freezing (e.g., blue)
color_no_bonsai = [0.9, 0.9, 0.9]; % RGB for no Bonsai Freezing (e.g., gray)
color_freezing = [0.8, 0.4, 0.2]; % RGB for Freezing (e.g., orange)
color_no_freezing = [0.9, 0.9, 0.9]; % RGB for no Freezing (e.g., light gray)

% Plot pie charts
figure;

% First pie chart (Bonsai Freezing)
subplot(121)
p1 = pie([mean_percent_bonsai_in_freezing_events 100 - mean_percent_bonsai_in_freezing_events], ...
    {'Events Fz video', 'No Fz video'});
title(sprintf('Freezing Events (Total: %d)', sum(overlap_results.Total_Bonsai_Events)));

% Change colors for the first pie chart
p1(1).FaceColor = color_bonsai; % Bonsai Freezing
p1(3).FaceColor = color_no_bonsai; % no Bonsai Freezing

% Second pie chart (Freezing)
subplot(122)
p2 = pie([mean_percent_freezing_in_bonsai_events 100 - mean_percent_freezing_in_bonsai_events], ...
    {'Events Fz Acc.', 'No Fz Acc.'});
title(sprintf('Freezing Events (Total: %d)', sum(overlap_results.Total_Freezing_Events)));

% Change colors for the second pie chart
p2(1).FaceColor = color_freezing; % Freezing
p2(3).FaceColor = color_no_freezing; % no Freezing

disp('Done!');
cd(parentFolder);
