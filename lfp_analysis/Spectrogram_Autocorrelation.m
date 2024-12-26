%% Script que recorre todas las sesiones de todos los animales, carga el espectrograma de BLA
% y calcula la matrix de autocorrelación del espectrograma en el dominio de
% las frecuencias. Luego calcula una media de todas esas matrices de
% correlacion.

clc;
clear all;

% Define the parent folder containing the 'Rxx' folders
parentFolder = 'D:\Doctorado\Backup Ordenado';

% List all 'Rxx' folders in the parent folder
R_folders = dir(fullfile(parentFolder, 'R*'));

autocorr_matrix_p = [];
autocorr_matrix_r = [];

% Iteratee through each 'Rxx' folder
for r = 10:16; %r = 1:length(R_folders)
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
        
        % Check if the LFP file exists
        
        if exist(strcat(name,'_specgram_BLALowFreq.mat'), 'file') == 2;
            load(strcat(name,'_specgram_BLALowFreq.mat'));
            if size(S,2) == 1967;
                S = zscore(S,0,1);
                [r,p] = corrcoef(S);
                autocorr_matrix_p = cat(3,autocorr_matrix_p,p);
                autocorr_matrix_r = cat(3,autocorr_matrix_r,r);
            end
        end
 
        % Go back to the 'Rxx' folder
        cd(current_R_folder);
    end
end
disp('Done!');
cd(parentFolder);

%% Ploteamos la media de todos las matrices de autocorrelacion calculadas con todas las sesiones
autocorr_matrix_r_mean = median(autocorr_matrix_r,3);
autocorr_matrix_p_mean = mean(autocorr_matrix_p,3);

autocorr_matrix_p_mean = autocorr_matrix_p_mean < 0.01;

% Quitamos interpolamos la franja de 100 Hz que es ruidosa
fmin = find(abs(f-98.5) == min(abs(f-98.5)));
fmax = find(abs(f-101.5) == min(abs(f-101.5)));
for i = 1:fmax-fmin;
    autocorr_matrix_r_mean(:,fmin+i) = autocorr_matrix_r_mean(:,fmin) + i*((autocorr_matrix_r_mean(:,fmax+1)-autocorr_matrix_r_mean(:,fmin-1))/(fmax-fmin));
    autocorr_matrix_r_mean(fmin+i,:) = autocorr_matrix_r_mean(fmin,:) + i*((autocorr_matrix_r_mean(fmax+1,:)-autocorr_matrix_r_mean(fmin-1,:))/(fmax-fmin));
    autocorr_matrix_p_mean(:,fmin+i) = autocorr_matrix_p_mean(:,fmin) + i*((autocorr_matrix_p_mean(:,fmax+1)-autocorr_matrix_p_mean(:,fmin-1))/(fmax-fmin));
    autocorr_matrix_p_mean(fmin+i,:) = autocorr_matrix_p_mean(fmin,:) + i*((autocorr_matrix_p_mean(fmax+1,:)-autocorr_matrix_p_mean(fmin-1,:))/(fmax-fmin));
end

% Ploteamos las figuras
figure()
ax1 = subplot(121);
plot_matrix(autocorr_matrix_r_mean,f,f,'n');
colorbar('off');
colormap(ax1,'jet')
xlabel('Frequency (Hz)');
ylabel('Frequency (Hz)');
title('Pearson Autocorrelation Matrix (r)');
clim([0.1 0.6]);

ax2 = subplot(122)
plot_matrix(autocorr_matrix_p_mean,f,f,'n');
colorbar('off');
colormap(ax2,flipud(bone(256)));
xlabel('Frequency (Hz)');
ylabel('Frequency (Hz)');
title('Significant Pearson Autocorrelation (p)');
clim([0 1]);

%%
% Ploteamos las figuras
figure()
plot_matrix(autocorr_matrix_r_mean,f,f,'n');
colorbar('off');
colormap('jet')
xlabel('Frequency (Hz)');
ylabel('Frequency (Hz)');
title('Pearson Autocorrelation Matrix (r)');
clim([0.1 0.6]);
hold on
line([0.5 0.5],[0 150],'Color',[1 1 1],'LineWidth',1,'LineStyle','--');
line([2 2],[0 150],'Color',[1 1 1],'LineWidth',1,'LineStyle','--');
line([5.3 5.3],[0 150],'Color',[1 1 1],'LineWidth',1,'LineStyle','--');
line([9.5 9.5],[0 150],'Color',[1 1 1],'LineWidth',1,'LineStyle','--');
line([13 13],[0 150],'Color',[1 1 1],'LineWidth',1,'LineStyle','--');
line([30 30],[0 150],'Color',[1 1 1],'LineWidth',1,'LineStyle','--');
line([43 43],[0 150],'Color',[1 1 1],'LineWidth',1,'LineStyle','--');
line([60 60],[0 150],'Color',[1 1 1],'LineWidth',1,'LineStyle','--');
line([100 100],[0 150],'Color',[1 1 1],'LineWidth',1,'LineStyle','--');

line([0 150],[0.5 0.5],'Color',[1 1 1],'LineWidth',1,'LineStyle','--');
line([0 150],[2 2],'Color',[1 1 1],'LineWidth',1,'LineStyle','--');
line([0 150],[5.3 5.3],'Color',[1 1 1],'LineWidth',1,'LineStyle','--');
line([0 150],[9.5 9.5],'Color',[1 1 1],'LineWidth',1,'LineStyle','--');
line([0 150],[13 13],'Color',[1 1 1],'LineWidth',1,'LineStyle','--');
line([0 150],[30 30],'Color',[1 1 1],'LineWidth',1,'LineStyle','--');
line([0 150],[43 43],'Color',[1 1 1],'LineWidth',1,'LineStyle','--');
line([0 150],[60 60],'Color',[1 1 1],'LineWidth',1,'LineStyle','--');
line([0 150],[100 100],'Color',[1 1 1],'LineWidth',1,'LineStyle','--');