%% Sincronizamos el registro, con el acelerómetro, con los eventos y con los frames del video.
% Este script requiere correr primero el archivo "Video_analysis.bonsai" para obtener los archivos .csv de los que se alimenta este script
clear all
clc
%% Importamos el registro con sus timestamps crudos.
cd('D:\Doctorado\Backup Ordenado\R11\R11D12');
% Importamos el registro.
Fs = 30000;
channel = 5;
num_channels = 35;
[data] = LoadBinary('continuous.dat', channel, num_channels); 
amplifier_data = data * 0.195;
% Importamos los timestamps.
amplifier_timestamps = readNPY('timestamps.npy');
amplifier_start = amplifier_timestamps(1);
amplifier_end = amplifier_timestamps(end);
amplifier_timestamps = (amplifier_start:1:amplifier_end)'; % Esto lo hago porque a veces el archivo "timestamps.npy" esta fallado y le faltan datos. Entonces construyo nuevamente el vector tiempo a partir del timestamps de inicio y el final.
% plot(data) % Ploteamos la señal de LFP en función de los datos.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Cargado y sincronizado

%% Importamos el acelerómetro con sus timestamps crudos.
cd('D:\Doctorado\Electrofisiología\Vol 11\Day12_2022-08-30_11-43-46_Rat1\Record Node 101\experiment1\recording1\continuous\Rhythm_FPGA-100.0');
[amplifier_aux1]=LoadBinary('continuous.dat', 33, 35); % Cargamos señal de AUX1
amplifier_aux1 = amplifier_aux1 * 0.0000374; % Convertimos a volts

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Cargado y sincronizado

%% Importamos los eventos con sus timestamps crudos.
cd('D:\Doctorado\Electrofisiología\Vol 11\Day12_2022-08-30_11-43-46_Rat1\Record Node 101\experiment1\recording1\events\Rhythm_FPGA-100.0\TTL_1');
TTL_states = readNPY('channel_states.npy'); % Cargamos el estado de cada input del IO Board.
TTL_timestamps = readNPY('timestamps.npy'); % Los timestamps estan en unidad de muestreo: 10kHz
TTL_channels = readNPY('channels.npy'); % Cargamos los estados de los canales.
TTL_start = TTL_timestamps(1);
TTL_end = TTL_timestamps(end);

TTL_sincro_start = TTL_timestamps(find(TTL_states == 7));
TTL_sincro_end = TTL_timestamps(find(TTL_states == -7));

if TTL_sincro_start(1) > TTL_sincro_end(1);
    TTL_sincro_end(1) = [];
elseif TTL_sincro_end(end) < TTL_sincro_start(end);
    TTL_sincro_start(end) = [];
end

TTL_sincro_duracion = TTL_sincro_end - TTL_sincro_start;
TTL_sincro_starttask = TTL_sincro_start(min(find(TTL_sincro_duracion > 20000))); % ms en el cual inicia el primer pulso largo de inicio de la tarea.

TTL_timestamps = TTL_timestamps - TTL_sincro_starttask;
amplifier_timestamps = amplifier_timestamps - TTL_sincro_starttask;

TTL_sincro_duracion_timestamps = TTL_timestamps(find(TTL_states == 7));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Cargado y sincronizado

%% Importamos el análisis del video con los timestamps crudos.
% Importamos Offline_freezing
filename = 'C:\Users\santi\Desktop\Offline_freezing2022-10-18T17_38_49.csv';
delimiter = '';
formatSpec = '%f%[^\n\r]';
fileID = fopen(filename,'r');
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'EmptyValue' ,NaN, 'ReturnOnError', false);
fclose(fileID);
video_freezing = dataArray{:, 1};
clearvars filename delimiter formatSpec fileID dataArray ans;

% Importamos Offline_sincro
filename = 'C:\Users\santi\Desktop\Offline_sincro2022-10-18T17_38_49.csv';
delimiter = '';
formatSpec = '%f%[^\n\r]';
fileID = fopen(filename,'r');
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'EmptyValue' ,NaN, 'ReturnOnError', false);
fclose(fileID);
video_sincro = dataArray{:, 1};
clearvars filename delimiter formatSpec fileID dataArray ans;

% Extraemos los frames de SINCRO
video_sincro_zscore = zscore(video_sincro);
video_sincro_zscore = video_sincro_zscore - min(video_sincro_zscore);
video_sincro_on = video_sincro_zscore >= 1;
sincro_on = video_timestamps(find(diff(video_sincro_on) == 1));
sincro_off = video_timestamps(find(diff(video_sincro_on) == -1));
if sincro_off(1) < sincro_on(1);
    sincro_off(1) = [];
end
video_sincro_duration = sincro_off - sincro_on;
video_sincro_starttask = sincro_on(min(find(video_sincro_duration > 10000))); % Frame en el cual inicia el primer pulso largo de inicio de la tarea. Dura 25 frames. 

% Importamos los timestamps del video, los transformamos a ms y los sincronizamos con el registro.
cd('D:\Doctorado\Electrofisiología\Vol 11');
filename = 'D:\Doctorado\Electrofisiología\Vol 11\video_timestamps2022-08-30T11_43_48.csv';
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
video_timestamps = HH*60*60*1000*30 + mm*60*1000*30 + ss*1000*30; % video_timestamps está en unidades de Fs.
video_timestamps = int64(video_timestamps);
video_start = video_timestamps(1);
video_end = video_timestamps(end);

% Triggereamos el video_timestamps en el momento del led Sincro.
video_timestamps = video_timestamps - video_sincro_starttask;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Cargado y sincronizado

%% Ploteamos video_sincro y TTL_sincro con el eje x linkeado
j = 1;
for i = 1:length(TTL_sincro_start);
    TTL_sincro_timestamps(j,1) = TTL_sincro_start(i);
    TTL_sincro(j,1) = 1;
    TTL_sincro_timestamps(j+1,1) = TTL_sincro_end(i);
    TTL_sincro(j+1,1) = -1;
    j = length(TTL_sincro_timestamps) + 1;
end

ax1 = subplot(2,1,1);
plot(TTL_sincro_timestamps,TTL_sincro);
hold on
ax2 = subplot(2,1,2);
plot(video_timestamps,video_sincro);
hold on
linkaxes([ax1 ax2],'x');
hold off


%% Ploteamos la señal del acelerómetro junto con el movimiento detectado en el video. 
ax1 = subplot(2,1,1);
plot(amplifier_timestamps,amplifier_aux1);
hold on
ax2 = subplot(2,1,2);
plot(video_timestamps,video_freezing)
hold on
linkaxes([ax1 ax2],'x');

%% Todos los timestamps de este script están en unidades de Fs.
% Para pasarlo a ms hay que dividir por 30.
% Para pasarlo a seg hay que dividir por 30000.