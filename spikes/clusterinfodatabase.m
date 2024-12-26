%% Creamos un cluster_info_dataset.txt compilando todos los cluster_info.txt de todos los animales y todas las sesiones
clc; % Borro el command window
clear all; % Borro el workspace

% Define the parent folder containing the 'Rxx' folders
parentFolder = 'D:\Doctorado\Backup Ordenado';

% List all 'Rxx' folders in the parent folder
R_folders = dir(fullfile(parentFolder, 'R*'));
rats = 10:20;  % Elijo que ratas quiero que se analizen.

% Creo una tabla vacía con el nombre cluster_info_database
cluster_info_database = table; 

for r = rats
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
        
        fstruct = dir('*Kilosort*'); % Busco el path de la carpeta que se llama Kilosort
        if size(fstruct,1) == 1; % Si el path de la carpeta Kilosort existe
            cd(fstruct.name); % Entro a la carpeta Kilosort                   
            if exist('cluster_info.tsv','file');
                clusterinfotxt = clusterinfotxt('cluster_info.tsv');
                clear clusterinfotxt;
            else
                % Do nothing    
            end
            if exist('cluster_info.csv','file'); % Si existe el file cluster_info.txt
                table = readtable('cluster_info.csv'); % Leo ese archivo y lo guardo como table
                table.group = num2cell(table.group);
            else
                % Do nothing    
            end
        end   
        if exist('table') == 1; % Si existe table
            cluster_info_database = vertcat(cluster_info_database, table); % Le concateno al final de cluster_info_database la informacion que contiene table
        end
        clear table; % Borro table porque no la voy a usar más
        cd(current_R_folder); % Volvemos a la carpeta del animal
    end
    cd(parentFolder); % Vuelvo al path original donde estan todos los animales
end
clearvars -except cluster_info_database; % Borro las variables que ya no necesito

disp(['Saving cluster info database...']);
writetable(cluster_info_database,'cluster_info_database.csv'); % Guardamos clusterinfo como tabla en .txt

disp('Ready!');