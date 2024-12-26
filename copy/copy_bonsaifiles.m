%% Script detectar ruido y guardar esos timestamps
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
        disp(['  Processing subfolder: ' current_D_folder]);
        
        % Change the current folder to the 'RxDy' subfolder
        cd(current_D_folder);
        [~,D,X] = fileparts(current_D_folder); name = D([1:6]);
        
        % Check if the .dat file exists
        spec1 = strcat(name, '_bonsai_CS1.csv');
        bonsai_2 = strcat(name, '_bonsai_CS2.csv');
        bonsai_3 = strcat(name, '_bonsai_freezing.csv');
        bonsai_4 = strcat(name, '_bonsai_sincro.csv');
        bonsai_5 = strcat(name, '_bonsai_freezing.csv');
        bonsai_6 = strcat(name, '_bonsai_sincro.csv');
        
        % Buscamos el directorio y armamos el path en el disco H:
        currentDir = pwd;
        parts = strsplit(currentDir, '\');
        lastTwoParts = fullfile(parts{end-1}, parts{end});
        newPath = fullfile('H:\', lastTwoParts);
        
        % Copiamos R00D00_bonsai_CS1.csv
        if exist(spec1, 'file') == 2
            disp(['    File ' spec1 ' exists. Copying in H:/... ']);
            cd(newPath);
            copyfile(strcat(currentDir,'\',spec1), newPath);
            cd(currentDir);
        else
            disp(['    File ' spec1 ' do not exist. Skipping action...']);
        end

        % Copiamos R00D00_bonsai_CS2.csv
        if exist(bonsai_2, 'file') == 2
            disp(['    File ' bonsai_2 ' exists. Copying in H:/... ']);
            cd(newPath);
            copyfile(strcat(currentDir,'\',bonsai_2), newPath);
            cd(currentDir);
        else
            disp(['    File ' bonsai_2 ' do not exist. Skipping action...']);
        end
        
        % Copiamos R00D00_bonsai_freezing.csv
        if exist(bonsai_3, 'file') == 2
            disp(['    File ' bonsai_3 ' exists. Copying in H:/... ']);
            cd(newPath);
            copyfile(strcat(currentDir,'\',bonsai_3), newPath);
            cd(currentDir);
        else
            disp(['    File ' bonsai_3 ' do not exist. Skipping action...']);
        end
        
        % Copiamos R00D00_bonsai_sincro.csv
        if exist(bonsai_4, 'file') == 2
            disp(['    File ' bonsai_4 ' exists. Copying in H:/... ']);
            cd(newPath);
            copyfile(strcat(currentDir,'\',bonsai_4), newPath);
            cd(currentDir);
        else
            disp(['    File ' bonsai_4 ' do not exist. Skipping action...']);
        end
        
        % Go back to the 'Rxx' folder
        cd(current_R_folder);
    end
end