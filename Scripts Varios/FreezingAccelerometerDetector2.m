%% Accelerometer Freezing Detector
% Calculo el porcentaje de freezing durante cada tono
% Este script solo requiere tener los archivos: continuous.dat, channel_states.npy, timestamps.npy y channels.npy
clc
clear all;
Fs = 1250; % Frequencia de muestro del amplificador: 30 kHz.

% Cargo los Eventos del CS
% Importamos los eventos con sus timestamps.
% Cargamos los datos de los TTL y los timestamps.
[~,name,~] = fileparts(pwd);
name = name([1:6]);
TTL_states = readNPY(strcat(name(1:6),'_TTL_channel_states.npy')); % Cargamos el estado de cada input del IO Board. 
TTL_timestamps = readNPY(strcat(name(1:6),'_TTL_timestamps.npy')); % Los timestamps estan en unidad de muestreo: 30 kHz.
TTL_channels = readNPY(strcat(name(1:6),'_TTL_channels.npy')); % Cargamos los estados de los canales.
TTL_start = TTL_timestamps(1); % Seteamos el primer timestamp 
TTL_end = TTL_timestamps(end); % Seteamos el último timestamp

% Buscamos los tiempos asociados a cada evento.
% Inicio y fin del CS+ asociado con la recompensa. Entrada #1 del IO board.
TTL_CS1_start = TTL_timestamps(find(TTL_states == 1));
TTL_CS1_end = TTL_timestamps(find(TTL_states == -1));
% Inicio y fin del CS-. Entrada #1 del IO board. Entrada #2 del IO board.
TTL_CS2_start = TTL_timestamps(find(TTL_states == 2));
TTL_CS2_end = TTL_timestamps(find(TTL_states == -2));

% Llevo los tiempos del CS1 a segundos y los sincronizo con los tiempos del registro
TTL_CS1_inicio = TTL_CS1_start - TTL_start; TTL_CS1_inicio = double(TTL_CS1_inicio);
TTL_CS1_fin = TTL_CS1_end - TTL_start; TTL_CS1_fin = double(TTL_CS1_fin);
TTL_CS1_inicio = TTL_CS1_inicio/30000; % Llevo los tiempos a segundos
TTL_CS1_fin = TTL_CS1_fin/30000; % Llevo los tiempos a segundos
% Llevo los tiempos del CS2 a segundos y los sincronizo con los tiempos del registro
TTL_CS2_inicio = TTL_CS2_start - TTL_start; TTL_CS2_inicio = double(TTL_CS2_inicio);
TTL_CS2_fin = TTL_CS2_end - TTL_start; TTL_CS2_fin = double(TTL_CS2_fin);
TTL_CS2_inicio = TTL_CS2_inicio/30000; % Llevo los tiempos a segundos
TTL_CS2_fin = TTL_CS2_fin/30000; % Llevo los tiempos a segundos

% Borramos todas las variables que no me sirven
clear TTL_timestamps TTL_states TTL_start TTL_end TTL_CS1_start TTL_CS1_end TTL_CS2_start TTL_CS2_end TTL_channels; 

load(strcat(name,'_sessioninfo.mat'), 'ch_total'); % Cargamos la cantidad de canales totales
load(strcat(name,'_sessioninfo.mat'), 'ACC_channels'); % Cargamos los canales del acelerómetro

% Importamos la señal del acelerómetro para detectar freezing para R10 a R14
[amplifier_aux1]=LoadBinary(strcat(name(1:6),'_lfp.dat'), ACC_channels(1), ch_total); % Cargamos señal de AUX1
amplifier_aux1 = amplifier_aux1 * 0.0000374; % Convertimos a volts
[amplifier_aux2]=LoadBinary(strcat(name(1:6),'_lfp.dat'), ACC_channels(2), ch_total); % Cargamos señal de AUX2
amplifier_aux2 = amplifier_aux2 * 0.0000374; % Convertimos a volts
[amplifier_aux3]=LoadBinary(strcat(name(1:6),'_lfp.dat'), ACC_channels(3), ch_total); % Cargamos señal de AUX3
amplifier_aux3 = amplifier_aux3 * 0.0000374; % Convertimos a volts

Fs = 1250; % Frecuencia de muestreo del acelerómetro
timestamps = (0:1/Fs:((size(amplifier_aux1,2)/Fs)-(1/Fs))); % Timestamps en seg.

% Combinamos las tres señales de aceleración en una sola realizando la suma de cuadrados
amplifier_aux123 = sqrt(sum(amplifier_aux1(1,:).^2 + amplifier_aux1(1,:).^2 + amplifier_aux3(1,:).^2, 1)); % Magnitud de la aceleración

% Filtramos las señales del acelerómetro con un pasa altos en 0.25 Hz y un pasabajos en 6 Hz.
% Las señales quedan filtradas entre 0.25 Hz y 6 Hz. Quedan centradas en 0.
samplePeriod = 1/Fs;
% Filtro pasa altos
filtCutOff = 0.25; % Frecuencia de corte del pasaaltos.
filtHPF = (2*filtCutOff)/(1/samplePeriod);
[b, a] = butter(1, filtHPF, 'high');
amplifier_aux123_filt = filtfilt(b, a, amplifier_aux123); % Filtramos HPF a la señal aux123
% Filtro pasa bajos
filtCutOff = 6; % Frecuecia de corte del pasabajos.
filtLPF = (2*filtCutOff)/(1/samplePeriod);
[b, a] = butter(1, filtLPF, 'low');
amplifier_aux123_filt = filtfilt(b, a, amplifier_aux123_filt); % Filtramos LPF a la señal aux123

% Calculamos el desvío estándar de las señales filtradas en ventanas de tiempo fijas, no solapadas.
ww_ms = 100; % Ventana de análisis del acelerómetro en ms.
ww = (ww_ms/1000)*Fs; % Ventana de análisis del acelerómetro en muestras.
j = 1;

for i = ((round(ww/2))+1):ww:(size(amplifier_aux123_filt,2)-(round(ww/2))); % Desde el dato ww/2 hasta el final - ww/2 
    amplifier_aux123_filt_std(j) = std(amplifier_aux123_filt(i-(round(ww/2)):i+((round(ww/2))-1))); % Calculamos el desvío estándar de la señal aux123 filtrada
    amplifier_aux_filt_std_timestamps(j) = timestamps(i); % Timestamps en seg.
    j = j + 1;
end

% Detectamos inmovilidad seteando un umbral en el std.
th_immovility = 0.004; % Umbral para detectar inmovilidad, en volts.
for i = 1:length(amplifier_aux123_filt_std);
    immovility_aux123(i) = amplifier_aux123_filt_std(i) < th_immovility;
end
immovility_aux_timestamps = amplifier_aux_filt_std_timestamps;

% Descartamos los eventos de inmovilidad que duran menos de 10 ventanas ww.
ww_inc = 10; % Número de ventanas necesarias como mínimo para incluir un evento de inmovilidad. Cada ventana tiene una duración de ww_ms
ww_desc = 5; % Número máximo de ventanas para descartar un evento de movilidad dentro de uno de inmovilidad. Cada ventana tiene una duración de ww_ms
% Calculo la posición de los cambios de movilidad->inmovilidad o de inmovilidad->movilidad y la duración de esos eventos
cambio_duracion = diff(find(diff(immovility_aux123))); % Duración del evento
cambio_puntos = find(diff(immovility_aux123)) + 1; % Puntos de cambio de evento
cambio = diff(immovility_aux123); cambio(cambio == 0) = []; % Me quedo con los 1 y -1
% Me quedo solo con los eventos de inmovilidad que superan ww_inc de duración
immovility_aux123_wwn(1:length(immovility_aux123)) = 0; % Arranco con un vector de todos ceros
for i = 1:length(cambio_duracion);
    if cambio(i) == 1 & cambio_duracion(i) >= ww_inc;
        immovility_aux123_wwn(cambio_puntos(i):(cambio_puntos(i+1))-1) = 1; % Reemplazo con 1 donde ocurren esos eventos de inmovilidad
    end
end
% Una vez que me quedé solo con los eventos de inmovilidad que superan ww_inc de duracion, voy a descartar los eventos de movilidad que no superan ww_desc
% Vuelvo a calcular la posicion de los cambios y la duración de los eventos
cambio_duracion = diff(find(diff(immovility_aux123_wwn))); % Duración del evento
cambio_puntos = find(diff(immovility_aux123_wwn)) + 1; % Puntos de cambio
cambio = diff(immovility_aux123_wwn); cambio(cambio == 0) = []; % Me quedo solo con los 1 y -1
% Descarto los eventos de movilidad que no superan ww_desc de duración
for i = 1:length(cambio_duracion);
    if cambio(i) == -1 & cambio_duracion(i) <= ww_desc;
        immovility_aux123_wwn(cambio_puntos(i):(cambio_puntos(i+1))-1) = 1; % si la duración de la movilidad no supera ww_desc de duración, lo considero como inmovilidad
    end
end
% Vuelvo a calcular la posicion de los cambios y la duración de los eventos
cambio_duracion = diff(find(diff(immovility_aux123_wwn))); % Duración del evento
cambio_puntos = find(diff(immovility_aux123_wwn)) + 1; % Puntos de cambio
cambio = diff(immovility_aux123_wwn); cambio(cambio == 0) = []; % Me quedo solo con los 1 y -1

% Calculo los timestamps en segundos en los que inicia el freezing, los momentos en que termina, y la duración de cada evento.
inicio_freezing = immovility_aux_timestamps(cambio_puntos(find(cambio == 1))); % Timestamps de inicio del freezing
fin_freezing =  immovility_aux_timestamps(cambio_puntos(find(cambio == -1))); % Timestamps del fin del freezing
duracion_freezing = fin_freezing - inicio_freezing; % Duración de los eventos de freezing

%Borro todas las variables que no me sirven
% clear ww_ms ww_inc ww_desc ww i j th_immovility samplePeriod b a cambio cambio_duracion cambio_puntos ...
%       filtCutOff Fs filtHPF filtLPF timestamps amplifier_aux1 amplifier_aux2 amplifier_aux3 ...
%       amplifier_aux1_filt amplifier_aux2_filt amplifier_aux3_filt amplifier_aux1_filt_std ...
%       amplifier_aux2_filt_std amplifier_aux3_filt_std amplifier_aux123 amplifier_aux123_filt ...
%       amplifier_aux123_filt_std amplifier_aux123_filt_std_timestamps immovility_aux1 immovility_aux2 ...
%       immovility_aux3 immovility_aux123 amplifier_aux_filt_std_timestamps Fs;
  
freezing_timestamps = immovility_aux_timestamps;
freezing_detection = immovility_aux123_wwn;

% clear immovility_aux123_wwn immovility_aux_timestamps;

% Calculamos el tiempo de freezing 60 seg previos al primer CS+
Pre_CS_inicio = TTL_CS1_inicio(1)-60;
Pre_CS_fin = TTL_CS1_inicio(1);

freezing_preCS = 0;
for i = 1:length(inicio_freezing);
    if inicio_freezing(i) >= Pre_CS_inicio && inicio_freezing(i) < Pre_CS_fin;
        if inicio_freezing(i) + duracion_freezing(i) <= Pre_CS_fin;
            freezing_preCS = freezing_preCS + duracion_freezing(i);
        elseif inicio_freezing(i) + duracion_freezing(i) > Pre_CS_fin;
            freezing_preCS = freezing_preCS + (Pre_CS_fin - inicio_freezing(i));
        end
    end
end
freezing_preCS_porc = (freezing_preCS/60)*100;

% Ahora calculamos el tiempo de freezing durante los tonos

for i = 1:length(TTL_CS1_inicio);
    freezing = 0;
    for j = 1:length(inicio_freezing);
        if inicio_freezing(j) >= TTL_CS1_inicio(i) && inicio_freezing(j) <= TTL_CS1_fin(i) == 1;
            if duracion_freezing(j) > TTL_CS1_fin(i) - inicio_freezing(j);
                duracion_f(j) = TTL_CS1_fin(i) - inicio_freezing(j);
            else
                duracion_f(j) = duracion_freezing(j);
            end    
            freezing = freezing + duracion_f(j);
        end
        clear duracion_f;
    end
    if freezing > 60;
        freezing = 60;
    end
    freezing_CS1(i) = freezing;
end

for i = 1:length(TTL_CS2_inicio);
    freezing = 0;
    for j = 1:length(inicio_freezing);
        if inicio_freezing(j) >= TTL_CS2_inicio(i) && inicio_freezing(j) <= TTL_CS2_fin(i) == 1;
            if duracion_freezing(j) > TTL_CS2_fin(i) - inicio_freezing(j);
                duracion_f(j) = TTL_CS2_fin(i) - inicio_freezing(j);
            else
                duracion_f(j) = duracion_freezing(j);
            end    
            freezing = freezing + duracion_f(j);
        end
        clear duracion_f;
    end
    if freezing > 60;
        freezing = 60;
    end
    freezing_CS2(i) = freezing;
end

clear i j freezing fin_freezing;

freezing_CS1_porc = (freezing_CS1'/60)*100;
freezing_CS2_porc = (freezing_CS2'/60)*100;

freezing_CS1 = freezing_CS1';
freezing_CS2 = freezing_CS2';
freezing = table(freezing_CS1,freezing_CS2,freezing_CS1_porc,freezing_CS2_porc); % Creamos una tabla con los datos de freezing de CS1 y CS2

% Borro todas las variables que no me sirven
clear ww_ms ww_inc ww_desc ww i j th_immovility samplePeriod b a cambio cambio_duracion cambio_puntos ...
      filtCutOff Fs filtHPF filtLPF timestamps amplifier_aux1 amplifier_aux2 amplifier_aux3 ...
      amplifier_aux1_filt amplifier_aux2_filt amplifier_aux3_filt amplifier_aux1_filt_std ...
      amplifier_aux2_filt_std amplifier_aux3_filt_std amplifier_aux123 amplifier_aux123_filt ...
      amplifier_aux123_filt_std amplifier_aux123_filt_std_timestamps immovility_aux1 immovility_aux2 ...
      immovility_aux3 immovility_aux123 immovility_aux123_wwn immovility_aux_timestamps amplifier_aux_filt_std_timestamps...
      ACC_channels Fs;

disp('Ready quiescence detection!');