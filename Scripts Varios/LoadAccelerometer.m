%% Análisis para la señal del acelerómetro
% Script actualizado el 21/09/2022
clc;
clear all
% clearvars -except amplifier_aux1 amplifier_aux2 amplifier_aux3;

% Vol 10 
% path = 'D:\Doctorado\Electrofisiología\Vol 10\Day11_2022-06-24_13-55-22_Rat1\Record Node 101\experiment1\recording1\continuous\Rhythm_FPGA-100.0\';
% path = 'D:\Doctorado\Electrofisiología\Vol 10\Day12_2022-06-25_15-34-05_Rat1\Record Node 101\experiment1\recording2\continuous\Rhythm_FPGA-100.0\';

% Vol 11
% path = 'D:\Doctorado\Electrofisiología\Vol 11\Day12_2022-08-30_11-43-46_Rat1\Record Node 101\experiment1\recording1\continuous\Rhythm_FPGA-100.0\';
% path = 'D:\Doctorado\Electrofisiología\Vol 11\Day13_2022-08-31_11-01-32_Rat1\Record Node 101\experiment1\recording1\continuous\Rhythm_FPGA-100.0\';
% path = 'D:\Doctorado\Electrofisiología\Vol 11\Day14_2022-09-01_11-45-44_Rat1\Record Node 101\experiment1\recording1\continuous\Rhythm_FPGA-100.0\';

% Vol 12
% path = 'D:\Doctorado\Electrofisiología\Vol 12\Day14_2022-09-22_15-21-01_Rat1\Record Node 105\experiment1\recording1\continuous\Rhythm_FPGA-100.0';
path_amplifier = 'D:\Doctorado\Electrofisiología\Vol 12\Day14_2022-09-22_15-21-01_Rat1\Record Node 105\experiment1\recording1\continuous\Rhythm_FPGA-100.0';
path_events = 'D:\Doctorado\Electrofisiología\Vol 12\Day14_2022-09-22_15-21-01_Rat1\Record Node 105\experiment1\recording1\events\Rhythm_FPGA-100.0\TTL_1';
% path = 'D:\Doctorado\Electrofisiología\Vol 12\Day14_2022-09-22_15-21-01_Rat1\Record Node 105\experiment1\recording1\continuous\Rhythm_FPGA-100.0\';
% path = 'D:\Doctorado\Electrofisiología\Vol 12\Day15_2022-09-23_11-20-10_Rat1\Record Node 105\experiment1\recording1\continuous\Rhythm_FPGA-100.0\';

cd(path_amplifier);

% Aux1: señal del acelerómetro en el eje X
% Aux2: señal del acelerómetro en el eje Y
% Aux3: señal del acelerómetro en el eje Z
% Aux123: magnitud de la aceleración XYZ

[amplifier_aux1]=LoadBinary('continuous.dat', 33, 35); % Cargamos señal de AUX1
amplifier_aux1 = amplifier_aux1 * 0.0000374; % Convertimos a volts
[amplifier_aux2]=LoadBinary('continuous.dat', 34, 35); % Cargamos señal de AUX2
amplifier_aux2 = amplifier_aux2 * 0.0000374; % Convertimos a volts
[amplifier_aux3]=LoadBinary('continuous.dat', 35, 35); % Cargamos señal de AUX3
amplifier_aux3 = amplifier_aux3 * 0.0000374; % Convertimos a volts

Fs = 30000; % Frecuencia de muestreo
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
amplifier_aux1_filt = filtfilt(b, a, amplifier_aux1); % Filtramos HPF a la señal aux1
amplifier_aux2_filt = filtfilt(b, a, amplifier_aux2); % Filtramos HPF a la señal aux2
amplifier_aux3_filt = filtfilt(b, a, amplifier_aux3); % Filtramos HPF a la señal aux3
amplifier_aux123_filt = filtfilt(b, a, amplifier_aux123); % Filtramos HPF a la señal aux123
% Filtro pasa bajos
filtCutOff = 6; % Frecuecia de corte del pasabajos.
filtLPF = (2*filtCutOff)/(1/samplePeriod);
[b, a] = butter(1, filtLPF, 'low');
amplifier_aux1_filt = filtfilt(b, a, amplifier_aux1_filt); % Filtramos LPF a la señal aux1
amplifier_aux2_filt = filtfilt(b, a, amplifier_aux2_filt); % Filtramos LPF a la señal aux2
amplifier_aux3_filt = filtfilt(b, a, amplifier_aux3_filt); % Filtramos LPF a la señal aux3
amplifier_aux123_filt = filtfilt(b, a, amplifier_aux123_filt); % Filtramos LPF a la señal aux123

% Calculamos el desvío estándar de las señales filtradas en ventanas de tiempo fijas, no solapadas.
ww_ms = 100; % Ventana de análisis del acelerómetro en ms.
ww = (ww_ms/1000)*Fs; % Ventana de análisis del acelerómetro en muestras.
j = 1;
for i = ((ww/2)+1):ww:(size(amplifier_aux1_filt,2)-(ww/2)); % Desde el dato ww/2 hasta el final - ww/2 
    amplifier_aux1_filt_std(j) = std(amplifier_aux1_filt(i-(ww/2):i+((ww/2)-1))); % Calculamos el desvío estándar de la señal aux1 filtrada
    amplifier_aux2_filt_std(j) = std(amplifier_aux2_filt(i-(ww/2):i+((ww/2)-1))); % Calculamos el desvío estándar de la señal aux2 filtrada
    amplifier_aux3_filt_std(j) = std(amplifier_aux3_filt(i-(ww/2):i+((ww/2)-1))); % Calculamos el desvío estándar de la señal aux3 filtrada
    amplifier_aux123_filt_std(j) = std(amplifier_aux123_filt(i-(ww/2):i+((ww/2)-1))); % Calculamos el desvío estándar de la señal aux123 filtrada
    amplifier_aux_filt_std_timestamps(j) = timestamps(i); % Timestamps en seg.
    j = j + 1;
end

% Detectamos inmovilidad seteando un umbral en el std.
th_immovility = 0.004; % Umbral para detectar inmovilidad.
for i = 1:length(amplifier_aux123_filt_std);
    immovility_aux1(i) = amplifier_aux1_filt_std(i) < th_immovility;
    immovility_aux2(i) = amplifier_aux2_filt_std(i) < th_immovility;
    immovility_aux3(i) = amplifier_aux3_filt_std(i) < th_immovility;
    immovility_aux123(i) = amplifier_aux123_filt_std(i) < th_immovility;
end
immovility_aux_timestamps = amplifier_aux_filt_std_timestamps;

% Descartamos los eventos de inmovilidad que duran menos de 5 ventanas ww.
ww_inc = 10; % Número de ventanas necesarias como mínimo para incluir un evento de inmovilidad. Cada ventana tiene una duración de ww_ms
ww_desc = 5; % Número máximo de ventanas para descartar un evento de movilidad dentro de uno de inmovilidad. Cada ventana tiene una duración de ww_ms
% Calculo la posición de los cambios de movilidad->inmovilidad o de inmovilidad->movilidad y la duración de esos eventos
cambio_duracion = diff(find(diff(immovility_aux123))); % Duración del evento
cambio_puntos = find(diff(immovility_aux123)) + 1; % Puntos de cambio de evento
cambio = diff(immovility_aux123);
cambio(cambio == 0) = []; % Me quedo con los 1 y -1
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
cambio = diff(immovility_aux123_wwn);
cambio(cambio == 0) = []; % Me quedo solo con los 1 y -1
% Descarto los eventos de movilidad que no superan ww_desc de duración
for i = 1:length(cambio_duracion);
    if cambio(i) == -1 & cambio_duracion(i) <= ww_desc;
        immovility_aux123_wwn(cambio_puntos(i):(cambio_puntos(i+1))-1) = 1; % si la duración de la movilidad no supera ww_desc de duración, lo considero como inmovilidad
    end
end

% Ploteo el detector y el std de la señal del acelerómetro para chequear si funcionó bien
% ax1 = subplot(2,1,1); 
% plot(immovility_aux_timestamps,immovility_aux123_wwn,'color',[0.3 0.8 1],'LineWidth',1.5); % Ploteo el detector junto con los timestamps en seg
% title('Immobility detector');
% ax2 = subplot(2,1,2);
% plot(amplifier_aux_filt_std_timestamps,amplifier_aux123_filt_std,'color',[1 0 0.5],'LineWidth',1.5); % Ploteo el std de la señal con los timestamps en seg
% xlabel('Time (seg)');
% title('Standard deviation from acceleration signal');
% linkaxes([ax1 ax2],'x'); % Linkeo el eje x de ambas figuras para que se comporten en conjunto

%% Busco los timestamps de los tonos para cuantificar freezing en esos instantes.
cd(path_eventos);

% Cargamos los datos de los TTL y los timestamps.
TTL.states = readNPY('channel_states.npy'); % Cargamos el estado de cada input del IO Board.
TTL.timestamps = readNPY('timestamps.npy'); % Los timestamps estan en unidad de muestreo
TTL.channels = readNPY('channels.npy'); % Cargamos los estados de los canales.
TTL.timestamps = TTL.timestamps - TTL.timestamps(1); % Restamos el primer timestamp para que inicie en 0.
TTL.timestamps = TTL.timestamps/3000; % Pasamos a las unidades de immobility_aux123_wwn

% Buscamos los tiempos asociados a cada evento.
% Inicio y fin del CS+ asociado con la recompensa. Entrada #1 del IO board.
CS1.start = TTL.timestamps(find(TTL.states == 1));
CS1.end = TTL.timestamps(find(TTL.states == -1));
% Inicio y fin del CS-. Entrada #1 del IO board. Entrada #2 del IO board.
CS2.start = TTL.timestamps(find(TTL.states == 2));
CS2.end = TTL.timestamps(find(TTL.states == -2));

% Recortamos el detector de inmobilidad durante el tono
for i = 1:length(CS1.start);
    tono_CS1(i,:) = immovility_aux123_wwn(CS1.start(i):CS1.start(i)+600);
    tono_CS2(i,:) = immovility_aux123_wwn(CS2.start(i):CS2.start(i)+600);
end

% Calculamos el porcentaje de inmobilidad durante el tono
freezing_CS1 = mean(tono_CS1,2)*100;
freezing_CS2 = mean(tono_CS2,2)*100;

% Ploteamos ambas curvas
cs1_color = [255 67 66]/255; % Color para el CS1 o CS+
cs2_color = [70 171 215]/255; % Color para el CS2 o CS-
plot(freezing_CS1,'color',cs1_color,'LineWidth',2);
hold on
plot(freezing_CS2,'color',cs2_color,'LineWidth',2);
xlabel('Trial #');
ylabel('Porcentaje de tiempo freezando (%)');
title('Detección de freezing con acelerómetro');

%% Guardo las variables que me interesan

inicio_freezing = cambio_puntos(find(cambio == 1)) * Fs; % Busco los momentos donde inicia el freezing, en unidades de Fs
duracion_freezing = cambio_duracion(find(cambio == 1)) * Fs; % Duración del freezing en unidades de Fs.

cd('D:\Doctorado\Electrofisiología\Vol 11');
inicio_freezing_Day14 = inicio_freezing;
duracion_freezing_Day14 = duracion_freezing;
save('Freezing_Day14.mat','inicio_freezing_Day14','duracion_freezing_Day14');

%% Guardo el ploteo en una figura
cd(path); cd ../;
saveas(gcf,'Day12_Accelerometer_Freezing.png');
clearvars -except freezing_CS1 freezing_CS2;
save(['Day12_Accelerometer_Freezing.mat']);

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A partir de acá el script es un borrador %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Calculamos la diferencia entre el estado en un momento - el momento anterior
for i = 2:length(amplifier_aux1);
    movement_aux1(i) = amplifier_aux1(i) - amplifier_aux1(i-1); 
    movement_aux2(i) = amplifier_aux2(i) - amplifier_aux2(i-1);
    movement_aux3(i) = amplifier_aux3(i) - amplifier_aux3(i-1);
end
%% Calculamos la envolvente de cada señal
movement_aux1 = envelope(movement_aux1);
movement_aux2 = envelope(movement_aux2);
movement_aux3 = envelope(movement_aux3);
%% Guardamos las 3 envolventes en la misma matriz
movement(1,:) = movement_aux1;
movement(2,:) = movement_aux2; 
movement(3,:) = movement_aux3;
%% Calculamos el promedio de las tres envolventes
mean_movement = mean(movement);
%% Determinamos que esta freezando cuando la señal es mayor a 0.0015.
for i = 1:length(mean_movement);
    if mean_movement(i) > 0.0015;
         freezing(i) = 1;
    else
         freezing(i) = 0;
    end
end
%% Ploteamos
% plot(timestamps,freezing);
 plot(timestamps,amplifier_aux1);
 hold on
% plot(timestamps,envel);
% plot(timestamp_prommean,(prommean-min(prommean)));
plot(std_amplifier_aux1_timestamps,std_amplifier_aux1);

%%
a = 1;
for i = 1:3000:(size(envel,2)-3000);
    prommean(a) = mean(envel(i:i+3000));
    timestamp_prommean(a) = timestamps(i);
    a = a + 1;
end

%% La idea de este análisis es calcular el std en una ventana de x cantidad de tiempo. Ventanas que no se solapan.
% 
clearvars -except amplifier_aux1 amplifier_aux2 amplifier_aux3 timestamps

Fs = 30000; % Frecuencia de muestreo.
ww_ms = 100; % Ventana de análisis del acelerómetro en ms.
ww = (ww_ms/1000)*Fs; % Ventana de análisis del acelerómetro en muestras.
th_freezing = 0.01;

% j = 1;
% for i = ((ww/2)+1):(size(amplifier_aux1,2)-(ww/2)); % Desde el dato ww/2 hasta el final - ww/2 
%     std_amplifier_aux1(j) = std(amplifier_aux1(i-(ww/2):i+((ww/2)-1)));
%     std_amplifier_aux1_timestamps(j) = timestamps(i);
%     j = j + 1;
% end

% Calculamos para el canal aux1 el acelerómetro 1.
j = 1;
for i = ((ww/2)+1):ww:(size(amplifier_aux1,2)-(ww/2)); % Desde el dato ww/2 hasta el final - ww/2 
    std_amplifier_aux1(j) = std(amplifier_aux1(i-(ww/2):i+((ww/2)-1)));
    std_amplifier_aux2(j) = std(amplifier_aux2(i-(ww/2):i+((ww/2)-1)));
    std_amplifier_aux3(j) = std(amplifier_aux3(i-(ww/2):i+((ww/2)-1)));
    std_amplifier_aux_timestamps(j) = timestamps(i); % Timestamps en seg
    freezing(1,j) = std_amplifier_aux1(j) < th_freezing;
    freezing(2,j) = std_amplifier_aux2(j) < th_freezing;
    freezing(3,j) = std_amplifier_aux3(j) < th_freezing;
    j = j + 1;
end

freezing_xyz = mean(freezing,1); % Calculamos la media de las tres señales
freezing_xyz = freezing_xyz == 1; % Solo consideramos freezing cuando las tres señales dan 1. Si alguna señal detecta movimiento no es freezing.

estado = freezing_xyz(1);
for i = 2:length(freezing_xyz);
    detector_freezing(i) = freezing_xyz(i);
    detector_change(i) = freezing_xyz(i) ~= freezing_xyz(i-1);
    detector_timestamps(i) = std_amplifier_aux_timestamps(i);
end

detector_timestamps_change = detector_timestamps(find(detector_change == 1));
for i = 1:length(detector_timestamps_change)-1;
    detector_duration(i) = detector_timestamps_change(i+1) - detector_timestamps_change(i);
    detector_th(i) = detector_duration(i) >= 1;
end
detector_timestamps_change(end) = [];

for i = 1:length(detector_timestamps_change);
    detector_state(i) = detector_freezing(find(detector_timestamps == detector_timestamps_change(i)));
end

 ax1 = subplot(2,1,1);
 plot(std_amplifier_aux_timestamps,std_amplifier_aux1);
 hold on 
 ax2 = subplot(2,1,2);
 plot(std_amplifier_aux_timestamps,freezing_xyz);
 linkaxes([ax1 ax2],'x');
 
%% Filtramos las señales del acelerómetro con un pasaaltos en 0.25 Hz y un pasabajos en 6 Hz. 

samplePeriod = 1/Fs;
% Filtro pasa altos
filtCutOff = 0.25; % Frecuencia de corte del pasaaltos.
filtHPF = (2*filtCutOff)/(1/samplePeriod);
[b, a] = butter(1, filtHPF, 'high');
aux1_filt = filtfilt(b, a, amplifier_aux1);
aux2_filt = filtfilt(b, a, amplifier_aux2);
aux3_filt = filtfilt(b, a, amplifier_aux3);
% Filtro pasa ajos
filtCutOff = 6; % Frecuecia de corte del pasabajos.
filtLPF = (2*filtCutOff)/(1/samplePeriod);
[b, a] = butter(1, filtLPF, 'low');
aux1_filt = filtfilt(b, a, aux1_filt);
aux2_filt = filtfilt(b, a, aux2_filt);
aux3_filt = filtfilt(b, a, aux3_filt);

% Las señales van a quedar filtradas entre 0.25 Hz y 6 Hz y centradas en 0.

%% Calculamos el std de las tres señales filtradas en ventanas de tiempo fijas.
% 
clearvars -except amplifier_aux1 amplifier_aux2 amplifier_aux3 timestamps aux1_filt aux2_filt aux3_filt

Fs = 30000; % Frecuencia de muestreo.
ww_ms = 100; % Ventana de análisis del acelerómetro en ms.
ww = (ww_ms/1000)*Fs; % Ventana de análisis del acelerómetro en muestras.
th_freezing = 0.002; % Umbral para detectar freezing en la señal de std filtrada.

% Calculamos para el canal aux1 el acelerómetro 1.
j = 1;
for i = ((ww/2)+1):ww:(size(aux1_filt,2)-(ww/2)); % Desde el dato ww/2 hasta el final - ww/2 
    std_aux1_filt(j) = std(aux1_filt(i-(ww/2):i+((ww/2)-1)));
    std_aux2_filt(j) = std(aux2_filt(i-(ww/2):i+((ww/2)-1)));
    std_aux3_filt(j) = std(aux3_filt(i-(ww/2):i+((ww/2)-1)));
    std_aux_filt_timestamps(j) = timestamps(i); % Timestamps en seg.
    freezing_aux1_filt(j) = std_aux1_filt(j) < th_freezing;
    freezing_aux2_filt(j) = std_aux2_filt(j) < th_freezing;
    freezing_aux3_filt(j) = std_aux3_filt(j) < th_freezing;
    j = j + 1;
end
freezing_aux_filt_timestamps = std_aux_filt_timestamps; % Timestamps en seg. 

% Mejorar detector: despreciar eventos muy cortos de freezing metidos dentro de un evento más largo de movilidad o eventos de 
% movilidad muy cortos metidos dentro de un evento más largo de freezing.

for i = 2:length(freezing_aux1_filt);
    detector_change(i) = freezing_aux1_filt(i) ~= freezing_aux1_filt(i-1);
    detector_timestamps(i) = freezing_aux_filt_timestamps(i);
end

positions_change = find(detector_change == 1);
detector_durations(1) = detector_timestamps(positions_change(1));
for i = 2:length(positions_change);
    detector_durations(i) = detector_timestamps(positions_change(i)) - detector_timestamps(positions_change(i-1));
end

% En las siguientes lineas tengo que lograr obtener un vector igual a
% detector_change pero con los eventos cortos despreciados. 

j = 1;
for i = 1:length(positions_change);
    if freezing_aux1_filt(positions_change(i)) == 1;
        detector_change_immovility(j) = positions_change(i);
        detector_change_dif(j) = dif_positions_change(i);
        detector_change_durations(j) = detector_durations(i);
        j = j + 1;
    else
    end
end

%%
clear freezing_aux1_filt_th;
duration_th = 1; % Umbral de duración de evento de inmovilidad mínimo. 500ms de duración mínimo para considerarlo.
freezing_aux1_filt_th = freezing_aux1_filt;
for i = 1:length(detector_change_durations);
    if detector_change_durations(i+1) < duration_th;
        fin = positions_change(find(positions_change == detector_change_immovility(i))+1) - 1;
        freezing_aux1_filt_th(detector_change_immovility(i):fin) = 0;
    else
        % No reemplazo nada
    end
end


%%
dif_positions_change = diff(positions_change);

%%
clear freezing_aux1_filt_th;
freezing_aux1_filt_th = freezing_aux1_filt;
for i = 1:length(detector_change_immovility);
    if detector_change_dif(i) <= 40;
        inicio = detector_change_immovility(i);
        fin = inicio + detector_change_dif - 1;
        freezing_aux1_filt_th(inicio:fin) = 0;
    else
    end
end
%%
 ax1 = subplot(4,1,1);
 plot(timestamps,amplifier_aux1_filt);
 hold on 
 ax2 = subplot(4,1,2);
 plot(timestamps,amplifier_aux2_filt);
 hold on 
 ax3 = subplot(4,1,3);
 plot(timestamps,amplifier_aux3_filt);
 hold on 
 ax4 = subplot(4,1,4);
 plot(timestamps,amplifier_aux123_filt);
 hold on 
 linkaxes([ax1 ax2 ax3 ax4],'x');

%%
state = detector_change(1);

for i = 1:length();
    if detector_change == 1;
        if detector_durations(find(positions_change == i)) < 
        end
    else
        detector_state(i) = state;
    end
end



j = 1;
for i = 1:length(detector_change);
    if i = position_change(j);
    
    end
    detector_state(i) = detector_change(i);
end
% freezing_xyz = mean(freezing,1); % Calculamos la media de las tres señales
% freezing_xyz = freezing_xyz == 1; % Solo consideramos freezing cuando las tres señales dan 1. Si alguna señal detecta movimiento no es freezing.
% 
% estado = freezing_xyz(1);
% for i = 2:length(freezing_xyz);
%     detector_freezing(i) = freezing_xyz(i);
%     detector_change(i) = freezing_xyz(i) ~= freezing_xyz(i-1);
%     detector_timestamps(i) = std_amplifier_aux_timestamps(i);
% end
% 
% detector_timestamps_change = detector_timestamps(find(detector_change == 1));
% for i = 1:length(detector_timestamps_change)-1;
%     detector_duration(i) = detector_timestamps_change(i+1) - detector_timestamps_change(i);
%     detector_th(i) = detector_duration(i) >= 1;
% end
% detector_timestamps_change(end) = [];
% 
% for i = 1:length(detector_timestamps_change);
%     detector_state(i) = detector_freezing(find(detector_timestamps == detector_timestamps_change(i)));
% end
% 
%  ax1 = subplot(2,1,1);
%  plot(std_amplifier_aux_timestamps,std_amplifier_aux1);
%  hold on 
%  ax2 = subplot(2,1,2);
%  plot(std_amplifier_aux_timestamps,freezing_xyz);
%  linkaxes([ax1 ax2],'x');
%%
% plot(amplifier_aux1);
% hold on 
plot(std_aux1_filt);
hold on
plot(freezing(1,:));