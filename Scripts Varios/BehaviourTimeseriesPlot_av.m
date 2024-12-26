%% Script para backupear los archivos R00D00_freezing.mat
clc;
clear all;

% En estas lineas selecciono que animales, paradigma y sesiones quiero analizar
rats = [11,12,13,17,18,19,20]; % Filtro por animales
paradigm_toinclude = 'aversive'; % Filtro por el paradigma
session_toinclude = {'TEST'}; % Filtro por las sesiones
trials_toinclude = 1:2; % Filtro por los trials
meantitle = 'Reinstatement: CS 1-2'; % Titulo general que le voy a poner a la figura

% Define the parent folder containing the 'Rxx' folders
parentFolder = 'D:\Doctorado\Backup Ordenado';

% List all 'Rxx' folders in the parent folder
R_folders = dir(fullfile(parentFolder, 'R*'));

% Inicializo algunas variables
CS1_freezing_Rall = [];
CS1_movement_Rall = [];
CS2_freezing_Rall = [];
CS2_movement_Rall = [];

% Iterate through each 'Rxx' folder
j = 1;
for r = rats;
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
        
        if exist(strcat(name,'_sessioninfo.mat')) == 2;
            load(strcat(name,'_sessioninfo.mat'),'paradigm','session');
            if strcmp(paradigm,paradigm_toinclude) && any(strcmp(session, session_toinclude));
                disp(['      Session found, including in dataset...']);
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                if exist(strcat(name,'_behavior_timeseries.mat')) == 2;        
                    load(strcat(name,'_behavior_timeseries.mat'));

                    CS1_freezing_Rall = horzcat(CS1_freezing_Rall,CS1_freezing(:,trials_toinclude));
                    CS1_movement_Rall = horzcat(CS1_movement_Rall,CS1_movement(:,trials_toinclude));
                    CS2_freezing_Rall = horzcat(CS2_freezing_Rall,CS2_freezing(:,trials_toinclude));
                    CS2_movement_Rall = horzcat(CS2_movement_Rall,CS2_movement(:,trials_toinclude));
                    
                    j = j + 1; 
                end
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            end
        end      
    end      
    % Go back to the 'Rxx' folder
    cd(current_R_folder);
end
cd(parentFolder);

clearvars -except CS1_freezing_Rall CS1_head_entries_Rall CS1_movement_Rall CS1_nosepokes_Rall...
    CS1_number_head_Rall CS1_number_reward_Rall CS2_freezing_Rall CS2_head_entries_Rall CS2_movement_Rall...
    CS2_nosepokes_Rall CS2_number_head_Rall CS2_number_reward_Rall tt trials_toinclude meantitle

% Finalmente ploteamos los tres comportamientos en la misma figura
ax1 = subplot(321);
    plot_behavior_mov_av(CS1_movement_Rall,CS2_movement_Rall,tt);
    xlim([-30 90]);
    ylabel('Acceleration (cm/s^2)');
    xlabel('Time (sec.)');   
ax2 = subplot(322);
    plot_behavior_prob_av(CS1_freezing_Rall,CS2_freezing_Rall,tt);
    ylim([0 1]);
    xlim([-30 90]);
    ylabel('Freezing (probability)');
    xlabel('Time (sec.)');   
    
set(gcf, 'Color', 'white');

linkaxes([ax1 ax2],'x');

annotation('textbox', [0 0.95 1 0.05], ...
           'String', meantitle, ...
           'EdgeColor', 'none', ...
           'HorizontalAlignment', 'center', ...
           'FontSize', 14, ...
           'FontWeight', 'bold');

set(gcf, 'Position', [100, 100, 1000, 700]);

disp('Done!');