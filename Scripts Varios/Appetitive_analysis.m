%% Analizamos todas las carpetas. Genero un OUTPUT con todos los resultados en ms.

% Entradas IO Board:
% 1 --> Pin A0. CS1. CS+
% 2 --> Pin A1. CS2. CS-
% 3 --> Pin A2. Shock/Solenoide
% 4 --> Pin A3. IR1. Puerta 1
% 5 --> Pin A4. IR2. Puerta 2
% 6 --> Pin A5. IR3. Target
% 7 --> Pin 8. Pulso de Sincronización
% 8 --> Libre.

clear all
clc
path = pwd;
cd(path);

[filpath,name,ext] = fileparts(cd);

d = dir(cd); dfolders = d([d(:).isdir]); dfolders = dfolders(~ismember({dfolders(:).name},{'.','..'}));

% Seteamos de forma manual los folders de las sesiones apetitivas
cd(strcat(name,'_Analisis'));
load(strcat(name,'_folders.mat'));
cd(path);

% Si el file 'R00_folders.mat' no existe, lo creamos con lo siguiente:
% folders = [3,7,8,9,10,11,12];
% save(strcat(name,'_folders.mat'),'folders');

 for a = folders;
    path1 = [path '\' dfolders(a).name;];
    name = dfolders(a).name;
    cd(path1);
    
    % Cargamos los datos de los TTL y los timestamps.
    TTL.states = readNPY(strcat(name(1:6),'_TTL_channel_states.npy')); % Cargamos el estado de cada input del IO Board. 
    TTL.timestamps = readNPY(strcat(name(1:6),'_TTL_timestamps.npy')); % Los timestamps estan en unidad de muestreo: 30 kHz.
    TTL.channels = readNPY(strcat(name(1:6),'_TTL_channels.npy')); % Cargamos los estados de los canales.
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
    % Borramos el dato si arranca en end o termina en start
    if size(IR2.start,1) ~= size(IR2.end,1);
        if IR2.start(1) >= IR2.end(1);
            if size(IR2.start,1) > size(IR2.end,1);  % Este if fue agregado despues y falta agregarlo para la condicion de IR3
                IR2.start(end) = [];
            elseif size(IR2.start,1) < size(IR2.end,1);
                IR2.end(1) = [];
            end
        elseif IR2.end(end) <= IR2.start(end);
            IR2.start(end) = [];
        end
    end
    
    clear i;      
    for i = 1:length(IR2.start);
        IR2.duration(i,1) = IR2.end(i) - IR2.start(i);
    end
    
    clear i; clear ai;
    
    % Inicio y fin de los nosepokes en el target. Entrada #6 del IO board.
    IR3.start = TTL.timestamps(find(TTL.states == 6));
    IR3.end = TTL.timestamps(find(TTL.states == -6));
    
    % Borramos el dato si arranca en end o termina en start
    if size(IR3.start,1) ~= size(IR3.end,1);
        if IR3.start(1) >= IR3.end(1);
            IR3.end(1) = [];
        elseif IR3.end(end) <= IR3.start(end);
            IR3.start(end) = [];
        end
    end
    
    clear i;      
    for i = 1:length(IR3.start);
        IR3.duration(i,1) = IR3.end(i) - IR3.start(i);
    end
    
    clear i; clear ai;

    % Análisis para el target
    % Calculamos tiempo acumulado, número de NP y latencia al primer NP
    % Durante el CS+
    for i = 1:length(CS1.start);
        target.tacumulado = 0;
        target.cantidad = 0;
        k = 0;
        target.latency = 10000; % Latencia cuando no hay ningun caso de nosepoke
        for j = 1:length(IR3.start);
            % Si el nosepoke inicia luego del onset del CS y termina antes del offset del CS.
            if IR3.start(j) >= CS1.start(i) && IR3.end(j) <= CS1.end(i);
                 target.tacumulado = target.tacumulado + IR3.duration(j);
                 target.cantidad = target.cantidad + 1;
                 if k == 0;
                      target.latency = IR3.start(j) - CS1.start(i);
                 end
                 k = 1;
            end
            % Si el nosepoke inicia durante el CS pero termina luego del offset del CS.
            if IR3.start(j) >= CS1.start(i) && IR3.start(j) < CS1.end(i) && IR3.end(j) > CS1.end(i);
                 target.tacumulado = target.tacumulado + (CS1.end(i) - IR3.start(j));
                 target.cantidad = target.cantidad + 1;
                 if k == 0;
                      target.latency = IR3.start(j) - CS1.start(i);
                 end
                 k = 1;
            end
            % Si el nosepoke inicia antes del onset del CS pero termina durante CS.
            if IR3.start(j) < CS1.start(i) && IR3.end(j) > CS1.start(i) && IR3.end(j) <= CS1.end(i);
                 target.tacumulado = target.tacumulado + (IR3.end(j) - CS1.start(i));
                 target.cantidad = target.cantidad + 1;
                 if k == 0;
                      target.latency = 0;
                 end
                 k = 1;
            end
            % Si el nosepoke inicia antes del onset del CS y termina despues del offset del CS.
            if IR3.start(j) < CS1.start(i) && IR3.end(j) > CS1.end(i);
                 target.tacumulado = target.tacumulado + 10000;
                 target.cantidad = target.cantidad + 1;
                 if k == 0;
                      target.latency = 0;
                 end
                 k = 1;
            end
        end
        results.duringCS.ttarget.CS1(i,1) = target.tacumulado;
        results.duringCS.ntarget.CS1(i,1) = target.cantidad;
        results.duringCS.ltarget.CS1(i,1) = target.latency;
    end
    % Durante el CS-
    for i = 1:length(CS2.start);
        target.tacumulado = 0;
        target.cantidad = 0;
        k = 0;
        target.latency = 10000; % Latencia cuando no hay ningun caso de nosepoke
        for j = 1:length(IR3.start);
            % Si el nosepoke inicia luego del onset del CS y termina antes del offset del CS.
            if IR3.start(j) >= CS2.start(i) && IR3.end(j) <= CS2.end(i);
                 target.tacumulado = target.tacumulado + IR3.duration(j);
                 target.cantidad = target.cantidad + 1;
                 if k == 0;
                      target.latency = IR3.start(j) - CS2.start(i);
                 end
                 k = 1;
            end
            % Si el nosepoke inicia durante el CS pero termina luego del offset del CS.
            if IR3.start(j) >= CS2.start(i) && IR3.start(j) < CS2.end(i) && IR3.end(j) > CS2.end(i);
                 target.tacumulado = target.tacumulado + (CS2.end(i) - IR3.start(j));
                 target.cantidad = target.cantidad + 1;
                 if k == 0;
                      target.latency = IR3.start(j) - CS2.start(i);
                 end
                 k = 1;
            end
            % Si el nosepoke inicia antes del onset del CS pero termina durante CS.
            if IR3.start(j) < CS2.start(i) && IR3.end(j) > CS2.start(i) && IR3.end(j) <= CS2.end(i);
                 target.tacumulado = target.tacumulado + (IR3.end(j) - CS2.start(i));
                 target.cantidad = target.cantidad + 1;
                 if k == 0;
                      target.latency = 0;
                 end
                 k = 1;
            end
            % Si el nosepoke inicia antes del onset del CS y termina despues del offset del CS.
            if IR3.start(j) < CS2.start(i) && IR3.end(j) > CS2.end(i);
                 target.tacumulado = target.tacumulado + 10000;
                 target.cantidad = target.cantidad + 1;
                 if k == 0;
                      target.latency = 0;
                 end
                 k = 1;
            end
        end
        results.duringCS.ttarget.CS2(i,1) = target.tacumulado;
        results.duringCS.ntarget.CS2(i,1) = target.cantidad;
        results.duringCS.ltarget.CS2(i,1) = target.latency;
    end
    % Post CS+  ---> 10 seg post CS+
    for i = 1:length(CS1.start);
        target.tacumulado = 0;
        target.cantidad = 0;
        k = 0;
        target.latency = 10000; % Latencia cuando no hay ningun caso de nosepoke
        for j = 1:length(IR3.start);
            % Si el nosepoke inicia luego del offset del CS y termina antes de los 10 seg.
            if IR3.start(j) >= CS1.end(i) && IR3.end(j) <= (CS1.end(i) + 10000);
                 target.tacumulado = target.tacumulado + IR3.duration(j);
                 target.cantidad = target.cantidad + 1;
                 if k == 0;
                      target.latency = IR3.start(j) - CS1.end(i);
                 end
                 k = 1;
            end
            % Si el nosepoke inicia luego del offset del CS y termina despues de los 10 seg.
            if IR3.start(j) >= CS1.end(i) && IR3.start(j) <= (CS1.end(i) + 10000) && IR3.end(j) > (CS1.end(i) + 10000);
                 target.tacumulado = target.tacumulado + ((CS1.end(i) + 10000) - IR3.start(j));
                 target.cantidad = target.cantidad + 1;
                 if k == 0;
                      target.latency = IR3.start(j) - CS1.end(i);
                 end
                 k = 1;
            end
            % Si el nosepoke inicia antes del offset del CS y termina antes de los 10 seg.
            if IR3.start(j) < CS1.end(i) && IR3.end(j) > CS1.end(i) && IR3.end(j) <= (CS1.end(i) + 10000);
                 target.tacumulado = target.tacumulado + (IR3.end(j) - CS1.end(i));
                 target.cantidad = target.cantidad + 1;
                 if k == 0;
                      target.latency = 0;
                 end
                 k = 1;
            end
            % Si el nosepoke inicia antes del offset del CS y termina despues de los 10 seg.
            if IR3.start(j) < CS1.end(i) && IR3.end(j) > (CS1.end(i) + 10000);
                 target.tacumulado = target.tacumulado + 10000;
                 target.cantidad = target.cantidad + 1;
                 if k == 0;
                      target.latency = 0;
                 end
                 k = 1;
            end
        end
        results.postCS.ttarget.CS1(i,1) = target.tacumulado;
        results.postCS.ntarget.CS1(i,1) = target.cantidad;
        results.postCS.ltarget.CS1(i,1) = target.latency;
    end
    % Post CS-  ---> 10 seg post CS-
    for i = 1:length(CS2.start);
        target.tacumulado = 0;
        target.cantidad = 0;
        k = 0;
        target.latency = 10000; % Latencia cuando no hay ningun caso de nosepoke
        for j = 1:length(IR3.start);
            % Si el nosepoke inicia luego del offset del CS y termina antes de los 10 seg.
            if IR3.start(j) >= CS2.end(i) && IR3.end(j) <= (CS2.end(i) + 10000);
                 target.tacumulado = target.tacumulado + IR3.duration(j);
                 target.cantidad = target.cantidad + 1;
                 if k == 0;
                      target.latency = IR3.start(j) - CS2.end(i);
                 end
                 k = 1;
            end
            % Si el nosepoke inicia luego del offset del CS y termina despues de los 10 seg.
            if IR3.start(j) >= CS2.end(i) && IR3.start(j) <= (CS2.end(i) + 10000) && IR3.end(j) > (CS2.end(i) + 10000);
                 target.tacumulado = target.tacumulado + ((CS2.end(i) + 10000) - IR3.start(j));
                 target.cantidad = target.cantidad + 1;
                 if k == 0;
                      target.latency = IR3.start(j) - CS2.end(i);
                 end
                 k = 1;
            end
            % Si el nosepoke inicia antes del offset del CS y termina antes de los 10 seg.
            if IR3.start(j) < CS2.end(i) && IR3.end(j) > CS2.end(i) && IR3.end(j) <= (CS2.end(i) + 10000);
                 target.tacumulado = target.tacumulado + (IR3.end(j) - CS2.end(i));
                 target.cantidad = target.cantidad + 1;
                 if k == 0;
                      target.latency = 0;
                 end
                 k = 1;
            end
            % Si el nosepoke inicia antes del offset del CS y termina despues de los 10 seg.
            if IR3.start(j) < CS2.end(i) && IR3.end(j) > (CS2.end(i) + 10000);
                 target.tacumulado = target.tacumulado + 10000;
                 target.cantidad = target.cantidad + 1;
                 if k == 0;
                      target.latency = 0;
                 end
                 k = 1;
            end
        end
        results.postCS.ttarget.CS2(i,1) = target.tacumulado;
        results.postCS.ntarget.CS2(i,1) = target.cantidad;
        results.postCS.ltarget.CS2(i,1) = target.latency;
    end
    % Pre CS+  ---> 5 seg pre CS+
    for i = 1:length(CS1.start);
        target.tacumulado = 0;
        target.cantidad = 0;
        k = 0;
        target.latency = 10000; % Latencia cuando no hay ningun caso de nosepoke
        for j = 1:length(IR3.start);
            % Si el nosepoke inicia despues de 5 seg pre CS y termina antes del onset del CS
            if IR3.start(j) >= (CS1.start(i) - 10000) && IR3.end(j) <= CS1.start(i);
                 target.tacumulado = target.tacumulado + IR3.duration(j);
                 target.cantidad = target.cantidad + 1;
                 if k == 0;
                      target.latency = IR3.start(j) - (CS1.start(i) - 10000);
                 end
                 k = 1;
            end
            % Si el nosepoke inicia despues de 5 seg pre CS y termina despues del onset del CS
            if IR3.start(j) >= (CS1.start(i) - 10000) && IR3.start(j) < CS1.start(i) && IR3.end(j) > CS1.start(i);
                 target.tacumulado = target.tacumulado + (CS1.start(i) - IR3.start(j));
                 target.cantidad = target.cantidad + 1;
                 if k == 0;
                      target.latency = IR3.start(j) - (CS1.start(i) - 10000);
                 end
                 k = 1;
            end
            % Si el nosepoke inicia antes de 5 seg pre CS y termina antes del onset del CS
            if IR3.start(j) < (CS1.start(i) - 10000) && IR3.end(j) > (CS1.start(i) - 10000) && IR3.end(j) <= CS1.start(i);
                 target.tacumulado = target.tacumulado + (IR3.end(j) - (CS1.start(i) - 10000));
                 target.cantidad = target.cantidad + 1;
                 if k == 0;
                      target.latency = 0;
                 end
                 k = 1;
            end
            % Si el nosepoke inicia antes de 5 seg pre CS y termina despues del onset del CS
            if IR3.start(j) < (CS1.start(i) - 10000) && IR3.end(j) > CS1.start(i);
                 target.tacumulado = target.tacumulado + 10000;
                 target.cantidad = target.cantidad + 1;
                 if k == 0;
                      target.latency = 0;
                 end
                 k = 1;
            end
        end
        results.preCS.ttarget.CS1(i,1) = target.tacumulado;
        results.preCS.ntarget.CS1(i,1) = target.cantidad;
        results.preCS.ltarget.CS1(i,1) = target.latency;
    end
    % Pre CS-  ---> 5 seg pre CS-
    for i = 1:length(CS2.start);
        target.tacumulado = 0;
        target.cantidad = 0;
        k = 0;
        target.latency = 10000; % Latencia cuando no hay ningun caso de nosepoke
        for j = 1:length(IR3.start);
            % Si el nosepoke inicia despues de 5 seg pre CS y termina antes del onset del CS
            if IR3.start(j) >= (CS2.start(i) - 10000) && IR3.end(j) <= CS2.start(i);
                 target.tacumulado = target.tacumulado + IR3.duration(j);
                 target.cantidad = target.cantidad + 1;
                 if k == 0;
                      target.latency = IR3.start(j) - (CS2.start(i) - 10000);
                 end
                 k = 1;
            end
            % Si el nosepoke inicia despues de 5 seg pre CS y termina despues del onset del CS
            if IR3.start(j) >= (CS2.start(i) - 10000) && IR3.start(j) < CS2.start(i) && IR3.end(j) > CS2.start(i);
                 target.tacumulado = target.tacumulado + (CS2.start(i) - IR3.start(j));
                 target.cantidad = target.cantidad + 1;
                 if k == 0;
                      target.latency = IR3.start(j) - (CS2.start(i) - 10000);
                 end
                 k = 1;
            end
            % Si el nosepoke inicia antes de 5 seg pre CS y termina antes del onset del CS
            if IR3.start(j) < (CS2.start(i) - 10000) && IR3.end(j) > (CS2.start(i) - 10000) && IR3.end(j) <= CS2.start(i);
                 target.tacumulado = target.tacumulado + (IR3.end(j) - (CS2.start(i) - 10000));
                 target.cantidad = target.cantidad + 1;
                 if k == 0;
                      target.latency = 0;
                 end
                 k = 1;
            end
            % Si el nosepoke inicia antes de 5 seg pre CS y termina despues del onset del CS
            if IR3.start(j) < (CS2.start(i) - 10000) && IR3.end(j) > CS2.start(i);
                 target.tacumulado = target.tacumulado + 10000;
                 target.cantidad = target.cantidad + 1;
                 if k == 0;
                      target.latency = 0;
                 end
                 k = 1;
            end
        end
        results.preCS.ttarget.CS2(i,1) = target.tacumulado;
        results.preCS.ntarget.CS2(i,1) = target.cantidad;
        results.preCS.ltarget.CS2(i,1) = target.latency;
    end
    
    % Análisis para la puerta
    % Calculamos tiempo acumulado, número de NP y latencia al primer NP
    % Durante el CS+
    for i = 1:length(CS1.start);
        puerta.tacumulado = 0;
        puerta.cantidad = 0;
        k = 0;
        puerta.latency = 10000; % Latencia cuando no hay ningun caso de nosepoke
        for j = 1:length(IR2.start);
            % Si el nosepoke inicia luego del onset del CS y termina antes del offset del CS.
            if IR2.start(j) >= CS1.start(i) && IR2.end(j) <= CS1.end(i);
                 puerta.tacumulado = puerta.tacumulado + IR2.duration(j);
                 puerta.cantidad = puerta.cantidad + 1;
                 if k == 0;
                      puerta.latency = IR2.start(j) - CS1.start(i);
                 end
                 k = 1;
            end
            % Si el nosepoke inicia durante el CS pero termina luego del offset del CS.
            if IR2.start(j) >= CS1.start(i) && IR2.start(j) < CS1.end(i) && IR2.end(j) > CS1.end(i);
                 puerta.tacumulado = puerta.tacumulado + (CS1.end(i) - IR2.start(j));
                 puerta.cantidad = puerta.cantidad + 1;
                 if k == 0;
                      puerta.latency = IR2.start(j) - CS1.start(i);
                 end
                 k = 1;
            end
            % Si el nosepoke inicia antes del onset del CS pero termina durante CS.
            if IR2.start(j) < CS1.start(i) && IR2.end(j) > CS1.start(i) && IR2.end(j) <= CS1.end(i);
                 puerta.tacumulado = puerta.tacumulado + (IR2.end(j) - CS1.start(i));
                 puerta.cantidad = puerta.cantidad + 1;
                 if k == 0;
                      puerta.latency = 0;
                 end
                 k = 1;
            end
            % Si el nosepoke inicia antes del onset del CS y termina despues del offset del CS.
            if IR2.start(j) < CS1.start(i) && IR2.end(j) > CS1.end(i);
                 puerta.tacumulado = puerta.tacumulado + 10000;
                 puerta.cantidad = puerta.cantidad + 1;
                 if k == 0;
                      puerta.latency = 0;
                 end
                 k = 1;
            end
        end
        results.duringCS.tpuerta.CS1(i,1) = puerta.tacumulado;
        results.duringCS.npuerta.CS1(i,1) = puerta.cantidad;
        results.duringCS.lpuerta.CS1(i,1) = puerta.latency;
    end
    % Durante el CS-
    for i = 1:length(CS2.start);
        puerta.tacumulado = 0;
        puerta.cantidad = 0;
        k = 0;
        puerta.latency = 10000; % Latencia cuando no hay ningun caso de nosepoke
        for j = 1:length(IR2.start);
            % Si el nosepoke inicia luego del onset del CS y termina antes del offset del CS.
            if IR2.start(j) >= CS2.start(i) && IR2.end(j) <= CS2.end(i);
                 puerta.tacumulado = puerta.tacumulado + IR2.duration(j);
                 puerta.cantidad = puerta.cantidad + 1;
                 if k == 0;
                      puerta.latency = IR2.start(j) - CS2.start(i);
                 end
                 k = 1;
            end
            % Si el nosepoke inicia durante el CS pero termina luego del offset del CS.
            if IR2.start(j) >= CS2.start(i) && IR2.start(j) < CS2.end(i) && IR2.end(j) > CS2.end(i);
                 puerta.tacumulado = puerta.tacumulado + (CS2.end(i) - IR2.start(j));
                 puerta.cantidad = puerta.cantidad + 1;
                 if k == 0;
                      puerta.latency = IR2.start(j) - CS2.start(i);
                 end
                 k = 1;
            end
            % Si el nosepoke inicia antes del onset del CS pero termina durante CS.
            if IR2.start(j) < CS2.start(i) && IR2.end(j) > CS2.start(i) && IR2.end(j) <= CS2.end(i);
                 puerta.tacumulado = puerta.tacumulado + (IR2.end(j) - CS2.start(i));
                 puerta.cantidad = puerta.cantidad + 1;
                 if k == 0;
                      puerta.latency = 0;
                 end
                 k = 1;
            end
            % Si el nosepoke inicia antes del onset del CS y termina despues del offset del CS.
            if IR2.start(j) < CS2.start(i) && IR2.end(j) > CS2.end(i);
                 puerta.tacumulado = puerta.tacumulado + 10000;
                 puerta.cantidad = puerta.cantidad + 1;
                 if k == 0;
                      puerta.latency = 0;
                 end
                 k = 1;
            end
        end
        results.duringCS.tpuerta.CS2(i,1) = puerta.tacumulado;
        results.duringCS.npuerta.CS2(i,1) = puerta.cantidad;
        results.duringCS.lpuerta.CS2(i,1) = puerta.latency;
    end
    % Post CS+  ---> 10 seg post CS+
    for i = 1:length(CS1.start);
        puerta.tacumulado = 0;
        puerta.cantidad = 0;
        k = 0;
        puerta.latency = 10000; % Latencia cuando no hay ningun caso de nosepoke
        for j = 1:length(IR2.start);
            % Si el nosepoke inicia luego del offset del CS y termina antes de los 10 seg.
            if IR2.start(j) >= CS1.end(i) && IR2.end(j) <= (CS1.end(i) + 10000);
                 puerta.tacumulado = puerta.tacumulado + IR2.duration(j);
                 puerta.cantidad = puerta.cantidad + 1;
                 if k == 0;
                      puerta.latency = IR2.start(j) - CS1.end(i);
                 end
                 k = 1;
            end
            % Si el nosepoke inicia luego del offset del CS y termina despues de los 10 seg.
            if IR2.start(j) >= CS1.end(i) && IR2.start(j) <= (CS1.end(i) + 10000) && IR2.end(j) > (CS1.end(i) + 10000);
                 puerta.tacumulado = puerta.tacumulado + ((CS1.end(i) + 10000) - IR2.start(j));
                 puerta.cantidad = puerta.cantidad + 1;
                 if k == 0;
                      puerta.latency = IR2.start(j) - CS1.end(i);
                 end
                 k = 1;
            end
            % Si el nosepoke inicia antes del offset del CS y termina antes de los 10 seg.
            if IR2.start(j) < CS1.end(i) && IR2.end(j) > CS1.end(i) && IR2.end(j) <= (CS1.end(i) + 10000);
                 puerta.tacumulado = puerta.tacumulado + (IR2.end(j) - CS1.end(i));
                 puerta.cantidad = puerta.cantidad + 1;
                 if k == 0;
                      puerta.latency = 0;
                 end
                 k = 1;
            end
            % Si el nosepoke inicia antes del offset del CS y termina despues de los 10 seg.
            if IR2.start(j) < CS1.end(i) && IR2.end(j) > (CS1.end(i) + 10000);
                 puerta.tacumulado = puerta.tacumulado + 10000;
                 puerta.cantidad = puerta.cantidad + 1;
                 if k == 0;
                      puerta.latency = 0;
                 end
                 k = 1;
            end
        end
        results.postCS.tpuerta.CS1(i,1) = puerta.tacumulado;
        results.postCS.npuerta.CS1(i,1) = puerta.cantidad;
        results.postCS.lpuerta.CS1(i,1) = puerta.latency;
    end
    % Post CS-  ---> 10 seg post CS-
    for i = 1:length(CS2.start);
        puerta.tacumulado = 0;
        puerta.cantidad = 0;
        k = 0;
        puerta.latency = 10000; % Latencia cuando no hay ningun caso de nosepoke
        for j = 1:length(IR2.start);
            % Si el nosepoke inicia luego del offset del CS y termina antes de los 10 seg.
            if IR2.start(j) >= CS2.end(i) && IR2.end(j) <= (CS2.end(i) + 10000);
                 puerta.tacumulado = puerta.tacumulado + IR2.duration(j);
                 puerta.cantidad = puerta.cantidad + 1;
                 if k == 0;
                      puerta.latency = IR2.start(j) - CS2.end(i);
                 end
                 k = 1;
            end
            % Si el nosepoke inicia luego del offset del CS y termina despues de los 10 seg.
            if IR2.start(j) >= CS2.end(i) && IR2.start(j) <= (CS2.end(i) + 10000) && IR2.end(j) > (CS2.end(i) + 10000);
                 puerta.tacumulado = puerta.tacumulado + ((CS2.end(i) + 10000) - IR2.start(j));
                 puerta.cantidad = puerta.cantidad + 1;
                 if k == 0;
                      puerta.latency = IR2.start(j) - CS2.end(i);
                 end
                 k = 1;
            end
            % Si el nosepoke inicia antes del offset del CS y termina antes de los 10 seg.
            if IR2.start(j) < CS2.end(i) && IR2.end(j) > CS2.end(i) && IR2.end(j) <= (CS2.end(i) + 10000);
                 puerta.tacumulado = puerta.tacumulado + (IR2.end(j) - CS2.end(i));
                 puerta.cantidad = puerta.cantidad + 1;
                 if k == 0;
                      puerta.latency = 0;
                 end
                 k = 1;
            end
            % Si el nosepoke inicia antes del offset del CS y termina despues de los 10 seg.
            if IR2.start(j) < CS2.end(i) && IR2.end(j) > (CS2.end(i) + 10000);
                 puerta.tacumulado = puerta.tacumulado + 10000;
                 puerta.cantidad = puerta.cantidad + 1;
                 if k == 0;
                      puerta.latency = 0;
                 end
                 k = 1;
            end
        end
        results.postCS.tpuerta.CS2(i,1) = puerta.tacumulado;
        results.postCS.npuerta.CS2(i,1) = puerta.cantidad;
        results.postCS.lpuerta.CS2(i,1) = puerta.latency;
    end
    % Pre CS+  ---> 5 seg pre CS+
    for i = 1:length(CS1.start);
        puerta.tacumulado = 0;
        puerta.cantidad = 0;
        k = 0;
        puerta.latency = 10000; % Latencia cuando no hay ningun caso de nosepoke
        for j = 1:length(IR2.start);
            % Si el nosepoke inicia despues de 5 seg pre CS y termina antes del onset del CS
            if IR2.start(j) >= (CS1.start(i) - 10000) && IR2.end(j) <= CS1.start(i);
                 puerta.tacumulado = puerta.tacumulado + IR2.duration(j);
                 puerta.cantidad = puerta.cantidad + 1;
                 if k == 0;
                      puerta.latency = IR2.start(j) - (CS1.start(i) - 10000);
                 end
                 k = 1;
            end
            % Si el nosepoke inicia despues de 5 seg pre CS y termina despues del onset del CS
            if IR2.start(j) >= (CS1.start(i) - 10000) && IR2.start(j) < CS1.start(i) && IR2.end(j) > CS1.start(i);
                 puerta.tacumulado = puerta.tacumulado + (CS1.start(i) - IR2.start(j));
                 puerta.cantidad = puerta.cantidad + 1;
                 if k == 0;
                      puerta.latency = IR2.start(j) - (CS1.start(i) - 10000);
                 end
                 k = 1;
            end
            % Si el nosepoke inicia antes de 5 seg pre CS y termina antes del onset del CS
            if IR2.start(j) < (CS1.start(i) - 10000) && IR2.end(j) > (CS1.start(i) - 10000) && IR2.end(j) <= CS1.start(i);
                 puerta.tacumulado = puerta.tacumulado + (IR2.end(j) - (CS1.start(i) - 10000));
                 puerta.cantidad = puerta.cantidad + 1;
                 if k == 0;
                      puerta.latency = 0;
                 end
                 k = 1;
            end
            % Si el nosepoke inicia antes de 5 seg pre CS y termina despues del onset del CS
            if IR2.start(j) < (CS1.start(i) - 10000) && IR2.end(j) > CS1.start(i);
                 puerta.tacumulado = puerta.tacumulado + 10000;
                 puerta.cantidad = puerta.cantidad + 1;
                 if k == 0;
                      puerta.latency = 0;
                 end
                 k = 1;
            end
        end
        results.preCS.tpuerta.CS1(i,1) = puerta.tacumulado;
        results.preCS.npuerta.CS1(i,1) = puerta.cantidad;
        results.preCS.lpuerta.CS1(i,1) = puerta.latency;
    end
    % Pre CS-  ---> 5 seg pre CS-
    for i = 1:length(CS2.start);
        puerta.tacumulado = 0;
        puerta.cantidad = 0;
        k = 0;
        puerta.latency = 10000; % Latencia cuando no hay ningun caso de nosepoke
        for j = 1:length(IR2.start);
            % Si el nosepoke inicia despues de 5 seg pre CS y termina antes del onset del CS
            if IR2.start(j) >= (CS2.start(i) - 10000) && IR2.end(j) <= CS2.start(i);
                 puerta.tacumulado = puerta.tacumulado + IR2.duration(j);
                 puerta.cantidad = puerta.cantidad + 1;
                 if k == 0;
                      puerta.latency = IR2.start(j) - (CS2.start(i) - 10000);
                 end
                 k = 1;
            end
            % Si el nosepoke inicia despues de 5 seg pre CS y termina despues del onset del CS
            if IR2.start(j) >= (CS2.start(i) - 10000) && IR2.start(j) < CS2.start(i) && IR2.end(j) > CS2.start(i);
                 puerta.tacumulado = puerta.tacumulado + (CS2.start(i) - IR2.start(j));
                 puerta.cantidad = puerta.cantidad + 1;
                 if k == 0;
                      puerta.latency = IR2.start(j) - (CS2.start(i) - 10000);
                 end
                 k = 1;
            end
            % Si el nosepoke inicia antes de 5 seg pre CS y termina antes del onset del CS
            if IR2.start(j) < (CS2.start(i) - 10000) && IR2.end(j) > (CS2.start(i) - 10000) && IR2.end(j) <= CS2.start(i);
                 puerta.tacumulado = puerta.tacumulado + (IR2.end(j) - (CS2.start(i) - 10000));
                 puerta.cantidad = puerta.cantidad + 1;
                 if k == 0;
                      puerta.latency = 0;
                 end
                 k = 1;
            end
            % Si el nosepoke inicia antes de 5 seg pre CS y termina despues del onset del CS
            if IR2.start(j) < (CS2.start(i) - 10000) && IR2.end(j) > CS2.start(i);
                 puerta.tacumulado = puerta.tacumulado + 10000;
                 puerta.cantidad = puerta.cantidad + 1;
                 if k == 0;
                      puerta.latency = 0;
                 end
                 k = 1;
            end
        end
        results.preCS.tpuerta.CS2(i,1) = puerta.tacumulado;
        results.preCS.npuerta.CS2(i,1) = puerta.cantidad;
        results.preCS.lpuerta.CS2(i,1) = puerta.latency;
    end
    
    clear i; clear j; clear k;
    OUTPUT.(name(1:6)) = results;
        
    clear results;              % Borro results para que me calcule valores nuevos en cada folder. Si no hago esto y en esa sesión no tengo todos los trials me va a completar con los resultados del folder anterior.     
        
    end
%     
% clearvars -except path OUTPUT name;
cd(path);
[~,name,~] = fileparts(pwd);
cd(strcat(name,'_Analisis'));

% Formato del OUTPUT
% OUTPUT
        % DayN_RatN
                % duringCS
                % postCS
                % preCS
                        % ttarget
                        % ntarget
                        % ltarget
                        % tpuerta
                        % npuerta
                        % tpuerta
                                % CS1
                                % CS2                         

fields = char(fieldnames(OUTPUT));

for i = 1:length(fields);
    % Rat1
        % target
            % duringCS
                % ttarget
                    Rat1.duringCS.ttarget(:,((i*2)-1)) = OUTPUT.(fields(i,1:end)).duringCS.ttarget.CS1;
                    Rat1.duringCS.ttarget(:,(i*2)) = OUTPUT.(fields(i,1:end)).duringCS.ttarget.CS2;
                % ntarget
                    Rat1.duringCS.ntarget(:,((i*2)-1)) = OUTPUT.(fields(i,1:end)).duringCS.ntarget.CS1;
                    Rat1.duringCS.ntarget(:,(i*2)) = OUTPUT.(fields(i,1:end)).duringCS.ntarget.CS2;
                % ltarget
                    Rat1.duringCS.ltarget(:,((i*2)-1)) = OUTPUT.(fields(i,1:end)).duringCS.ltarget.CS1;
                    Rat1.duringCS.ltarget(:,(i*2)) = OUTPUT.(fields(i,1:end)).duringCS.ltarget.CS2;
            % postCS
                % ttarget
                    Rat1.postCS.ttarget(:,((i*2)-1)) = OUTPUT.(fields(i,1:end)).postCS.ttarget.CS1;
                    Rat1.postCS.ttarget(:,(i*2)) = OUTPUT.(fields(i,1:end)).postCS.ttarget.CS2;
                % ntarget
                    Rat1.postCS.ntarget(:,((i*2)-1)) = OUTPUT.(fields(i,1:end)).postCS.ntarget.CS1;
                    Rat1.postCS.ntarget(:,(i*2)) = OUTPUT.(fields(i,1:end)).postCS.ntarget.CS2;
                % ltarget
                    Rat1.postCS.ltarget(:,((i*2)-1)) = OUTPUT.(fields(i,1:end)).postCS.ltarget.CS1;
                    Rat1.postCS.ltarget(:,(i*2)) = OUTPUT.(fields(i,1:end)).postCS.ltarget.CS2;
            % preCS
                % ttarget
                    Rat1.preCS.ttarget(:,((i*2)-1)) = OUTPUT.(fields(i,1:end)).preCS.ttarget.CS1;
                    Rat1.preCS.ttarget(:,(i*2)) = OUTPUT.(fields(i,1:end)).preCS.ttarget.CS2;
                % ntarget
                    Rat1.preCS.ntarget(:,((i*2)-1)) = OUTPUT.(fields(i,1:end)).preCS.ntarget.CS1;
                    Rat1.preCS.ntarget(:,(i*2)) = OUTPUT.(fields(i,1:end)).preCS.ntarget.CS2;
                % ltarget
                    Rat1.preCS.ltarget(:,((i*2)-1)) = OUTPUT.(fields(i,1:end)).preCS.ltarget.CS1;
                    Rat1.preCS.ltarget(:,(i*2)) = OUTPUT.(fields(i,1:end)).preCS.ltarget.CS2;

        % puerta
            % duringCS
                % tpuerta
                    Rat1.duringCS.tpuerta(:,((i*2)-1)) = OUTPUT.(fields(i,1:end)).duringCS.tpuerta.CS1;
                    Rat1.duringCS.tpuerta(:,(i*2)) = OUTPUT.(fields(i,1:end)).duringCS.tpuerta.CS2;
                % npuerta
                    Rat1.duringCS.npuerta(:,((i*2)-1)) = OUTPUT.(fields(i,1:end)).duringCS.npuerta.CS1;
                    Rat1.duringCS.npuerta(:,(i*2)) = OUTPUT.(fields(i,1:end)).duringCS.npuerta.CS2;
                % lpuerta
                    Rat1.duringCS.lpuerta(:,((i*2)-1)) = OUTPUT.(fields(i,1:end)).duringCS.lpuerta.CS1;
                    Rat1.duringCS.lpuerta(:,(i*2)) = OUTPUT.(fields(i,1:end)).duringCS.lpuerta.CS2;
            % postCS
                % tpuerta
                    Rat1.postCS.tpuerta(:,((i*2)-1)) = OUTPUT.(fields(i,1:end)).postCS.tpuerta.CS1;
                    Rat1.postCS.tpuerta(:,(i*2)) = OUTPUT.(fields(i,1:end)).postCS.tpuerta.CS2;
                % npuerta
                    Rat1.postCS.npuerta(:,((i*2)-1)) = OUTPUT.(fields(i,1:end)).postCS.npuerta.CS1;
                    Rat1.postCS.npuerta(:,(i*2)) = OUTPUT.(fields(i,1:end)).postCS.npuerta.CS2;
                % lpuerta
                    Rat1.postCS.lpuerta(:,((i*2)-1)) = OUTPUT.(fields(i,1:end)).postCS.lpuerta.CS1;
                    Rat1.postCS.lpuerta(:,(i*2)) = OUTPUT.(fields(i,1:end)).postCS.lpuerta.CS2;
            % preCS
                % tpuerta
                    Rat1.preCS.tpuerta(:,((i*2)-1)) = OUTPUT.(fields(i,1:end)).preCS.tpuerta.CS1;
                    Rat1.preCS.tpuerta(:,(i*2)) = OUTPUT.(fields(i,1:end)).preCS.tpuerta.CS2;
                % npuerta
                    Rat1.preCS.npuerta(:,((i*2)-1)) = OUTPUT.(fields(i,1:end)).preCS.npuerta.CS1;
                    Rat1.preCS.npuerta(:,(i*2)) = OUTPUT.(fields(i,1:end)).preCS.npuerta.CS2;
                % lpuerta
                    Rat1.preCS.lpuerta(:,((i*2)-1)) = OUTPUT.(fields(i,1:end)).preCS.lpuerta.CS1;
                    Rat1.preCS.lpuerta(:,(i*2)) = OUTPUT.(fields(i,1:end)).preCS.lpuerta.CS2;
end

% Calculamos el porcentaje de entradas 
Rat1.duringCS.ppuerta = mean(Rat1.duringCS.tpuerta > 0) * 100;
Rat1.duringCS.ptarget = mean(Rat1.duringCS.ttarget > 0) * 100;
Rat1.postCS.ppuerta = mean(Rat1.postCS.tpuerta > 0) * 100;
Rat1.postCS.ptarget = mean(Rat1.postCS.ttarget > 0) * 100;
Rat1.preCS.ppuerta = mean(Rat1.preCS.tpuerta > 0) * 100;
Rat1.preCS.ptarget = mean(Rat1.preCS.ttarget > 0) * 100;

% Convertimos todo a doubles
Rat1.duringCS.ttarget = double(Rat1.duringCS.ttarget);
Rat1.duringCS.ltarget = double(Rat1.duringCS.ltarget);
Rat1.duringCS.ntarget = double(Rat1.duringCS.ntarget);
Rat1.duringCS.ptarget = double(Rat1.duringCS.ptarget);
Rat1.duringCS.tpuerta = double(Rat1.duringCS.tpuerta);
Rat1.duringCS.lpuerta = double(Rat1.duringCS.lpuerta);
Rat1.duringCS.npuerta = double(Rat1.duringCS.npuerta);
Rat1.duringCS.ppuerta = double(Rat1.duringCS.ppuerta);

Rat1.preCS.ttarget = double(Rat1.preCS.ttarget);
Rat1.preCS.ltarget = double(Rat1.preCS.ltarget);
Rat1.preCS.ntarget = double(Rat1.preCS.ntarget);
Rat1.preCS.ptarget = double(Rat1.preCS.ptarget);
Rat1.preCS.tpuerta = double(Rat1.preCS.tpuerta);
Rat1.preCS.lpuerta = double(Rat1.preCS.lpuerta);
Rat1.preCS.npuerta = double(Rat1.preCS.npuerta);
Rat1.preCS.ppuerta = double(Rat1.preCS.ppuerta);

Rat1.postCS.ttarget = double(Rat1.postCS.ttarget);
Rat1.postCS.ltarget = double(Rat1.postCS.ltarget);
Rat1.postCS.ntarget = double(Rat1.postCS.ntarget);
Rat1.postCS.ptarget = double(Rat1.postCS.ptarget);
Rat1.postCS.tpuerta = double(Rat1.postCS.tpuerta);
Rat1.postCS.lpuerta = double(Rat1.postCS.lpuerta);
Rat1.postCS.npuerta = double(Rat1.postCS.npuerta);
Rat1.postCS.ppuerta = double(Rat1.postCS.ppuerta);

cd(path);
[~,name,~] = fileparts(pwd);
cd(strcat(name,'_Analisis'));

% tpuerta
clear data1 data2 data3
data1 = double(Rat1.duringCS.tpuerta); 
data2 = double(Rat1.preCS.tpuerta);
data1 = mean(data1,1)';
data2 = mean(data2,1)';
data3(:,1) = data2(1:2:end,:);
data3(:,2) = data2(2:2:end,:);
data3 = mean(data3,2);
behaviour.tpuerta(:,1) = data1(1:2:end,:);
behaviour.tpuerta(:,2) = data1(2:2:end,:);
behaviour.tpuerta(:,3) = data3;

% ttarget
clear data1 data2 data3
data1 = double(Rat1.duringCS.ttarget); 
data2 = double(Rat1.preCS.ttarget);
data1 = mean(data1,1)';
data2 = mean(data2,1)';
data3(:,1) = data2(1:2:end,:);
data3(:,2) = data2(2:2:end,:);
data3 = mean(data3,2);
behaviour.ttarget(:,1) = data1(1:2:end,:);
behaviour.ttarget(:,2) = data1(2:2:end,:);
behaviour.ttarget(:,3) = data3;

% npuerta
clear data1 data2 data3
data1 = double(Rat1.duringCS.npuerta); 
data2 = double(Rat1.preCS.npuerta);
data1 = mean(data1,1)';
data2 = mean(data2,1)';
data3(:,1) = data2(1:2:end,:);
data3(:,2) = data2(2:2:end,:);
data3 = mean(data3,2);
behaviour.npuerta(:,1) = data1(1:2:end,:);
behaviour.npuerta(:,2) = data1(2:2:end,:);
behaviour.npuerta(:,3) = data3;
behaviour.npuerta = round(behaviour.npuerta);

% ntarget
clear data1 data2 data3
data1 = double(Rat1.duringCS.ntarget); 
data2 = double(Rat1.preCS.ntarget);
data1 = mean(data1,1)';
data2 = mean(data2,1)';
data3(:,1) = data2(1:2:end,:);
data3(:,2) = data2(2:2:end,:);
data3 = mean(data3,2);
behaviour.ntarget(:,1) = data1(1:2:end,:);
behaviour.ntarget(:,2) = data1(2:2:end,:);
behaviour.ntarget(:,3) = data3;
behaviour.ntarget = round(behaviour.ntarget);

% lpuerta
clear data1 data2 data3
data1 = double(Rat1.duringCS.lpuerta); 
data2 = double(Rat1.preCS.lpuerta);
data1 = mean(data1,1)';
data2 = mean(data2,1)';
data3(:,1) = data2(1:2:end,:);
data3(:,2) = data2(2:2:end,:);
data3 = mean(data3,2);
behaviour.lpuerta(:,1) = data1(1:2:end,:);
behaviour.lpuerta(:,2) = data1(2:2:end,:);
behaviour.lpuerta(:,3) = data3;

% ltarget
clear data1 data2 data3
data1 = double(Rat1.duringCS.ltarget); 
data2 = double(Rat1.preCS.ltarget);
data1 = mean(data1,1)';
data2 = mean(data2,1)';
data3(:,1) = data2(1:2:end,:);
data3(:,2) = data2(2:2:end,:);
data3 = mean(data3,2);
behaviour.ltarget(:,1) = data1(1:2:end,:);
behaviour.ltarget(:,2) = data1(2:2:end,:);
behaviour.ltarget(:,3) = data3;

% ppuerta
clear data1 data2 data3
data1 = double(Rat1.duringCS.ppuerta); 
data2 = double(Rat1.preCS.ppuerta);
data1 = mean(data1,1)';
data2 = mean(data2,1)';
data3(:,1) = data2(1:2:end,:);
data3(:,2) = data2(2:2:end,:);
data3 = mean(data3,2);
behaviour.ppuerta(:,1) = data1(1:2:end,:);
behaviour.ppuerta(:,2) = data1(2:2:end,:);
behaviour.ppuerta(:,3) = data3;

% ptarget
clear data1 data2 data3
data1 = double(Rat1.duringCS.ptarget); 
data2 = double(Rat1.preCS.ptarget);
data1 = mean(data1,1)';
data2 = mean(data2,1)';
data3(:,1) = data2(1:2:end,:);
data3(:,2) = data2(2:2:end,:);
data3 = mean(data3,2);
behaviour.ptarget(:,1) = data1(1:2:end,:);
behaviour.ptarget(:,2) = data1(2:2:end,:);
behaviour.ptarget(:,3) = data3;
clear data1 data2 data3

% Calculamos el comportamiento pero binneado de a 5 trials
data = Rat1.duringCS.ttarget ; binned_behaviour.duringCS.ttarget = reshape(mean(reshape(data, [5, 12, size(data, 2)]), 1), [12, size(data, 2)]); clear data;
data = Rat1.duringCS.tpuerta ; binned_behaviour.duringCS.tpuerta = reshape(mean(reshape(data, [5, 12, size(data, 2)]), 1), [12, size(data, 2)]); clear data;
data = Rat1.duringCS.ntarget ; binned_behaviour.duringCS.ntarget = reshape(mean(reshape(data, [5, 12, size(data, 2)]), 1), [12, size(data, 2)]); clear data;
data = Rat1.duringCS.npuerta ; binned_behaviour.duringCS.npuerta = reshape(mean(reshape(data, [5, 12, size(data, 2)]), 1), [12, size(data, 2)]); clear data;
data = Rat1.duringCS.ltarget ; binned_behaviour.duringCS.ltarget = reshape(mean(reshape(data, [5, 12, size(data, 2)]), 1), [12, size(data, 2)]); clear data;
data = Rat1.duringCS.lpuerta ; binned_behaviour.duringCS.lpuerta = reshape(mean(reshape(data, [5, 12, size(data, 2)]), 1), [12, size(data, 2)]); clear data;

data = Rat1.preCS.ttarget ; binned_behaviour.preCS.ttarget = reshape(mean(reshape(data, [5, 12, size(data, 2)]), 1), [12, size(data, 2)]); clear data;
data = Rat1.preCS.tpuerta ; binned_behaviour.preCS.tpuerta = reshape(mean(reshape(data, [5, 12, size(data, 2)]), 1), [12, size(data, 2)]); clear data;
data = Rat1.preCS.ntarget ; binned_behaviour.preCS.ntarget = reshape(mean(reshape(data, [5, 12, size(data, 2)]), 1), [12, size(data, 2)]); clear data;
data = Rat1.preCS.npuerta ; binned_behaviour.preCS.npuerta = reshape(mean(reshape(data, [5, 12, size(data, 2)]), 1), [12, size(data, 2)]); clear data;
data = Rat1.preCS.ltarget ; binned_behaviour.preCS.ltarget = reshape(mean(reshape(data, [5, 12, size(data, 2)]), 1), [12, size(data, 2)]); clear data;
data = Rat1.preCS.lpuerta ; binned_behaviour.preCS.lpuerta = reshape(mean(reshape(data, [5, 12, size(data, 2)]), 1), [12, size(data, 2)]); clear data;

data = Rat1.postCS.ttarget ; binned_behaviour.postCS.ttarget = reshape(mean(reshape(data, [5, 12, size(data, 2)]), 1), [12, size(data, 2)]); clear data;
data = Rat1.postCS.tpuerta ; binned_behaviour.postCS.tpuerta = reshape(mean(reshape(data, [5, 12, size(data, 2)]), 1), [12, size(data, 2)]); clear data;
data = Rat1.postCS.ntarget ; binned_behaviour.postCS.ntarget = reshape(mean(reshape(data, [5, 12, size(data, 2)]), 1), [12, size(data, 2)]); clear data;
data = Rat1.postCS.npuerta ; binned_behaviour.postCS.npuerta = reshape(mean(reshape(data, [5, 12, size(data, 2)]), 1), [12, size(data, 2)]); clear data;
data = Rat1.postCS.ltarget ; binned_behaviour.postCS.ltarget = reshape(mean(reshape(data, [5, 12, size(data, 2)]), 1), [12, size(data, 2)]); clear data;
data = Rat1.postCS.lpuerta ; binned_behaviour.postCS.lpuerta = reshape(mean(reshape(data, [5, 12, size(data, 2)]), 1), [12, size(data, 2)]); clear data;

% Borro algunas variables que no sirve y guardo los resultados
clearvars -except behaviour CS1 CS2 dfolders fields IR2 IR3 name OUTPUT path Rat1 TTL binned_behaviour
cd(path);
[~,name,~] = fileparts(pwd);
cd(strcat(name,'_Analisis'));
save(strcat(name,'_behaviour.mat'));
cd(path);
disp(strcat(name,'_behaviour.mat already saved!'));