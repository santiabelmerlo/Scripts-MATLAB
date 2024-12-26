%% Inspeccionar señal de aceleración en eventos de freezing que me dan aceleraciones altas
clc
clearvars -except T

i = 17; % Seteamos el evento que quiero analizar
event = T(i,:);
% Construir la ruta utilizando los campos de la tabla
base_path = 'D:\Doctorado\Backup Ordenado';
rat_folder = sprintf('R%d', event.Rat); % Formato para incluir "R" antes del número de Rat
session_name = event.Name{1}; % Convertir el valor a string si es necesario
path = fullfile(base_path, rat_folder, session_name); % Construir la ruta completa

% Obtenemos el nombre de la carpeta en la que estoy parado
cd(path);
[~,D] = fileparts(pwd); name = D([1:6]); clear D ;

% Check if the sessioninfo.mat file exists
sessioninfo_path = strcat(name, '_sessioninfo.mat');

load(strcat(name,'_sessioninfo.mat')); % Número de canales totales                        

% Reiniciamos algunas variables
movement = [];
t_movement = [];
aceleracion = [];
cambio = [];
cambio_puntos = [];
desaceleracion = [];
duracion_aceleracion = [];

% Importamos la señal del acelerómetro
[amplifier_aux1]=LoadBinary(strcat(name(1:6),'_lfp.dat'), ACC_channels(1), ch_total); % Cargamos señal de AUX1
amplifier_aux1 = amplifier_aux1 * 0.0000374; % Convertimos a volts
amplifier_aux1 = ((amplifier_aux1-0.4816)/0.3458)*100; % Convertimos a g
[amplifier_aux2]=LoadBinary(strcat(name(1:6),'_lfp.dat'), ACC_channels(2), ch_total); % Cargamos señal de AUX2
amplifier_aux2 = amplifier_aux2 * 0.0000374; % Convertimos a volts
amplifier_aux2 = ((amplifier_aux2-0.4927)/0.3420)*100; % Convertimos a g
[amplifier_aux3]=LoadBinary(strcat(name(1:6),'_lfp.dat'), ACC_channels(3), ch_total); % Cargamos señal de AUX3
amplifier_aux3 = amplifier_aux3 * 0.0000374; % Convertimos a volts
amplifier_aux3 = ((amplifier_aux3-0.5091)/0.3386)*100; % Convertimos a g

Fs = 1250; % Frecuencia de muestreo del acelerómetro
timestamps = (0:1/Fs:((size(amplifier_aux1,2)/Fs)-(1/Fs))); % Timestamps en seg.

% Filtramos Aux1
% Filtro pasa altos
samplePeriod = 1/Fs;
filtCutOff = 0.25; % Frecuencia de corte del pasaaltos.
filtHPF = (2*filtCutOff)/(1/samplePeriod);
[b, a] = butter(4, filtHPF, 'high');
amplifier_aux1_filt = filtfilt(b, a, amplifier_aux1); % Filtramos HPF a la señal aux1
% Filtro pasa bajos
filtCutOff = 6; % Frecuecia de corte del pasabajos.
filtLPF = (2*filtCutOff)/(1/samplePeriod);
[b, a] = butter(4, filtLPF, 'low');
amplifier_aux1_filt = filtfilt(b, a, amplifier_aux1_filt); % Filtramos LPF a la señal aux1

% Filtramos Aux2
% Filtro pasa altos
samplePeriod = 1/Fs;
filtCutOff = 0.25; % Frecuencia de corte del pasaaltos.
filtHPF = (2*filtCutOff)/(1/samplePeriod);
[b, a] = butter(4, filtHPF, 'high');
amplifier_aux2_filt = filtfilt(b, a, amplifier_aux2); % Filtramos HPF a la señal aux2
% Filtro pasa bajos
filtCutOff = 6; % Frecuecia de corte del pasabajos.
filtLPF = (2*filtCutOff)/(1/samplePeriod);
[b, a] = butter(4, filtLPF, 'low');
amplifier_aux2_filt = filtfilt(b, a, amplifier_aux2_filt); % Filtramos LPF a la señal aux2

% Filtramos Aux3
% Filtro pasa altos
samplePeriod = 1/Fs;
filtCutOff = 0.25; % Frecuencia de corte del pasaaltos.
filtHPF = (2*filtCutOff)/(1/samplePeriod);
[b, a] = butter(4, filtHPF, 'high');
amplifier_aux3_filt = filtfilt(b, a, amplifier_aux3); % Filtramos HPF a la señal aux3
% Filtro pasa bajos
filtCutOff = 6; % Frecuecia de corte del pasabajos.
filtLPF = (2*filtCutOff)/(1/samplePeriod);
[b, a] = butter(4, filtLPF, 'low');
amplifier_aux3_filt = filtfilt(b, a, amplifier_aux3_filt); % Filtramos LPF a la señal aux3

% Combinamos las tres señales de aceleración en una sola realizando la suma de cuadrados
% Queda en unidades de aceleración de cm/s^2
amplifier_aux123_filt = sqrt(sum(amplifier_aux1_filt(1,:).^2 + amplifier_aux2_filt(1,:).^2 + amplifier_aux3_filt(1,:).^2, 1)); % Magnitud de la aceleración

movement = amplifier_aux123_filt;
t_movement = timestamps;

% Buscamos el tiempo del evento en t_movement
pos = unique(find(abs(t_movement - event.Inicio) == min(abs(t_movement - event.Inicio))));
step = median(diff(t_movement));
t = -5:step:5;
Acc = movement(1,pos-(round(5/step)):pos+round(5/step)-1);
plot(t,Acc);
ylabel('Aceleración (cm/s2)');
xlabel('Tiempo (seg.)');
line([0 0], [0 100], 'LineWidth', 1, 'LineStyle', '--', 'color', colores('Negro'));
line([event.Duracion event.Duracion], [0 100], 'LineWidth', 1, 'LineStyle', '--', 'color', colores('Negro'));
ylim([0 100]);
xlim([-5 5]);

% Set figure properties
set(gcf, 'Color', 'white');
set(gcf, 'Position', [100, 500, 300 200]);