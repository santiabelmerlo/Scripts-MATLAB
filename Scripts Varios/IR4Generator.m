%% Timestamps de entradas y salidas de la puerta del nosepoke unificando los sensores IR2 e IR3 en uno solo
clear all
clc
path = 'D:\Doctorado\Electrofisiología\Vol 11\'; % path en IFIBIO
cd(path);

[filpath,name,ext] = fileparts(cd); clear ext; clear filpath;
d = dir(cd); dfolders = d([d(:).isdir]); dfolders = dfolders(~ismember({dfolders(:).name},{'.','..'}));

a = 12;
path1 = [path dfolders(a).name;];
name = dfolders(a).name;
cd(path1);
cd('./Record Node 101/experiment1/recording1/events/Rhythm_FPGA-100.0/TTL_1/');

% Cargamos los datos de los TTL y los timestamps.
TTL.states = readNPY('channel_states.npy'); % Cargamos el estado de cada input del IO Board.
TTL.timestamps = readNPY('timestamps.npy'); % Los timestamps estan en unidad de muestreo: 10kHz
TTL.channels = readNPY('channels.npy'); % Cargamos los estados de los canales.
TTL.timestamps = TTL.timestamps/30; % Pasamos las unidades a milisegundos. Esto se hace cuando el muestreo es a 30kb/s en el Open Ephys.
TTL.timestamps = TTL.timestamps - TTL.timestamps(1); % Restamos el primer timestamp para que inicie en 0.

% Buscamos los tiempos asociados a cada evento.
% Inicio y fin del CS+ asociado con la recompensa. Entrada #1 del IO board.
CS1.start = TTL.timestamps(find(TTL.states == 1));
CS1.end = TTL.timestamps(find(TTL.states == -1));
% Inicio y fin del CS-. Entrada #1 del IO board. Entrada #2 del IO board.
CS2.start = TTL.timestamps(find(TTL.states == 2));
CS2.end = TTL.timestamps(find(TTL.states == -2));
% Inicio y fin de los nosepokes en la puerta. Entrada #5 del IO board.
IR2.start = TTL.timestamps(find(TTL.states == 5));
IR2.end = TTL.timestamps(find(TTL.states == -5));
% Inicio y fin de los nosepokes en el target. Entrada #6 del IO board.
IR3.start = TTL.timestamps(find(TTL.states == 6));
IR3.end = TTL.timestamps(find(TTL.states == -6));

% En una segunda columna asignamos 1 cuando se corta el haz del sensor y -1 cuando deja de cortar el haz.
IR2.start(:,2) = 1;
IR2.end(:,2) = -1;
IR3.start(:,2) = 1;
IR3.end(:,2) = -1;

% En un nuevo array ponemos todos los tiempos juntos y si se trata de start o end en la segunda columna.
AA = cat(1,IR2.start,IR2.end,IR3.start,IR3.end);

% Ordenamos de menor a mayor según los timestamps para que esten en orden cronológico.
B = sortrows(AA,1);

% En una tercera columna vamos sumando los estados, de forma tal que sea 1 o 2 cuando se corta uno o los dos haces, pero solo sea cero cuando
% se apagaron los dos haces a la vez.
estado = 0;
for i = 1:length(B);
    B(i,3) = B(i,2) + estado;
    estado = B(i,3);
end

% En una cuarta columna ponemos si es mayor a 0 o igual a cero.
B(:,4) = B(:,3) > 0;

% Nos quedamos con los tiempos donde pasa de 1 -> 0 o de 0 -> 1. Si se repite 1 varias veces o 0 varias veces no los tenemos en cuenta.
estado = 0;
IR4.start = 0;
IR4.end = 0;
for i = 1:length(B);
    if B(i,4) ~= estado;
        if B(i,4) == 1;
            IR4.start(end+1,1) = B(i,1);
        elseif B(i,4) == 0;
            IR4.end(end+1,1) = B(i,1);
        end
    end
    estado = B(i,4);    
end

IR4.start(1) = []; % Borramos el primer dato que siempre va a ser 0.
IR4.end(1) = []; % Borramos el primer dato que siempre va a ser 0.

% Calculamos la duración del corte del haz IR4.
for i = 1:length(IR4.start);
    IR4.duration(i,1) = IR4.end(i) - IR4.start(i);
end