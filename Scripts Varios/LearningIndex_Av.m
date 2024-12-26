%% Learning index

% Dicrimination Score = CS1 - CS2
% Delta Response = CS1 - PreCS1 & CS2 - PreCS2
% Response Score = (CS1 + CS2) - (preCS1 + preCS2) ./ (CS1 + CS2) + (preCS1 + preCS2) + 1
% Learning Index 1 = pCS1 - ppreCS1
% Learning Index 2 = pCS1 - pCS2

% Calculamos el learning index para cada animal 
clear all
clc

% Selecciono que ratas quiero analizar
rats = [11,12,13,17,18,19,20]; % Filtro por animales
paradigm_toinclude = 'aversive'; % Filtro por el paradigma
parentFolder = 'D:\Doctorado\Backup Ordenado';
R_folders = dir(fullfile(parentFolder, 'R*'));
session_toinclude = {'TR1'}; % Filtro por las sesiones

% Creamos algunas variables con nans para guardar luego los datos

extinction1_DS = nan(7,20);
extinction1_DR1 = nan(7,20);
extinction1_DR2 = nan(7,20);
extinction1_RS = nan(7,20);

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
        
        if exist(strcat(name,'_sessioninfo.mat')) == 2 & exist(strcat(name,'_freezing.mat')) == 2;
            load(strcat(name,'_sessioninfo.mat'),'paradigm','session');
            if strcmp(paradigm,paradigm_toinclude) && any(strcmp(session, session_toinclude));
                disp(['      Session found, including in dataset...']);
                
                load(strcat(name,'_freezing.mat'),'freezing_CS1_porc','freezing_CS2_porc','freezing_preCS_porc','CS_freezing_porc','preCS_porc');
                
                if exist('freezing_CS1_porc') == 1;
                    extinction1_DS(j,1:size(freezing_CS1_porc',2)) = freezing_CS1_porc' - freezing_CS2_porc';
                    extinction1_DR1(j,1:size(freezing_CS1_porc',2)) = freezing_CS1_porc' - freezing_preCS_porc';
                    extinction1_DR2(j,1:size(freezing_CS1_porc',2)) = freezing_CS2_porc' - freezing_preCS_porc';
                    extinction1_RS(j,1:size(freezing_CS1_porc',2)) = (freezing_CS1_porc' + freezing_CS2_porc') - freezing_preCS_porc' ./ (freezing_CS1_porc' + freezing_CS2_porc' + freezing_preCS_porc' +1 );
                elseif exist('CS_freezing_porc') == 1;
                    extinction1_DS(j,1:size(CS_freezing_porc',2)) = (CS_freezing_porc(:,1))' - (CS_freezing_porc(:,2))';
                    extinction1_DR1(j,1:size(CS_freezing_porc',2)) = (CS_freezing_porc(:,1))' - preCS_porc;
                    extinction1_DR2(j,1:size(CS_freezing_porc',2)) = (CS_freezing_porc(:,2))' - preCS_porc;
                    extinction1_RS(j,1:size(CS_freezing_porc',2)) = (((CS_freezing_porc(:,1))' + (CS_freezing_porc(:,2))') - preCS_porc) ./ (((CS_freezing_porc(:,1))' + (CS_freezing_porc(:,2))') + preCS_porc+1);
                end
                
                j = j + 1;
            end
        end      
    end      
    % Go back to the 'Rxx' folder
    cd(current_R_folder);
end
cd(parentFolder);

% Ploteamos heatmaps de DS y GS

% Define the points and corresponding colors
x = [-100, 0, 100];
colors = [0.5, 0.5, 0.5;  % Gray for -3000
          0, 0, 0;        % Black for 0
          0.5, 0, 1];       % Green for 3000
numColors = 256; % Number of points in the colormap
% Interpolate to create a smooth colormap
xq = linspace(-100, 100, numColors);
customColormap = interp1(x, colors, xq, 'linear');

subplot(4,4,4)
S = extinction1_DS(:,1:10)'; plot_matrix(S,1:size(S,1),1:size(S,2),'n'); 
colormap(customColormap); clim([-50 50]); colorbar('off');
ylabel('Animal'); xlabel('Trial'); title('Reinst. Discrimination Score');

subplot(4,4,8)
S = extinction1_DR1(:,1:10)'; plot_matrix(S,1:size(S,1),1:size(S,2),'n'); 
colormap(customColormap); clim([-50 50]); colorbar('off');
ylabel('Animal'); xlabel('Trial'); title('Reinst. ? Response to CS+');

subplot(4,4,12)
S = extinction1_DR2(:,1:10)'; plot_matrix(S,1:size(S,1),1:size(S,2),'n'); 
colormap(customColormap); clim([-50 50]); colorbar('off');
ylabel('Animal'); xlabel('Trial'); title('Reinst. ? Response to CS-');

subplot(4,4,16)
S = extinction1_RS(:,1:10)'; plot_matrix(S,1:size(S,1),1:size(S,2),'n'); 
colormap(customColormap); clim([-100 100]); colorbar('off');
ylabel('Animal'); xlabel('Trial'); title('Reinst. Response Score');

set(gcf, 'Color', 'white');
hold on;
