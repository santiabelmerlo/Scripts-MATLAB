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

%     clear all
    clc
    path = 'D:\Doctorado\Electrofisiología\Vol 11\'; % path en IFIBIO
    cd(path);

    [filpath,name,ext] = fileparts(cd); clear ext; clear filpath;
    d = dir(cd); dfolders = d([d(:).isdir]); dfolders = dfolders(~ismember({dfolders(:).name},{'.','..'}));

    a = 2; % Día 12 y 14 son Folders 2 y 4
    path1 = [path dfolders(a).name;];
    name = dfolders(a).name;
    cd(path1);
    cd('./Record Node 101/experiment1/recording1/events/Rhythm_FPGA-100.0/TTL_1/')

    % Cargamos los datos de los TTL y los timestamps.
    TTL.states = readNPY('channel_states.npy'); % Cargamos el estado de cada input del IO Board. 
    TTL.timestamps = readNPY('timestamps.npy'); % Los timestamps estan en unidad de muestreo: 30kHz
    TTL.channels = readNPY('channels.npy'); % Cargamos los estados de los canales.
    
    % Cargamos los timestamps del registro.
    cd(path1);
    cd('./Record Node 101/experiment1/recording1/continuous/Rhythm_FPGA-100.0/')
    data_timestamps = readNPY('timestamps.npy');
    data_start = data_timestamps(1);
    data_end = data_timestamps(end);
    data_timestamps = (data_start:1:data_end)'; % Esto lo hago porque a veces el archivo "timestamps.npy" esta fallado y le faltan datos. Entonces construyo nuevamente el vector tiempo a partir del timestamps de inicio y el final. 
    
    % Buscamos los tiempos asociados a cada evento.
    TTL.timestamps = TTL.timestamps - (data_start + 1); % Restamos el timestamps del primer dato de registro para sincronizar TTL y registro.
    % Inicio y fin del CS+ asociado con la recompensa. Entrada #1 del IO board.
    CS1.start = TTL.timestamps(find(TTL.states == 1));
    CS1.end = TTL.timestamps(find(TTL.states == -1));
    % Inicio y fin del CS-. Entrada #1 del IO board. Entrada #2 del IO board.
    CS2.start = TTL.timestamps(find(TTL.states == 2));
    CS2.end = TTL.timestamps(find(TTL.states == -2));
    % Inicio y fin de los nosepokes en el target. Entrada #6 del IO board.
    IR3.start = TTL.timestamps(find(TTL.states == 6));
    IR3.end = TTL.timestamps(find(TTL.states == -6));
    
%% Cargamos la señal
cd(path1);
cd('./Record Node 101/experiment1/recording1/continuous/Rhythm_FPGA-100.0/')

Fs = 30000;
channel = 1;
num_channels = 70;
downsample = 24; % Para pasar de 
[data] = LoadBinary('continuous.dat', channel, num_channels); 
data = data * 0.195;
% data(abs(data) > 1000) = 0;
plot(data) % Ploteamos la señal de LFP en función de los datos

%% Cortamos la señal en trozos que comienzan 20 seg antes del onset del tono y terminan 20 segundos despues del onset del tono
for i = 1:60;
    data_CS1(i,:) = data((CS1.start(i)-(20*Fs)):(CS1.start(i)+(20*Fs)-1));
    data_CS2(i,:) = data((CS2.start(i)-(20*Fs)):(CS2.start(i)+(20*Fs)-1));
end

%%
for i = 200:400;
    data_IR3(i,:) = data((IR3.start(i)-(10*Fs)):(IR3.start(i)+(20*Fs)-1));
end

%% Seteamos algunos parámetros para luego computar el espectrograma y espectro de potencias.
clear S; clear SS; clear f; clear t;

%clearvars -except CS1 CS2 data data_CS1 data_CS2 Fs 

params.Fs = 30000; % Frecuencia de muestreo: 1250 muestras por segundo.
params.fpass=[2 12]; % Frecuencias de interes. En este caso de 26 a 34 Hz.
params.err=0;
params.tapers=[3 5]; %[3 5]
movingwin=[5 0.5]; %[0.5 0.05]

for i = 1:20;
    % Computamos el espectrograma.
    % Computamos el espectrograma. Quitamos Serr porque no queremos calcular el error.
    [S,t,f] = mtspecgramc(data_CS1(i,:),movingwin,params);
    
    % Multiplicamos por f para normalizar el espectrograma.
%     for j = 1:length(f);          
%         S(:,j) = S(:,j)*f(j);
%     end
    
    % Ploteamos el espectrograma
    SS(:,:,i) = S;
    ff(:,:,i) = f;
    tt(:,:,i) = t;
end

S = mean(SS,3);

% Ploteamos el espectrograma
 for i  = 1:20;
    plot_matrix(SS(:,:,i),t,f,'l'); xlabel(['Time (sec)']); ylabel(['Frequency (Hz)']);
    colormap jet;
    pause(5);
 end
%%
clear S;
clear SS;
clear ff;
clear tt;
clear t;
clear f;

%%
    % Multiplicamos por f para normalizar el espectrograma.
    for j = 1:length(f);          
    S(:,j) = S(:,j)*f(j);
    end
    
%% Ploteamos los 20 CSs con una pausa para visualizar

params.Fs = 30000; % Frecuencia de muestreo: 30000 muestras por segundo.
params.fpass=[20 100]; % Frecuencias de interes. En este caso de 26 a 34 Hz.
params.err=0;
params.tapers=[3 5];
movingwin= [2 0.5];
% movingwin= [0.5 0.05];
% movingwin= [5 0.5];

    for i = 1:20;

    clear S; clear f; clear t;

    [S,t,f] = mtspecgramc(data_CS2(i,:),movingwin,params);
    
    % Multiplicamos por f para normalizar el espectrograma.
    for j = 1:length(f);          
        S(:,j) = S(:,j)*f(j);
    end
    
    plot_matrix(S(:,:),t,f,'n'); xlabel(['Time (sec)']); ylabel(['Frequency (Hz)']);
    colormap jet;
    pause(0.2);
    
end