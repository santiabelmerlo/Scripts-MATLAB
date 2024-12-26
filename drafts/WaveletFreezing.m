%% Wavelet Loop
% Loop para calcular la wavelet, cuantificar en 4Hz y Theta y guardar el vector en cada carpeta
% Usamos las funciones cwt()

clc
clear all

% rats = 17;
rats = [11,12,13,17,18,19,20]; % Filtro por animales para aversivo.
paradigm_toinclude = 'aversive'; % Fi ltro por el paradigma
session_toinclude = {'EXT1','EXT2','TEST'}; % Filtro por las sesiones
region = 'BLA'; % Filtro por región que quiero mirar
event = 'Freezing'; % Filtramos por el evento que queremos ver con wavelet

% Cargamos los datos
cd('D:\Doctorado\Analisis\Sheets');
EventsSheet_raw = readtable('EventsSheet.csv');

% Definimos algunas variables vacías
recortes_wavelets = [];
recortes_ID = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Define the parent folder containing the 'Rxx' folders
parentFolder = 'D:\Doctorado\Backup Ordenado';

% List all 'Rxx' folders in the parent folder
R_folders = dir(fullfile(parentFolder, 'R*'));

for r = rats % Iterate through each 'Rxx' folder
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
        
        if exist(strcat(name,'_sessioninfo.mat')) == 2;
            session_end = [];
            load(strcat(name,'_sessioninfo.mat'));
            if  strcmp(paradigm,paradigm_toinclude) && ...
                any(strcmp(session, session_toinclude))||any(strcmp(session_end, session_toinclude));
                disp(['  All required files exists. Performing action...']);
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
               % Filtramos la tabla con las distintas condiciones
               EventsSheet = EventsSheet_raw(EventsSheet_raw.Rat == r, :);
               EventsSheet = EventsSheet(strcmp(EventsSheet.Name, name), :);
               EventsSheet = EventsSheet(strcmp(EventsSheet.Event, event), :);
               EventsSheet = EventsSheet(EventsSheet.noisy == 0, :); % Solo me quedo con los eventos no ruidosos
               EventsSheet = EventsSheet(EventsSheet.Epileptic <= 5, :); % Tolerancia de 5% del evento con evento epiléptico
               event_inicio = EventsSheet.Inicio;
               event_ID = EventsSheet.ID;
                
                Fs = 1250; % Frecuencia de sampleo

                % BLA
                if ~isempty(BLA_mainchannel) && strcmp(region,'BLA');
                    disp('    Loading BLA Channel...')
                    % Cargamos la señal de BLA
                    lfp_BLA = LoadBinary(strcat(name,'_lfp.dat'), BLA_mainchannel, ch_total); % Cargamos la señal
                    lfp_BLA = lfp_BLA * 0.195; % Convertir un canal de registro de bits a microvolts (uV)
                    lfp_BLA = zpfilt(lfp_BLA,1250,0.1,300); % Filtramos la señal entre 0.1 y 300
                    lfp_BLA = zscorem(lfp_BLA); % Lo normalizamos con zscore
                    t = 1/Fs:1/Fs:size(lfp_BLA,2)/Fs;
                    % Calculamos el wavelet
                    disp('      Computing Wavelet from BLA Channel...')
                    clear y f coi;
                    % Wavelet con función wavelet
                    [y,p] = wavelet(lfp_BLA,1/Fs,1,log2(16)/32,1/16,32);
                    wave = zscorem(abs(y),2);
                    f = 1./p;
%                     Borramos lo que no nos interesa
                    clear y coi;
                end

                % PL
                if ~isempty(PL_mainchannel) && strcmp(region,'PL');
                    disp('    Loading PL Channel...')
                    % Cargamos la señal de PL
                    lfp_PL = LoadBinary(strcat(name,'_lfp.dat'), PL_mainchannel, ch_total); % Cargamos la señal
                    lfp_PL  = lfp_PL  * 0.195; % Convertir un canal de registro de bits a microvolts (uV)
                    lfp_PL  = zpfilt(lfp_PL ,1250,0.1,300); % Filtramos la señal entre 0.1 y 300
                    lfp_PL  = zscorem(lfp_PL); % Lo normalizamos con zscore
                    t = 1/Fs:1/Fs:size(lfp_PL ,2)/Fs;
                    % Calculamos el wavelet
                    disp('      Computing Wavelet from PL Channel...')
                    clear y f coi;
                    % Wavelet con función wavelet
                    [y,p] = wavelet(lfp_PL,1/Fs,1,log2(16)/32,1/16,32);
                    wave = zscorem(abs(y),2);
                    f = 1./p;
                    % Borramos lo que no nos interesa
                    clear lfp_PL y coi;
                end

                % IL
                if ~isempty(IL_mainchannel) && strcmp(region,'IL');
                    disp('    Loading IL Channel...')
                    % Cargamos la señal de IL
                    lfp_IL = LoadBinary(strcat(name,'_lfp.dat'), IL_mainchannel, ch_total); % Cargamos la señal
                    lfp_IL  = lfp_IL  * 0.195; % Convertir un canal de registro de bits a microvolts (uV)
                    lfp_IL  = zpfilt(lfp_IL ,1250,0.1,300); % Filtramos la señal entre 0.1 y 300
                    lfp_IL  = zscorem(lfp_IL); % Lo normalizamos con zscore
                    t = 1/Fs:1/Fs:size(lfp_IL ,2)/Fs;
                    % Calculamos el wavelet
                    disp('      Computing Wavelet from IL Channel...')
                    clear y f coi;
                    % Wavelet con función wavelet
                    [y,p] = wavelet(lfp_IL,1/Fs,1,log2(16)/32,1/16,32);
                    wave = zscorem(abs(y),2);
                    f = 1./p;
                    % Borramos lo que no nos interesa
                    clear lfp_IL y coi;
                end
                
                if exist('event_inicio', 'var') && ~isempty(event_inicio)
                    recorte = 5; % Ventana de recorte en segundos (±5 seg)
                    disp('Recortando wavelet en torno a los eventos...');
                    for e = 3:length(event_inicio)-3
                        % Encontrar los índices en la variable de tiempo t
                        idx_inicio = find(t >= event_inicio(e), 1, 'first');
                        % Verificar que los índices sean válidos
                        if ~isempty(idx_inicio)
                            % Extraer el recorte de la matriz wave
                            recorte_wave = wave(:, idx_inicio-5*Fs:idx_inicio+5*Fs);
                            recortes_wavelets = cat(3, recortes_wavelets, recorte_wave);
                            recortes_ID = cat(1,recortes_ID,event_ID(e));
                        end
                    end
                end
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            else
                disp(['  Some required file do not exist.']);
                disp(['  Skipping action...']);
            end
        end
    end
    % Go back to the 'Rxx' folder
    cd(current_R_folder);
end

cd(parentFolder);

t = -5:1/Fs:5;
clearvars -except recortes_ID recortes_wavelets f t

disp('Ready!');

%%
% Save the table as a CSV file
cd('D:\Doctorado\Analisis');
save('WaveletFreezing.mat','-v7.3');

%% Cargamos el dato para despues plotear
clc
clear all

cd('D:\Doctorado\Analisis');
load('WaveletFreezing.mat');

%% Crear el gráfico con imagesc
figure;
Fs = 1250;
wave = nanmedian(recortes_wavelets,3);

% Define a new linear frequency vector
f_linear = linspace(min(f), max(f), length(f)); % Linear frequency axis with the same length as original f
% Interpolate the wave matrix to the new linear frequency scale
wave_linear = interp1(f, wave, f_linear, 'linear'); % Interpolate along the frequency axis

% Plot using imagesc
figure;
imagesc(t, f_linear, wave_linear);
colormap(jet);
axis xy; % Ensure correct orientation for frequencies
colorbar('off');

line([0 0],[0 200],'LineWidth',2,'LineStyle','--','color',[1 1 1]);
     
% Etiquetas y título
xlabel('Tiempo (s)');
ylabel('Frecuencia (Hz)');
title('Todos los freezings');
colorbar;

%% Separamos por tipo de freezing y ploteamos en una escala lineal
% Cargamos los datos
cd('D:\Doctorado\Analisis\Sheets');
FzType = readtable('NormPower_Sheet.csv');

% Your calculation
ID_Fz1 = FzType.ID((FzType.FourHz_BLA ./ FzType.Theta_BLA) > 1);
ID_Fz2 = FzType.ID((FzType.FourHz_BLA ./ FzType.Theta_BLA) < 1);

Fz1 = recortes_wavelets(:, :, ismember(recortes_ID, ID_Fz1));
Fz2 = recortes_wavelets(:, :, ismember(recortes_ID, ID_Fz2));

% Ploteamos para 4Hz Fz.
figure;
Fs = 1250;
wave = nanmedian(Fz1,3);
% Define a new linear frequency vector
f_linear = linspace(min(f), max(f), length(f)); % Linear frequency axis with the same length as original f
% Interpolate the wave matrix to the new linear frequency scale
wave_linear = interp1(f, wave, f_linear, 'linear'); % Interpolate along the frequency axis
imagesc(t, f_linear, wave_linear);
colormap(jet);
axis xy; % Para invertir el eje Y si es necesario

line([0 0],[0 200],'LineWidth',2,'LineStyle','--','color',[1 1 1]);
     
% Etiquetas y título
xlabel('Tiempo (s)');
ylabel('Frecuencia (Hz)');
title('Todos los freezings');
colorbar;

% Ploteamos para Theta Fz
figure;
Fs = 1250;
wave = nanmedian(Fz2,3);
% Define a new linear frequency vector
f_linear = linspace(min(f), max(f), length(f)); % Linear frequency axis with the same length as original f
% Interpolate the wave matrix to the new linear frequency scale
wave_linear = interp1(f, wave, f_linear, 'linear'); % Interpolate along the frequency axis
imagesc(t, f_linear, wave_linear);
colormap(jet);
axis xy; % Para invertir el eje Y si es necesario

line([0 0],[0 200],'LineWidth',2,'LineStyle','--','color',[1 1 1]);
     
% Etiquetas y título
xlabel('Tiempo (s)');
ylabel('Frecuencia (Hz)');
title('Todos los freezings');
colorbar;

%% Ploteamos todos los freezings pero con una escala lineal
% Define a new linear frequency vector
f_linear = linspace(min(f), max(f), length(f)); % Linear frequency axis with the same length as original f

% Interpolate the wave matrix to the new linear frequency scale
wave_linear = interp1(f, wave, f_linear, 'linear'); % Interpolate along the frequency axis

% Plot using imagesc
figure;
imagesc(t, f_linear, wave_linear);
axis xy; % Ensure correct orientation for frequencies
xlabel('Time (s)');
ylabel('Frequency (Hz)');
title('Wave Data on Linear Frequency Scale');
colorbar;

%% Usamos la nueva clasificación de freezing para separar los wavelets
% Cargamos los datos
cd('D:\Doctorado\Analisis\Sheets');
EventsSheet = readtable('EventsSheet.csv');

EventsSheet = EventsSheet(EventsSheet.Epileptic < 0.1 ,:);
EventsSheet = EventsSheet(EventsSheet.Flat < 0.1 ,:);
EventsSheet = EventsSheet(EventsSheet.noisy == 0 ,:);
EventsSheet = EventsSheet(strcmp(EventsSheet.Event,'Freezing') ,:);

Fz4hz = EventsSheet(strcmp(EventsSheet.Enrich,'4Hz'),:);
FzTheta = EventsSheet(strcmp(EventsSheet.Enrich,'Theta'),:);

% Your calculation
ID_Fz1 = Fz4hz.ID;
ID_Fz2 = FzTheta.ID;

Fz1 = recortes_wavelets(:, :, ismember(recortes_ID, ID_Fz1));
Fz2 = recortes_wavelets(:, :, ismember(recortes_ID, ID_Fz2));

% Ploteamos esos eventos de freezing
figure;
Fs = 1250;
wave = nanmedian(Fz1,3);
% Define a new linear frequency vector
f_linear = linspace(min(f), max(f), length(f)); % Linear frequency axis with the same length as original f
% Interpolate the wave matrix to the new linear frequency scale
wave_linear = interp1(f, wave, f_linear, 'linear'); % Interpolate along the frequency axis
plot_matrix_smooth(wave_linear',t,f_linear,'n',1);
colormap(jet);
colorbar('off');
axis xy; % Para invertir el eje Y si es necesario

line([0 0],[0 200],'LineWidth',1,'LineStyle','--','color',[0 0 0]);
ylim([1 12]);
clim([-0.5 0.5]);
     
% Etiquetas y título
xlabel('Tiempo (s)');
ylabel('Frecuencia (Hz)');
title(['Freezing 4Hz. n= ' num2str(size(Fz1,3))]);

% Set figure properties
set(gcf, 'Color', 'white');
set(gcf, 'Position', [100, 500, 300 300]);

% Ploteamos para Theta Fz
figure;
Fs = 1250;
wave = nanmedian(Fz2,3);
% Define a new linear frequency vector
f_linear = linspace(min(f), max(f), length(f)); % Linear frequency axis with the same length as original f
% Interpolate the wave matrix to the new linear frequency scale
wave_linear = interp1(f, wave, f_linear, 'linear'); % Interpolate along the frequency axis
plot_matrix_smooth(wave_linear',t,f_linear,'n',1);
colormap(jet);
colorbar('off');
axis xy; % Para invertir el eje Y si es necesario

line([0 0],[0 200],'LineWidth',2,'LineStyle','--','color',[0 0 0]);
ylim([1 12]);
clim([-0.5 0.5]);
     
% Etiquetas y título
xlabel('Tiempo (s)');
ylabel('Frecuencia (Hz)');
title(['Freezing Theta. n= ' num2str(size(Fz2,3))]);

% Set figure properties
set(gcf, 'Color', 'white');
set(gcf, 'Position', [100, 500, 300 300]);