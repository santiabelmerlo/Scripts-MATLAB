%% SpecgramFolderLoop
% Change parentFolder in order to match the path where I have folders
% R01,R02,R03,etc.
% This script enters in each folder, then in each R00D00 subfolder,
% calculates the spectrogram and saves a "R00D00_specgram.mat" file in each
% subfolder

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
        file_path = strcat(name, '_lfp.dat');
        
        if exist(file_path, 'file') == 2
            % The file exists, do something
            disp(['    File ' file_path ' exists. Performing spectrogram...']);
            
            % Load data and do analysis on data
            %%%%%%%%
            
            % Save the results to a .mat file
            % Guardamos solo las variables f,S,Serr,t
            filename = strcat(name,'_specgram.mat');
%             save(filename, 'f', 'S', 'Serr', 't');
            disp(['      Saving ' filename ' file into the Current Folder']);
            
        else
            % The file does not exist, do nothing
            disp(['    File ' file_path ' does not exist. Skipping action...']);
        end
        
        % Go back to the 'Rxx' folder
        cd(current_R_folder);
    end
end
disp('Done!');
cd(parentFolder);