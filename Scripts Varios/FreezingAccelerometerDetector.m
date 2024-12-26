%% Accelerometer Freezing Detector
% Calculo el porcentaje de freezing durante cada tono
% Este script solo requiere tener los archivos: continuous.dat, channel_states.npy, timestamps.npy y channels.npy
clc
clear all;

% path_amplifier = 'D:\Doctorado\Electrofisiología\Vol 10\Day6_2022-06-19_14-04-13_Rat1\Record Node 101\experiment1\recording1\continuous\Rhythm_FPGA-100.0';
% path_events = 'D:\Doctorado\Electrofisiología\Vol 10\Day6_2022-06-19_14-04-13_Rat1\Record Node 101\experiment1\recording1\events\Rhythm_FPGA-100.0\TTL_1';

% Vol 13
% path_amplifier = 'D:\Doctorado\Electrofisiología\Vol 13\Day12_2022-12-20_09-51-09_Rat1\Record Node 105\experiment1\recording1\continuous\Rhythm_FPGA-100.0';
% path_events = 'D:\Doctorado\Electrofisiología\Vol 13\Day12_2022-12-20_09-51-09_Rat1\Record Node 105\experiment1\recording1\events\Rhythm_FPGA-100.0\TTL_1';
% path_amplifier = 'D:\Doctorado\Electrofisiología\Vol 13\Day13_2022-12-21_14-54-16_Rat1\Record Node 105\experiment1\recording1\continuous\Rhythm_FPGA-100.0';
% path_events = 'D:\Doctorado\Electrofisiología\Vol 13\Day13_2022-12-21_14-54-16_Rat1\Record Node 105\experiment1\recording1\events\Rhythm_FPGA-100.0\TTL_1';
% path_amplifier = 'D:\Doctorado\Electrofisiología\Vol 13\Day14_2022-12-22_10-58-31_Rat1\Record Node 105\experiment1\recording1\continuous\Rhythm_FPGA-100.0';
% path_events = 'D:\Doctorado\Electrofisiología\Vol 13\Day14_2022-12-22_10-58-31_Rat1\Record Node 105\experiment1\recording1\events\Rhythm_FPGA-100.0\TTL_1';

% Vol 14
% path_amplifier = 'D:\Doctorado\Electrofisiología\Vol 14\Day12_2022-12-20_11-07-39_Rat1\Record Node 105\experiment1\recording1\continuous\Rhythm_FPGA-100.0';
% path_events = 'D:\Doctorado\Electrofisiología\Vol 14\Day12_2022-12-20_11-07-39_Rat1\Record Node 105\experiment1\recording1\events\Rhythm_FPGA-100.0\TTL_1';
path_amplifier = 'D:\Doctorado\Electrofisiología\Vol 14\Day13_2022-12-21_16-16-49_Rat1\Record Node 105\experiment1\recording1\continuous\Rhythm_FPGA-100.0';
path_events = 'D:\Doctorado\Electrofisiología\Vol 14\Day13_2022-12-21_16-16-49_Rat1\Record Node 105\experiment1\recording1\events\Rhythm_FPGA-100.0\TTL_1';
% path_amplifier = 'D:\Doctorado\Electrofisiología\Vol 14\Day14_2022-12-22_11-55-49_Rat1\Record Node 105\experiment1\recording1\continuous\Rhythm_FPGA-100.0';
% path_events = 'D:\Doctorado\Electrofisiología\Vol 14\Day14_2022-12-22_11-55-49_Rat1\Record Node 105\experiment1\recording1\events\Rhythm_FPGA-100.0\TTL_1';

% Vol 12
% path_amplifier = 'D:\Doctorado\Electrofisiología\Vol 12\Day13_2022-09-21_13-14-10_Rat1\Record Node 101\experiment1\recording1\continuous\Rhythm_FPGA-100.0';
% path_events = 'D:\Doctorado\Electrofisiología\Vol 12\Day13_2022-09-21_13-14-10_Rat1\Record Node 101\experiment1\recording1\events\Rhythm_FPGA-100.0\TTL_1';
% path_amplifier = 'D:\Doctorado\Electrofisiología\Vol 12\Day14_2022-09-22_15-21-01_Rat1\Record Node 105\experiment1\recording1\continuous\Rhythm_FPGA-100.0';
% path_events = 'D:\Doctorado\Electrofisiología\Vol 12\Day14_2022-09-22_15-21-01_Rat1\Record Node 105\experiment1\recording1\events\Rhythm_FPGA-100.0\TTL_1';

cd(path_amplifier); % Seteamos el path donde esta la señal del amplificador: continuous.dat
Fs = 30000; % Frequencia de muestro del amplificador: 30 kHz.

%% Cargo los Eventos del CS
% Importamos los eventos con sus timestamps.
cd(path_events)
TTL_states = readNPY('channel_states.npy'); % Cargamos el estado de cada input del IO Board.
TTL_timestamps = readNPY('timestamps.npy'); % Los timestamps estan en unidad de muestreo: 10kHz
TTL_channels = readNPY('channels.npy'); % Cargamos los estados de los canales.
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

% Importamos la señal del acelerómetro para detectar freezing
cd(path_amplifier); % Seteamos el path del amplificador que es donde está la señal "continuous.dat"
[amplifier_aux1]=LoadBinary('continuous.dat', 33, 35); % Cargamos señal de AUX1
amplifier_aux1 = amplifier_aux1 * 0.0000374; % Convertimos a volts
[amplifier_aux2]=LoadBinary('continuous.dat', 34, 35); % Cargamos señal de AUX2
amplifier_aux2 = amplifier_aux2 * 0.0000374; % Convertimos a volts
[amplifier_aux3]=LoadBinary('continuous.dat', 35, 35); % Cargamos señal de AUX3
amplifier_aux3 = amplifier_aux3 * 0.0000374; % Convertimos a volts

Fs = 30000; % Frecuencia de muestreo del acelerómetro
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
for i = ((ww/2)+1):ww:(size(amplifier_aux123_filt,2)-(ww/2)); % Desde el dato ww/2 hasta el final - ww/2 
    amplifier_aux123_filt_std(j) = std(amplifier_aux123_filt(i-(ww/2):i+((ww/2)-1))); % Calculamos el desvío estándar de la señal aux123 filtrada
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

% Borro todas las variables que no me sirven
clear ww_ms ww_inc ww_desc ww i j th_immovility samplePeriod b a cambio cambio_duracion cambio_puntos ...
      filtCutOff Fs filtHPF filtLPF timestamps amplifier_aux1 amplifier_aux2 amplifier_aux3 ...
      amplifier_aux1_filt amplifier_aux2_filt amplifier_aux3_filt amplifier_aux1_filt_std ...
      amplifier_aux2_filt_std amplifier_aux3_filt_std amplifier_aux123 amplifier_aux123_filt ...
      amplifier_aux123_filt_std amplifier_aux123_filt_std_timestamps immovility_aux1 immovility_aux2 ...
      immovility_aux3 immovility_aux123 immovility_aux123_wwn immovility_aux_timestamps amplifier_aux_filt_std_timestamps Fs;

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

freezing = table(freezing_CS1',freezing_CS2',(freezing_CS1'/60)*100,(freezing_CS2'/60)*100); % Creamos una tabla con los datos de freezing de CS1 y CS2


% Ploteamos ambas curvas
cs1_color = [255 67 66]/255; % Color para el CS1 o CS+
cs2_color = [70 171 215]/255; % Color para el CS2 o CS-
plot(freezing_CS1/60,'color',cs1_color,'LineWidth',2);
hold on
plot(freezing_CS2/60,'color',cs2_color,'LineWidth',2);
xlabel('Trial #');
ylabel('Porcentaje de tiempo freezando (%)');
title('Detección de freezing con acelerómetro');