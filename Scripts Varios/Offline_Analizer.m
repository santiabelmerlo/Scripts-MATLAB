%% Análisis de los datos Offline
% Este Script se alimenta del output de correr el archivo Bonsai Video_analysis.bonsai
clear all   
clc
path = 'D:\Drive\Doctorado\Electrofisiología\Experimentos\Scripts\Scripts Bonsai\'; % path en IFIBIO
% path = 'C:\Users\santi\Desktop'; % path en IFIBIO
cd(path);

%% Importamos Offline_freezing
dir = dir('Offline_freezing*.csv');
filename = dir.name;
delimiter = '';
formatSpec = '%f%[^\n\r]';
fileID = fopen(filename,'r');
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'EmptyValue' ,NaN, 'ReturnOnError', false);
fclose(fileID);
Offline_freezing = dataArray{:, 1};
clearvars filename delimiter formatSpec fileID dataArray ans dir;

%% Importamos Offline_sincro
dir = dir('Offline_sincro*.csv');
filename = dir.name;
delimiter = '';
formatSpec = '%f%[^\n\r]';
fileID = fopen(filename,'r');
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'EmptyValue' ,NaN, 'ReturnOnError', false);
fclose(fileID);
Offline_sincro = dataArray{:, 1};
clearvars filename delimiter formatSpec fileID dataArray ans dir;

%% Importamos Offline_CS1
dir = dir('Offline_CS1*.csv');
filename = dir.name;
delimiter = '';
formatSpec = '%f%[^\n\r]';
fileID = fopen(filename,'r');
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'EmptyValue' ,NaN, 'ReturnOnError', false);
fclose(fileID);
Offline_CS1 = dataArray{:, 1};
clearvars filename delimiter formatSpec fileID dataArray ans dir;

%% Importamos Offline_CS2
dir = dir('Offline_CS2*.csv');
filename = dir.name;
delimiter = '';
formatSpec = '%f%[^\n\r]';
fileID = fopen(filename,'r');
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'EmptyValue' ,NaN, 'ReturnOnError', false);
fclose(fileID);
Offline_CS2 = dataArray{:, 1};
clearvars filename delimiter formatSpec fileID dataArray ans dir;

%% Extraemos los frames de inicio y fin del CS1
Offline_CS1_zscore = zscore(Offline_CS1);
Offline_CS1_zscore = Offline_CS1_zscore - min(Offline_CS1_zscore);
Offline_CS1_on = Offline_CS1_zscore >= 0.5;
CS1_on = find(diff(Offline_CS1_on) == 1);
CS1_off = find(diff(Offline_CS1_on) == -1);
CS1_duration = CS1_off - CS1_on;

for i = 1:length(CS1_duration);
    j = i;
    if CS1_duration(i) > 20;
        CS1_cummulativesum = CS1_duration(i);
        while CS1_cummulativesum < 1400 & j+1 <= length(CS1_duration);
            CS1_cummulativesum = CS1_cummulativesum + CS1_duration (j+1);
            j = j+1;
        end
        if CS1_cummulativesum > 1450 & CS1_cummulativesum < 1550;
            CS1_sumduration(i,:) = CS1_cummulativesum;
        end
    end
end

CS1_start = CS1_on(find(CS1_sumduration > 0));
CS1_end = CS1_start + 1499;

clear CS1_on; clear CS1_off; clear CS1_duration; clear CS1_cummulativesum; clear i; clear j; 
clear Offline_CS1_zscore; clear CS1_sumduration;        

%% Extraemos los frames de inicio y fin del CS2
Offline_CS2_zscore = zscore(Offline_CS2);
Offline_CS2_zscore = Offline_CS2_zscore - min(Offline_CS2_zscore);
Offline_CS2_on = Offline_CS2_zscore >= 0.5;
CS2_on = find(diff(Offline_CS2_on) == 1);
CS2_off = find(diff(Offline_CS2_on) == -1);
CS2_duration = CS2_off - CS2_on;

for i = 1:length(CS2_duration);
    j = i;
    if CS2_duration(i) > 20;
        CS2_cummulativesum = CS2_duration(i);
        while CS2_cummulativesum < 1400 & j+1 <= length(CS2_duration);
            CS2_cummulativesum = CS2_cummulativesum + CS2_duration (j+1);
            j = j+1;
        end
        if CS2_cummulativesum > 1450 & CS2_cummulativesum < 1550;
            CS2_sumduration(i,:) = CS2_cummulativesum;
        end
    end
end

CS2_start = CS2_on(find(CS2_sumduration > 0));
CS2_end = CS2_start + 1499;

clear CS2_on; clear CS2_off; clear CS2_duration; clear CS2_cummulativesum; clear i; clear j; 
clear Offline_CS2_zscore; clear CS2_sumduration; 

%% Extraemos los frames de SINCRO
Offline_sincro_zscore = zscore(Offline_sincro);
Offline_sincro_zscore = Offline_sincro_zscore - min(Offline_sincro_zscore);
Offline_sincro_on = Offline_sincro_zscore >= 1;
sincro_on = find(diff(Offline_sincro_on) == 1);
sincro_off = find(diff(Offline_sincro_on) == -1);
if sincro_off(1) < sincro_on(1);
    sincro_off(1) = [];
end
sincro_duration = sincro_off - sincro_on;
sincro_starttask = sincro_on(min(find(sincro_duration > 20))); % Frame en el cual inicia el primer pulso largo de inicio de la tarea. Dura 25 frames. 

%%
Offline_freezing_zscore = zscore(Offline_freezing);
Offline_freezing_zscore = Offline_freezing_zscore - min(Offline_freezing_zscore);
Offline_freezing_true = Offline_freezing_zscore < 0.004; % Seteamos umbral de freezing en un z = 0.004;

% Descartamos los eventos de inmovilidad que duran menos de 5 ventanas ww.
ww_inc = 25; % Número de ventanas necesarias como mínimo para incluir un evento de inmovilidad. Cada ventana tiene una duración de 1 seg
ww_desc = 12; % Número máximo de ventanas para descartar un evento de movilidad dentro de uno de inmovilidad. Cada ventana tiene una duración de 0.5 seg

% Calculo la posición de los cambios de movilidad->inmovilidad o de inmovilidad->movilidad y la duración de esos eventos
cambio_duracion = diff(find(diff(Offline_freezing_true))); % Duración del evento
cambio_puntos = find(diff(Offline_freezing_true)) + 1; % Puntos de cambio de evento
cambio = diff(Offline_freezing_true);
cambio(cambio == 0) = []; % Me quedo con los 1 y -1
% Me quedo solo con los eventos de inmovilidad que superan ww_inc de duración
Offline_freezing_wwn(1:length(Offline_freezing_true)) = 0; % Arranco con un vector de todos ceros
for i = 1:length(cambio_duracion);
    if cambio(i) == 1 & cambio_duracion(i) >= ww_inc;
        Offline_freezing_wwn(cambio_puntos(i):(cambio_puntos(i+1))-1) = 1; % Reemplazo con 1 donde ocurren esos eventos de inmovilidad
    end
end
% Una vez que me quedé solo con los eventos de inmovilidad que superan ww_inc de duracion, voy a descartar los eventos de movilidad que no superan ww_desc
% Vuelvo a calcular la posicion de los cambios y la duración de los eventos
cambio_duracion = diff(find(diff(Offline_freezing_wwn))); % Duración del evento
cambio_puntos = find(diff(Offline_freezing_wwn)) + 1; % Puntos de cambio
cambio = diff(Offline_freezing_wwn);
cambio(cambio == 0) = []; % Me quedo solo con los 1 y -1
% Descarto los eventos de movilidad que no superan ww_desc de duración
for i = 1:length(cambio_duracion);
    if cambio(i) == -1 & cambio_duracion(i) <= ww_desc;
        Offline_freezing_wwn(cambio_puntos(i):(cambio_puntos(i+1))-1) = 1; % si la duración de la movilidad no supera ww_desc de duración, lo considero como inmovilidad
    end
end

%% Cuantificamos movimiento durante el CS1 y el CS2
for i = 1:20;
    CS1_freezing(i,1) = sum(Offline_freezing_true(CS1_start(i):CS1_end(i)));
    CS2_freezing(i,1) = sum(Offline_freezing_true(CS2_start(i):CS2_end(i)));
end

CS1_freezing_porc = (CS1_freezing/1500)*100;
CS2_freezing_porc = (CS2_freezing/1500)*100;
plot(CS1_freezing_porc);
hold on 
plot(CS2_freezing_porc);
%% Ploteamos las tres cosas con el eje x linkeado
 ax1 = subplot(4,1,1);
 plot(Offline_sincro_on);
 hold on 
 ax2 = subplot(4,1,2);
 plot(Offline_CS1_on);
 hold on 
 ax3 = subplot(4,1,3);
 plot(Offline_CS2_on);
 hold on 
 ax4 = subplot(4,1,4);
 plot(Offline_freezing);
 hold on 
 linkaxes([ax1 ax2 ax3 ax4],'x');
 
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
video_timestamps_ms = HH*60*60*1000 + mm*60*1000 + ss*1000; % ms está en ms

% Seteamos el tiempo cero en el momento que comienza la tarea.
video_timestamps_ms = video_timestamps_ms - video_timestamps_ms(sincro_starttask);

% OUTPUT: 'video_timestamps_ms' double con los timestamps de cada frame en
% ms y triggereado en el onset del primer pulso SINCRO.

%% Importamos el acelerómetro, el pulso sincro y los timestamps
cd('D:\Doctorado\Electrofisiología\Vol 11\Day12_2022-08-30_11-43-46_Rat1\Record Node 101\experiment1\recording1\events\Rhythm_FPGA-100.0\TTL_1');

% Cargamos los datos de los TTL y los timestamps.
TTL.states = readNPY('channel_states.npy'); % Cargamos el estado de cada input del IO Board.
TTL.timestamps = readNPY('timestamps.npy'); % Los timestamps estan en unidad de muestreo
TTL.channels = readNPY('channels.npy'); % Cargamos los estados de los canales.
TTL.timestamps = TTL.timestamps - data_start; % Restamos el primer timestamp para que inicie en 0.
data_timestamps = data_timestamps - data_start;
data_timestamps = data_timestamps/30;
TTL.timestamps = TTL.timestamps/30; % Pasamos las unidades a ms.

% Buscamos los tiempos asociados a cada evento.
% Inicio y fin del CS+ asociado con la recompensa. Entrada #1 del IO board.
sincro.start = TTL.timestamps(find(TTL.states == 7));
sincro.end = TTL.timestamps(find(TTL.states == -7));

if sincro.start(1) > sincro.end(1);
    sincro.end(1) = [];
elseif sincro.end(end) < sincro.start(end);
    sincro.start(end) = [];
end

sincro.duracion = sincro.end - sincro.start;
sincro.starttask = sincro.start(min(find(sincro.duracion > 900))); % ms en el cual inicia el primer pulso largo de inicio de la tarea.
TTL.timestamps = TTL.timestamps - sincro.starttask;
data_timestamps = data_timestamps - sincro.starttask;

