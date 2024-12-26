%% Reaponsive Loop
% Me marca en qué trials el animal respondió y en qué trials no
% Si durante el tono el animal freeza más del 20% es responsive

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
        
        % Check if the .dat file exists
        file_path = strcat(name, '_lfp.dat');
        
        % Check if the sessioninfo.mat file exists
        sessioninfo_path = strcat(name, '_sessioninfo.mat');
        
        if exist(file_path, 'file') && exist(sessioninfo_path, 'file') == 2 && ...
                exist(strcat(name,'_freezing.mat'), 'file')
            % The file exists, do something
            disp(['  File ' file_path ' exists. Performing action...']);
            load(strcat(name,'_sessioninfo.mat'));
            load(strcat(name,'_freezing.mat'));
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            resp_CS1 = find(freezing_CS1_porc' >= 20);
            resp_CS2 = find(freezing_CS2_porc' >= 20);
            nonresp_CS1 = find(freezing_CS1_porc' < 20);
            nonresp_CS2 = find(freezing_CS2_porc' < 20);
            
            save([name, '_freezing.mat'], 'resp_CS1', 'resp_CS2', 'nonresp_CS1', 'nonresp_CS2', '-append');
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
        else
            if exist(file_path, 'file') == 0;
                % The file does not exist, do nothing
                disp(['  File ' file_path ' does not exist.']);
            end
            if exist(sessioninfo_path, 'file') == 0;
                % The file does not exist, do nothing
                disp(['  File ' sessioninfo_path ' does not exist.']);
            end
            disp(['  Skipping action...']);
        end
        
        % Go back to the 'Rxx' folder
        cd(current_R_folder);
    end
end
disp('Done!');
cd(parentFolder);