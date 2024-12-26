%% PSTH para todas las neuronas de todos los animales

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc
clear all

% En estas lineas selecciono que animales, paradigma y sesiones quiero analizar
% rats = [10,11,13,14,16,17,18,19]; % Filtro por animales para apetitivo
rats = [11,12,13,17,18,19,20]; % Filtro por animales para aversivo.

paradigm_toinclude = 'aversive'; % Filtro por el paradigma
session_toinclude = {'EXT1','EXT2','TEST'}; % Filtro por las sesiones

type = {'good'}; % Filtro por el tipo de neurona: 'good', 'mua', 'unsorted'
position = {'BLA','BLP','BMP','LaVL','BLV','LaVM'}; % Filtro por la posición del electrodo. 'BLA','BLP','BMP','LaVL','BLV','LaVM','PL','IL'
event = 'freezing'; % Filtramos por el evento con el cual quiero triggerear. 'CS1'
pre_t = 20000; % Tiempo pre evento desde donde quiero calular, en ms.
post_t = 20000; % Tiempo post evento hasta donde quiero calcular, en ms.
bin_sz = 50; % Tamaño del bin para calcular el FR, en ms.
baseline_start = -5000; % Inicio de ventana para usar como baseline para zscorear, en ms
baseline_end = -500;   % Fin de ventana para usar como baseline para zscorear, en ms

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Define the parent folder containing the 'Rxx' folders
parentFolder = 'D:\Doctorado\Backup Ordenado';

% List all 'Rxx' folders in the parent folder
R_folders = dir(fullfile(parentFolder, 'R*'));

% Definimos algunas variables
Fs = 30000;
psth3 = [];
trialspx2 = {};
stats= [];

% Iterate through each 'Rxx' folder
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
        
        if exist(strcat(name,'_sessioninfo.mat')) == 2;
            session_end = [];
            load(strcat(name,'_sessioninfo.mat'));
            if strcmp(paradigm,paradigm_toinclude) && any(strcmp(session, session_toinclude))||any(strcmp(session_end, session_toinclude));
        
                if exist(strcat(name,'_epileptic.mat')) == 2;
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    load(strcat(name,'_epileptic.mat')); % Cargamos los datos de epileptic

                    % Le sumo 450 ms a los timestamps de los tonos
                    TTL_CS1_inicio = TTL_CS1_inicio + 0.450;
                    TTL_CS1_fin = TTL_CS1_fin + 0.450;
                    TTL_CS2_inicio = TTL_CS2_inicio + 0.450;
                    TTL_CS2_fin = TTL_CS2_fin + 0.450;

                    fstruct = dir('*Kilosort*'); % Busco la ruta completa de la carpeta Kilosort

                        if size(fstruct,1) == 1; % Si existe la ruta a la carpeta kilosort    
                            cd(fstruct.name); % Entro a la carpeta Kilosort
                            if exist(strcat('spike_clusters.npy')) == 2
                                spike_clusters = double(readNPY('spike_clusters.npy'));
                                spike_times = double(readNPY('spike_times.npy'));
                                table = readtable('cluster_info.csv');

                                % Aplico algunos filtros y sorting sobre la tabla
                                table = table(table.fr > 0.5, :); % Elimino aquellas neuronas que tienen un fr menor a 0.5               
                                table = table(ismember(table.type, type), :);
                                table = table(ismember(table.position, position), :);
                                table = table(table.target == 1, :); % Me quedo con las que están en el target
                                table = sortrows(table, 'n_spikes', 'descend');

                                clusters = table.cluster_id;
                                if size(clusters,1) >= 1;
                                    for i = 1:size(clusters,1);
                                        disp(strcat('     Processing neuron = ', num2str(i)));
                                        neuron = clusters(i);
                                        spikes = spike_times(find(spike_clusters == neuron)); spikes = spikes/Fs;
                                        if strcmp(event,'CS1')
                                            [psth trialspx] = mpsth(spikes,TTL_CS1_inicio,'fr',1,'pre',pre_t,'post',post_t,'chart',0,'binsz',bin_sz);
                                        elseif strcmp(event,'CS2')
                                            [psth trialspx] = mpsth(spikes,TTL_CS2_inicio,'fr',1,'pre',pre_t,'post',post_t,'chart',0,'binsz',bin_sz);
                                        elseif strcmp(event,'freezing')
                                            [psth trialspx] = mpsth(spikes,inicio_freezing,'fr',1,'pre',pre_t,'post',post_t,'chart',0,'binsz',bin_sz);
                                        elseif strcmp(event,'movement')
                                            [psth trialspx] = mpsth(spikes,inicio_movement,'fr',1,'pre',pre_t,'post',post_t,'chart',0,'binsz',bin_sz);
                                        end
                                        psth2(:,i) = psth(:,2);
                                        trialspx2(1:size(trialspx,1),i) = trialspx(1:end,1);
                                    end    
                                    psth3 = cat(2,psth3,psth2);
                                end
                            else    
                            end
                        else
                            % Do nothing
                        end

                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                else
                    disp(['  File sessioninfo does not exist.']);
                    disp(['  Skipping action...']);
                end
            end
        end
        clear table psth psth2
        
        % Go back to the 'Rxx' folder
        cd(current_R_folder);
    end
end

cd(parentFolder);

% Calculamos algunas cosas
t = -pre_t:bin_sz:post_t-bin_sz;
n = 1:size(psth3,2);

% Zscoreamos por la actividad que sucede de -3 a -1 seg pre evento
baseline_idx = t >= baseline_start & t <= baseline_end;
baseline_firing_rates = psth3(baseline_idx, :);
baseline_mean = mean(baseline_firing_rates, 1); %(media por neurona)
baseline_std = std(baseline_firing_rates, 0, 1); % (desviación estándar por neurona
baseline_mean = repmat(baseline_mean, size(psth3, 1), 1); % 200x3200
baseline_std = repmat(baseline_std, size(psth3, 1), 1);   % 200x3200
psth3 = (psth3 - baseline_mean) ./ baseline_std; % Realizar z-score: (X - mean) / std

% Ordenamos por respuesta
% Define the time window
timeStart = 0; % in ms
timeEnd = 1000;   % in ms
% Find the indices corresponding to the time window (400 ms to 500 ms)
indices = find(t >= timeStart & t <= timeEnd);
% Calculate the mean value for each neuron in this time window
meanValues = mean(psth3(indices, :), 1); % Compute mean across the selected time indices
% Sort the neurons based on the mean values
[sortedMeans, sortIdx] = sort(meanValues);
% Sort the columns of the data matrix according to the sorted neuron order
psth3 = psth3(:, sortIdx);
% Calculate the mean value for each neuron in this time window
meanValues = mean(psth3(indices, :), 1); % Compute mean across the selected time indices
% Buscamos neuronas responsivas
responsiveN = meanValues >= 1 | meanValues <= -1;

% Filtramos las que responden
psth4 = psth3(:,responsiveN);
n2 = 1:size(psth4,2);

%% Ploteamos 
plot_matrix(psth3,t,n,'n');
clim([-2 2]);
xlabel('Time (ms)');
ylabel('BLA Neuron #');
title('');
hold on
line([0 0],[0 150],'Color',[1 1 1],'LineWidth',1,'LineStyle','--');

% Calculamos cuantas son las que se excitan, cuantas se inhiben, del total de goods
exc = sum(meanValues >= 1);
inh = sum(meanValues <= -1);
total = size(psth3,2);
nonResponsive = total - (exc + inh);  % Count of non-responsive neurons

% Prepare data for pie chart
data = [exc, inh, nonResponsive];

% Define colors for each category: red for excitatory, blue for inhibitory, gray for non-responsive
colors = [1 0 0;    % Red for excitatory
          0 0 1;    % Blue for inhibitory
          1 1 1];   % Light gray for non-responsive

% Create the pie chart without labels first
figure;
h = pie(data); 

% Set the colors of the pie chart
for k = 1:length(h)
    if mod(k, 2) == 1  % Check if it is a slice (odd index)
        if k == 1
            h(k).FaceColor = colors(1, :);  % Excitatory
        elseif k == 3
            h(k).FaceColor = colors(2, :);  % Inhibitory
        elseif k == 5
            h(k).FaceColor = colors(3, :);  % Non-Responsive
        end
    end
end

% Add total values and percentages as labels
% Calculate percentages
percentages = data / total * 100;

% Customize labels to include both counts and percentages
labels = cellstr(num2str([data', percentages'], '%d (%.1f%%)'));

% Set the labels to the pie chart
for k = 1:length(h)
    if mod(k, 2) == 0  % Check if it is a label (even index)
        h(k).String = labels{k/2};  % Assign label
    end
end

% Add title
% title('BLA Single-units');

% Create a legend
legend({'Excitatory', 'Inhibitory', 'Non-responsive'}, 'Location', 'bestoutside');

% Add total count below the pie chart
totalText = sprintf('Total Neurons: %d', total);
text(0, -1.5, totalText, 'FontSize', 12, 'HorizontalAlignment', 'center');

disp('Done!');