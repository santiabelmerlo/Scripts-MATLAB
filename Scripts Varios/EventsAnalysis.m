%% Analizamos todas las carpetas. Genero un OUTPUT con todos los resultados en ms.
% Análisis al 26/05/2022 para analizar 1 sola rata implantada.

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

%
[filpath,name,ext] = fileparts(cd); clear ext; clear filpath;
d = dir(cd); dfolders = d([d(:).isdir]); dfolders = dfolders(~ismember({dfolders(:).name},{'.','..'}));

% a = [5,7,9,10,11,12]; % Rat2
% %a = [3,5,7,9,11,13,15,17]; % Rat1

% results = [];

 for a = 3:length(dfolders);
    path1 = [path dfolders(a).name;];
    name = dfolders(a).name;
    cd(path1);
    cd('./Record Node 124/experiment1/recording1/events/Rhythm_FPGA-123.0/TTL_1/');

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
        target.latency = NaN; % Latencia cuando no hay ningun caso de nosepoke
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
        target.latency = NaN; % Latencia cuando no hay ningun caso de nosepoke
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
        target.latency = NaN; % Latencia cuando no hay ningun caso de nosepoke
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
        target.latency = NaN; % Latencia cuando no hay ningun caso de nosepoke
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
        target.latency = NaN; % Latencia cuando no hay ningun caso de nosepoke
        for j = 1:length(IR3.start);
            % Si el nosepoke inicia despues de 5 seg pre CS y termina antes del onset del CS
            if IR3.start(j) >= (CS1.start(i) - 5000) && IR3.end(j) <= CS1.start(i);
                 target.tacumulado = target.tacumulado + IR3.duration(j);
                 target.cantidad = target.cantidad + 1;
                 if k == 0;
                      target.latency = IR3.start(j) - (CS1.start(i) - 5000);
                 end
                 k = 1;
            end
            % Si el nosepoke inicia despues de 5 seg pre CS y termina despues del onset del CS
            if IR3.start(j) >= (CS1.start(i) - 5000) && IR3.start(j) < CS1.start(i) && IR3.end(j) > CS1.start(i);
                 target.tacumulado = target.tacumulado + (CS1.start(i) - IR3.start(j));
                 target.cantidad = target.cantidad + 1;
                 if k == 0;
                      target.latency = IR3.start(j) - (CS1.start(i) - 5000);
                 end
                 k = 1;
            end
            % Si el nosepoke inicia antes de 5 seg pre CS y termina antes del onset del CS
            if IR3.start(j) < (CS1.start(i) - 5000) && IR3.end(j) > (CS1.start(i) - 5000) && IR3.end(j) <= CS1.start(i);
                 target.tacumulado = target.tacumulado + (IR3.end(j) - (CS1.start(i) - 5000));
                 target.cantidad = target.cantidad + 1;
                 if k == 0;
                      target.latency = 0;
                 end
                 k = 1;
            end
            % Si el nosepoke inicia antes de 5 seg pre CS y termina despues del onset del CS
            if IR3.start(j) < (CS1.start(i) - 5000) && IR3.end(j) > CS1.start(i);
                 target.tacumulado = target.tacumulado + 5000;
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
        target.latency = NaN; % Latencia cuando no hay ningun caso de nosepoke
        for j = 1:length(IR3.start);
            % Si el nosepoke inicia despues de 5 seg pre CS y termina antes del onset del CS
            if IR3.start(j) >= (CS2.start(i) - 5000) && IR3.end(j) <= CS2.start(i);
                 target.tacumulado = target.tacumulado + IR3.duration(j);
                 target.cantidad = target.cantidad + 1;
                 if k == 0;
                      target.latency = IR3.start(j) - (CS2.start(i) - 5000);
                 end
                 k = 1;
            end
            % Si el nosepoke inicia despues de 5 seg pre CS y termina despues del onset del CS
            if IR3.start(j) >= (CS2.start(i) - 5000) && IR3.start(j) < CS2.start(i) && IR3.end(j) > CS2.start(i);
                 target.tacumulado = target.tacumulado + (CS2.start(i) - IR3.start(j));
                 target.cantidad = target.cantidad + 1;
                 if k == 0;
                      target.latency = IR3.start(j) - (CS2.start(i) - 5000);
                 end
                 k = 1;
            end
            % Si el nosepoke inicia antes de 5 seg pre CS y termina antes del onset del CS
            if IR3.start(j) < (CS2.start(i) - 5000) && IR3.end(j) > (CS2.start(i) - 5000) && IR3.end(j) <= CS2.start(i);
                 target.tacumulado = target.tacumulado + (IR3.end(j) - (CS2.start(i) - 5000));
                 target.cantidad = target.cantidad + 1;
                 if k == 0;
                      target.latency = 0;
                 end
                 k = 1;
            end
            % Si el nosepoke inicia antes de 5 seg pre CS y termina despues del onset del CS
            if IR3.start(j) < (CS2.start(i) - 5000) && IR3.end(j) > CS2.start(i);
                 target.tacumulado = target.tacumulado + 5000;
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
        puerta.latency = NaN; % Latencia cuando no hay ningun caso de nosepoke
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
        puerta.latency = NaN; % Latencia cuando no hay ningun caso de nosepoke
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
        puerta.latency = NaN; % Latencia cuando no hay ningun caso de nosepoke
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
        puerta.latency = NaN; % Latencia cuando no hay ningun caso de nosepoke
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
        puerta.latency = NaN; % Latencia cuando no hay ningun caso de nosepoke
        for j = 1:length(IR2.start);
            % Si el nosepoke inicia despues de 5 seg pre CS y termina antes del onset del CS
            if IR2.start(j) >= (CS1.start(i) - 5000) && IR2.end(j) <= CS1.start(i);
                 puerta.tacumulado = puerta.tacumulado + IR2.duration(j);
                 puerta.cantidad = puerta.cantidad + 1;
                 if k == 0;
                      puerta.latency = IR2.start(j) - (CS1.start(i) - 5000);
                 end
                 k = 1;
            end
            % Si el nosepoke inicia despues de 5 seg pre CS y termina despues del onset del CS
            if IR2.start(j) >= (CS1.start(i) - 5000) && IR2.start(j) < CS1.start(i) && IR2.end(j) > CS1.start(i);
                 puerta.tacumulado = puerta.tacumulado + (CS1.start(i) - IR2.start(j));
                 puerta.cantidad = puerta.cantidad + 1;
                 if k == 0;
                      puerta.latency = IR2.start(j) - (CS1.start(i) - 5000);
                 end
                 k = 1;
            end
            % Si el nosepoke inicia antes de 5 seg pre CS y termina antes del onset del CS
            if IR2.start(j) < (CS1.start(i) - 5000) && IR2.end(j) > (CS1.start(i) - 5000) && IR2.end(j) <= CS1.start(i);
                 puerta.tacumulado = puerta.tacumulado + (IR2.end(j) - (CS1.start(i) - 5000));
                 puerta.cantidad = puerta.cantidad + 1;
                 if k == 0;
                      puerta.latency = 0;
                 end
                 k = 1;
            end
            % Si el nosepoke inicia antes de 5 seg pre CS y termina despues del onset del CS
            if IR2.start(j) < (CS1.start(i) - 5000) && IR2.end(j) > CS1.start(i);
                 puerta.tacumulado = puerta.tacumulado + 5000;
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
        puerta.latency = NaN; % Latencia cuando no hay ningun caso de nosepoke
        for j = 1:length(IR2.start);
            % Si el nosepoke inicia despues de 5 seg pre CS y termina antes del onset del CS
            if IR2.start(j) >= (CS2.start(i) - 5000) && IR2.end(j) <= CS2.start(i);
                 puerta.tacumulado = puerta.tacumulado + IR2.duration(j);
                 puerta.cantidad = puerta.cantidad + 1;
                 if k == 0;
                      puerta.latency = IR2.start(j) - (CS2.start(i) - 5000);
                 end
                 k = 1;
            end
            % Si el nosepoke inicia despues de 5 seg pre CS y termina despues del onset del CS
            if IR2.start(j) >= (CS2.start(i) - 5000) && IR2.start(j) < CS2.start(i) && IR2.end(j) > CS2.start(i);
                 puerta.tacumulado = puerta.tacumulado + (CS2.start(i) - IR2.start(j));
                 puerta.cantidad = puerta.cantidad + 1;
                 if k == 0;
                      puerta.latency = IR2.start(j) - (CS2.start(i) - 5000);
                 end
                 k = 1;
            end
            % Si el nosepoke inicia antes de 5 seg pre CS y termina antes del onset del CS
            if IR2.start(j) < (CS2.start(i) - 5000) && IR2.end(j) > (CS2.start(i) - 5000) && IR2.end(j) <= CS2.start(i);
                 puerta.tacumulado = puerta.tacumulado + (IR2.end(j) - (CS2.start(i) - 5000));
                 puerta.cantidad = puerta.cantidad + 1;
                 if k == 0;
                      puerta.latency = 0;
                 end
                 k = 1;
            end
            % Si el nosepoke inicia antes de 5 seg pre CS y termina despues del onset del CS
            if IR2.start(j) < (CS2.start(i) - 5000) && IR2.end(j) > CS2.start(i);
                 puerta.tacumulado = puerta.tacumulado + 5000;
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
        if name(5) == '_';
            OUTPUT.(name(1:4)) = results;
        else
            OUTPUT.(name(1:5)) = results;
        end
    
    clear results;              % Borro results para que me calcule valores nuevos en cada folder. Si no hago esto y en esa sesión no tengo todos los trials me va a completar con los resultados del folder anterior.     
        
    end
    
%clearvars -except path OUTPUT;
cd(path);
save(['OUTPUT.mat']);

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
                                
%% Creo las tablas para exportar al Graphpad. 
clear all
clc
path = 'C:/Users/Santiago Abel Merlo/Google drive/Doctorado/Electrofisiología/Experimentos/Vol 4/'; % Path en casa
cd(path);
load(['OUTPUT.mat']);
%%
load(['OUTPUT.mat']);
% Rat1
% target
% duringCS
% ttarget
Rat1.duringCS.ttarget(:,1) = OUTPUT.Day2.duringCS.ttarget.CS1;
Rat1.duringCS.ttarget(:,2) = OUTPUT.Day2.duringCS.ttarget.CS2;
Rat1.duringCS.ttarget(:,3) = OUTPUT.Day3.duringCS.ttarget.CS1;
Rat1.duringCS.ttarget(:,4) = OUTPUT.Day3.duringCS.ttarget.CS2;
Rat1.duringCS.ttarget(:,5) = OUTPUT.Day4.duringCS.ttarget.CS1;
Rat1.duringCS.ttarget(:,6) = OUTPUT.Day4.duringCS.ttarget.CS2;
Rat1.duringCS.ttarget(:,7) = OUTPUT.Day5.duringCS.ttarget.CS1;
Rat1.duringCS.ttarget(:,8) = OUTPUT.Day5.duringCS.ttarget.CS2;
% Rat1.duringCS.ttarget(:,9) = OUTPUT.Day6.duringCS.ttarget.CS1;
% Rat1.duringCS.ttarget(:,10) = OUTPUT.Day6.duringCS.ttarget.CS2;
% Rat1.duringCS.ttarget(:,11) = OUTPUT.Day7.duringCS.ttarget.CS1;
% Rat1.duringCS.ttarget(:,12) = OUTPUT.Day7.duringCS.ttarget.CS2;
% Rat1.duringCS.ttarget(:,13) = OUTPUT.Day8.duringCS.ttarget.CS1;
% Rat1.duringCS.ttarget(:,14) = OUTPUT.Day8.duringCS.ttarget.CS2;
% Rat1.duringCS.ttarget(:,15) = OUTPUT.Day9.duringCS.ttarget.CS1;
% Rat1.duringCS.ttarget(:,16) = OUTPUT.Day9.duringCS.ttarget.CS2;

% ntarget
Rat1.duringCS.ntarget(:,1) = OUTPUT.Day2.duringCS.ntarget.CS1;
Rat1.duringCS.ntarget(:,2) = OUTPUT.Day2.duringCS.ntarget.CS2;
Rat1.duringCS.ntarget(:,3) = OUTPUT.Day3.duringCS.ntarget.CS1;
Rat1.duringCS.ntarget(:,4) = OUTPUT.Day3.duringCS.ntarget.CS2;
Rat1.duringCS.ntarget(:,5) = OUTPUT.Day4.duringCS.ntarget.CS1;
Rat1.duringCS.ntarget(:,6) = OUTPUT.Day4.duringCS.ntarget.CS2;
Rat1.duringCS.ntarget(:,7) = OUTPUT.Day5.duringCS.ntarget.CS1;
Rat1.duringCS.ntarget(:,8) = OUTPUT.Day5.duringCS.ntarget.CS2;
% Rat1.duringCS.ntarget(:,9) = OUTPUT.Day6.duringCS.ntarget.CS1;
% Rat1.duringCS.ntarget(:,10) = OUTPUT.Day6.duringCS.ntarget.CS2;
% Rat1.duringCS.ntarget(:,11) = OUTPUT.Day7.duringCS.ntarget.CS1;
% Rat1.duringCS.ntarget(:,12) = OUTPUT.Day7.duringCS.ntarget.CS2;
% Rat1.duringCS.ntarget(:,13) = OUTPUT.Day8.duringCS.ntarget.CS1;
% Rat1.duringCS.ntarget(:,14) = OUTPUT.Day8.duringCS.ntarget.CS2;
% Rat1.duringCS.ntarget(:,15) = OUTPUT.Day9.duringCS.ntarget.CS1;
% Rat1.duringCS.ntarget(:,16) = OUTPUT.Day9.duringCS.ntarget.CS2;

% ltarget
Rat1.duringCS.ltarget(:,1) = OUTPUT.Day2.duringCS.ltarget.CS1;
Rat1.duringCS.ltarget(:,2) = OUTPUT.Day2.duringCS.ltarget.CS2;
Rat1.duringCS.ltarget(:,3) = OUTPUT.Day3.duringCS.ltarget.CS1;
Rat1.duringCS.ltarget(:,4) = OUTPUT.Day3.duringCS.ltarget.CS2;
Rat1.duringCS.ltarget(:,5) = OUTPUT.Day4.duringCS.ltarget.CS1;
Rat1.duringCS.ltarget(:,6) = OUTPUT.Day4.duringCS.ltarget.CS2;
Rat1.duringCS.ltarget(:,7) = OUTPUT.Day5.duringCS.ltarget.CS1;
Rat1.duringCS.ltarget(:,8) = OUTPUT.Day5.duringCS.ltarget.CS2;
% Rat1.duringCS.ltarget(:,9) = OUTPUT.Day6.duringCS.ltarget.CS1;
% Rat1.duringCS.ltarget(:,10) = OUTPUT.Day6.duringCS.ltarget.CS2;
% Rat1.duringCS.ltarget(:,11) = OUTPUT.Day7.duringCS.ltarget.CS1;
% Rat1.duringCS.ltarget(:,12) = OUTPUT.Day7.duringCS.ltarget.CS2;
% Rat1.duringCS.ltarget(:,13) = OUTPUT.Day8.duringCS.ltarget.CS1;
% Rat1.duringCS.ltarget(:,14) = OUTPUT.Day8.duringCS.ltarget.CS2;
% Rat1.duringCS.ltarget(:,15) = OUTPUT.Day9.duringCS.ltarget.CS1;
% Rat1.duringCS.ltarget(:,16) = OUTPUT.Day9.duringCS.ltarget.CS2;

% postCS
% ttarget
Rat1.postCS.ttarget(:,1) = OUTPUT.Day2.postCS.ttarget.CS1;
Rat1.postCS.ttarget(:,2) = OUTPUT.Day2.postCS.ttarget.CS2;
Rat1.postCS.ttarget(:,3) = OUTPUT.Day3.postCS.ttarget.CS1;
Rat1.postCS.ttarget(:,4) = OUTPUT.Day3.postCS.ttarget.CS2;
Rat1.postCS.ttarget(:,5) = OUTPUT.Day4.postCS.ttarget.CS1;
Rat1.postCS.ttarget(:,6) = OUTPUT.Day4.postCS.ttarget.CS2;
Rat1.postCS.ttarget(:,7) = OUTPUT.Day5.postCS.ttarget.CS1;
Rat1.postCS.ttarget(:,8) = OUTPUT.Day5.postCS.ttarget.CS2;
% Rat1.postCS.ttarget(:,9) = OUTPUT.Day6.postCS.ttarget.CS1;
% Rat1.postCS.ttarget(:,10) = OUTPUT.Day6.postCS.ttarget.CS2;
% Rat1.postCS.ttarget(:,11) = OUTPUT.Day7.postCS.ttarget.CS1;
% Rat1.postCS.ttarget(:,12) = OUTPUT.Day7.postCS.ttarget.CS2;
% Rat1.postCS.ttarget(:,13) = OUTPUT.Day8.postCS.ttarget.CS1;
% Rat1.postCS.ttarget(:,14) = OUTPUT.Day8.postCS.ttarget.CS2;
% Rat1.postCS.ttarget(:,15) = OUTPUT.Day9.postCS.ttarget.CS1;
% Rat1.postCS.ttarget(:,16) = OUTPUT.Day9.postCS.ttarget.CS2;

% ntarget
Rat1.postCS.ntarget(:,1) = OUTPUT.Day2.postCS.ntarget.CS1;
Rat1.postCS.ntarget(:,2) = OUTPUT.Day2.postCS.ntarget.CS2;
Rat1.postCS.ntarget(:,3) = OUTPUT.Day3.postCS.ntarget.CS1;
Rat1.postCS.ntarget(:,4) = OUTPUT.Day3.postCS.ntarget.CS2;
Rat1.postCS.ntarget(:,5) = OUTPUT.Day4.postCS.ntarget.CS1;
Rat1.postCS.ntarget(:,6) = OUTPUT.Day4.postCS.ntarget.CS2;
Rat1.postCS.ntarget(:,7) = OUTPUT.Day5.postCS.ntarget.CS1;
Rat1.postCS.ntarget(:,8) = OUTPUT.Day5.postCS.ntarget.CS2;
% Rat1.postCS.ntarget(:,9) = OUTPUT.Day6.postCS.ntarget.CS1;
% Rat1.postCS.ntarget(:,10) = OUTPUT.Day6.postCS.ntarget.CS2;
% Rat1.postCS.ntarget(:,11) = OUTPUT.Day7.postCS.ntarget.CS1;
% Rat1.postCS.ntarget(:,12) = OUTPUT.Day7.postCS.ntarget.CS2;
% Rat1.postCS.ntarget(:,13) = OUTPUT.Day8.postCS.ntarget.CS1;
% Rat1.postCS.ntarget(:,14) = OUTPUT.Day8.postCS.ntarget.CS2;
% Rat1.postCS.ntarget(:,15) = OUTPUT.Day9.postCS.ntarget.CS1;
% Rat1.postCS.ntarget(:,16) = OUTPUT.Day9.postCS.ntarget.CS2;

% ltarget
Rat1.postCS.ltarget(:,1) = OUTPUT.Day2.postCS.ltarget.CS1;
Rat1.postCS.ltarget(:,2) = OUTPUT.Day2.postCS.ltarget.CS2;
Rat1.postCS.ltarget(:,3) = OUTPUT.Day3.postCS.ltarget.CS1;
Rat1.postCS.ltarget(:,4) = OUTPUT.Day3.postCS.ltarget.CS2;
Rat1.postCS.ltarget(:,5) = OUTPUT.Day4.postCS.ltarget.CS1;
Rat1.postCS.ltarget(:,6) = OUTPUT.Day4.postCS.ltarget.CS2;
Rat1.postCS.ltarget(:,7) = OUTPUT.Day5.postCS.ltarget.CS1;
Rat1.postCS.ltarget(:,8) = OUTPUT.Day5.postCS.ltarget.CS2;
% Rat1.postCS.ltarget(:,9) = OUTPUT.Day6.postCS.ltarget.CS1;
% Rat1.postCS.ltarget(:,10) = OUTPUT.Day6.postCS.ltarget.CS2;
% Rat1.postCS.ltarget(:,11) = OUTPUT.Day7.postCS.ltarget.CS1;
% Rat1.postCS.ltarget(:,12) = OUTPUT.Day7.postCS.ltarget.CS2;
% Rat1.postCS.ltarget(:,13) = OUTPUT.Day8.postCS.ltarget.CS1;
% Rat1.postCS.ltarget(:,14) = OUTPUT.Day8.postCS.ltarget.CS2;
% Rat1.postCS.ltarget(:,13) = OUTPUT.Day9.postCS.ltarget.CS1;
% Rat1.postCS.ltarget(:,14) = OUTPUT.Day9.postCS.ltarget.CS2;

% preCS
% ttarget
Rat1.preCS.ttarget(:,1) = OUTPUT.Day2.preCS.ttarget.CS1;
Rat1.preCS.ttarget(:,2) = OUTPUT.Day2.preCS.ttarget.CS2;
Rat1.preCS.ttarget(:,3) = OUTPUT.Day3.preCS.ttarget.CS1;
Rat1.preCS.ttarget(:,4) = OUTPUT.Day3.preCS.ttarget.CS2;
Rat1.preCS.ttarget(:,5) = OUTPUT.Day4.preCS.ttarget.CS1;
Rat1.preCS.ttarget(:,6) = OUTPUT.Day4.preCS.ttarget.CS2;
Rat1.preCS.ttarget(:,7) = OUTPUT.Day5.preCS.ttarget.CS1;
Rat1.preCS.ttarget(:,8) = OUTPUT.Day5.preCS.ttarget.CS2;
% Rat1.preCS.ttarget(:,9) = OUTPUT.Day6.preCS.ttarget.CS1;
% Rat1.preCS.ttarget(:,10) = OUTPUT.Day6.preCS.ttarget.CS2;
% Rat1.preCS.ttarget(:,11) = OUTPUT.Day7.preCS.ttarget.CS1;
% Rat1.preCS.ttarget(:,12) = OUTPUT.Day7.preCS.ttarget.CS2;
% Rat1.preCS.ttarget(:,13) = OUTPUT.Day8.preCS.ttarget.CS1;
% Rat1.preCS.ttarget(:,14) = OUTPUT.Day8.preCS.ttarget.CS2;
% Rat1.preCS.ttarget(:,15) = OUTPUT.Day9.preCS.ttarget.CS1;
% Rat1.preCS.ttarget(:,16) = OUTPUT.Day9.preCS.ttarget.CS2;

% ntarget
Rat1.preCS.ntarget(:,1) = OUTPUT.Day2.preCS.ntarget.CS1;
Rat1.preCS.ntarget(:,2) = OUTPUT.Day2.preCS.ntarget.CS2;
Rat1.preCS.ntarget(:,3) = OUTPUT.Day3.preCS.ntarget.CS1;
Rat1.preCS.ntarget(:,4) = OUTPUT.Day3.preCS.ntarget.CS2;
Rat1.preCS.ntarget(:,5) = OUTPUT.Day4.preCS.ntarget.CS1;
Rat1.preCS.ntarget(:,6) = OUTPUT.Day4.preCS.ntarget.CS2;
Rat1.preCS.ntarget(:,7) = OUTPUT.Day5.preCS.ntarget.CS1;
Rat1.preCS.ntarget(:,8) = OUTPUT.Day5.preCS.ntarget.CS2;
% Rat1.preCS.ntarget(:,9) = OUTPUT.Day6.preCS.ntarget.CS1;
% Rat1.preCS.ntarget(:,10) = OUTPUT.Day6.preCS.ntarget.CS2;
% Rat1.preCS.ntarget(:,11) = OUTPUT.Day7.preCS.ntarget.CS1;
% Rat1.preCS.ntarget(:,12) = OUTPUT.Day7.preCS.ntarget.CS2;
% Rat1.preCS.ntarget(:,13) = OUTPUT.Day8.preCS.ntarget.CS1;
% Rat1.preCS.ntarget(:,14) = OUTPUT.Day8.preCS.ntarget.CS2;
% Rat1.preCS.ntarget(:,15) = OUTPUT.Day9.preCS.ntarget.CS1;
% Rat1.preCS.ntarget(:,16) = OUTPUT.Day9.preCS.ntarget.CS2;

% ltarget
Rat1.preCS.ltarget(:,1) = OUTPUT.Day2.preCS.ltarget.CS1;
Rat1.preCS.ltarget(:,2) = OUTPUT.Day2.preCS.ltarget.CS2;
Rat1.preCS.ltarget(:,3) = OUTPUT.Day3.preCS.ltarget.CS1;
Rat1.preCS.ltarget(:,4) = OUTPUT.Day3.preCS.ltarget.CS2;
Rat1.preCS.ltarget(:,5) = OUTPUT.Day4.preCS.ltarget.CS1;
Rat1.preCS.ltarget(:,6) = OUTPUT.Day4.preCS.ltarget.CS2;
Rat1.preCS.ltarget(:,7) = OUTPUT.Day5.preCS.ltarget.CS1;
Rat1.preCS.ltarget(:,8) = OUTPUT.Day5.preCS.ltarget.CS2;
% Rat1.preCS.ltarget(:,9) = OUTPUT.Day6.preCS.ltarget.CS1;
% Rat1.preCS.ltarget(:,10) = OUTPUT.Day6.preCS.ltarget.CS2;
% Rat1.preCS.ltarget(:,11) = OUTPUT.Day7.preCS.ltarget.CS1;
% Rat1.preCS.ltarget(:,12) = OUTPUT.Day7.preCS.ltarget.CS2;
% Rat1.preCS.ltarget(:,13) = OUTPUT.Day8.preCS.ltarget.CS1;
% Rat1.preCS.ltarget(:,14) = OUTPUT.Day8.preCS.ltarget.CS2;                               
% Rat1.preCS.ltarget(:,15) = OUTPUT.Day9.preCS.ltarget.CS1;
% Rat1.preCS.ltarget(:,16) = OUTPUT.Day9.preCS.ltarget.CS2;

% puerta
% duringCS
% tpuerta
Rat1.duringCS.tpuerta(:,1) = OUTPUT.Day2.duringCS.tpuerta.CS1;
Rat1.duringCS.tpuerta(:,2) = OUTPUT.Day2.duringCS.tpuerta.CS2;
Rat1.duringCS.tpuerta(:,3) = OUTPUT.Day3.duringCS.tpuerta.CS1;
Rat1.duringCS.tpuerta(:,4) = OUTPUT.Day3.duringCS.tpuerta.CS2;
Rat1.duringCS.tpuerta(:,5) = OUTPUT.Day4.duringCS.tpuerta.CS1;
Rat1.duringCS.tpuerta(:,6) = OUTPUT.Day4.duringCS.tpuerta.CS2;
Rat1.duringCS.tpuerta(:,7) = OUTPUT.Day5.duringCS.tpuerta.CS1;
Rat1.duringCS.tpuerta(:,8) = OUTPUT.Day5.duringCS.tpuerta.CS2;
% Rat1.duringCS.tpuerta(:,9) = OUTPUT.Day6.duringCS.tpuerta.CS1;
% Rat1.duringCS.tpuerta(:,10) = OUTPUT.Day6.duringCS.tpuerta.CS2;
% Rat1.duringCS.tpuerta(:,11) = OUTPUT.Day7.duringCS.tpuerta.CS1;
% Rat1.duringCS.tpuerta(:,12) = OUTPUT.Day7.duringCS.tpuerta.CS2;
% Rat1.duringCS.tpuerta(:,13) = OUTPUT.Day8.duringCS.tpuerta.CS1;
% Rat1.duringCS.tpuerta(:,14) = OUTPUT.Day8.duringCS.tpuerta.CS2;
% Rat1.duringCS.tpuerta(:,15) = OUTPUT.Day9.duringCS.tpuerta.CS1;
% Rat1.duringCS.tpuerta(:,16) = OUTPUT.Day9.duringCS.tpuerta.CS2;

% npuerta
Rat1.duringCS.npuerta(:,1) = OUTPUT.Day2.duringCS.npuerta.CS1;
Rat1.duringCS.npuerta(:,2) = OUTPUT.Day2.duringCS.npuerta.CS2;
Rat1.duringCS.npuerta(:,3) = OUTPUT.Day3.duringCS.npuerta.CS1;
Rat1.duringCS.npuerta(:,4) = OUTPUT.Day3.duringCS.npuerta.CS2;
Rat1.duringCS.npuerta(:,5) = OUTPUT.Day4.duringCS.npuerta.CS1;
Rat1.duringCS.npuerta(:,6) = OUTPUT.Day4.duringCS.npuerta.CS2;
Rat1.duringCS.npuerta(:,7) = OUTPUT.Day5.duringCS.npuerta.CS1;
Rat1.duringCS.npuerta(:,8) = OUTPUT.Day5.duringCS.npuerta.CS2;
% Rat1.duringCS.npuerta(:,9) = OUTPUT.Day6.duringCS.npuerta.CS1;
% Rat1.duringCS.npuerta(:,10) = OUTPUT.Day6.duringCS.npuerta.CS2;
% Rat1.duringCS.npuerta(:,11) = OUTPUT.Day7.duringCS.npuerta.CS1;
% Rat1.duringCS.npuerta(:,12) = OUTPUT.Day7.duringCS.npuerta.CS2;
% Rat1.duringCS.npuerta(:,13) = OUTPUT.Day8.duringCS.npuerta.CS1;
% Rat1.duringCS.npuerta(:,14) = OUTPUT.Day8.duringCS.npuerta.CS2;
% Rat1.duringCS.npuerta(:,15) = OUTPUT.Day9.duringCS.npuerta.CS1;
% Rat1.duringCS.npuerta(:,16) = OUTPUT.Day9.duringCS.npuerta.CS2;

% lpuerta
Rat1.duringCS.lpuerta(:,1) = OUTPUT.Day2.duringCS.lpuerta.CS1;
Rat1.duringCS.lpuerta(:,2) = OUTPUT.Day2.duringCS.lpuerta.CS2;
Rat1.duringCS.lpuerta(:,3) = OUTPUT.Day3.duringCS.lpuerta.CS1;
Rat1.duringCS.lpuerta(:,4) = OUTPUT.Day3.duringCS.lpuerta.CS2;
Rat1.duringCS.lpuerta(:,5) = OUTPUT.Day4.duringCS.lpuerta.CS1;
Rat1.duringCS.lpuerta(:,6) = OUTPUT.Day4.duringCS.lpuerta.CS2;
Rat1.duringCS.lpuerta(:,7) = OUTPUT.Day5.duringCS.lpuerta.CS1;
Rat1.duringCS.lpuerta(:,8) = OUTPUT.Day5.duringCS.lpuerta.CS2;
% Rat1.duringCS.lpuerta(:,9) = OUTPUT.Day6.duringCS.lpuerta.CS1;
% Rat1.duringCS.lpuerta(:,10) = OUTPUT.Day6.duringCS.lpuerta.CS2;
% Rat1.duringCS.lpuerta(:,11) = OUTPUT.Day7.duringCS.lpuerta.CS1;
% Rat1.duringCS.lpuerta(:,12) = OUTPUT.Day7.duringCS.lpuerta.CS2;
% Rat1.duringCS.lpuerta(:,13) = OUTPUT.Day8.duringCS.lpuerta.CS1;
% Rat1.duringCS.lpuerta(:,14) = OUTPUT.Day8.duringCS.lpuerta.CS2;
% Rat1.duringCS.lpuerta(:,15) = OUTPUT.Day9.duringCS.lpuerta.CS1;
% Rat1.duringCS.lpuerta(:,16) = OUTPUT.Day9.duringCS.lpuerta.CS2;

% postCS
% tpuerta
Rat1.postCS.tpuerta(:,1) = OUTPUT.Day2.postCS.tpuerta.CS1;
Rat1.postCS.tpuerta(:,2) = OUTPUT.Day2.postCS.tpuerta.CS2;
Rat1.postCS.tpuerta(:,3) = OUTPUT.Day3.postCS.tpuerta.CS1;
Rat1.postCS.tpuerta(:,4) = OUTPUT.Day3.postCS.tpuerta.CS2;
Rat1.postCS.tpuerta(:,5) = OUTPUT.Day4.postCS.tpuerta.CS1;
Rat1.postCS.tpuerta(:,6) = OUTPUT.Day4.postCS.tpuerta.CS2;
Rat1.postCS.tpuerta(:,7) = OUTPUT.Day5.postCS.tpuerta.CS1;
Rat1.postCS.tpuerta(:,8) = OUTPUT.Day5.postCS.tpuerta.CS2;
% Rat1.postCS.tpuerta(:,9) = OUTPUT.Day6.postCS.tpuerta.CS1;
% Rat1.postCS.tpuerta(:,10) = OUTPUT.Day6.postCS.tpuerta.CS2;
% Rat1.postCS.tpuerta(:,11) = OUTPUT.Day7.postCS.tpuerta.CS1;
% Rat1.postCS.tpuerta(:,12) = OUTPUT.Day7.postCS.tpuerta.CS2;
% Rat1.postCS.tpuerta(:,13) = OUTPUT.Day8.postCS.tpuerta.CS1;
% Rat1.postCS.tpuerta(:,14) = OUTPUT.Day8.postCS.tpuerta.CS2;
% Rat1.postCS.tpuerta(:,15) = OUTPUT.Day9.postCS.tpuerta.CS1;
% Rat1.postCS.tpuerta(:,16) = OUTPUT.Day9.postCS.tpuerta.CS2;

% npuerta
Rat1.postCS.npuerta(:,1) = OUTPUT.Day2.postCS.npuerta.CS1;
Rat1.postCS.npuerta(:,2) = OUTPUT.Day2.postCS.npuerta.CS2;
Rat1.postCS.npuerta(:,3) = OUTPUT.Day3.postCS.npuerta.CS1;
Rat1.postCS.npuerta(:,4) = OUTPUT.Day3.postCS.npuerta.CS2;
Rat1.postCS.npuerta(:,5) = OUTPUT.Day4.postCS.npuerta.CS1;
Rat1.postCS.npuerta(:,6) = OUTPUT.Day4.postCS.npuerta.CS2;
Rat1.postCS.npuerta(:,7) = OUTPUT.Day5.postCS.npuerta.CS1;
Rat1.postCS.npuerta(:,8) = OUTPUT.Day5.postCS.npuerta.CS2;
% Rat1.postCS.npuerta(:,9) = OUTPUT.Day6.postCS.npuerta.CS1;
% Rat1.postCS.npuerta(:,10) = OUTPUT.Day6.postCS.npuerta.CS2;
% Rat1.postCS.npuerta(:,11) = OUTPUT.Day7.postCS.npuerta.CS1;
% Rat1.postCS.npuerta(:,12) = OUTPUT.Day7.postCS.npuerta.CS2;
% Rat1.postCS.npuerta(:,13) = OUTPUT.Day8.postCS.npuerta.CS1;
% Rat1.postCS.npuerta(:,14) = OUTPUT.Day8.postCS.npuerta.CS2;
% Rat1.postCS.npuerta(:,15) = OUTPUT.Day9.postCS.npuerta.CS1;
% Rat1.postCS.npuerta(:,16) = OUTPUT.Day9.postCS.npuerta.CS2;

% lpuerta
Rat1.postCS.lpuerta(:,1) = OUTPUT.Day2.postCS.lpuerta.CS1;
Rat1.postCS.lpuerta(:,2) = OUTPUT.Day2.postCS.lpuerta.CS2;
Rat1.postCS.lpuerta(:,3) = OUTPUT.Day3.postCS.lpuerta.CS1;
Rat1.postCS.lpuerta(:,4) = OUTPUT.Day3.postCS.lpuerta.CS2;
Rat1.postCS.lpuerta(:,5) = OUTPUT.Day4.postCS.lpuerta.CS1;
Rat1.postCS.lpuerta(:,6) = OUTPUT.Day4.postCS.lpuerta.CS2;
Rat1.postCS.lpuerta(:,7) = OUTPUT.Day5.postCS.lpuerta.CS1;
Rat1.postCS.lpuerta(:,8) = OUTPUT.Day5.postCS.lpuerta.CS2;
% Rat1.postCS.lpuerta(:,9) = OUTPUT.Day6.postCS.lpuerta.CS1;
% Rat1.postCS.lpuerta(:,10) = OUTPUT.Day6.postCS.lpuerta.CS2;
% Rat1.postCS.lpuerta(:,11) = OUTPUT.Day7.postCS.lpuerta.CS1;
% Rat1.postCS.lpuerta(:,12) = OUTPUT.Day7.postCS.lpuerta.CS2;
% Rat1.postCS.lpuerta(:,13) = OUTPUT.Day8.postCS.lpuerta.CS1;
% Rat1.postCS.lpuerta(:,14) = OUTPUT.Day8.postCS.lpuerta.CS2;
% Rat1.postCS.lpuerta(:,15) = OUTPUT.Day9.postCS.lpuerta.CS1;
% Rat1.postCS.lpuerta(:,16) = OUTPUT.Day9.postCS.lpuerta.CS2;

% preCS
% tpuerta
Rat1.preCS.tpuerta(:,1) = OUTPUT.Day2.preCS.tpuerta.CS1;
Rat1.preCS.tpuerta(:,2) = OUTPUT.Day2.preCS.tpuerta.CS2;
Rat1.preCS.tpuerta(:,3) = OUTPUT.Day3.preCS.tpuerta.CS1;
Rat1.preCS.tpuerta(:,4) = OUTPUT.Day3.preCS.tpuerta.CS2;
Rat1.preCS.tpuerta(:,5) = OUTPUT.Day4.preCS.tpuerta.CS1;
Rat1.preCS.tpuerta(:,6) = OUTPUT.Day4.preCS.tpuerta.CS2;
Rat1.preCS.tpuerta(:,7) = OUTPUT.Day5.preCS.tpuerta.CS1;
Rat1.preCS.tpuerta(:,8) = OUTPUT.Day5.preCS.tpuerta.CS2;
% Rat1.preCS.tpuerta(:,9) = OUTPUT.Day6.preCS.tpuerta.CS1;
% Rat1.preCS.tpuerta(:,10) = OUTPUT.Day6.preCS.tpuerta.CS2;
% Rat1.preCS.tpuerta(:,11) = OUTPUT.Day7.preCS.tpuerta.CS1;
% Rat1.preCS.tpuerta(:,12) = OUTPUT.Day7.preCS.tpuerta.CS2;
% Rat1.preCS.tpuerta(:,13) = OUTPUT.Day8.preCS.tpuerta.CS1;
% Rat1.preCS.tpuerta(:,14) = OUTPUT.Day8.preCS.tpuerta.CS2;
% Rat1.preCS.tpuerta(:,15) = OUTPUT.Day9.preCS.tpuerta.CS1;
% Rat1.preCS.tpuerta(:,16) = OUTPUT.Day9.preCS.tpuerta.CS2;

% npuerta
Rat1.preCS.npuerta(:,1) = OUTPUT.Day2.preCS.npuerta.CS1;
Rat1.preCS.npuerta(:,2) = OUTPUT.Day2.preCS.npuerta.CS2;
Rat1.preCS.npuerta(:,3) = OUTPUT.Day3.preCS.npuerta.CS1;
Rat1.preCS.npuerta(:,4) = OUTPUT.Day3.preCS.npuerta.CS2;
Rat1.preCS.npuerta(:,5) = OUTPUT.Day4.preCS.npuerta.CS1;
Rat1.preCS.npuerta(:,6) = OUTPUT.Day4.preCS.npuerta.CS2;
Rat1.preCS.npuerta(:,7) = OUTPUT.Day5.preCS.npuerta.CS1;
Rat1.preCS.npuerta(:,8) = OUTPUT.Day5.preCS.npuerta.CS2;
% Rat1.preCS.npuerta(:,9) = OUTPUT.Day6.preCS.npuerta.CS1;
% Rat1.preCS.npuerta(:,10) = OUTPUT.Day6.preCS.npuerta.CS2;
% Rat1.preCS.npuerta(:,11) = OUTPUT.Day7.preCS.npuerta.CS1;
% Rat1.preCS.npuerta(:,12) = OUTPUT.Day7.preCS.npuerta.CS2;
% Rat1.preCS.npuerta(:,13) = OUTPUT.Day8.preCS.npuerta.CS1;
% Rat1.preCS.npuerta(:,14) = OUTPUT.Day8.preCS.npuerta.CS2;
% Rat1.preCS.npuerta(:,15) = OUTPUT.Day9.preCS.npuerta.CS1;
% Rat1.preCS.npuerta(:,16) = OUTPUT.Day9.preCS.npuerta.CS2;

% lpuerta
Rat1.preCS.lpuerta(:,1) = OUTPUT.Day2.preCS.lpuerta.CS1;
Rat1.preCS.lpuerta(:,2) = OUTPUT.Day2.preCS.lpuerta.CS2;
Rat1.preCS.lpuerta(:,3) = OUTPUT.Day3.preCS.lpuerta.CS1;
Rat1.preCS.lpuerta(:,4) = OUTPUT.Day3.preCS.lpuerta.CS2;
Rat1.preCS.lpuerta(:,5) = OUTPUT.Day4.preCS.lpuerta.CS1;
Rat1.preCS.lpuerta(:,6) = OUTPUT.Day4.preCS.lpuerta.CS2;
Rat1.preCS.lpuerta(:,7) = OUTPUT.Day5.preCS.lpuerta.CS1;
Rat1.preCS.lpuerta(:,8) = OUTPUT.Day5.preCS.lpuerta.CS2;
% Rat1.preCS.lpuerta(:,9) = OUTPUT.Day6.preCS.lpuerta.CS1;
% Rat1.preCS.lpuerta(:,10) = OUTPUT.Day6.preCS.lpuerta.CS2;
% Rat1.preCS.lpuerta(:,11) = OUTPUT.Day7.preCS.lpuerta.CS1;
% Rat1.preCS.lpuerta(:,12) = OUTPUT.Day7.preCS.lpuerta.CS2;
% Rat1.preCS.lpuerta(:,13) = OUTPUT.Day8.preCS.lpuerta.CS1;
% Rat1.preCS.lpuerta(:,14) = OUTPUT.Day8.preCS.lpuerta.CS2;
% Rat1.preCS.lpuerta(:,15) = OUTPUT.Day9.preCS.lpuerta.CS1;
% Rat1.preCS.lpuerta(:,16) = OUTPUT.Day9.preCS.lpuerta.CS2;


%% Calculamos el porcentaje de entradas 
Rat1.duringCS.ppuerta = (length(Rat1.duringCS.lpuerta)-sum(isnan(Rat1.duringCS.lpuerta)))/(length(Rat1.duringCS.lpuerta))*100;
Rat1.duringCS.ptarget = (length(Rat1.duringCS.ltarget)-sum(isnan(Rat1.duringCS.ltarget)))/(length(Rat1.duringCS.ltarget))*100;
Rat1.postCS.ppuerta = (length(Rat1.postCS.lpuerta)-sum(isnan(Rat1.postCS.lpuerta)))/(length(Rat1.postCS.lpuerta))*100;
Rat1.postCS.ptarget = (length(Rat1.postCS.ltarget)-sum(isnan(Rat1.postCS.ltarget)))/(length(Rat1.postCS.ltarget))*100;
Rat1.preCS.ppuerta = (length(Rat1.preCS.lpuerta)-sum(isnan(Rat1.preCS.lpuerta)))/(length(Rat1.preCS.lpuerta))*100;
Rat1.preCS.ptarget = (length(Rat1.preCS.ltarget)-sum(isnan(Rat1.preCS.ltarget)))/(length(Rat1.preCS.ltarget))*100;

save(['Rat1.mat']);

%% Generamos los .csv para luego graficarlos en el Graphpad o R.
% Rat1
% duringCS
csvwrite('Rat1_duringCS_ttarget.csv',Rat1.duringCS.ttarget);
csvwrite('Rat1_duringCS_ntarget.csv',Rat1.duringCS.ntarget);
csvwrite('Rat1_duringCS_ltarget.csv',Rat1.duringCS.ltarget);
csvwrite('Rat1_duringCS_ptarget.csv',Rat1.duringCS.ptarget);
csvwrite('Rat1_duringCS_tpuerta.csv',Rat1.duringCS.tpuerta);
csvwrite('Rat1_duringCS_npuerta.csv',Rat1.duringCS.npuerta);
csvwrite('Rat1_duringCS_lpuerta.csv',Rat1.duringCS.lpuerta);
csvwrite('Rat1_duringCS_ppuerta.csv',Rat1.duringCS.ppuerta);
%preCS
csvwrite('Rat1_preCS_ttarget.csv',Rat1.preCS.ttarget);
csvwrite('Rat1_preCS_ntarget.csv',Rat1.preCS.ntarget);
% csvwrite('Rat1_preCS_ltarget.csv',Rat1.preCS.ltarget); % No tiene sentido medir latencia en el preCS
csvwrite('Rat1_preCS_ptarget.csv',Rat1.preCS.ptarget);
csvwrite('Rat1_preCS_tpuerta.csv',Rat1.preCS.tpuerta);
csvwrite('Rat1_preCS_npuerta.csv',Rat1.preCS.npuerta);
% csvwrite('Rat1_preCS_lpuerta.csv',Rat1.preCS.lpuerta); % No tiene sentido medir latencia en el preCS
csvwrite('Rat1_preCS_ppuerta.csv',Rat1.preCS.ppuerta);
%postCS
csvwrite('Rat1_postCS_ttarget.csv',Rat1.postCS.ttarget);
csvwrite('Rat1_postCS_ntarget.csv',Rat1.postCS.ntarget);
csvwrite('Rat1_postCS_ltarget.csv',Rat1.postCS.ltarget);
csvwrite('Rat1_postCS_ptarget.csv',Rat1.postCS.ptarget);
csvwrite('Rat1_postCS_tpuerta.csv',Rat1.postCS.tpuerta);
csvwrite('Rat1_postCS_npuerta.csv',Rat1.postCS.npuerta);
csvwrite('Rat1_postCS_lpuerta.csv',Rat1.postCS.lpuerta);
csvwrite('Rat1_postCS_ppuerta.csv',Rat1.postCS.ppuerta);
%%
% Rat2
% duringCS
csvwrite('Rat2_duringCS_ttarget.csv',Rat2.duringCS.ttarget);
csvwrite('Rat2_duringCS_ntarget.csv',Rat2.duringCS.ntarget);
csvwrite('Rat2_duringCS_ltarget.csv',Rat2.duringCS.ltarget);
csvwrite('Rat2_duringCS_ptarget.csv',Rat2.duringCS.ptarget);
csvwrite('Rat2_duringCS_tpuerta.csv',Rat2.duringCS.tpuerta);
csvwrite('Rat2_duringCS_npuerta.csv',Rat2.duringCS.npuerta);
csvwrite('Rat2_duringCS_lpuerta.csv',Rat2.duringCS.lpuerta);
csvwrite('Rat2_duringCS_ppuerta.csv',Rat2.duringCS.ppuerta);
%preCS
csvwrite('Rat2_preCS_ttarget.csv',Rat2.preCS.ttarget);
csvwrite('Rat2_preCS_ntarget.csv',Rat2.preCS.ntarget);
% csvwrite('Rat2_preCS_ltarget.csv',Rat2.preCS.ltarget); % No tiene sentido medir latencia en el preCS
csvwrite('Rat2_preCS_ptarget.csv',Rat2.preCS.ptarget);
csvwrite('Rat2_preCS_tpuerta.csv',Rat2.preCS.tpuerta);
csvwrite('Rat2_preCS_npuerta.csv',Rat2.preCS.npuerta);
% csvwrite('Rat2_preCS_lpuerta.csv',Rat2.preCS.lpuerta); % No tiene sentido medir latencia en el preCS
csvwrite('Rat2_preCS_ppuerta.csv',Rat2.preCS.ppuerta);
%postCS
csvwrite('Rat2_postCS_ttarget.csv',Rat2.postCS.ttarget);
csvwrite('Rat2_postCS_ntarget.csv',Rat2.postCS.ntarget);
csvwrite('Rat2_postCS_ltarget.csv',Rat2.postCS.ltarget);
csvwrite('Rat2_postCS_ptarget.csv',Rat2.postCS.ptarget);
csvwrite('Rat2_postCS_tpuerta.csv',Rat2.postCS.tpuerta);
csvwrite('Rat2_postCS_npuerta.csv',Rat2.postCS.npuerta);
csvwrite('Rat2_postCS_lpuerta.csv',Rat2.postCS.lpuerta);
csvwrite('Rat2_postCS_ppuerta.csv',Rat2.postCS.ppuerta);

%% Borrar el dato 61 del Day 5 al day 8

OUTPUT.Day5.duringCS.ttarget.CS2(61) = [];
OUTPUT.Day5.duringCS.ntarget.CS2(61) = [];
OUTPUT.Day5.duringCS.ltarget.CS2(61) = [];
OUTPUT.Day5.duringCS.tpuerta.CS2(61) = [];
OUTPUT.Day5.duringCS.npuerta.CS2(61) = [];
OUTPUT.Day5.duringCS.lpuerta.CS2(61) = [];

OUTPUT.Day5.preCS.ttarget.CS2(61) = [];
OUTPUT.Day5.preCS.ntarget.CS2(61) = [];
OUTPUT.Day5.preCS.ltarget.CS2(61) = [];
OUTPUT.Day5.preCS.tpuerta.CS2(61) = [];
OUTPUT.Day5.preCS.npuerta.CS2(61) = [];
OUTPUT.Day5.preCS.lpuerta.CS2(61) = [];

OUTPUT.Day5.postCS.ttarget.CS2(61) = [];
OUTPUT.Day5.postCS.ntarget.CS2(61) = [];
OUTPUT.Day5.postCS.ltarget.CS2(61) = [];
OUTPUT.Day5.postCS.tpuerta.CS2(61) = [];
OUTPUT.Day5.postCS.npuerta.CS2(61) = [];
OUTPUT.Day5.postCS.lpuerta.CS2(61) = [];

OUTPUT.Day6.duringCS.ttarget.CS2(61) = [];
OUTPUT.Day6.duringCS.ntarget.CS2(61) = [];
OUTPUT.Day6.duringCS.ltarget.CS2(61) = [];
OUTPUT.Day6.duringCS.tpuerta.CS2(61) = [];
OUTPUT.Day6.duringCS.npuerta.CS2(61) = [];
OUTPUT.Day6.duringCS.lpuerta.CS2(61) = [];

OUTPUT.Day6.preCS.ttarget.CS2(61) = [];
OUTPUT.Day6.preCS.ntarget.CS2(61) = [];
OUTPUT.Day6.preCS.ltarget.CS2(61) = [];
OUTPUT.Day6.preCS.tpuerta.CS2(61) = [];
OUTPUT.Day6.preCS.npuerta.CS2(61) = [];
OUTPUT.Day6.preCS.lpuerta.CS2(61) = [];

OUTPUT.Day6.postCS.ttarget.CS2(61) = [];
OUTPUT.Day6.postCS.ntarget.CS2(61) = [];
OUTPUT.Day6.postCS.ltarget.CS2(61) = [];
OUTPUT.Day6.postCS.tpuerta.CS2(61) = [];
OUTPUT.Day6.postCS.npuerta.CS2(61) = [];
OUTPUT.Day6.postCS.lpuerta.CS2(61) = [];

OUTPUT.Day7.duringCS.ttarget.CS2(61) = [];
OUTPUT.Day7.duringCS.ntarget.CS2(61) = [];
OUTPUT.Day7.duringCS.ltarget.CS2(61) = [];
OUTPUT.Day7.duringCS.tpuerta.CS2(61) = [];
OUTPUT.Day7.duringCS.npuerta.CS2(61) = [];
OUTPUT.Day7.duringCS.lpuerta.CS2(61) = [];

OUTPUT.Day7.preCS.ttarget.CS2(61) = [];
OUTPUT.Day7.preCS.ntarget.CS2(61) = [];
OUTPUT.Day7.preCS.ltarget.CS2(61) = [];
OUTPUT.Day7.preCS.tpuerta.CS2(61) = [];
OUTPUT.Day7.preCS.npuerta.CS2(61) = [];
OUTPUT.Day7.preCS.lpuerta.CS2(61) = [];

OUTPUT.Day7.postCS.ttarget.CS2(61) = [];
OUTPUT.Day7.postCS.ntarget.CS2(61) = [];
OUTPUT.Day7.postCS.ltarget.CS2(61) = [];
OUTPUT.Day7.postCS.tpuerta.CS2(61) = [];
OUTPUT.Day7.postCS.npuerta.CS2(61) = [];
OUTPUT.Day7.postCS.lpuerta.CS2(61) = [];

OUTPUT.Day8.duringCS.ttarget.CS2(61) = [];
OUTPUT.Day8.duringCS.ntarget.CS2(61) = [];
OUTPUT.Day8.duringCS.ltarget.CS2(61) = [];
OUTPUT.Day8.duringCS.tpuerta.CS2(61) = [];
OUTPUT.Day8.duringCS.npuerta.CS2(61) = [];
OUTPUT.Day8.duringCS.lpuerta.CS2(61) = [];

OUTPUT.Day8.preCS.ttarget.CS2(61) = [];
OUTPUT.Day8.preCS.ntarget.CS2(61) = [];
OUTPUT.Day8.preCS.ltarget.CS2(61) = [];
OUTPUT.Day8.preCS.tpuerta.CS2(61) = [];
OUTPUT.Day8.preCS.npuerta.CS2(61) = [];
OUTPUT.Day8.preCS.lpuerta.CS2(61) = [];

OUTPUT.Day8.postCS.ttarget.CS2(61) = [];
OUTPUT.Day8.postCS.ntarget.CS2(61) = [];
OUTPUT.Day8.postCS.ltarget.CS2(61) = [];
OUTPUT.Day8.postCS.tpuerta.CS2(61) = [];
OUTPUT.Day8.postCS.npuerta.CS2(61) = [];
OUTPUT.Day8.postCS.lpuerta.CS2(61) = [];

%%
