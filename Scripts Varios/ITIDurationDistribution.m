%% Calculo y ploteo una distribución de duraciones de los ITI
% Corro este script una vez parado en la carpeta de la sesión que quiero analizar
clear all
clc
path = pwd;
[~,D,X] = fileparts(path);
D = strcat(D,X)

% Cargamos los datos de los TTL y los timestamps.
TTL.states = readNPY(strcat(D,'_TTL_channel_states.npy')); % Cargamos el estado de cada input del IO Board. 
TTL.timestamps = readNPY(strcat(D,'_TTL_timestamps.npy')); % Los timestamps estan en unidad de muestreo: 30 kHz.
TTL.channels = readNPY(strcat(D,'_TTL_channels.npy')); % Cargamos los estados de los canales.
TTL.timestamps = TTL.timestamps/30; % Pasamos las unidades a milisegundos. Esto se hace cuando el muestreo es a 30kb/s en el Open Ephys.
TTL.timestamps = TTL.timestamps - TTL.timestamps(1); % Restamos el primer timestamp para que inicie en 0.

% Buscamos los tiempos asociados a cada evento. 
% Inicio y fin del CS+ asociado con la recompensa. Entrada #1 del IO board.
CS1.start = TTL.timestamps(find(TTL.states == 1));
CS1.end = TTL.timestamps(find(TTL.states == -1));
% Inicio y fin del CS-. Entrada #1 del IO board. Entrada #2 del IO board.
CS2.start = TTL.timestamps(find(TTL.states == 2));
CS2.end = TTL.timestamps(find(TTL.states == -2));

CS_start = [CS1.start;CS2.start]; CS_start = sort(CS_start);
CS_end = [CS1.end;CS2.end]; CS_end = sort(CS_end);

for i = 1:size(CS_start,1)-1;
    ITI(i) = CS_start(i+1) - CS_end(i);
end

ITI = double(ITI); ITI = ITI/1000;
hist(ITI,30);
xlabel('ITI duration (sec.)');
ylabel('Frequency (counts)');
title('ITI duration distribution');
line([mean(ITI) mean(ITI)],[0 10])