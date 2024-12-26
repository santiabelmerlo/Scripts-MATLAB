%% Script para plotear los rasters del freezing de una sesión en particular del aversivo
clc;
clear all;

% En estas lineas selecciono que animales, paradigma y sesiones quiero analizar
rats = [11,12,13,17,18,19,20]; % Filtro por animales
paradigm_toinclude = 'aversive'; % Filtro por el paradigma
session_toinclude = {'TEST'}; % Filtro por las sesiones
trials_toinclude = 1:2; % Filtro por los trials
meantitle = 'Reinstatement: Trial 1-4'; % Titulo general que le voy a poner a la figura

% Creamos el colormap
color1 = [244, 67, 54]/255;
color2 = [255, 152, 0]/255;
color3 = [255, 235, 59]/255;
color4 = [139, 195, 74]/255;
color5 = [0, 150, 136]/255;
color6 = [3, 169, 244]/255;
color7 = [63, 81, 181]/255;
color8 = [156, 39, 176]/255; 

custom_colormap = [
    1, 1, 1;    % White for 0
    color1;     % Color for 1
    color2;     % Color for 2
    color3;     % Color for 3
    color4;     % Color for 4
    color5;     % Color for 5
    color6;     % Color for 6
    color7;     % Color for 7
    color8      % Color for 8
];

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
    CS2_nosepokes_Rall CS2_number_head_Rall CS2_number_reward_Rall tt trials_toinclude meantitle custom_colormap

figure()

for i = 1:(size(CS1_freezing_Rall,2)/size(trials_toinclude,2));
    CS1_freezing_Rall(:,(size(trials_toinclude,2)*i)-(size(trials_toinclude,2)-1):size(trials_toinclude,2)*i) = CS1_freezing_Rall(:,(size(trials_toinclude,2)*i)-(size(trials_toinclude,2)-1):size(trials_toinclude,2)*i)*i;
    CS2_freezing_Rall(:,(size(trials_toinclude,2)*i)-(size(trials_toinclude,2)-1):size(trials_toinclude,2)*i) = CS2_freezing_Rall(:,(size(trials_toinclude,2)*i)-(size(trials_toinclude,2)-1):size(trials_toinclude,2)*i)*i;
end

subplot(211)
% plot_matrix(CS1_freezing_Rall,tt,1:size(CS1_freezing_Rall,2),'n'); hold on;
pcolor(tt,1:size(CS1_freezing_Rall,2),CS1_freezing_Rall'); hold on;
shading flat;
line([0 0],[0 1000],'Color',[0 0 0],'LineWidth',0.5,'LineStyle','--');
line([60 60],[0 1000],'Color',[0 0 0],'LineWidth',0.5,'LineStyle','--');
colormap(custom_colormap);
% cmp = colormap;
% cmp(1,:) = [1 1 1];
% colormap(cmp);
caxis([0 8]);
title('CS+');
ylabel('Animals'); % Hide z-axis label
xlabel('Time (sec.)'); % Hide z-axis label
set(gca, 'YTick', []); % Hide z-axis ticks
delete(colorbar); % Hide colorbar
ax = gca; % Get current axes
ax.Box = 'on'; % Turn on the box
ax.XColor = 'k'; % Set the X-axis color to black
ax.YColor = 'k'; % Set the Y-axis color to black
ax.LineWidth = 1; % Set the width of the frame line (optional)
hold off;

subplot(212)
% plot_matrix(CS2_freezing_Rall,tt,1:size(CS2_freezing_Rall,2),'n'); hold on;
pcolor(tt,1:size(CS2_freezing_Rall,2),CS2_freezing_Rall'); hold on;
shading flat;
line([0 0],[0 1000],'Color',[0 0 0],'LineWidth',0.5,'LineStyle','--');
line([60 60],[0 1000],'Color',[0 0 0],'LineWidth',0.5,'LineStyle','--');
colormap(custom_colormap);
% cmp = colormap;
% cmp(1,:) = [1 1 1];
% colormap(cmp);
caxis([0 8]);
title('CS-');
ylabel('Animals'); % Hide z-axis label
xlabel('Time (sec.)'); % Hide z-axis label
set(gca, 'YTick', []); % Hide z-axis ticks
delete(colorbar); % Hide colorbar
ax = gca; % Get current axes
ax.Box = 'on'; % Turn on the box
ax.XColor = 'k'; % Set the X-axis color to black
ax.YColor = 'k'; % Set the Y-axis color to black
ax.LineWidth = 1; % Set the width of the frame line (optional)
hold off;

% Ponemos un main title
annotation('textbox', [0 0.9 1 0.12], 'String', meantitle, ...
           'EdgeColor', 'none', 'HorizontalAlignment', 'center', 'FontSize', 12);

set(gcf, 'Position', [100, 100, 300, 400]);
set(gcf, 'Color', 'white');

disp('Done!');