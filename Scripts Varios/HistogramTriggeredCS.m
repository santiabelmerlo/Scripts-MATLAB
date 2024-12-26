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
path = 'D:\Doctorado\Electrofisiología\Vol 10\'; % path en IFIBIO
cd(path);

[filpath,name,ext] = fileparts(cd); clear ext; clear filpath;
d = dir(cd); dfolders = d([d(:).isdir]); dfolders = dfolders(~ismember({dfolders(:).name},{'.','..'}));

 for a = 8:14; %length(dfolders)
    path1 = [path dfolders(a).name;];
    name = dfolders(a).name;
    cd(path1);
    cd('./Record Node 101/experiment1/recording1/events/Rhythm_FPGA-100.0/TTL_1/')

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
    for i = 1:length(IR2.start);
        if IR2.start(i) == IR2.end(i);
            
        else
            ai = i;
        end
    end 
        if IR2.start(ai) > IR2.end(ai);
            IR2.end(1) = [];
        elseif IR2.end(end) < IR2.start(end);
            IR2.start(end) = [];
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
    for i = 1:length(IR3.start);
        if IR3.start(i) == IR3.end(i);
            
        else
            ai = i;
        end
    end
        if IR3.start(ai) > IR3.end(ai);
            IR3.end(1) = [];
        elseif IR3.end(end) < IR3.start(end);
            IR3.start(end) = [];
        end
    clear i;    
    for i = 1:length(IR3.start);
        IR3.duration(i,1) = IR3.end(i) - IR3.start(i);
    end
    clear i; clear ai;
 end
        %% Pre4 CS+  ---> 4 seg pre CS+
    for i = 1:length(CS1.start);
        puerta.tacumulado = 0;
        for j = 1:length(IR2.start);
            % Si el nosepoke inicia despues de 4 seg pre CS y termina antes de 2 seg pre del CS
            if IR2.start(j) >= (CS1.start(i) - 4000) && IR2.end(j) < (CS1.start(i) - 2000);
                 puerta.tacumulado = puerta.tacumulado + IR2.duration(j);
            end
            % Si el nosepoke inicia despues de 4 seg pre CS y termina despues de 2 seg pre del CS
            if IR2.start(j) >= (CS1.start(i) - 4000) && IR2.start(j) < (CS1.start(i) - 2000) && IR2.end(j) > (CS1.start(i) - 2000);
                 puerta.tacumulado = puerta.tacumulado + ((CS1.start(i) - 2000) - IR2.start(j));
            end
            % Si el nosepoke inicia antes de 4 seg pre CS y termina antes de 2 seg pre del CS
            if IR2.start(j) < (CS1.start(i) - 4000) && IR2.end(j) > (CS1.start(i) - 4000) && IR2.end(j) <= (CS1.start(i) - 2000);
                 puerta.tacumulado = puerta.tacumulado + (IR2.end(j) - (CS1.start(i) - 4000));
            end
            % Si el nosepoke inicia antes de 4 seg pre CS y termina despues de 2 seg pre del CS
            if IR2.start(j) < (CS1.start(i) - 4000) && IR2.end(j) > (CS1.start(i) - 2000);
                 puerta.tacumulado = puerta.tacumulado + 2000;
            end
        end
        results.pre4.tpuerta.CS1(i,1) = puerta.tacumulado;
    end
    
    % Pre2 CS+  ---> 2 seg pre CS+
    for i = 1:length(CS1.start);
        puerta.tacumulado = 0;
        for j = 1:length(IR2.start);
            % Si el nosepoke inicia despues de 4 seg pre CS y termina antes de 2 seg pre del CS
            if IR2.start(j) >= (CS1.start(i) - 2000) && IR2.end(j) < CS1.start(i);
                 puerta.tacumulado = puerta.tacumulado + IR2.duration(j);
            end
            % Si el nosepoke inicia despues de 4 seg pre CS y termina despues de 2 seg pre del CS
            if IR2.start(j) >= (CS1.start(i) - 2000) && IR2.start(j) < CS1.start(i) && IR2.end(j) > CS1.start(i);
                 puerta.tacumulado = puerta.tacumulado + (CS1.start(i) - IR2.start(j));
            end
            % Si el nosepoke inicia antes de 4 seg pre CS y termina antes de 2 seg pre del CS
            if IR2.start(j) < (CS1.start(i) - 2000) && IR2.end(j) > (CS1.start(i) - 2000) && IR2.end(j) <= CS1.start(i);
                 puerta.tacumulado = puerta.tacumulado + (IR2.end(j) - (CS1.start(i) - 2000));
            end
            % Si el nosepoke inicia antes de 4 seg pre CS y termina despues de 2 seg pre del CS
            if IR2.start(j) < (CS1.start(i) - 2000) && IR2.end(j) > CS1.start(i);
                 puerta.tacumulado = puerta.tacumulado + 2000;
            end
        end
        results.pre2.tpuerta.CS1(i,1) = puerta.tacumulado;
    end
    
    % Durante 0-2 seg del CS+
    for i = 1:length(CS1.start);
        puerta.tacumulado = 0;
        for j = 1:length(IR2.start);
            % Si el nosepoke inicia luego del onset del CS y termina antes del offset del CS.
            if IR2.start(j) >= CS1.start(i) && IR2.end(j) < (CS1.start(i) + 2000);
                 puerta.tacumulado = puerta.tacumulado + IR2.duration(j);
            end
            % Si el nosepoke inicia durante el CS pero termina luego del offset del CS.
            if IR2.start(j) >= CS1.start(i) && IR2.start(j) < (CS1.start(i) + 2000) && IR2.end(j) > (CS1.start(i) + 2000);
                 puerta.tacumulado = puerta.tacumulado + ((CS1.start(i) + 2000) - IR2.start(j));
            end
            % Si el nosepoke inicia antes del onset del CS pero termina durante CS.
            if IR2.start(j) < CS1.start(i) && IR2.end(j) > CS1.start(i) && IR2.end(j) <= (CS1.start(i) + 2000);
                 puerta.tacumulado = puerta.tacumulado + (IR2.end(j) - CS1.start(i));
            end
            % Si el nosepoke inicia antes del onset del CS y termina despues del offset del CS.
            if IR2.start(j) < CS1.start(i) && IR2.end(j) > (CS1.start(i) + 2000);
                 puerta.tacumulado = puerta.tacumulado + 2000;
            end
        end
        results.sec0to2duringCS.tpuerta.CS1(i,1) = puerta.tacumulado;
    end
    
        % Durante 2-4 seg del CS+
    for i = 1:length(CS1.start);
        puerta.tacumulado = 0;
        for j = 1:length(IR2.start);
            % Si el nosepoke inicia luego del onset del CS y termina antes del offset del CS.
            if IR2.start(j) >= (CS1.start(i) + 2000) && IR2.end(j) < (CS1.start(i) + 4000);
                 puerta.tacumulado = puerta.tacumulado + IR2.duration(j);
            end
            % Si el nosepoke inicia durante el CS pero termina luego del offset del CS.
            if IR2.start(j) >= (CS1.start(i) + 2000) && IR2.start(j) < (CS1.start(i) + 4000) && IR2.end(j) > (CS1.start(i) + 4000);
                 puerta.tacumulado = puerta.tacumulado + ((CS1.start(i) + 4000) - IR2.start(j));
            end
            % Si el nosepoke inicia antes del onset del CS pero termina durante CS.
            if IR2.start(j) < (CS1.start(i) + 2000) && IR2.end(j) > (CS1.start(i) + 2000) && IR2.end(j) <= (CS1.start(i) + 4000);
                 puerta.tacumulado = puerta.tacumulado + (IR2.end(j) - (CS1.start(i) + 2000));
            end
            % Si el nosepoke inicia antes del onset del CS y termina despues del offset del CS.
            if IR2.start(j) < (CS1.start(i) + 2000) && IR2.end(j) > (CS1.start(i) + 4000);
                 puerta.tacumulado = puerta.tacumulado + 2000;
            end
        end
        results.sec2to4duringCS.tpuerta.CS1(i,1) = puerta.tacumulado;
    end
    
        % Durante 4-6 seg del CS+
    for i = 1:length(CS1.start);
        puerta.tacumulado = 0;
        for j = 1:length(IR2.start);
            % Si el nosepoke inicia luego del onset del CS y termina antes del offset del CS.
            if IR2.start(j) >= (CS1.start(i) + 4000) && IR2.end(j) < (CS1.start(i) + 6000);
                 puerta.tacumulado = puerta.tacumulado + IR2.duration(j);
            end
            % Si el nosepoke inicia durante el CS pero termina luego del offset del CS.
            if IR2.start(j) >= (CS1.start(i) + 4000) && IR2.start(j) < (CS1.start(i) + 6000) && IR2.end(j) > (CS1.start(i) + 6000);
                 puerta.tacumulado = puerta.tacumulado + ((CS1.start(i) + 6000) - IR2.start(j));
            end
            % Si el nosepoke inicia antes del onset del CS pero termina durante CS.
            if IR2.start(j) < (CS1.start(i) + 4000) && IR2.end(j) > (CS1.start(i) + 4000) && IR2.end(j) <= (CS1.start(i) + 6000);
                 puerta.tacumulado = puerta.tacumulado + (IR2.end(j) - (CS1.start(i) + 4000));
            end
            % Si el nosepoke inicia antes del onset del CS y termina despues del offset del CS.
            if IR2.start(j) < (CS1.start(i) + 4000) && IR2.end(j) > (CS1.start(i) + 6000);
                 puerta.tacumulado = puerta.tacumulado + 2000;
            end
        end
        results.sec4to6duringCS.tpuerta.CS1(i,1) = puerta.tacumulado;
    end
    
        % Durante 6-8 seg del CS+
    for i = 1:length(CS1.start);
        puerta.tacumulado = 0;
        for j = 1:length(IR2.start);
            % Si el nosepoke inicia luego del onset del CS y termina antes del offset del CS.
            if IR2.start(j) >= (CS1.start(i) + 6000) && IR2.end(j) < (CS1.start(i) + 8000);
                 puerta.tacumulado = puerta.tacumulado + IR2.duration(j);
            end
            % Si el nosepoke inicia durante el CS pero termina luego del offset del CS.
            if IR2.start(j) >= (CS1.start(i) + 6000) && IR2.start(j) < (CS1.start(i) + 8000) && IR2.end(j) > (CS1.start(i) + 8000);
                 puerta.tacumulado = puerta.tacumulado + ((CS1.start(i) + 8000) - IR2.start(j));
            end
            % Si el nosepoke inicia antes del onset del CS pero termina durante CS.
            if IR2.start(j) < (CS1.start(i) + 6000) && IR2.end(j) > (CS1.start(i) + 6000) && IR2.end(j) <= (CS1.start(i) + 8000);
                 puerta.tacumulado = puerta.tacumulado + (IR2.end(j) - (CS1.start(i) + 6000));
            end
            % Si el nosepoke inicia antes del onset del CS y termina despues del offset del CS.
            if IR2.start(j) < (CS1.start(i) + 6000) && IR2.end(j) > (CS1.start(i) + 8000);
                 puerta.tacumulado = puerta.tacumulado + 2000;
            end
        end
        results.sec6to8duringCS.tpuerta.CS1(i,1) = puerta.tacumulado;
    end
    
        % Durante 8-10 seg del CS+
    for i = 1:length(CS1.start);
        puerta.tacumulado = 0;
        for j = 1:length(IR2.start);
            % Si el nosepoke inicia luego del onset del CS y termina antes del offset del CS.
            if IR2.start(j) >= (CS1.start(i) + 8000) && IR2.end(j) < (CS1.start(i) + 10000);
                 puerta.tacumulado = puerta.tacumulado + IR2.duration(j);
            end
            % Si el nosepoke inicia durante el CS pero termina luego del offset del CS.
            if IR2.start(j) >= (CS1.start(i) + 8000) && IR2.start(j) < (CS1.start(i) + 10000) && IR2.end(j) > (CS1.start(i) + 10000);
                 puerta.tacumulado = puerta.tacumulado + ((CS1.start(i) + 10000) - IR2.start(j));
            end
            % Si el nosepoke inicia antes del onset del CS pero termina durante CS.
            if IR2.start(j) < (CS1.start(i) + 8000) && IR2.end(j) > (CS1.start(i) + 8000) && IR2.end(j) <= (CS1.start(i) + 10000);
                 puerta.tacumulado = puerta.tacumulado + (IR2.end(j) - (CS1.start(i) + 8000));
            end
            % Si el nosepoke inicia antes del onset del CS y termina despues del offset del CS.
            if IR2.start(j) < (CS1.start(i) + 8000) && IR2.end(j) > (CS1.start(i) + 10000);
                 puerta.tacumulado = puerta.tacumulado + 2000;
            end
        end
        results.sec8to10duringCS.tpuerta.CS1(i,1) = puerta.tacumulado;
    end
    
        % 2 seg post CS+
    for i = 1:length(CS1.start);
        puerta.tacumulado = 0;
        for j = 1:length(IR2.start);
            % Si el nosepoke inicia luego del onset del CS y termina antes del offset del CS.
            if IR2.start(j) >= (CS1.start(i) + 10000) && IR2.end(j) < (CS1.start(i) + 12000);
                 puerta.tacumulado = puerta.tacumulado + IR2.duration(j);
            end
            % Si el nosepoke inicia durante el CS pero termina luego del offset del CS.
            if IR2.start(j) >= (CS1.start(i) + 10000) && IR2.start(j) < (CS1.start(i) + 12000) && IR2.end(j) > (CS1.start(i) + 12000);
                 puerta.tacumulado = puerta.tacumulado + ((CS1.start(i) + 12000) - IR2.start(j));
            end
            % Si el nosepoke inicia antes del onset del CS pero termina durante CS.
            if IR2.start(j) < (CS1.start(i) + 10000) && IR2.end(j) > (CS1.start(i) + 10000) && IR2.end(j) <= (CS1.start(i) + 12000);
                 puerta.tacumulado = puerta.tacumulado + (IR2.end(j) - (CS1.start(i) + 10000));
            end
            % Si el nosepoke inicia antes del onset del CS y termina despues del offset del CS.
            if IR2.start(j) < (CS1.start(i) + 10000) && IR2.end(j) > (CS1.start(i) + 12000);
                 puerta.tacumulado = puerta.tacumulado + 2000;
            end
        end
        results.postCS2.tpuerta.CS1(i,1) = puerta.tacumulado;
    end
    
        % 4 seg post CS+
    for i = 1:length(CS1.start);
        puerta.tacumulado = 0;
        for j = 1:length(IR2.start);
            % Si el nosepoke inicia luego del onset del CS y termina antes del offset del CS.
            if IR2.start(j) >= (CS1.start(i) + 12000) && IR2.end(j) < (CS1.start(i) + 14000);
                 puerta.tacumulado = puerta.tacumulado + IR2.duration(j);
            end
            % Si el nosepoke inicia durante el CS pero termina luego del offset del CS.
            if IR2.start(j) >= (CS1.start(i) + 12000) && IR2.start(j) < (CS1.start(i) + 14000) && IR2.end(j) > (CS1.start(i) + 14000);
                 puerta.tacumulado = puerta.tacumulado + ((CS1.start(i) + 14000) - IR2.start(j));
            end
            % Si el nosepoke inicia antes del onset del CS pero termina durante CS.
            if IR2.start(j) < (CS1.start(i) + 12000) && IR2.end(j) > (CS1.start(i) + 12000) && IR2.end(j) <= (CS1.start(i) + 14000);
                 puerta.tacumulado = puerta.tacumulado + (IR2.end(j) - (CS1.start(i) + 12000));
            end
            % Si el nosepoke inicia antes del onset del CS y termina despues del offset del CS.
            if IR2.start(j) < (CS1.start(i) + 12000) && IR2.end(j) > (CS1.start(i) + 14000);
                 puerta.tacumulado = puerta.tacumulado + 2000;
            end
        end
        results.postCS4.tpuerta.CS1(i,1) = puerta.tacumulado;
    end
    
        %% Pre4 CS-  ---> 4 seg pre CS-
    for i = 1:length(CS2.start);
        puerta.tacumulado = 0;
        for j = 1:length(IR2.start);
            % Si el nosepoke inicia despues de 4 seg pre CS y termina antes de 2 seg pre del CS
            if IR2.start(j) >= (CS2.start(i) - 4000) && IR2.end(j) < (CS2.start(i) - 2000);
                 puerta.tacumulado = puerta.tacumulado + IR2.duration(j);
            end
            % Si el nosepoke inicia despues de 4 seg pre CS y termina despues de 2 seg pre del CS
            if IR2.start(j) >= (CS2.start(i) - 4000) && IR2.start(j) < (CS2.start(i) - 2000) && IR2.end(j) > (CS2.start(i) - 2000);
                 puerta.tacumulado = puerta.tacumulado + ((CS2.start(i) - 2000) - IR2.start(j));
            end
            % Si el nosepoke inicia antes de 4 seg pre CS y termina antes de 2 seg pre del CS
            if IR2.start(j) < (CS2.start(i) - 4000) && IR2.end(j) > (CS2.start(i) - 4000) && IR2.end(j) <= (CS2.start(i) - 2000);
                 puerta.tacumulado = puerta.tacumulado + (IR2.end(j) - (CS2.start(i) - 4000));
            end
            % Si el nosepoke inicia antes de 4 seg pre CS y termina despues de 2 seg pre del CS
            if IR2.start(j) < (CS2.start(i) - 4000) && IR2.end(j) > (CS2.start(i) - 2000);
                 puerta.tacumulado = puerta.tacumulado + 2000;
            end
        end
        results.pre4.tpuerta.CS2(i,1) = puerta.tacumulado;
    end
    
    % Pre2 CS-  ---> 2 seg pre CS-
    for i = 1:length(CS2.start);
        puerta.tacumulado = 0;
        for j = 1:length(IR2.start);
            % Si el nosepoke inicia despues de 4 seg pre CS y termina antes de 2 seg pre del CS
            if IR2.start(j) >= (CS2.start(i) - 2000) && IR2.end(j) < CS2.start(i);
                 puerta.tacumulado = puerta.tacumulado + IR2.duration(j);
            end
            % Si el nosepoke inicia despues de 4 seg pre CS y termina despues de 2 seg pre del CS
            if IR2.start(j) >= (CS2.start(i) - 2000) && IR2.start(j) < CS2.start(i) && IR2.end(j) > CS2.start(i);
                 puerta.tacumulado = puerta.tacumulado + (CS2.start(i) - IR2.start(j));
            end
            % Si el nosepoke inicia antes de 4 seg pre CS y termina antes de 2 seg pre del CS
            if IR2.start(j) < (CS2.start(i) - 2000) && IR2.end(j) > (CS2.start(i) - 2000) && IR2.end(j) <= CS2.start(i);
                 puerta.tacumulado = puerta.tacumulado + (IR2.end(j) - (CS2.start(i) - 2000));
            end
            % Si el nosepoke inicia antes de 4 seg pre CS y termina despues de 2 seg pre del CS
            if IR2.start(j) < (CS2.start(i) - 2000) && IR2.end(j) > CS2.start(i);
                 puerta.tacumulado = puerta.tacumulado + 2000;
            end
        end
        results.pre2.tpuerta.CS2(i,1) = puerta.tacumulado;
    end
    
    % Durante 0-2 seg del CS-
    for i = 1:length(CS2.start);
        puerta.tacumulado = 0;
        for j = 1:length(IR2.start);
            % Si el nosepoke inicia luego del onset del CS y termina antes del offset del CS.
            if IR2.start(j) >= CS2.start(i) && IR2.end(j) < (CS2.start(i) + 2000);
                 puerta.tacumulado = puerta.tacumulado + IR2.duration(j);
            end
            % Si el nosepoke inicia durante el CS pero termina luego del offset del CS.
            if IR2.start(j) >= CS2.start(i) && IR2.start(j) < (CS2.start(i) + 2000) && IR2.end(j) > (CS2.start(i) + 2000);
                 puerta.tacumulado = puerta.tacumulado + ((CS2.start(i) + 2000) - IR2.start(j));
            end
            % Si el nosepoke inicia antes del onset del CS pero termina durante CS.
            if IR2.start(j) < CS2.start(i) && IR2.end(j) > CS2.start(i) && IR2.end(j) <= (CS2.start(i) + 2000);
                 puerta.tacumulado = puerta.tacumulado + (IR2.end(j) - CS2.start(i));
            end
            % Si el nosepoke inicia antes del onset del CS y termina despues del offset del CS.
            if IR2.start(j) < CS2.start(i) && IR2.end(j) > (CS2.start(i) + 2000);
                 puerta.tacumulado = puerta.tacumulado + 2000;
            end
        end
        results.sec0to2duringCS.tpuerta.CS2(i,1) = puerta.tacumulado;
    end
    
        % Durante 2-4 seg del CS-
    for i = 1:length(CS2.start);
        puerta.tacumulado = 0;
        for j = 1:length(IR2.start);
            % Si el nosepoke inicia luego del onset del CS y termina antes del offset del CS.
            if IR2.start(j) >= (CS2.start(i) + 2000) && IR2.end(j) < (CS2.start(i) + 4000);
                 puerta.tacumulado = puerta.tacumulado + IR2.duration(j);
            end
            % Si el nosepoke inicia durante el CS pero termina luego del offset del CS.
            if IR2.start(j) >= (CS2.start(i) + 2000) && IR2.start(j) < (CS2.start(i) + 4000) && IR2.end(j) > (CS2.start(i) + 4000);
                 puerta.tacumulado = puerta.tacumulado + ((CS2.start(i) + 4000) - IR2.start(j));
            end
            % Si el nosepoke inicia antes del onset del CS pero termina durante CS.
            if IR2.start(j) < (CS2.start(i) + 2000) && IR2.end(j) > (CS2.start(i) + 2000) && IR2.end(j) <= (CS2.start(i) + 4000);
                 puerta.tacumulado = puerta.tacumulado + (IR2.end(j) - (CS2.start(i) + 2000));
            end
            % Si el nosepoke inicia antes del onset del CS y termina despues del offset del CS.
            if IR2.start(j) < (CS2.start(i) + 2000) && IR2.end(j) > (CS2.start(i) + 4000);
                 puerta.tacumulado = puerta.tacumulado + 2000;
            end
        end
        results.sec2to4duringCS.tpuerta.CS2(i,1) = puerta.tacumulado;
    end
    
        % Durante 4-6 seg del CS-
    for i = 1:length(CS2.start);
        puerta.tacumulado = 0;
        for j = 1:length(IR2.start);
            % Si el nosepoke inicia luego del onset del CS y termina antes del offset del CS.
            if IR2.start(j) >= (CS2.start(i) + 4000) && IR2.end(j) < (CS2.start(i) + 6000);
                 puerta.tacumulado = puerta.tacumulado + IR2.duration(j);
            end
            % Si el nosepoke inicia durante el CS pero termina luego del offset del CS.
            if IR2.start(j) >= (CS2.start(i) + 4000) && IR2.start(j) < (CS2.start(i) + 6000) && IR2.end(j) > (CS2.start(i) + 6000);
                 puerta.tacumulado = puerta.tacumulado + ((CS2.start(i) + 6000) - IR2.start(j));
            end
            % Si el nosepoke inicia antes del onset del CS pero termina durante CS.
            if IR2.start(j) < (CS2.start(i) + 4000) && IR2.end(j) > (CS2.start(i) + 4000) && IR2.end(j) <= (CS2.start(i) + 6000);
                 puerta.tacumulado = puerta.tacumulado + (IR2.end(j) - (CS2.start(i) + 4000));
            end
            % Si el nosepoke inicia antes del onset del CS y termina despues del offset del CS.
            if IR2.start(j) < (CS2.start(i) + 4000) && IR2.end(j) > (CS2.start(i) + 6000);
                 puerta.tacumulado = puerta.tacumulado + 2000;
            end
        end
        results.sec4to6duringCS.tpuerta.CS2(i,1) = puerta.tacumulado;
    end
    
        % Durante 6-8 seg del CS-
    for i = 1:length(CS2.start);
        puerta.tacumulado = 0;
        for j = 1:length(IR2.start);
            % Si el nosepoke inicia luego del onset del CS y termina antes del offset del CS.
            if IR2.start(j) >= (CS2.start(i) + 6000) && IR2.end(j) < (CS2.start(i) + 8000);
                 puerta.tacumulado = puerta.tacumulado + IR2.duration(j);
            end
            % Si el nosepoke inicia durante el CS pero termina luego del offset del CS.
            if IR2.start(j) >= (CS2.start(i) + 6000) && IR2.start(j) < (CS2.start(i) + 8000) && IR2.end(j) > (CS2.start(i) + 8000);
                 puerta.tacumulado = puerta.tacumulado + ((CS2.start(i) + 8000) - IR2.start(j));
            end
            % Si el nosepoke inicia antes del onset del CS pero termina durante CS.
            if IR2.start(j) < (CS2.start(i) + 6000) && IR2.end(j) > (CS2.start(i) + 6000) && IR2.end(j) <= (CS2.start(i) + 8000);
                 puerta.tacumulado = puerta.tacumulado + (IR2.end(j) - (CS2.start(i) + 6000));
            end
            % Si el nosepoke inicia antes del onset del CS y termina despues del offset del CS.
            if IR2.start(j) < (CS2.start(i) + 6000) && IR2.end(j) > (CS2.start(i) + 8000);
                 puerta.tacumulado = puerta.tacumulado + 2000;
            end
        end
        results.sec6to8duringCS.tpuerta.CS2(i,1) = puerta.tacumulado;
    end
    
        % Durante 8-10 seg del CS-
    for i = 1:length(CS2.start);
        puerta.tacumulado = 0;
        for j = 1:length(IR2.start);
            % Si el nosepoke inicia luego del onset del CS y termina antes del offset del CS.
            if IR2.start(j) >= (CS2.start(i) + 8000) && IR2.end(j) < (CS2.start(i) + 10000);
                 puerta.tacumulado = puerta.tacumulado + IR2.duration(j);
            end
            % Si el nosepoke inicia durante el CS pero termina luego del offset del CS.
            if IR2.start(j) >= (CS2.start(i) + 8000) && IR2.start(j) < (CS2.start(i) + 10000) && IR2.end(j) > (CS2.start(i) + 10000);
                 puerta.tacumulado = puerta.tacumulado + ((CS2.start(i) + 10000) - IR2.start(j));
            end
            % Si el nosepoke inicia antes del onset del CS pero termina durante CS.
            if IR2.start(j) < (CS2.start(i) + 8000) && IR2.end(j) > (CS2.start(i) + 8000) && IR2.end(j) <= (CS2.start(i) + 10000);
                 puerta.tacumulado = puerta.tacumulado + (IR2.end(j) - (CS2.start(i) + 8000));
            end
            % Si el nosepoke inicia antes del onset del CS y termina despues del offset del CS.
            if IR2.start(j) < (CS2.start(i) + 8000) && IR2.end(j) > (CS2.start(i) + 10000);
                 puerta.tacumulado = puerta.tacumulado + 2000;
            end
        end
        results.sec8to10duringCS.tpuerta.CS2(i,1) = puerta.tacumulado;
    end
    
        % 2 seg post CS-
    for i = 1:length(CS2.start);
        puerta.tacumulado = 0;
        for j = 1:length(IR2.start);
            % Si el nosepoke inicia luego del onset del CS y termina antes del offset del CS.
            if IR2.start(j) >= (CS2.start(i) + 10000) && IR2.end(j) < (CS2.start(i) + 12000);
                 puerta.tacumulado = puerta.tacumulado + IR2.duration(j);
            end
            % Si el nosepoke inicia durante el CS pero termina luego del offset del CS.
            if IR2.start(j) >= (CS2.start(i) + 10000) && IR2.start(j) < (CS2.start(i) + 12000) && IR2.end(j) > (CS2.start(i) + 12000);
                 puerta.tacumulado = puerta.tacumulado + ((CS2.start(i) + 12000) - IR2.start(j));
            end
            % Si el nosepoke inicia antes del onset del CS pero termina durante CS.
            if IR2.start(j) < (CS2.start(i) + 10000) && IR2.end(j) > (CS2.start(i) + 10000) && IR2.end(j) <= (CS2.start(i) + 12000);
                 puerta.tacumulado = puerta.tacumulado + (IR2.end(j) - (CS2.start(i) + 10000));
            end
            % Si el nosepoke inicia antes del onset del CS y termina despues del offset del CS.
            if IR2.start(j) < (CS2.start(i) + 10000) && IR2.end(j) > (CS2.start(i) + 12000);
                 puerta.tacumulado = puerta.tacumulado + 2000;
            end
        end
        results.postCS2.tpuerta.CS2(i,1) = puerta.tacumulado;
    end
    
        % 4 seg post CS-
    for i = 1:length(CS2.start);
        puerta.tacumulado = 0;
        for j = 1:length(IR2.start);
            % Si el nosepoke inicia luego del onset del CS y termina antes del offset del CS.
            if IR2.start(j) >= (CS2.start(i) + 12000) && IR2.end(j) < (CS2.start(i) + 14000);
                 puerta.tacumulado = puerta.tacumulado + IR2.duration(j);
            end
            % Si el nosepoke inicia durante el CS pero termina luego del offset del CS.
            if IR2.start(j) >= (CS2.start(i) + 12000) && IR2.start(j) < (CS2.start(i) + 14000) && IR2.end(j) > (CS2.start(i) + 14000);
                 puerta.tacumulado = puerta.tacumulado + ((CS2.start(i) + 14000) - IR2.start(j));
            end
            % Si el nosepoke inicia antes del onset del CS pero termina durante CS.
            if IR2.start(j) < (CS2.start(i) + 12000) && IR2.end(j) > (CS2.start(i) + 12000) && IR2.end(j) <= (CS2.start(i) + 14000);
                 puerta.tacumulado = puerta.tacumulado + (IR2.end(j) - (CS2.start(i) + 12000));
            end
            % Si el nosepoke inicia antes del onset del CS y termina despues del offset del CS.
            if IR2.start(j) < (CS2.start(i) + 12000) && IR2.end(j) > (CS2.start(i) + 14000);
                 puerta.tacumulado = puerta.tacumulado + 2000;
            end
        end
        results.postCS4.tpuerta.CS2(i,1) = puerta.tacumulado;
    end
    
    clear i; clear j; clear k;
        if name(5) == '_';
            OUTPUT.(name(1:4)) = results;
        else
            OUTPUT.(name(1:5)) = results;
        end
        


clearvars -except path OUTPUT;
cd(path);

OUTPUT_HIST = OUTPUT;
save(['OUTPUT_HIST.mat']);

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
                                
%% Creo las tablas para luego graficar
load(['OUTPUT_HIST.mat']);

HistTrigCS.Day2.tpuerta.CS1(:,1) = OUTPUT_HIST.Day2.pre4.tpuerta.CS1;
HistTrigCS.Day2.tpuerta.CS1(:,2) = OUTPUT_HIST.Day2.pre2.tpuerta.CS1;
HistTrigCS.Day2.tpuerta.CS1(:,3) = OUTPUT_HIST.Day2.sec0to2duringCS.tpuerta.CS1;
HistTrigCS.Day2.tpuerta.CS1(:,4) = OUTPUT_HIST.Day2.sec2to4duringCS.tpuerta.CS1;
HistTrigCS.Day2.tpuerta.CS1(:,5) = OUTPUT_HIST.Day2.sec4to6duringCS.tpuerta.CS1;
HistTrigCS.Day2.tpuerta.CS1(:,6) = OUTPUT_HIST.Day2.sec6to8duringCS.tpuerta.CS1;
HistTrigCS.Day2.tpuerta.CS1(:,7) = OUTPUT_HIST.Day2.sec8to10duringCS.tpuerta.CS1;
HistTrigCS.Day2.tpuerta.CS1(:,8) = OUTPUT_HIST.Day2.postCS2.tpuerta.CS1;
HistTrigCS.Day2.tpuerta.CS1(:,9) = OUTPUT_HIST.Day2.postCS4.tpuerta.CS1;

HistTrigCS.Day2.tpuerta.CS2(:,1) = OUTPUT_HIST.Day2.pre4.tpuerta.CS2;
HistTrigCS.Day2.tpuerta.CS2(:,2) = OUTPUT_HIST.Day2.pre2.tpuerta.CS2;
HistTrigCS.Day2.tpuerta.CS2(:,3) = OUTPUT_HIST.Day2.sec0to2duringCS.tpuerta.CS2;
HistTrigCS.Day2.tpuerta.CS2(:,4) = OUTPUT_HIST.Day2.sec2to4duringCS.tpuerta.CS2;
HistTrigCS.Day2.tpuerta.CS2(:,5) = OUTPUT_HIST.Day2.sec4to6duringCS.tpuerta.CS2;
HistTrigCS.Day2.tpuerta.CS2(:,6) = OUTPUT_HIST.Day2.sec6to8duringCS.tpuerta.CS2;
HistTrigCS.Day2.tpuerta.CS2(:,7) = OUTPUT_HIST.Day2.sec8to10duringCS.tpuerta.CS2;
HistTrigCS.Day2.tpuerta.CS2(:,8) = OUTPUT_HIST.Day2.postCS2.tpuerta.CS2;
HistTrigCS.Day2.tpuerta.CS2(:,9) = OUTPUT_HIST.Day2.postCS4.tpuerta.CS2;

HistTrigCS.Day3.tpuerta.CS1(:,1) = OUTPUT_HIST.Day3.pre4.tpuerta.CS1;
HistTrigCS.Day3.tpuerta.CS1(:,2) = OUTPUT_HIST.Day3.pre2.tpuerta.CS1;
HistTrigCS.Day3.tpuerta.CS1(:,3) = OUTPUT_HIST.Day3.sec0to2duringCS.tpuerta.CS1;
HistTrigCS.Day3.tpuerta.CS1(:,4) = OUTPUT_HIST.Day3.sec2to4duringCS.tpuerta.CS1;
HistTrigCS.Day3.tpuerta.CS1(:,5) = OUTPUT_HIST.Day3.sec4to6duringCS.tpuerta.CS1;
HistTrigCS.Day3.tpuerta.CS1(:,6) = OUTPUT_HIST.Day3.sec6to8duringCS.tpuerta.CS1;
HistTrigCS.Day3.tpuerta.CS1(:,7) = OUTPUT_HIST.Day3.sec8to10duringCS.tpuerta.CS1;
HistTrigCS.Day3.tpuerta.CS1(:,8) = OUTPUT_HIST.Day3.postCS2.tpuerta.CS1;
HistTrigCS.Day3.tpuerta.CS1(:,9) = OUTPUT_HIST.Day3.postCS4.tpuerta.CS1;

HistTrigCS.Day3.tpuerta.CS2(:,1) = OUTPUT_HIST.Day3.pre4.tpuerta.CS2;
HistTrigCS.Day3.tpuerta.CS2(:,2) = OUTPUT_HIST.Day3.pre2.tpuerta.CS2;
HistTrigCS.Day3.tpuerta.CS2(:,3) = OUTPUT_HIST.Day3.sec0to2duringCS.tpuerta.CS2;
HistTrigCS.Day3.tpuerta.CS2(:,4) = OUTPUT_HIST.Day3.sec2to4duringCS.tpuerta.CS2;
HistTrigCS.Day3.tpuerta.CS2(:,5) = OUTPUT_HIST.Day3.sec4to6duringCS.tpuerta.CS2;
HistTrigCS.Day3.tpuerta.CS2(:,6) = OUTPUT_HIST.Day3.sec6to8duringCS.tpuerta.CS2;
HistTrigCS.Day3.tpuerta.CS2(:,7) = OUTPUT_HIST.Day3.sec8to10duringCS.tpuerta.CS2;
HistTrigCS.Day3.tpuerta.CS2(:,8) = OUTPUT_HIST.Day3.postCS2.tpuerta.CS2;
HistTrigCS.Day3.tpuerta.CS2(:,9) = OUTPUT_HIST.Day3.postCS4.tpuerta.CS2;

HistTrigCS.Day4.tpuerta.CS1(:,1) = OUTPUT_HIST.Day4.pre4.tpuerta.CS1;
HistTrigCS.Day4.tpuerta.CS1(:,2) = OUTPUT_HIST.Day4.pre2.tpuerta.CS1;
HistTrigCS.Day4.tpuerta.CS1(:,3) = OUTPUT_HIST.Day4.sec0to2duringCS.tpuerta.CS1;
HistTrigCS.Day4.tpuerta.CS1(:,4) = OUTPUT_HIST.Day4.sec2to4duringCS.tpuerta.CS1;
HistTrigCS.Day4.tpuerta.CS1(:,5) = OUTPUT_HIST.Day4.sec4to6duringCS.tpuerta.CS1;
HistTrigCS.Day4.tpuerta.CS1(:,6) = OUTPUT_HIST.Day4.sec6to8duringCS.tpuerta.CS1;
HistTrigCS.Day4.tpuerta.CS1(:,7) = OUTPUT_HIST.Day4.sec8to10duringCS.tpuerta.CS1;
HistTrigCS.Day4.tpuerta.CS1(:,8) = OUTPUT_HIST.Day4.postCS2.tpuerta.CS1;
HistTrigCS.Day4.tpuerta.CS1(:,9) = OUTPUT_HIST.Day4.postCS4.tpuerta.CS1;

HistTrigCS.Day4.tpuerta.CS2(:,1) = OUTPUT_HIST.Day4.pre4.tpuerta.CS2;
HistTrigCS.Day4.tpuerta.CS2(:,2) = OUTPUT_HIST.Day4.pre2.tpuerta.CS2;
HistTrigCS.Day4.tpuerta.CS2(:,3) = OUTPUT_HIST.Day4.sec0to2duringCS.tpuerta.CS2;
HistTrigCS.Day4.tpuerta.CS2(:,4) = OUTPUT_HIST.Day4.sec2to4duringCS.tpuerta.CS2;
HistTrigCS.Day4.tpuerta.CS2(:,5) = OUTPUT_HIST.Day4.sec4to6duringCS.tpuerta.CS2;
HistTrigCS.Day4.tpuerta.CS2(:,6) = OUTPUT_HIST.Day4.sec6to8duringCS.tpuerta.CS2;
HistTrigCS.Day4.tpuerta.CS2(:,7) = OUTPUT_HIST.Day4.sec8to10duringCS.tpuerta.CS2;
HistTrigCS.Day4.tpuerta.CS2(:,8) = OUTPUT_HIST.Day4.postCS2.tpuerta.CS2;
HistTrigCS.Day4.tpuerta.CS2(:,9) = OUTPUT_HIST.Day4.postCS4.tpuerta.CS2;

HistTrigCS.Day5.tpuerta.CS1(:,1) = OUTPUT_HIST.Day5.pre4.tpuerta.CS1;
HistTrigCS.Day5.tpuerta.CS1(:,2) = OUTPUT_HIST.Day5.pre2.tpuerta.CS1;
HistTrigCS.Day5.tpuerta.CS1(:,3) = OUTPUT_HIST.Day5.sec0to2duringCS.tpuerta.CS1;
HistTrigCS.Day5.tpuerta.CS1(:,4) = OUTPUT_HIST.Day5.sec2to4duringCS.tpuerta.CS1;
HistTrigCS.Day5.tpuerta.CS1(:,5) = OUTPUT_HIST.Day5.sec4to6duringCS.tpuerta.CS1;
HistTrigCS.Day5.tpuerta.CS1(:,6) = OUTPUT_HIST.Day5.sec6to8duringCS.tpuerta.CS1;
HistTrigCS.Day5.tpuerta.CS1(:,7) = OUTPUT_HIST.Day5.sec8to10duringCS.tpuerta.CS1;
HistTrigCS.Day5.tpuerta.CS1(:,8) = OUTPUT_HIST.Day5.postCS2.tpuerta.CS1;
HistTrigCS.Day5.tpuerta.CS1(:,9) = OUTPUT_HIST.Day5.postCS4.tpuerta.CS1;

HistTrigCS.Day5.tpuerta.CS2(:,1) = OUTPUT_HIST.Day5.pre4.tpuerta.CS2;
HistTrigCS.Day5.tpuerta.CS2(:,2) = OUTPUT_HIST.Day5.pre2.tpuerta.CS2;
HistTrigCS.Day5.tpuerta.CS2(:,3) = OUTPUT_HIST.Day5.sec0to2duringCS.tpuerta.CS2;
HistTrigCS.Day5.tpuerta.CS2(:,4) = OUTPUT_HIST.Day5.sec2to4duringCS.tpuerta.CS2;
HistTrigCS.Day5.tpuerta.CS2(:,5) = OUTPUT_HIST.Day5.sec4to6duringCS.tpuerta.CS2;
HistTrigCS.Day5.tpuerta.CS2(:,6) = OUTPUT_HIST.Day5.sec6to8duringCS.tpuerta.CS2;
HistTrigCS.Day5.tpuerta.CS2(:,7) = OUTPUT_HIST.Day5.sec8to10duringCS.tpuerta.CS2;
HistTrigCS.Day5.tpuerta.CS2(:,8) = OUTPUT_HIST.Day5.postCS2.tpuerta.CS2;
HistTrigCS.Day5.tpuerta.CS2(:,9) = OUTPUT_HIST.Day5.postCS4.tpuerta.CS2;

HistTrigCS.Day6.tpuerta.CS1(:,1) = OUTPUT_HIST.Day6.pre4.tpuerta.CS1;
HistTrigCS.Day6.tpuerta.CS1(:,2) = OUTPUT_HIST.Day6.pre2.tpuerta.CS1;
HistTrigCS.Day6.tpuerta.CS1(:,3) = OUTPUT_HIST.Day6.sec0to2duringCS.tpuerta.CS1;
HistTrigCS.Day6.tpuerta.CS1(:,4) = OUTPUT_HIST.Day6.sec2to4duringCS.tpuerta.CS1;
HistTrigCS.Day6.tpuerta.CS1(:,5) = OUTPUT_HIST.Day6.sec4to6duringCS.tpuerta.CS1;
HistTrigCS.Day6.tpuerta.CS1(:,6) = OUTPUT_HIST.Day6.sec6to8duringCS.tpuerta.CS1;
HistTrigCS.Day6.tpuerta.CS1(:,7) = OUTPUT_HIST.Day6.sec8to10duringCS.tpuerta.CS1;
HistTrigCS.Day6.tpuerta.CS1(:,8) = OUTPUT_HIST.Day6.postCS2.tpuerta.CS1;
HistTrigCS.Day6.tpuerta.CS1(:,9) = OUTPUT_HIST.Day6.postCS4.tpuerta.CS1;

HistTrigCS.Day6.tpuerta.CS2(:,1) = OUTPUT_HIST.Day6.pre4.tpuerta.CS2;
HistTrigCS.Day6.tpuerta.CS2(:,2) = OUTPUT_HIST.Day6.pre2.tpuerta.CS2;
HistTrigCS.Day6.tpuerta.CS2(:,3) = OUTPUT_HIST.Day6.sec0to2duringCS.tpuerta.CS2;
HistTrigCS.Day6.tpuerta.CS2(:,4) = OUTPUT_HIST.Day6.sec2to4duringCS.tpuerta.CS2;
HistTrigCS.Day6.tpuerta.CS2(:,5) = OUTPUT_HIST.Day6.sec4to6duringCS.tpuerta.CS2;
HistTrigCS.Day6.tpuerta.CS2(:,6) = OUTPUT_HIST.Day6.sec6to8duringCS.tpuerta.CS2;
HistTrigCS.Day6.tpuerta.CS2(:,7) = OUTPUT_HIST.Day6.sec8to10duringCS.tpuerta.CS2;
HistTrigCS.Day6.tpuerta.CS2(:,8) = OUTPUT_HIST.Day6.postCS2.tpuerta.CS2;
HistTrigCS.Day6.tpuerta.CS2(:,9) = OUTPUT_HIST.Day6.postCS4.tpuerta.CS2;

HistTrigCS.Day7.tpuerta.CS1(:,1) = OUTPUT_HIST.Day7.pre4.tpuerta.CS1;
HistTrigCS.Day7.tpuerta.CS1(:,2) = OUTPUT_HIST.Day7.pre2.tpuerta.CS1;
HistTrigCS.Day7.tpuerta.CS1(:,3) = OUTPUT_HIST.Day7.sec0to2duringCS.tpuerta.CS1;
HistTrigCS.Day7.tpuerta.CS1(:,4) = OUTPUT_HIST.Day7.sec2to4duringCS.tpuerta.CS1;
HistTrigCS.Day7.tpuerta.CS1(:,5) = OUTPUT_HIST.Day7.sec4to6duringCS.tpuerta.CS1;
HistTrigCS.Day7.tpuerta.CS1(:,6) = OUTPUT_HIST.Day7.sec6to8duringCS.tpuerta.CS1;
HistTrigCS.Day7.tpuerta.CS1(:,7) = OUTPUT_HIST.Day7.sec8to10duringCS.tpuerta.CS1;
HistTrigCS.Day7.tpuerta.CS1(:,8) = OUTPUT_HIST.Day7.postCS2.tpuerta.CS1;
HistTrigCS.Day7.tpuerta.CS1(:,9) = OUTPUT_HIST.Day7.postCS4.tpuerta.CS1;

HistTrigCS.Day7.tpuerta.CS2(:,1) = OUTPUT_HIST.Day7.pre4.tpuerta.CS2;
HistTrigCS.Day7.tpuerta.CS2(:,2) = OUTPUT_HIST.Day7.pre2.tpuerta.CS2;
HistTrigCS.Day7.tpuerta.CS2(:,3) = OUTPUT_HIST.Day7.sec0to2duringCS.tpuerta.CS2;
HistTrigCS.Day7.tpuerta.CS2(:,4) = OUTPUT_HIST.Day7.sec2to4duringCS.tpuerta.CS2;
HistTrigCS.Day7.tpuerta.CS2(:,5) = OUTPUT_HIST.Day7.sec4to6duringCS.tpuerta.CS2;
HistTrigCS.Day7.tpuerta.CS2(:,6) = OUTPUT_HIST.Day7.sec6to8duringCS.tpuerta.CS2;
HistTrigCS.Day7.tpuerta.CS2(:,7) = OUTPUT_HIST.Day7.sec8to10duringCS.tpuerta.CS2;
HistTrigCS.Day7.tpuerta.CS2(:,8) = OUTPUT_HIST.Day7.postCS2.tpuerta.CS2;
HistTrigCS.Day7.tpuerta.CS2(:,9) = OUTPUT_HIST.Day7.postCS4.tpuerta.CS2;

HistTrigCS.Day8.tpuerta.CS1(:,1) = OUTPUT_HIST.Day8.pre4.tpuerta.CS1;
HistTrigCS.Day8.tpuerta.CS1(:,2) = OUTPUT_HIST.Day8.pre2.tpuerta.CS1;
HistTrigCS.Day8.tpuerta.CS1(:,3) = OUTPUT_HIST.Day8.sec0to2duringCS.tpuerta.CS1;
HistTrigCS.Day8.tpuerta.CS1(:,4) = OUTPUT_HIST.Day8.sec2to4duringCS.tpuerta.CS1;
HistTrigCS.Day8.tpuerta.CS1(:,5) = OUTPUT_HIST.Day8.sec4to6duringCS.tpuerta.CS1;
HistTrigCS.Day8.tpuerta.CS1(:,6) = OUTPUT_HIST.Day8.sec6to8duringCS.tpuerta.CS1;
HistTrigCS.Day8.tpuerta.CS1(:,7) = OUTPUT_HIST.Day8.sec8to10duringCS.tpuerta.CS1;
HistTrigCS.Day8.tpuerta.CS1(:,8) = OUTPUT_HIST.Day8.postCS2.tpuerta.CS1;
HistTrigCS.Day8.tpuerta.CS1(:,9) = OUTPUT_HIST.Day8.postCS4.tpuerta.CS1;

HistTrigCS.Day8.tpuerta.CS2(:,1) = OUTPUT_HIST.Day8.pre4.tpuerta.CS2;
HistTrigCS.Day8.tpuerta.CS2(:,2) = OUTPUT_HIST.Day8.pre2.tpuerta.CS2;
HistTrigCS.Day8.tpuerta.CS2(:,3) = OUTPUT_HIST.Day8.sec0to2duringCS.tpuerta.CS2;
HistTrigCS.Day8.tpuerta.CS2(:,4) = OUTPUT_HIST.Day8.sec2to4duringCS.tpuerta.CS2;
HistTrigCS.Day8.tpuerta.CS2(:,5) = OUTPUT_HIST.Day8.sec4to6duringCS.tpuerta.CS2;
HistTrigCS.Day8.tpuerta.CS2(:,6) = OUTPUT_HIST.Day8.sec6to8duringCS.tpuerta.CS2;
HistTrigCS.Day8.tpuerta.CS2(:,7) = OUTPUT_HIST.Day8.sec8to10duringCS.tpuerta.CS2;
HistTrigCS.Day8.tpuerta.CS2(:,8) = OUTPUT_HIST.Day8.postCS2.tpuerta.CS2;
HistTrigCS.Day8.tpuerta.CS2(:,9) = OUTPUT_HIST.Day8.postCS4.tpuerta.CS2;

save('HistTrigCS.mat');

%% Borrar el dato 61 del Day 5 al Day 8

OUTPUT.Day5.pre4.tpuerta.CS2(61) = [];
OUTPUT.Day5.pre2.tpuerta.CS2(61) = [];
OUTPUT.Day5.sec0to2duringCS.tpuerta.CS2(61) = [];
OUTPUT.Day5.sec2to4duringCS.tpuerta.CS2(61) = [];
OUTPUT.Day5.sec4to6duringCS.tpuerta.CS2(61) = [];
OUTPUT.Day5.sec6to8duringCS.tpuerta.CS2(61) = [];
OUTPUT.Day5.sec8to10duringCS.tpuerta.CS2(61) = [];
OUTPUT.Day5.postCS2.tpuerta.CS2(61) = [];
OUTPUT.Day5.postCS4.tpuerta.CS2(61) = [];

OUTPUT.Day6.pre4.tpuerta.CS2(61) = [];
OUTPUT.Day6.pre2.tpuerta.CS2(61) = [];
OUTPUT.Day6.sec0to2duringCS.tpuerta.CS2(61) = [];
OUTPUT.Day6.sec2to4duringCS.tpuerta.CS2(61) = [];
OUTPUT.Day6.sec4to6duringCS.tpuerta.CS2(61) = [];
OUTPUT.Day6.sec6to8duringCS.tpuerta.CS2(61) = [];
OUTPUT.Day6.sec8to10duringCS.tpuerta.CS2(61) = [];
OUTPUT.Day6.postCS2.tpuerta.CS2(61) = [];
OUTPUT.Day6.postCS4.tpuerta.CS2(61) = [];

OUTPUT.Day7.pre4.tpuerta.CS2(61) = [];
OUTPUT.Day7.pre2.tpuerta.CS2(61) = [];
OUTPUT.Day7.sec0to2duringCS.tpuerta.CS2(61) = [];
OUTPUT.Day7.sec2to4duringCS.tpuerta.CS2(61) = [];
OUTPUT.Day7.sec4to6duringCS.tpuerta.CS2(61) = [];
OUTPUT.Day7.sec6to8duringCS.tpuerta.CS2(61) = [];
OUTPUT.Day7.sec8to10duringCS.tpuerta.CS2(61) = [];
OUTPUT.Day7.postCS2.tpuerta.CS2(61) = [];
OUTPUT.Day7.postCS4.tpuerta.CS2(61) = [];

OUTPUT.Day8.pre4.tpuerta.CS2(61) = [];
OUTPUT.Day8.pre2.tpuerta.CS2(61) = [];
OUTPUT.Day8.sec0to2duringCS.tpuerta.CS2(61) = [];
OUTPUT.Day8.sec2to4duringCS.tpuerta.CS2(61) = [];
OUTPUT.Day8.sec4to6duringCS.tpuerta.CS2(61) = [];
OUTPUT.Day8.sec6to8duringCS.tpuerta.CS2(61) = [];
OUTPUT.Day8.sec8to10duringCS.tpuerta.CS2(61) = [];
OUTPUT.Day8.postCS2.tpuerta.CS2(61) = [];
OUTPUT.Day8.postCS4.tpuerta.CS2(61) = [];

%% Grafico dotplot + bars

% Seteamos el path donde estan los datos

% Cargamos los datos
load('HistTrigCS.mat')
datos = HistTrigCS.Day2.tpuerta.CS1; 
which = 't';
subplot(2,4,1);

% Seteamos algunos parámetros
n_tr = 5;           % Número de días de entrenamiento
n_ext = 1;          % Número de días de extinción.
n_ts = 1;           % Número de días de testeo.

% Seteamos el texto del título
titletext = 'TR1';

%-----------------------------------------------------------------------------------%
% Ploteamos el area sombreada
g = [2.5 7.5];
h = [2000 2000];
shade = area(g,h);
shade.FaceColor = [0.9 0.9 0.9];
shade.EdgeColor = [0.9 0.9 0.9];
shade.LineWidth = 0.1;
hold on

% Labels para el eje x.
if n_tr > 0;
    for i = 1:n_tr;
        xlabels(i,:) = strcat('TR',int2str(i));
    end
end
if n_ext > 0;
    for i = 1:n_ext;
        xlabels(i+n_tr,:) = strcat('EX',int2str(i));
    end
end
if n_ts > 0;
    for i = 1:n_ts;
        xlabels(i+n_tr+n_ext,:) = strcat('TS',int2str(i));
    end
end

% Labels para el eje y:
if which == 't';
    ylab = 'Tiempo acumulado (ms)'; limsupy = 2000;
elseif which == 'n';
    ylab = '# de nosepokes por trial'; limsupy = 30;
elseif which == 'l';
    ylab = 'Latencia al primer nosepoke (ms)'; limsupy = 10000;
elseif which == 'p';
    ylab = 'Porcentaje de trials con nosepokes (%)'; limsupy = 100;
end

% Ploteamos la figura

if which == 't' | which == 'n' | which == 'l';
    dotseparation = 10;                                                 % Separación de puntos. Valor entre 0 y 100
    pre_color = [190 190 190]/255; % Color de los puntos para el CS1 o CS+
    cs1_color = [255 67 66]/255; % Color de los puntos para el CS1 o CS+
    cs2_color = [70 171 215]/255; % Color de los puntos para el CS2 o CS-
    dmean = nanmean(datos);                                                    % Mean
    stderror= nanstd(datos)/sqrt(length(datos));
    xt = [1:size(datos,2)];                                                         % X-Ticks
    xtd = repmat(xt, size(datos,1), 1);                                  % X-Ticks For Data
    for i = 1:size(xtd,1)
        for j = 1:size(xtd,2)
        xtdd(i,j) = xtd(i,j) + (randi([-dotseparation,dotseparation])/100);
        end
    end
    figure(1)
    p_cs1_dots = plot(xtdd(:,(1:size(datos,2))), datos(:,(1:size(datos,2))),'MarkerSize',2,'Marker','o','LineStyle','none',...)
         'Color', cs2_color, 'MarkerFaceColor', cs2_color);
    hold on
    p_cs1_bar = bar(xt(:,(1:size(datos,2))),dmean(:,(1:size(datos,2))),0.8,'FaceColor',cs2_color);
        p_cs1_bar.FaceAlpha = 0.3;
    hold on
    e = errorbar(xt,dmean,stderror); e.Color = 'black'; e.LineStyle = 'none'; 
    hold off
    xlim([0 (size(datos,2)+1)]);
    ylim([0 limsupy]);
    set(gca, 'XTick', xt, 'XTickLabel', {'-4','-2','0','2','4','6','8','10','12'});
    ylabel(ylab,'FontSize', 8);
    xlabel('Tiempo desde el onset del CS+ (seg)','FontSize', 8);
    title(titletext, 'FontSize', 8);
    set(gca,'FontSize',8);

    % Hacemos la estadística: ttest
    [p] = ranksum(datos(:,3),datos(:,4));
    j = 1;
    for i = 1:2:(size(datos,2)-1);
        [p] = ranksum(datos(:,i),datos(:,i+1));
        p = p * (size(datos,2)/2); % Correjimos por múltiples comparaciones
        p_value(j) = p;
        if p >= 0.05;
            p_value_res = 'ns';
        elseif p < 0.05 && p >= 0.01;
            p_value_res = '*';
        elseif p < 0.01 && p >= 0.001 ;
            p_value_res = '**';        
        elseif p < 0.001 && p >= 0.0001  ;
            p_value_res = '***';
        elseif p < 0.0001 && p >= 0.00001 ;
            p_value_res = '****';
        else
            p_value_res = '*****';
        end
        %text((i+0.5),limsupy,p_value_res,...
            %'HorizontalAlignment','center','VerticalAlignment','top','FontSize',8);
        j = j + 1;  
    end
end

if which == 'p';
    cs1_color = [255 67 66]/255; % Color de los puntos para el CS1 o CS+
    cs2_color = [70 171 215]/255; % Color de los puntos para el CS2 o CS-
    p_cs1_bar = bar((1:2:size(datos,2)),datos(1:2:size(datos,2)),0.4,'FaceColor',cs1_color);
    hold on
    p_cs2_bar = bar((2:2:size(datos,2)),datos(2:2:size(datos,2)),0.4,'FaceColor',cs2_color);
    hold on
    ax = gca;
    ax.XAxis.TickValues = (1:1:size(datos,2));
    e = errorbar((1:size(datos,2)),datos,repelem(0,size(datos,2))); e.Color = 'black'; e.LineStyle = 'none';
    xlim([0 (size(datos,2)+1)]);
    ylim([0 limsupy]);
    set(gca,'XTickLabel', {'CS+','CS-'});
    ylabel(ylab,'FontSize', 8);
    title(titletext, 'FontSize', 8);
    set(gca,'FontSize',8);
    
    % Hacemos la estadística: Chi-squared
    j = 1;
    for i = 1:2:(size(datos,2)-1);
        
        a = datos(i); n1 = round(a*0.6); N1 = 60;
        b = datos(i+1); n2 = round(b*0.6); N2 = 60;
        x1 = [repmat('a',N1,1); repmat('b',N2,1)];
        x2 = [repmat(1,n1,1); repmat(2,N1-n1,1); repmat(1,n2,1); repmat(2,N2-n2,1)];
        [tbl,chi2stat,pval] = crosstab(x1,x2);
        
        pval = pval * (size(datos,2)/2); % Correjimos por múltiples comparaciones
        p_value(j) = pval;
        
        if pval >= 0.05;
            p_value_res = 'ns';
        elseif pval < 0.05 && pval >= 0.01;
            p_value_res = '*';
        elseif pval < 0.01 && pval >= 0.001;
            p_value_res = '**';        
        elseif pval < 0.001 && pval >= 0.0001;
            p_value_res = '***';
        elseif pval < 0.0001 && pval >= 0.00001;
            p_value_res = '****';
        else
            p_value_res = '*****';
        end
        %text((i+0.5),limsupy,p_value_res,...
        %    'HorizontalAlignment','center','VerticalAlignment','top','FontSize',8);
        j = j + 1;  
    end
end