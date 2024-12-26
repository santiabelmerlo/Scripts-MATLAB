%% Sincronizamos los frames del video con las posiciones del registro
% Output: "synchronize.mat" n datos con las posiciones que tiene cada frame en el registro
clear all
clc

%%
path_amplifier = 'D:\Doctorado\Electrofisiología\Vol 11\Day12_2022-08-30_11-43-46_Rat1\Record Node 101\experiment1\recording1\continuous\Rhythm_FPGA-100.0';
path_events = 'D:\Doctorado\Electrofisiología\Vol 11\Day12_2022-08-30_11-43-46_Rat1\Record Node 101\experiment1\recording1\events\Rhythm_FPGA-100.0\TTL_1';
path_video = 'D:\Doctorado\Electrofisiología\Vol 11\Day12_2022-08-30_11-43-46_Rat1';

cd(path_amplifier);
% Importamos la señal del ch12 de BLA.
channel = 12; % Canal que elijo para importar
num_channels = 35; % Número de canales que tiene la señal (32 canales + 3 canales del acelerómetro)
[data] = LoadBinary('continuous.dat', channel, num_channels); % Importamos la señal como "data"
data = data * 0.195; % Multiplicamos la señal por 0.195 para llevar las unidades a uV (microvolts)
amplifier_BLA = data; % Guardamos la señal como "amplifier_BLA"
clear data channel num_channels; % Borro las variables que no me sirven más

% Importamos los timestamps de la señal
amplifier_timestamps = readNPY('timestamps.npy'); % Leemos el archivo "timestamps.npy" y guardamos como amplifier_timestamps
amplifier_timestamps = (amplifier_timestamps(1):1:amplifier_timestamps(end))'; % Esto lo hago porque a veces el archivo "timestamps.npy" esta fallado y le faltan datos. Entonces construyo nuevamente el vector tiempo a partir del timestamps de inicio y el final.

%% Importamos los eventos con sus timestamps crudos.
cd(path_events);
TTL_states = readNPY('channel_states.npy'); % Cargamos el estado de cada input del IO Board.
TTL_timestamps = readNPY('timestamps.npy'); % Los timestamps estan en unidad de muestreo: 10kHz
TTL_channels = readNPY('channels.npy'); % Cargamos los estados de los canales.
TTL_sincro_on = TTL_timestamps(find(TTL_states == 7));
TTL_sincro_off = TTL_timestamps(find(TTL_states == -7));

if TTL_sincro_on(1) > TTL_sincro_off(1);
    TTL_sincro_off(1) = [];
elseif TTL_sincro_off(end) < TTL_sincro_on(end);
    TTL_sincro_on(end) = [];
end
TTL_sincro_duration = TTL_sincro_off - TTL_sincro_on;
clear TTL_states TTL_timestamps TTL_channels; 


%% Importamos los timestamps del video, los transformamos a ms y los sincronizamos con el registro.
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
clear ss t mm i HH DateStrings;

%% Importamos el análisis del video con los timestamps crudos.
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
video_sincro_on = video_sincro_zscore >= 0.1;
sincro_on = video_timestamps(find(diff(video_sincro_on) == 1));
sincro_off = video_timestamps(find(diff(video_sincro_on) == -1));
if sincro_off(1) < sincro_on(1);
    sincro_off(1) = [];
end
video_sincro_duration = sincro_off - sincro_on;
video_sincro_starttask = sincro_on(min(find(video_sincro_duration > 10000))); % Timestamp del frame en el cual inicia el primer pulso largo de inicio de la tarea
video_sincro_startask_frame = find(video_timestamps == video_sincro_starttask); % Frame en el cual inicia el pulso largo del inicio de la tarea

% Triggereamos el video_timestamps en el momento del led Sincro.
% video_timestamps = video_timestamps - video_sincro_starttask;

%%
clear correct_sincro;
for i = 1:length(video_sincro_duration);
    if video_sincro_duration(i) > 5000 && video_sincro_duration(i) < 10000 | video_sincro_duration(i) > 29000 && video_sincro_duration(i) < 32000;
        correct_sincro(i,1) = 1;
    else
        correct_sincro(i,1) = 0;
    end
end
plot(correct_sincro)
%% video_sincro_duration; sincro_on; sincro_off; correct_sincro;
clear videosincro j;
j = 1;
for i = 1:length(sincro_on);
    if correct_sincro(i) == 1;
        videosincro.duration(j,1) = video_sincro_duration(i);
        videosincro.on(j,1) = sincro_on(i);
        videosincro.off(j,1) = sincro_off(i);
        j = j+1;
    elseif correct_sincro(i) == 0 && video_sincro_duration(i) > 32000;
        while videosincro.off(j-1,1) > 1.2*(sincro_on(i-1)-sincro_off(i-2)); % Aca esta el problema
            videosincro.on(j,1) = sincro_on(i-1)+(sincro_on(i-1)-sincro_on(i-2));
            videosincro.off(j,1) = sincro_off(i-1)+(sincro_off(i-1)-sincro_off(i-2));
            videosincro.duration(j,1) = sincro.off(j)-sincro.on(j);
            j = j+1;
        end
    end
end


%%
clear X;
for i = 1:length(sincro_on);
    X(i,1) = sincro_on(i+1)-sincro_off(i);
end