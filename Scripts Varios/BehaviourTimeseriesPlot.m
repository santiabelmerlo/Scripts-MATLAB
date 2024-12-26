%% Script para backupear los archivos R00D00_freezing.mat
clc;
clear all;

% En estas lineas selecciono que animales, paradigma y sesiones quiero analizar
rats = [10,11,13,14,16,17,18,19]; % Filtro por animales
paradigm_toinclude = 'appetitive'; % Filtro por el paradigma
session_toinclude = {'EXT2'}; % Filtro por las sesiones
trials_toinclude = 41:60; % Filtro por los trials
meantitle = 'Late Extinction 2'; % Titulo general que le voy a poner a la figura

% Define the parent folder containing the 'Rxx' folders
parentFolder = 'D:\Doctorado\Backup Ordenado';

% List all 'Rxx' folders in the parent folder
R_folders = dir(fullfile(parentFolder, 'R*'));

% Inicializo algunas variables
CS1_freezing_Rall = [];
CS1_head_entries_Rall = [];
CS1_movement_Rall = [];
CS1_nosepokes_Rall = [];
CS1_number_head_Rall = [];
CS1_number_reward_Rall = [];
CS2_freezing_Rall = [];
CS2_head_entries_Rall = [];
CS2_movement_Rall = [];
CS2_nosepokes_Rall = [];
CS2_number_head_Rall = [];
CS2_number_reward_Rall = [];

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
            session_end = [];
            load(strcat(name,'_sessioninfo.mat'));
            if strcmp(paradigm,paradigm_toinclude) && (any(strcmp(session, session_toinclude))||any(strcmp(session_end, session_toinclude)));
                disp(['      Session found, including in dataset...']);
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                if exist(strcat(name,'_behavior_timeseries.mat')) == 2;        
                    load(strcat(name,'_behavior_timeseries.mat'));

                    CS1_freezing_Rall(:,:,j) = CS1_freezing;
                    CS1_head_entries_Rall(:,:,j) = CS1_head_entries;
                    CS1_movement_Rall(:,:,j) = CS1_movement;
                    CS1_nosepokes_Rall(:,:,j) = CS1_nosepokes;
                    CS1_number_head_Rall(:,:,j) = CS1_number_head;
                    CS1_number_reward_Rall(:,:,j) = CS1_number_reward;
                    CS2_freezing_Rall(:,:,j) = CS2_freezing;
                    CS2_head_entries_Rall(:,:,j) = CS2_head_entries;
                    CS2_movement_Rall(:,:,j) = CS2_movement;
                    CS2_nosepokes_Rall(:,:,j) = CS2_nosepokes;
                    CS2_number_head_Rall(:,:,j) = CS2_number_head;
                    CS2_number_reward_Rall(:,:,j) = CS2_number_reward;
                    
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

% Calculo la media de todos los animales y sesiones
CS1_freezing_Rall = nanmean(CS1_freezing_Rall,3);
CS1_head_entries_Rall = nanmean(CS1_head_entries_Rall,3);
CS1_movement_Rall = nanmean(CS1_movement_Rall,3);
CS1_nosepokes_Rall = nanmean(CS1_nosepokes_Rall,3);
CS1_number_head_Rall = nanmean(CS1_number_head_Rall,3);
CS1_number_reward_Rall = nanmean(CS1_number_reward_Rall,3);
CS2_freezing_Rall = nanmean(CS2_freezing_Rall,3);
CS2_head_entries_Rall = nanmean(CS2_head_entries_Rall,3);
CS2_movement_Rall = nanmean(CS2_movement_Rall,3);
CS2_nosepokes_Rall = nanmean(CS2_nosepokes_Rall,3);
CS2_number_head_Rall = nanmean(CS2_number_head_Rall,3);
CS2_number_reward_Rall = nanmean(CS2_number_reward_Rall,3);

% Filtro los trials que me interesan
CS1_freezing_Rall = CS1_freezing_Rall(:,trials_toinclude);
CS1_head_entries_Rall = CS1_head_entries_Rall(:,trials_toinclude);
CS1_movement_Rall = CS1_movement_Rall(:,trials_toinclude);
CS1_nosepokes_Rall = CS1_nosepokes_Rall(:,trials_toinclude);
CS1_number_head_Rall = CS1_number_head_Rall(:,trials_toinclude);
CS1_number_reward_Rall = CS1_number_reward_Rall(:,trials_toinclude);
CS2_freezing_Rall = CS2_freezing_Rall(:,trials_toinclude);
CS2_head_entries_Rall = CS2_head_entries_Rall(:,trials_toinclude);
CS2_movement_Rall = CS2_movement_Rall(:,trials_toinclude);
CS2_nosepokes_Rall = CS2_nosepokes_Rall(:,trials_toinclude);
CS2_number_head_Rall = CS2_number_head_Rall(:,trials_toinclude);
CS2_number_reward_Rall = CS2_number_reward_Rall(:,trials_toinclude);

% Finalmente ploteamos los tres comportamientos en la misma figura
ax1 = subplot(2,3,1);
    plot_behavior_prob(CS1_head_entries_Rall,CS2_head_entries_Rall,tt);
    xlim([-5 30]);
    ylabel('Inside port (probability)');
    xlabel('Time (sec.)');
ax4 = subplot(2,3,4);
    plot_behavior_prob(CS1_nosepokes_Rall,CS2_nosepokes_Rall,tt);
    xlim([-5 30]);
    ylabel('Reward-seeking (probability)');
    xlabel('Time (sec.)');
ax3 = subplot(2,3,3);
    plot_behavior_mov(CS1_movement_Rall,CS2_movement_Rall,tt);
    xlim([-5 30]);
    ylabel('Acceleration (cm/s^2)');
    xlabel('Time (sec.)');  
ax2 = subplot(2,3,2);
    plot_behavior_num(CS1_number_head_Rall,CS2_number_head_Rall,tt);
    ylim([0 40]);
    xlim([-5 30]);
    ylabel('Port pokes (# pokes per min.)');
    xlabel('Time (sec.)');
ax5 = subplot(2,3,5);
    plot_behavior_num(CS1_number_reward_Rall,CS2_number_reward_Rall,tt);
    ylim([0 40]);
    xlim([-5 30]);
    ylabel('Reward poke (# pokes per min.)');
    xlabel('Time (sec.)'); 
ax6 = subplot(2,3,6);
    plot_behavior_prob(CS1_freezing_Rall,CS2_freezing_Rall,tt);
    ylim([0 0.5]);
    xlim([-5 30]);
    ylabel('Immobility (probability)');
    xlabel('Time (sec.)');   
    
set(gcf, 'Color', 'white');

linkaxes([ax1 ax2 ax3 ax4 ax5 ax6],'x');

annotation('textbox', [0 0.95 1 0.05], ...
           'String', meantitle, ...
           'EdgeColor', 'none', ...
           'HorizontalAlignment', 'center', ...
           'FontSize', 14, ...
           'FontWeight', 'bold');

set(gcf, 'Position', [100, 100, 1200, 600]);

disp('Done!');