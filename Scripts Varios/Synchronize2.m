%% Sincronización de LED sincro en TTL y video 
% Extrae los datos de encendido y apagado del led en el TTL del registro
% Extrae los datos de encendido y apagado del led en el video
% Sincroniza ambas señales y guarda un .csv con los timestamps de cada
% frame del video alineados al reloj del registro.

% OUTPUT: video_timestamps son los tiempos de cada frame en muestras (si la primer muestra es 0)

% El testeo del script lo hice con R11D12

clear all;
clc;
path = pwd;
cd(path);

% Extraemos el nombre de la carpeta: animal y sesión
[~,name,~] = fileparts(pwd);
name = name(1:6);

% Cargamos los datos del TTL1
TTL_states = readNPY(strcat(name,'_TTL_channel_states.npy')); % Cargamos el estado de cada input del IO Board. 
TTL_timestamps = readNPY(strcat(name,'_TTL_timestamps.npy')); % Los timestamps estan en unidad de muestreo: 30 kHz.
TTL_channels = readNPY(strcat(name,'_TTL_channels.npy')); % Cargamos los estados de los canales.

% Cargamos los datos del amplificador
amplifier_timestamps = readNPY(strcat(name,'_timestamps.npy')); % Cargamos el estado de cada input del IO Board.
amplifier_timestamps = double(amplifier_timestamps(1):1:amplifier_timestamps(end)); % Hay que hacer esto porque amplifier.timestamps devuelve distinto número de tiempos que de registro.

% Buscamos el primer y el último timestamp
TTL_start = amplifier_timestamps(1); % Seteamos el primer timestamp 
TTL_end = amplifier_timestamps(end); % Seteamos el último timestamp

% Inicio y fin del CS+ asociado con la recompensa. Entrada #1 del IO board.
TTL_CS1_start = TTL_timestamps(find(TTL_states == 1));
TTL_CS1_end = TTL_timestamps(find(TTL_states == -1));
% Inicio y fin del CS-. Entrada #1 del IO board. Entrada #2 del IO board.
TTL_CS2_start = TTL_timestamps(find(TTL_states == 2));
TTL_CS2_end = TTL_timestamps(find(TTL_states == -2));

% Eliminar aquellos TTL de CS que no tengan la duración indicada
TTL_CS1_duration = TTL_CS1_end - TTL_CS1_start;
TTL_CS1_start(find(TTL_CS1_duration < 200000)) = [];
TTL_CS1_end(find(TTL_CS1_duration < 200000)) = [];
TTL_CS2_duration = TTL_CS2_end - TTL_CS2_start;
TTL_CS2_start(find(TTL_CS2_duration < 200000)) = [];
TTL_CS2_end(find(TTL_CS2_duration < 200000)) = [];
clear TTL_CS1_duration TTL_CS2_duration;

% Inicio y fin del LED de sincronización
TTL_sincro_start = TTL_timestamps(find(TTL_states == 7));
TTL_sincro_end = TTL_timestamps(find(TTL_states == -7));

% Borramos el timestamps si arranca con un end o si termina con un start
% Para que ambas variables tengan el mismo tamaño
if TTL_sincro_start(1) > TTL_sincro_end(1);
    TTL_sincro_end(1) = [];
    while size(TTL_sincro_start,1) > size(TTL_sincro_end,1);
        TTL_sincro_start(end) = [];
    end
elseif TTL_sincro_end(end) < TTL_sincro_start(end);
    TTL_sincro_start(end) = [];
    while size(TTL_sincro_end,1) > size(TTL_sincro_start,1);
        TTL_sincro_end(1) = [];
    end
end

% Llevo los tiempos del CS1 a segundos y los sincronizo con los tiempos del registro
TTL_CS1_inicio = TTL_CS1_start - TTL_start; TTL_CS1_inicio = double(TTL_CS1_inicio);
TTL_CS1_fin = TTL_CS1_end - TTL_start; TTL_CS1_fin = double(TTL_CS1_fin);
% Llevo los tiempos del CS2 a segundos y los sincronizo con los tiempos del registro
TTL_CS2_inicio = TTL_CS2_start - TTL_start; TTL_CS2_inicio = double(TTL_CS2_inicio);
TTL_CS2_fin = TTL_CS2_end - TTL_start; TTL_CS2_fin = double(TTL_CS2_fin);
% Llevo los tiempos del CS2 a segundos y los sincronizo con los tiempos del registro
TTL_sincro_inicio = TTL_sincro_start - TTL_start; TTL_sincro_inicio = double(TTL_sincro_inicio);
TTL_sincro_fin = TTL_sincro_end - TTL_start; TTL_sincro_fin = double(TTL_sincro_fin);

% Calculamos la duración de cada pulso de luz LED
TTL_sincro_duration = TTL_sincro_fin - TTL_sincro_inicio;

% Importamos los timestamps del video, los transformamos a ms y los sincronizamos con el registro.
filename = strcat(name,'_video_timestamps.csv');
delimiter = '';
formatSpec = '%q%[^\n\r]';
fileID = fopen(filename,'r');
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'EmptyValue' ,NaN, 'ReturnOnError', false);
fclose(fileID);
video_timestamps = dataArray{:, 1};
clearvars filename delimiter formatSpec fileID dataArray ans;
video_timestamps(1) = [];

DateStrings = {'2022-08-30T11:43:51.8970880-03:00';'2022-08-30T11:43:51.9287552-03:00';'2022-08-30T11:43:52.7659392-03:00'};
t = datetime(video_timestamps,'InputFormat','uuuu-MM-dd''T''HH:mm:ss.SSSSSSSz','TimeZone','UTC');
t.Format = 'HH:mm:ss.SSSSSSS';
format long;
HH = hour(t);
mm = minute(t);
ss = second(t);
video_timestamps = HH*60*60*1000 + mm*60*1000 + ss*1000; % video_timestamps está en unidades de Fs.
video_timestamps = int64(video_timestamps);
video_timestamps = double(video_timestamps);
video_start = video_timestamps(1);
video_end = video_timestamps(end);
clear ss t mm i HH DateStrings;

% Chequeamos si existen los archivos de bonsai
if exist(strcat(name,'_bonsai_sincro.csv'))
    video_sincro = csvread(strcat(name,'_bonsai_sincro.csv'));
    video_CS1 = csvread(strcat(name,'_bonsai_CS1.csv'));
    video_CS2 = csvread(strcat(name,'_bonsai_CS2.csv'));
else
    disp('Bonsai files do not exist. Resuming');
end

% Importamos el análisis del video con los timestamps crudos.

% Extraemos los frames de SINCRO
video_sincro_zscore = zscore(video_sincro);
video_sincro_zscore = video_sincro_zscore - min(video_sincro_zscore);
video_sincro_on = video_sincro_zscore >= 0.1;
sincro_on = video_timestamps(find(diff(video_sincro_on) == 1));
sincro_off = video_timestamps(find(diff(video_sincro_on) == -1));
if sincro_off(1) < sincro_on(1);
    sincro_off(1) = [];
    while size(sincro_on,1) > size(sincro_off,1);
        sincro_on(end) = [];
    end
elseif sincro_off(end) < sincro_on(end);
    sincro_on(end) = [];
    while size(sincro_off,1) > size(sincro_on,1);
        sincro_off(1) = [];
    end
end
video_sincro_duration = sincro_off - sincro_on;
% En alcunos casos (R14 por ejemplo) hay que cambiar esta condición porque la dinámica del LED sincro es distinta
video_sincro_starttask = sincro_on(min(find(video_sincro_duration > 500))); % Timestamp del frame en el cual inicia el primer pulso largo de inicio de la tarea
video_sincro_startask_frame = find(video_timestamps == video_sincro_starttask)+1; % Frame en el cual inicia el pulso largo del inicio de la tarea

% Triggereamos el video_timestamps en el momento del led Sincro.
video_timestamps = video_timestamps - video_timestamps(video_sincro_startask_frame);

% Buscamos el tiempo de registro en el que inicia el pulso largo en el TTL
start_session = find(TTL_sincro_duration > 20000); % En alcunos casos (R14 por ejemplo) hay que cambiar esta condición porque la dinámica del LED sincro es distinta
start_session = start_session(1);
start_session = TTL_sincro_inicio(start_session); % Tiempo de registro en muestras donde está el pulso de inicio de sesión (contando desde 0 ms en la primer muestra)

% A los tiempos de los frames del video en ms, centrados en 0 en el frame
% que inicia el pulso largo, le sumamos el tiempo en muestras.
video_timestamps = video_timestamps*30 + start_session;
video_timestamps = double(video_timestamps);

% Corregimos los tiempos a partir del pulso CS1
video_CS1_zscore = zscore(video_CS1);
video_CS1_zscore = video_CS1_zscore - min(video_CS1_zscore);
video_CS1_on = video_CS1_zscore >= 1;
CS1_on = video_timestamps(find(diff(video_CS1_on) == 1));
CS1_off = video_timestamps(find(diff(video_CS1_on) == -1));
CS1_duration = CS1_off - CS1_on;
CS1_on = CS1_on(find(CS1_duration > 8*30000));
CS1_off = CS1_off(find(CS1_duration > 8*30000));
CS1_duration = CS1_off - CS1_on;

% Corregimos los timestamps a partir de cada pulso de CS1
% Me genera una variable llamada video_timestamps_corrected que tiene los
% timestamps de cada frame en unidades de samples donde el 0 es el primer sample
% del registro
video_timestamps_corrected = video_timestamps;
step = diff(video_timestamps);
for i = 1:size(CS1_on,1);
    pos = find(video_timestamps == CS1_on(i));
    video_timestamps_corrected(pos) = TTL_CS1_inicio(i);
    for j = 1:size(video_timestamps(pos+1:end))
        video_timestamps_corrected(pos+j) = video_timestamps_corrected(pos+j-1)+step(pos+j-1);
    end
end

% Ploteamos para ver si la sincronización se realizó correctamente
figure;
ax1 = subplot(211);
stem(TTL_timestamps-TTL_start,TTL_states==7);
hold on;
stem(TTL_timestamps-TTL_start,TTL_states==1);
ylim([-0.5 1.5]);
title('Pulso de sincronización TTL');
ax2 = subplot(212);
plot(video_timestamps_corrected,video_sincro_on);
hold on;
scatter(CS1_on,repmat(1,size(CS1_on,1),1));
hold on;
scatter(TTL_CS1_inicio,repmat(1,size(TTL_CS1_inicio,1),1));
ylim([-0.5 1.5]);
title('Pulso de sincronización Bonsai');

linkaxes([ax1, ax2], 'x');

%% Guardamos los timestamps en un archivo .csv
video_timestamps_synchronized = video_timestamps_corrected;
filename = strcat(name,'_video_timestamps_synchronized.csv');
csvwrite(filename,video_timestamps_synchronized);
disp(strcat(filename,' was successfully saved in D:!'));

% Guardar también en H:
% Get the current directory
currentDir = pwd;
parts = strsplit(currentDir, '\');
lastTwoParts = fullfile(parts{end-1}, parts{end});
newPath = fullfile('H:\', lastTwoParts);
cd(newPath);
csvwrite(filename,video_timestamps_synchronized);
disp(strcat(filename,' was successfully saved in H:!'));
cd(path);