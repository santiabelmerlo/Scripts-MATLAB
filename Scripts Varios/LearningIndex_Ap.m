%% Learning index

% Dicrimination Score = CS1 - CS2
% Delta Response = CS1 - PreCS1 & CS2 - PreCS2
% Response Score = (CS1 + CS2) - (preCS1 + preCS2) ./ (CS1 + CS2) + (preCS1 + preCS2)
% Learning Index 1 = pCS1 - ppreCS1
% Learning Index 2 = pCS1 - pCS2

% Calculamos el learning index para cada animal 
clear all
clc

% Selecciono que ratas quiero analizar
rats = [10,11,13,14,16,17,18,19]; % Filtro por animales
paradigm_toinclude = 'appetitive'; % Filtro por el paradigma
parentFolder = 'D:\Doctorado\Backup Ordenado';
R_folders = dir(fullfile(parentFolder, 'R*'));

% Creamos algunas variables con nans para guardar luego los datos
training_DS = nan(8,8);
training_DR1 = nan(8,8);
training_DR2 = nan(8,8);
training_RS = nan(8,8);

training_LI1 = nan(8,10);
training_LI2 = nan(8,10);

extinction1_DS = nan(8,12);
extinction1_DR1 = nan(8,12);
extinction1_DR2 = nan(8,12);
extinction1_RS = nan(8,12);

extinction2_DS = nan(8,12);
extinction2_DR1 = nan(8,12);
extinction2_DR2 = nan(8,12);
extinction2_RS = nan(8,12);

r = 1;
for i = rats;
    
    current_R_folder = fullfile(parentFolder, R_folders(i).name);
    disp(['Processing folder: ' current_R_folder]);
    cd(current_R_folder); 
    
    % Me paro en la carpeta de la rata R00
    path = pwd;
    cd(path);
    [filpath,name,ext] = fileparts(cd);
    cd(strcat(name,'_Analisis'));
    load(strcat(name,'_folders.mat'));
    load(strcat(name,'_behaviour.mat'),'OUTPUT','behaviour','binned_behaviour','Rat1');

    % Sesión de training
    training_CS = binned_behaviour.duringCS.tpuerta(:,1:end-4);
    training_preCS = binned_behaviour.preCS.tpuerta(:,1:end-4);
    training_CS1 = training_CS(1,1:2:end);
    training_CS2 = training_CS(1,2:2:end);
    training_preCS1 = training_preCS(1,1:2:end);
    training_preCS2 = training_preCS(1,2:2:end);
    clear training_CS training_preCS

    training_size = size(training_CS1,2);
%     training_DS(r,1:training_size) = (training_CS1 - training_CS2)./abs(training_CS1 + training_CS2 + 1);
    training_DS(r,1:training_size) = (training_CS1 - training_CS2)*0.01;
    training_DR1(r,1:training_size) = (training_CS1 - training_preCS1)*0.01;
    training_DR2(r,1:training_size) = (training_CS2 - training_preCS2)*0.01;
    training_RS(r,1:training_size) = ((training_CS1 + training_CS2) - (training_preCS1 + training_preCS2)) ./ abs(training_CS1 + training_CS2 + training_preCS1 + training_preCS2 + 1);
    
    % Sesión de extinción 1
    extinction1_CS = binned_behaviour.duringCS.tpuerta(:,end-3:end-2);
    extinction1_preCS = binned_behaviour.preCS.tpuerta(:,end-3:end-2);
    extinction1_preCS1 = (extinction1_preCS(:,1))';
    extinction1_preCS2 = (extinction1_preCS(:,2))';
    extinction1_CS1 = (extinction1_CS(:,1))';
    extinction1_CS2 = (extinction1_CS(:,2))';
    clear extinction1_CS extinction1_preCS

    extinction1_size = size(extinction1_CS1,2);
%     extinction1_DS(r,1:extinction1_size) = (extinction1_CS1 - extinction1_CS2)./abs(extinction1_CS1 + extinction1_CS2 + 1);
    extinction1_DS(r,1:extinction1_size) = (extinction1_CS1 - extinction1_CS2)*0.01;
    extinction1_DR1(r,1:extinction1_size) = (extinction1_CS1 - extinction1_preCS1)*0.01;
    extinction1_DR2(r,1:extinction1_size) = (extinction1_CS2 - extinction1_preCS2)*0.01;
    extinction1_RS(r,1:extinction1_size) = ((extinction1_CS1 + extinction1_CS2) - (extinction1_preCS1 + extinction1_preCS2)) ./ abs(extinction1_CS1 + extinction1_CS2 + extinction1_preCS1 + extinction1_preCS2 + 1);
    
    % Sesión de extinción 2
    extinction2_CS = binned_behaviour.duringCS.tpuerta(:,end-1:end);
    extinction2_preCS = binned_behaviour.preCS.tpuerta(:,end-1:end);
    extinction2_preCS1 = (extinction2_preCS(:,1))';
    extinction2_preCS2 = (extinction2_preCS(:,2))';
    extinction2_CS1 = (extinction2_CS(:,1))';
    extinction2_CS2 = (extinction2_CS(:,2))';
    clear extinction2_CS extinction2_preCS

    extinction2_size = size(extinction2_CS1,2);
%     extinction2_DS(r,1:extinction2_size) = (extinction2_CS1 - extinction2_CS2)./abs(extinction2_CS1 + extinction2_CS2 + 1);
    extinction2_DS(r,1:extinction2_size) = (extinction2_CS1 - extinction2_CS2)*0.01;
    extinction2_DR1(r,1:extinction2_size) = (extinction2_CS1 - extinction2_preCS1)*0.01;
    extinction2_DR2(r,1:extinction2_size) = (extinction2_CS2 - extinction2_preCS2)*0.01;
    extinction2_RS(r,1:extinction2_size) = ((extinction2_CS1 + extinction2_CS2) - (extinction2_preCS1 + extinction2_preCS2)) ./ abs(extinction2_CS1 + extinction2_CS2 + extinction2_preCS1 + extinction2_preCS2 + 1);
    
    % Calculamos el learning index
    LI = Rat1.duringCS.ppuerta(1,:) - Rat1.preCS.ppuerta(1,:);
    % pCS1 - ppreCS1
    training_LI1(r,1:training_size) = LI(1,1:2:end-4);
    training_LI1(r,end-1:end) = LI(1,end-3:2:end);
    % pCS1 - pCS2
    training_LI2(r,1:training_size) = LI(1,1:2:end-4)-LI(1,2:2:end-4);
    training_LI2(r,end-1:end) = LI(1,end-3:2:end)-LI(1,end-2:2:end);
    
    cd(current_R_folder); % Volvemos a la carpeta general del animal
    r = r+1;
end
cd(parentFolder); % Volvemos a la carpeta general de todos los animales

% Borramos el día 8 de entrenamiento del LI
training_LI1(:,8) = [];
training_LI2(:,8) = [];

% Ploteamos lo que calculamos arriba

subplot(431)
plot(training_DS'); xlim([0.8 7]); ylim([-30 30]); 
title('Training', 'FontSize', 8); 
ylabel('Discrimination Score', 'FontSize', 6); 
xlabel('Day', 'FontSize', 6);
ax = gca; ax.FontSize = 6;

subplot(432)
plot(extinction1_DS'); xlim([0.8 12.2]); ylim([-30 30]);
title('Extinction 1', 'FontSize', 8); 
ylabel('Discrimination Score', 'FontSize', 6); 
xlabel('Trials: blocks of 5', 'FontSize', 6);
ax = gca; ax.FontSize = 6;

subplot(433)
plot(extinction2_DS'); xlim([0.8 12.2]); ylim([-30 30]);
title('Extinction 2', 'FontSize', 8); 
ylabel('Discrimination Score', 'FontSize', 6); 
xlabel('Trials: blocks of 5', 'FontSize', 6);
ax = gca; ax.FontSize = 6;

subplot(434)
plot(training_DR1'); xlim([0.8 7]); ylim([-30 30]); 
title('Training', 'FontSize', 8); 
ylabel('? Response to CS+', 'FontSize', 6); 
xlabel('Day', 'FontSize', 6);
ax = gca; ax.FontSize = 6;

subplot(435)
plot(extinction1_DR1'); xlim([0.8 12.2]); ylim([-30 30]);
title('Extinction 1', 'FontSize', 8); 
ylabel('? Response to CS+', 'FontSize', 6); 
xlabel('Trials: blocks of 5', 'FontSize', 6);
ax = gca; ax.FontSize = 6;

subplot(436)
plot(extinction2_DR1'); xlim([0.8 12.2]); ylim([-30 30]);
title('Extinction 2', 'FontSize', 8); 
ylabel('? Response to CS+', 'FontSize', 6); 
xlabel('Trials: blocks of 5', 'FontSize', 6);
ax = gca; ax.FontSize = 6;

subplot(437)
plot(training_DR2'); xlim([0.8 7]); ylim([-30 30]); 
title('Training', 'FontSize', 8); 
ylabel('? Response to CS-', 'FontSize', 6); 
xlabel('Day', 'FontSize', 6);
ax = gca; ax.FontSize = 6;

subplot(438)
plot(extinction1_DR2'); xlim([0.8 12.2]); ylim([-30 30]);
title('Extinction 1', 'FontSize', 8); 
ylabel('? Response to CS-', 'FontSize', 6); 
xlabel('Trials: blocks of 5', 'FontSize', 6);
ax = gca; ax.FontSize = 6;

subplot(439)
plot(extinction2_DR2'); xlim([0.8 12.2]); ylim([-30 30]);
title('Extinction 2', 'FontSize', 8); 
ylabel('? Response to CS-', 'FontSize', 6); 
xlabel('Trials: blocks of 5', 'FontSize', 6);
ax = gca; ax.FontSize = 6;

subplot(4,3,10)
plot(training_LI1'); xlim([0.8 9.2]); ylim([-10 60]); 
title('Training + EXT', 'FontSize', 8); 
ylabel('Learning Index 1', 'FontSize', 6); 
xlabel('Day', 'FontSize', 6);
ax = gca; ax.FontSize = 6;

subplot(4,3,11)
plot(training_LI2'); xlim([0.8 9.2]); ylim([-10 60]);
title('Training + EXT', 'FontSize', 8); 
ylabel('Learning Index 2', 'FontSize', 6); 
xlabel('Day', 'FontSize', 6);
ax = gca; ax.FontSize = 6;

set(gcf, 'Color', 'white');

%% Ploteamos heatmaps de DS y GS

% Define the points and corresponding colors
x = [-20, 0, 20];
colors = [0.5, 0.5, 0.5;  % Gray for -3000
          0, 0, 0;        % Black for 0
          0, 1, 0];       % Green for 3000
numColors = 256; % Number of points in the colormap
% Interpolate to create a smooth colormap
xq = linspace(-20, 20, numColors);
customColormap = interp1(x, colors, xq, 'linear');

subplot(431)
S = training_DS(:,1:7)'; plot_matrix(S,1:size(S,1),1:size(S,2),'n'); 
colormap(customColormap); clim([-20 20]); colorbar('off');
ylabel('Animal'); xlabel('Training Day'); title('TR Discrimination Score');

subplot(432)
S = extinction1_DS'; plot_matrix(S,5:5:5*size(S,1),1:size(S,2),'n'); 
colormap(customColormap); clim([-20 20]); colorbar('off');
ylabel('Animal'); xlabel('Trial: Blocks of 5'); title('EXT1 Discrimination Score');

subplot(433)
S = extinction2_DS'; plot_matrix(S,5:5:5*size(S,1),1:size(S,2),'n'); 
colormap(customColormap); clim([-20 20]); colorbar('off');
ylabel('Animal'); xlabel('Trial: Blocks of 5'); title('EXT2 Discrimination Score');

subplot(434)
S = training_DR1(:,1:7)'; plot_matrix(S,1:size(S,1),1:size(S,2),'n'); 
colormap(customColormap); clim([-20 20]); colorbar('off');
ylabel('Animal'); xlabel('Training Day'); title('TR ? Response to CS+');

subplot(435)
S = extinction1_DR1'; plot_matrix(S,5:5:5*size(S,1),1:size(S,2),'n'); 
colormap(customColormap); clim([-20 20]); colorbar('off');
ylabel('Animal'); xlabel('Trial: Blocks of 5'); title('EXT1 ? Response to CS+');

subplot(436)
S = extinction2_DR1'; plot_matrix(S,5:5:5*size(S,1),1:size(S,2),'n'); 
colormap(customColormap); clim([-20 20]); colorbar('off');
ylabel('Animal'); xlabel('Trial: Blocks of 5'); title('EXT2 ? Response to CS+');

subplot(437)
S = training_DR2(:,1:7)'; plot_matrix(S,1:size(S,1),1:size(S,2),'n'); 
colormap(customColormap); clim([-20 20]); colorbar('off');
ylabel('Animal'); xlabel('Training Day'); title('TR ? Response to CS-');

subplot(438)
S = extinction1_DR2'; plot_matrix(S,5:5:5*size(S,1),1:size(S,2),'n'); 
colormap(customColormap); clim([-20 20]); colorbar('off');
ylabel('Animal'); xlabel('Trial: Blocks of 5'); title('EXT1 ? Response to CS-');

subplot(439)
S = extinction2_DR2'; plot_matrix(S,5:5:5*size(S,1),1:size(S,2),'n'); 
colormap(customColormap); clim([-20 20]); colorbar('off');
ylabel('Animal'); xlabel('Trial: Blocks of 5'); title('EXT2 ? Response to CS-');

% Define the points and corresponding colors
x = [-50, 0, 50];
colors = [0.5, 0.5, 0.5;  % Gray for -3000
          0, 0, 0;        % Black for 0
          0, 1, 0];       % Green for 3000
numColors = 256; % Number of points in the colormap
% Interpolate to create a smooth colormap
xq = linspace(-50, 50, numColors);
customColormap = interp1(x, colors, xq, 'linear');

subplot(4,3,10)
S = training_LI1'; plot_matrix(S,1:size(S,1),1:size(S,2),'n'); 
colormap(customColormap); clim([0 50]); colorbar('off');
ylabel('Animal'); xlabel('Days'); title('Learning Index 1');

subplot(4,3,11)
S = training_LI2'; plot_matrix(S,1:size(S,1),1:size(S,2),'n'); 
colormap(customColormap); clim([0 50]); colorbar('off');
ylabel('Animal'); xlabel('Days'); title('Learning Index 2');

set(gcf, 'Color', 'white');