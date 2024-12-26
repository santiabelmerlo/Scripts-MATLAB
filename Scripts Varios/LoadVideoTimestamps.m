%% Carga video_timestamps y guarda duración del video (min), los timestamps [YYYY MM DD HH MM SS FFFFFFF NN NN] y los timestamps(ms)
clear all
clc
cd 'D:\Doctorado\Electrofisiología\Vol 10\Day3_2022-06-16_11-50-31_Rat1/'

% Importo los timestamps en formato .csv 'YYYY-MM-DDTHH_MM_SS_FFFFFFF-03:00'
% Queda en formato char
file = dir('*video_timestamps*.csv');
v_timestamps = readtable(file.name,'Delimiter',' ');
v_timestamps = table2array(v_timestamps);
v_timestamps = cell2mat(v_timestamps);

% Separo los datos en [YYYY MM DD HH MM SS FFFFFFF NN NN]
% Queda en formato int32
for i = 1:length(v_timestamps);
     v_timestamps_2(i,:) = cell2mat(textscan(v_timestamps(i,:),'%4d-%2d-%2dT%2d:%2d:%2d.%7d-%2d:%2d','collectoutput',1));
end

% Convertimos a double
video_time = double(v_timestamps_2); % Timestamps [YYYY MM DD HH MM SS FFFFFFF NN NN]

% Con los datos de HH, MM, SS y FFFFFFF calculamos los ms
for i = 1:length(video_time);
    video_timestamps_ms(i,1) = video_time(i,4)*3600000+video_time(i,5)*60000+video_time(i,6)*1000+video_time(i,7)/10000;
end

% Restamos el primer tiempo para que el primer frame comience en 0 ms. 
video_timestamps_ms = video_timestamps_ms - video_timestamps_ms(1); % Restamos el primer timestamp para que el primer frame comience en 0 ms.

% Calculamos la duración del video en minutos para comprobar que este todo ok
video_duration = (video_timestamps_ms(end)/1000)/60; % Duración del video en minutos.

video_timestamps.video_duration = video_duration;
video_timestamps.video_timestamps = video_time;
video_timestamps.video_timestamps_ms = video_timestamps_ms;

clearvars -except video_timestamps;
save(['video_timestamps.mat']);
