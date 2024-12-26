%% Script detectar ruido y guardar esos timestamps
clc;
clear all;

% Define the parent folder containing the 'Rxx' folders
parentFolder = 'H:\';

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
        disp(['  Processing subfolder: ' current_D_folder]);
        
        % Change the current folder to the 'RxDy' subfolder
        cd(current_D_folder);
        [~,D,X] = fileparts(current_D_folder); name = D([1:6]);
        
        % Check if the .dat file exists
        spec1 = strcat(name, '_video_DLC.csv');
        spec2 = strcat(name, '_video_DLC.h5');
        spec3 = strcat(name, '_video_DLC_meta.pickle');

        % Buscamos el directorio y armamos el path en el disco H:
        currentDir = pwd;
        parts = strsplit(currentDir, '\');
        lastTwoParts = fullfile(parts{end-1}, parts{end});
        newPath = fullfile('D:\Doctorado\Backup Ordenado\', lastTwoParts);
        
        % Copiamos R00D00_specgram_BLAHighFreq.mat
        if exist(spec1, 'file') == 2
            disp(['    File ' spec1 ' exists. Copying in D:/... ']);
            cd(newPath);
            copyfile(strcat(currentDir,'\',spec1), newPath);
            cd(currentDir);
        else
            disp(['    File ' spec1 ' do not exist. Skipping action...']);
        end

        % Copiamos R00D00_specgram_BLALowFreq.mat
        if exist(spec2, 'file') == 2
            disp(['    File ' spec2 ' exists. Copying in D:/... ']);
            cd(newPath);
            copyfile(strcat(currentDir,'\',spec2), newPath);
            cd(currentDir);
        else
            disp(['    File ' spec2 ' do not exist. Skipping action...']);
        end
        
        % Copiamos R00D00_specgram_PLHighFreq.mat
        if exist(spec3, 'file') == 2
            disp(['    File ' spec3 ' exists. Copying in D:/... ']);
            cd(newPath);
            copyfile(strcat(currentDir,'\',spec3), newPath);
            cd(currentDir);
        else
            disp(['    File ' spec3 ' do not exist. Skipping action...']);
        end       
 
        % Go back to the 'Rxx' folder
        cd(current_R_folder);
    end
end
disp('Done!');
cd(parentFolder);