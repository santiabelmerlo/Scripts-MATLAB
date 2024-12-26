%% PSTH: Creamos algunos PSTH de ejemplo parandonos en la carpeta de interés
clc;
clear all;

path = pwd;
cd(path);
Fs = 30000;

[~,D,X] = fileparts(path); name = D([1:6]); % Obtenemos el nombre de la carpeta
load(strcat(name,'_epileptic.mat')); % Cargamos los datos de epileptic

% Le sumo 450 ms a los timestamps de los tonos
TTL_CS1_inicio = TTL_CS1_inicio + 0.450;
TTL_CS1_fin = TTL_CS1_fin + 0.450;
TTL_CS2_inicio = TTL_CS2_inicio + 0.450;
TTL_CS2_fin = TTL_CS2_fin + 0.450;

fstruct = dir('*Kilosort*'); % Busco la ruta completa de la carpeta Kilosort
if size(fstruct,1) == 1; % Si existe la ruta a la carpeta kilosort    
    cd(fstruct.name); % Entro a la carpeta Kilosort
    spike_clusters = double(readNPY('spike_clusters.npy'));
    spike_times = double(readNPY('spike_times.npy'));
    table = readtable('cluster_info.csv');
else
    cd(path);
end

% Aplico algunos filtros y sorting sobre la tabla
table = table(table.fr > 0.5, :); % Elimino aquellas neuronas que tienen un fr menor a 0.5
% table = table(strcmp(table.type,'good'), :); % Me quedo con las 'good', 'mua' o 'unsorted'
% table = table(strcmp(table.position,'BLA'), :); % Filtro por zona
table = table(table.target == 1, :); % Me quedo con las que están en el target
table = sortrows(table, 'n_spikes', 'descend');

clusters = table.cluster_id;
for i = 1:size(clusters,1);
    disp(strcat('Processing neuron = ', num2str(i)));
    neuron = clusters(i);
    spikes = spike_times(find(spike_clusters == neuron)); spikes = spikes/Fs;
    psth = mpsth(spikes,TTL_CS1_inicio,'fr',1,'pre',5000,'post',5000,'chart',0,'binsz',50);
%      psth = mpsth(spikes,TTL_CS2_inicio,'fr',1,'pre',5000,'post',5000,'chart',0,'binsz',50);
%     psth = mpsth(spikes,inicio_freezing,'fr',1,'pre',5000,'post',5000,'chart',0,'binsz',50);
%     psth = mpsth(spikes,inicio_movement,'fr',1,'pre',5000,'post',5000,'chart',0,'binsz',50);
%     pause(2);
    psth2(:,i) = psth(:,2);    
    close all;
    cd(path)
end

cd(path);

% Calculamos algunas cosas
t = -5000:50:4950;
n = 1:size(psth2,2);
psth2 = zscore(psth2,0,1);

% Ordenamos por respuesta

% Define the time window
timeStart = 0; % in ms
timeEnd = 500;   % in ms

% Find the indices corresponding to the time window (400 ms to 500 ms)
indices = find(t >= timeStart & t <= timeEnd);

% Calculate the mean value for each neuron in this time window
meanValues = mean(psth2(indices, :), 1); % Compute mean across the selected time indices

% Sort the neurons based on the mean values
[sortedMeans, sortIdx] = sort(meanValues);

% Sort the columns of the data matrix according to the sorted neuron order
psth2 = psth2(:, sortIdx);

% Ploteamos 
plot_matrix(psth2,t,n,'n');
clim([-3 3]);
xlabel('Time (ms)');
ylabel('Neuron #');
title('');

%%
% Cargamos los datos de los TTL y los timestamps.
TTL.states = readNPY(strcat(name(1:6),'_TTL_channel_states.npy')); % Cargamos el estado de cada input del IO Board. 
TTL.timestamps = readNPY(strcat(name(1:6),'_TTL_timestamps.npy')); % Los timestamps estan en unidad de muestreo: 30 kHz.
TTL.channels = readNPY(strcat(name(1:6),'_TTL_channels.npy')); % Cargamos los estados de los canales.
TTL.timestamps = double(TTL.timestamps);
TTL.timestamps = TTL.timestamps - TTL.timestamps(1); % Restamos el primer timestamp para que inicie en 0. 
% TTL.timestamps = TTL.timestamps/30000; % Pasamos las unidades a milisegundos. Esto se hace cuando el muestreo es a 30kb/s en el Open Ephys.

% Buscamos los tiempos asociados a cada evento. 
% Inicio y fin del CS+ asociado con la recompensa. Entrada #1 del IO board.
CS1.start = TTL.timestamps(find(TTL.states == 1));
CS1.end = TTL.timestamps(find(TTL.states == -1));
% Inicio y fin del CS-. Entrada #1 del IO board. Entrada #2 del IO board.
CS2.start = TTL.timestamps(find(TTL.states == 2));
CS2.end = TTL.timestamps(find(TTL.states == -2));

%%
CS1_inicio2 = CS1.start;