%% Script detectar ruido y guardar esos timestamps
clc;
clear all;

% Define the parent folder containing the 'Rxx' folders
parentFolder = 'D:\Doctorado\Backup Ordenado';

% List all 'Rxx' folders in the parent folder
R_folders = dir(fullfile(parentFolder, 'R*'));

% Iterate through each 'Rxx' folder
for r = 10;
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
        
        % Check if the .dat file exists
        freezing_file = strcat(name, '_video_timestamps_synchronized.csv');
        
        % Buscamos el directorio y armamos el path en el disco H:
        currentDir = pwd;
        parts = strsplit(currentDir, '\');
        lastTwoParts = fullfile(parts{end-1}, parts{end});
        newPath = fullfile('H:\', lastTwoParts);
        
        % Copiamos R00D00_video_timestamps_synchronized.csv
        if exist(freezing_file, 'file') == 2
            disp(['    File ' freezing_file ' exists. Copying in H:/... ']);
            cd(newPath);
            copyfile(strcat(currentDir,'\',freezing_file), newPath);
            cd(currentDir);
        else
            disp(['    File ' freezing_file ' do not exist. Skipping action...']);
        end      
 
        % Go back to the 'Rxx' folder
        cd(current_R_folder);
    end
end
disp('Done!');
cd(parentFolder);