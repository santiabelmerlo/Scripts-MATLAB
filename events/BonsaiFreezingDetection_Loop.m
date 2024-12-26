%% Bonsai Freezing Detection Loop
% Detects freezing with bonsai movement detection and cleans that freezing
% events excluding the ones that overlaps with sleep or epileptic events.

clc;
clear all;

% Define the parent folder containing the 'Rxx' folders
parentFolder = 'D:\Doctorado\Backup Ordenado';

% List all 'Rxx' folders in the parent folder
R_folders = dir(fullfile(parentFolder, 'R*'));

% Iterate through each 'Rxx' folder
for r = 1:length(R_folders)
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
        
        % Check if neccesary files exists
        file_path1 = strcat(name, '_epileptic.mat'); 
        file_path2 = strcat(name, '_bonsai_freezing.csv');
        file_path3 = strcat(name, '_video_timestamps_synchronized.csv');
        
        if exist(file_path1, 'file') && exist(file_path2, 'file') && exist(file_path3, 'file') == 2
            disp(['     File found. Processing data...']);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            video_freezing = csvread(strcat(name,'_bonsai_freezing.csv'));
            video_timestamps = csvread(strcat(name,'_video_timestamps_synchronized.csv'));
            video_timestamps = video_timestamps/30000;

            video_freezing_zscore = zscore(video_freezing);
            video_freezing_zscore = video_freezing_zscore - min(video_freezing_zscore);

            % Detectamos el freezing en el video
            th = 0.02;
            freezing = video_freezing_zscore < th;
            inicio_freezing = video_timestamps(diff(freezing) == 1);
            fin_freezing = video_timestamps(diff(freezing) == -1);

            % Borramos inicio y fin tienen distintas dimensiones
            if inicio_freezing(1) >= fin_freezing(1);
                if size(inicio_freezing,1) > size(fin_freezing,1); 
                    inicio_freezing(end) = [];
                elseif size(inicio_freezing,1) < size(fin_freezing,1);
                    fin_freezing(1) = [];
                elseif size(inicio_freezing,1) == size(fin_freezing,1);
                    inicio_freezing(end) = [];
                    fin_freezing(1) = [];
                end
            elseif fin_freezing(end) <= inicio_freezing(end);
                inicio_freezing(end) = [];
            end
            duracion_freezing = fin_freezing - inicio_freezing;

            % Nos quedamos con los freezings mayor a 1 seg
            inicio_freezing = inicio_freezing(duracion_freezing >= 1);
            fin_freezing = fin_freezing(duracion_freezing >= 1);
            duracion_freezing = duracion_freezing(duracion_freezing >= 1);

            inicio_freezing_bonsai = inicio_freezing';
            fin_freezing_bonsai = fin_freezing';
            duracion_freezing_bonsai = duracion_freezing';

            clearvars -except inicio_freezing_bonsai fin_freezing_bonsai...
                duracion_freezing_bonsai name path parentFolder R_folders...
                current_R_folder D_folders current_D_folder
 
            load(strcat(name,'_epileptic.mat'));

            % Initialize a logical array to keep track of which freezing_bonsai events to keep
            keep_freezing_bonsai = true(size(inicio_freezing_bonsai));

            % Loop through each freezing_bonsai event
            for i = 1:length(inicio_freezing_bonsai)
                % Get the start and end of the current freezing_bonsai event
                start_fb = inicio_freezing_bonsai(i);
                end_fb = fin_freezing_bonsai(i);

                % Check if it overlaps with any epileptic event
                overlaps_epileptic = any((start_fb >= inicio_epileptic & start_fb <= fin_epileptic) | ...
                                         (end_fb >= inicio_epileptic & end_fb <= fin_epileptic) | ...
                                         (start_fb <= inicio_epileptic & end_fb >= fin_epileptic));  % fully encloses the epileptic event

                % Check if it overlaps with any sleep event
                overlaps_sleep = any((start_fb >= inicio_sleep & start_fb <= fin_sleep) | ...
                                     (end_fb >= inicio_sleep & end_fb <= fin_sleep) | ...
                                     (start_fb <= inicio_sleep & end_fb >= fin_sleep));  % fully encloses the sleep event

                % Check if it does not overlap with any freezing event
                dontoverlap_freezing = ~any((start_fb >= inicio_freezing & start_fb <= fin_freezing) | ...
                                     (end_fb >= inicio_freezing & end_fb <= fin_freezing) | ...
                                     (start_fb <= inicio_freezing & end_fb >= fin_freezing));  % fully encloses the freezing event
                
                % If it overlaps with either, mark it to be excluded
                if overlaps_epileptic || overlaps_sleep || dontoverlap_freezing
                    keep_freezing_bonsai(i) = false;
                end
            end

            % Now, filter the freezing_bonsai events to exclude the overlapping ones
            inicio_freezing_bonsai = inicio_freezing_bonsai(keep_freezing_bonsai);
            fin_freezing_bonsai = fin_freezing_bonsai(keep_freezing_bonsai);
            duracion_freezing_bonsai = duracion_freezing_bonsai(keep_freezing_bonsai);

            clear inicio_freezing_bonsai_cleaned fin_freezing_bonsai_cleaned duracion_freezing_bonsai_cleaned end_fb start_fb...
                overlaps_sleep overlaps_epileptic keep_freezing_bonsai i

            % Calculate the gaps between consecutive freezing events
            gaps = inicio_freezing_bonsai(2:end) - fin_freezing_bonsai(1:end-1);

            % Find the gaps that are smaller than 0.5 seconds
            small_gaps_idx = find(gaps < 0.5);

            % Merge the events by extending the end of the earlier event to the end of the later event
            for i = 1:length(small_gaps_idx)
                fin_freezing_bonsai(small_gaps_idx(i)) = fin_freezing_bonsai(small_gaps_idx(i)+1);
            end

            % Remove the merged events from the arrays
            inicio_freezing_bonsai(small_gaps_idx + 1) = [];
            fin_freezing_bonsai(small_gaps_idx + 1) = [];
            duracion_freezing_bonsai = fin_freezing_bonsai - inicio_freezing_bonsai;

            % Ensure that only freezing events with a duration greater than or equal to 1 second are kept
            valid_freezing_idx = duracion_freezing_bonsai >= 1;
            inicio_freezing_bonsai = inicio_freezing_bonsai(valid_freezing_idx);
            fin_freezing_bonsai = fin_freezing_bonsai(valid_freezing_idx);
            duracion_freezing_bonsai = duracion_freezing_bonsai(valid_freezing_idx);

            clear gaps i small_gaps_idx valid_freezing_idx
            
            %%%%%%%%%%%%%%%%%%%%%%
            % Find freezing events that do not overlap with any freezing_bonsai event
            keep_freezing_new = true(size(inicio_freezing));

            for i = 1:length(inicio_freezing)
                % Get the start and end of the current freezing event
                start_f = inicio_freezing(i);
                end_f = fin_freezing(i);

                % Check if it overlaps with any freezing_bonsai event
                overlaps_bonsai = any((start_f >= inicio_freezing_bonsai & start_f <= fin_freezing_bonsai) | ...
                                      (end_f >= inicio_freezing_bonsai & end_f <= fin_freezing_bonsai) | ...
                                      (start_f <= inicio_freezing_bonsai & end_f >= fin_freezing_bonsai));  % fully encloses the freezing_bonsai event

                % If it overlaps, mark it to be excluded from the new freezing events
                if overlaps_bonsai
                    keep_freezing_new(i) = false;
                end
            end

            % Filter freezing events that do not overlap with freezing_bonsai
            new_inicio_freezing = inicio_freezing(keep_freezing_new);
            new_fin_freezing = fin_freezing(keep_freezing_new);
            new_duracion_freezing = new_fin_freezing - new_inicio_freezing;

            % Concatenate the new freezing events with the existing freezing_bonsai events
            inicio_freezing_bonsai = [inicio_freezing_bonsai'; new_inicio_freezing'];
            fin_freezing_bonsai = [fin_freezing_bonsai'; new_fin_freezing'];
            duracion_freezing_bonsai = [duracion_freezing_bonsai'; new_duracion_freezing'];
            
            inicio_freezing_bonsai = inicio_freezing_bonsai';
            fin_freezing_bonsai = fin_freezing_bonsai';
            duracion_freezing_bonsai = duracion_freezing_bonsai';
            
            % Sort the concatenated freezing_bonsai events by their start times
            [~, sort_idx] = sort(inicio_freezing_bonsai);
            inicio_freezing_bonsai = inicio_freezing_bonsai(sort_idx);
            fin_freezing_bonsai = fin_freezing_bonsai(sort_idx);
            duracion_freezing_bonsai = duracion_freezing_bonsai(sort_idx);

            clear keep_freezing_new new_inicio_freezing new_fin_freezing new_duracion_freezing sort_idx
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % Save all variables except the specified ones
            save([name, '_epileptic.mat'],'inicio_freezing_bonsai','fin_freezing_bonsai','duracion_freezing_bonsai', '-append');
            disp(['     Saving epileptic.mat file...']);

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        end
        
        % Go back to the 'Rxx' folder
        cd(current_R_folder);        
    end
end
disp('Done!');
cd(parentFolder);