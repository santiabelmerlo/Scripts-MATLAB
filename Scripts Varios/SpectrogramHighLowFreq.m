%% Espectrogramas de frecuencias bajas (0.5 a 20 Hz) y frecuencias altas (20 - 120 Hz) para la BLA y la PFC
% En la misma figura grafico los momentos que el animal freeza, el CS+ y el CS-
clear all
clc

%% Cargo las dos señales para PFC y BLA
% Seteamos los path del amplificador y de los TTL

% Vol 11 Aversivo
% path_amplifier = 'D:\Doctorado\Electrofisiología\Vol 11\Day12_2022-08-30_11-43-46_Rat1\Record Node 101\experiment1\recording1\continuous\Rhythm_FPGA-100.0';
% path_events = 'D:\Doctorado\Electrofisiología\Vol 11\Day12_2022-08-30_11-43-46_Rat1\Record Node 101\experiment1\recording1\events\Rhythm_FPGA-100.0\TTL_1';

% Vol 12 Aversivo
% path_amplifier = 'D:\Doctorado\Electrofisiología\Vol 12\Day13_2022-09-21_13-14-10_Rat1\Record Node 101\experiment1\recording1\continuous\Rhythm_FPGA-100.0';
% path_events = 'D:\Doctorado\Electrofisiología\Vol 12\Day13_2022-09-21_13-14-10_Rat1\Record Node 101\experiment1\recording1\events\Rhythm_FPGA-100.0\TTL_1';

% Vol 11 Apetitivo
% path_amplifier = 'D:\Doctorado\Electrofisiología\Vol 11\Day6_2022-08-24_11-56-44_Rat1\Record Node 101\experiment1\recording1\continuous\Rhythm_FPGA-100.0';
% path_events = 'D:\Doctorado\Electrofisiología\Vol 11\Day6_2022-08-24_11-56-44_Rat1\Record Node 101\experiment1\recording1\events\Rhythm_FPGA-100.0\TTL_1';

% Vol 10 Apetitivo
path_amplifier = 'D:\Doctorado\Electrofisiología\Vol 10\Day6_2022-06-19_14-04-13_Rat1\Record Node 101\experiment1\recording1\continuous\Rhythm_FPGA-100.0';
path_events = 'D:\Doctorado\Electrofisiología\Vol 10\Day6_2022-06-19_14-04-13_Rat1\Record Node 101\experiment1\recording1\events\Rhythm_FPGA-100.0\TTL_1';

cd(path_amplifier); % Seteamos el path donde esta la señal del amplificador: continuous.dat
Fs = 30000; % Frequencia de muestro del amplificador: 30 kHz.

% Importamos la señal del ch3 de PFC.
% channel = 2; % Canal que elijo para importar Vol 12
channel = 3; % Canal que elijo para importar Vol 11
% channel = 32; % Canal que elijo para importar Vol 10
num_channels = 35; % Número de canales que tiene la señal (32 canales + 3 canales del acelerómetro)
[data] = LoadBinary('continuous.dat', channel, num_channels); % Importamos la señal como "data"
data = data * 0.195; % Multiplicamos la señal por 0.195 para llevar las unidades a uV (microvolts)
amplifier_PFC = data; % Guardamos la señal como "amplifier_PFC"
clear data channel num_channels; % Borro las variables que no me sirven más

% Importamos la señal del ch12 de BLA.
% channel = 14; % Canal que elijo para importar Vol 12
channel = 12; % Canal que elijo para importar Vol 11
% channel = 26; % Canal que elijo para importar Vol 10
num_channels = 35; % Número de canales que tiene la señal (32 canales + 3 canales del acelerómetro)
[data] = LoadBinary('continuous.dat', channel, num_channels); % Importamos la señal como "data"
data = data * 0.195; % Multiplicamos la señal por 0.195 para llevar las unidades a uV (microvolts)
amplifier_BLA = data; % Guardamos la señal como "amplifier_BLA"
clear data channel num_channels; % Borro las variables que no me sirven más

% Importamos los timestamps de la señal
amplifier_timestamps = readNPY('timestamps.npy'); % Leemos el archivo "timestamps.npy" y guardamos como amplifier_timestamps
amplifier_timestamps = (amplifier_timestamps(1):1:amplifier_timestamps(end))'; % Esto lo hago porque a veces el archivo "timestamps.npy" esta fallado y le faltan datos. Entonces construyo nuevamente el vector tiempo a partir del timestamps de inicio y el final.

%% Subsampleamos las señales "amplifier_BLA" y "amplifier_PFC" y "amplifier_timestamps" a 1000 Hz para facilitar el procesamiento para el LFP
% Subsampleamos a 1000 Hz.
amplifier_BLA_downsample = amplifier_BLA(1:30:length(amplifier_timestamps)); % Subsampleamos "amplifier_BLA"
% amplifier_BLA_downsample = downsample(amplifier_BLA,30); % También se puede hacer así y da lo mismo
amplifier_PFC_downsample = amplifier_PFC(1:30:length(amplifier_timestamps)); % Subsampleamos "amplifier_PFC"
% amplifier_PFC_downsample = downsample(amplifier_PFC,30); % También se puede hacer así y da lo mismo
amplifier_timestamps_downsample = amplifier_timestamps(1:30:length(amplifier_timestamps)); % Subsampleamos "amplifier_timestamps"
amplifier_timestamps_downsample_sec = (double(amplifier_timestamps_downsample))/30000; % Timestamps en segundos
amplifier_timestamps_downsample_sec = amplifier_timestamps_downsample_sec - amplifier_timestamps_downsample_sec(1) ; % Reseteamos el inicio de "amplifier_timestamps_downsample_sec" a cero
clear amplifier_BLA amplifier_PFC amplifier_timestamps;

%% Filtramos las señales "amplifier_BLA" y "amplifier_PFC" entre 0.1 Hz y 300 Hz para eliminar información que no me interesa para el LFP
% Filtramos "amplifier_BLA_downsample"
highpass = 0.1; lowpass = 300; % Frecuencias de corte del filtro
data = amplifier_BLA_downsample; % Señal que queremos filtrar
samplePeriod = 1/1000; % Frecuencia de muestreo de la señal subsampleada
% Aplicamos un filtro pasa altos con corte en 0.1 Hz
filtHPF = (2*highpass)/(1/samplePeriod);
[b, a] = butter(1, filtHPF, 'high');
data_hp = filtfilt(b, a, data);
% Aplicamos un filtro pasa bajos con corte en 300 Hz
filtLPF = (2*lowpass)/(1/samplePeriod);
[b, a] = butter(1, filtLPF, 'low');
data_hlp = filtfilt(b, a, data_hp); %señal de mag de acel filtrada
amplifier_BLA_downsample_filt = data_hlp; % Guardamos la señal filtrada como "amplifier_BLA_downsample_filt"
clear data_hlp a b data filtHPF data_hp filtLPF amplifier_BLA_downsample; % Borramos las variables que no me sirven más

% Filtramos "amplifier_PFC_downsample"
data = amplifier_PFC_downsample; % Señal que queremos filtrar
% hp filter accelerometer data
filtHPF = (2*highpass)/(1/samplePeriod);
[b, a] = butter(1, filtHPF, 'high');
data_hp = filtfilt(b, a, data);
% LP filter accelerometer data
filtLPF = (2*lowpass)/(1/samplePeriod);
[b, a] = butter(1, filtLPF, 'low');
data_hlp = filtfilt(b, a, data_hp); %señal de mag de acel filtrada
amplifier_PFC_downsample_filt = data_hlp; 
clear data_hlp a b data highpass lowpass SamplePeriod filtHPF data_hp filtLPF amplifier_PFC_downsample samplePeriod;

%% Calculamos los espectrogramas para frecuencias bajas (0.5 a 20 Hz) y frecuencias altas (20 - 120 Hz). Lo hacemos para BLA y PFC
% Seteamos algunos parámetros para luego computar el espectrograma y espectro de potencias.
params.Fs = 1000; % Frecuencia de muestreo: 1000 muestras por segundo.
params.err = 0;
params.tapers = [6 11];

% Computamos el espectrograma para la BLA en el rango de 0.5 a 20 Hz
params.fpass=[0.5 20]; % Frecuencias de interes. En este caso de 2 a 20 Hz
movingwin=[2 0.5]; % Parámetros para frecuencias entre 0.5 Hz y 20 Hz. Movingstep es un 25% del movingwin.
[S,t,f] = mtspecgramc(amplifier_BLA_downsample_filt,movingwin,params);
% plot_matrix(S,t,f,'l'); xlabel(['Time (msec)']); ylabel(['Frequency (Hz)']); colormap(jet);
S_lowband_BLA = S; t_lowband_BLA = t; f_lowband_BLA = f; clear S; clear t; clear f;
% Corregimos para quitar el pink noise
for i = 1:size(S_lowband_BLA,2)
    S_lowband_BLA(:,i) = S_lowband_BLA(:,i)*f_lowband_BLA(1,i);
end

% Computamos el espectrograma para la BLA en el rango de 20 a 120 Hz.
params.fpass=[20 120]; % Frecuencias de interes. En este caso de 20 a 120 Hz
movingwin=[0.5 0.125]; % Parámetros para frecuencias entre 20 Hz y 120 Hz. Movingstep es un 25% del movingwin
[S,t,f] = mtspecgramc(amplifier_BLA_downsample_filt,movingwin,params);
% plot_matrix(S,t,f,'l'); xlabel(['Time (msec)']); ylabel(['Frequency (Hz)']); colormap(jet);
S_highband_BLA = S; t_highband_BLA = t; f_highband_BLA = f; clear S; clear t; clear f;
% Corregimos para quitar el pink noise
for i = 1:size(S_highband_BLA,2)
    S_highband_BLA(:,i) = S_highband_BLA(:,i)*f_highband_BLA(1,i);
end

% Computamos el espectrograma para la BLA en el rango de 0.5 a 120 Hz.
params.fpass=[0.5 120]; % Frecuencias de interes. En este caso de 20 a 120 Hz
movingwin=[2 0.5]; % Parámetros para frecuencias entre 20 Hz y 120 Hz. Movingstep es un 25% del movingwin
[S,t,f] = mtspecgramc(amplifier_BLA_downsample_filt,movingwin,params);
% plot_matrix(S,t,f,'l'); xlabel(['Time (msec)']); ylabel(['Frequency (Hz)']); colormap(jet);
S_fullband_BLA = S; t_fullband_BLA = t; f_fullband_BLA = f; clear S; clear t; clear f;
% Corregimos para quitar el pink noise
for i = 1:size(S_fullband_BLA,2)
    S_fullband_BLA(:,i) = S_fullband_BLA(:,i)*f_fullband_BLA(1,i);
end

% Computamos el espectrograma para la PFC en el rango de 0.5 a 20 Hz
params.fpass=[0.5 20]; % Frecuencias de interes. En este caso de 2 a 20 Hz
movingwin=[2 0.5]; % Parámetros para frecuencias entre 0.5 Hz y 20 Hz. Movingstep es un 25% del movingwin
[S,t,f] = mtspecgramc(amplifier_PFC_downsample_filt,movingwin,params);
% plot_matrix(S,t,f,'l'); xlabel(['Time (msec)']); ylabel(['Frequency (Hz)']); colormap(jet);
S_lowband_PFC = S; t_lowband_PFC = t; f_lowband_PFC = f; clear S; clear t; clear f;
% Corregimos para quitar el pink noise
for i = 1:size(S_lowband_PFC,2)
    S_lowband_PFC(:,i) = S_lowband_PFC(:,i)*f_lowband_PFC(1,i);
end

% Computamos el espectrograma para la PFC en el rango de 20 a 120 Hz.
params.fpass=[20 120]; % Frecuencias de interes. En este caso de 20 a 120 Hz
movingwin=[0.5 0.125]; % Parámetros para frecuencias entre 20 Hz y 120 Hz. Movingstep es un 25% del movingwin
[S,t,f] = mtspecgramc(amplifier_PFC_downsample_filt,movingwin,params);
% plot_matrix(S,t,f,'l'); xlabel(['Time (msec)']); ylabel(['Frequency (Hz)']); colormap(jet);
S_highband_PFC = S; t_highband_PFC = t; f_highband_PFC = f; clear S; clear t; clear f;
% Corregimos para quitar el pink noise
for i = 1:size(S_highband_PFC,2)
    S_highband_PFC(:,i) = S_highband_PFC(:,i)*f_highband_PFC(1,i);
end

% Computamos el espectrograma para la PFC en el rango de 0.5 a 120 Hz.
params.fpass=[0.5 120]; % Frecuencias de interes. En este caso de 20 a 120 Hz
movingwin=[2 0.5]; % Parámetros para frecuencias entre 20 Hz y 120 Hz. Movingstep es un 25% del movingwin
[S,t,f] = mtspecgramc(amplifier_PFC_downsample_filt,movingwin,params);
% plot_matrix(S,t,f,'l'); xlabel(['Time (msec)']); ylabel(['Frequency (Hz)']); colormap(jet);
S_fullband_PFC = S; t_fullband_PFC = t; f_fullband_PFC = f; clear S; clear t; clear f;
% Corregimos para quitar el pink noise
for i = 1:size(S_fullband_PFC,2)
    S_fullband_PFC(:,i) = S_fullband_PFC(:,i)*f_fullband_PFC(1,i);
end

clear params.Fs params.err params.tapers params.fpass movingwin i params Fs;

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

%% Importamos la señal del acelerómetro para detectar freezing
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
  
%% Guardo el workspace para trabajarlo luego 
clc
clear all
path_analisis = 'C:\Users\santi\Desktop\Análisis';
cd(path_analisis);
% save('Vol10_Day6.mat');
load('Vol11_Day6.mat');

%%
% Para el espectro de potencias sacar el pink noise con S.*f y plotear con 10*log10 como power(au)
% El espectrograma además calcularle el zscore y plotearlo así


%% Ploteo los espectrogramas: del lado izquierdo BLA y del lado derecho PFC. Arriba frecuencias altas y abajo frecuencias bajas
cs1_color = [255 67 66]/255; % Seteo el color para el CS1
cs2_color = [70 171 215]/255; % Seteo el color para el CS2

% Ploteo Espectrograma de frecuencias altas de BLA
ax1 = subplot(2,2,1); % Primer panel de ploteo
yyaxis left; % Seteo la figura que va a quedar con el eje y a la izquierda
plot_matrix(S_highband_BLA,t_highband_BLA,f_highband_BLA,'n'); 
xlabel(['Time (sec)']); ylabel(['Frequency (Hz)']);  title(['High Freq BLA Spectrogram ']);
colormap(jet); caxis([0 3000]); % Cambio el color del espectrograma y lo acoto entre 0 y 3000
ylim([20 120]); % Seteo el eje y izquiero de 20 a 120
hold on; % Sigo ploteando en la misma figura
yyaxis right % Seteo la figura que va a quedar con el eje y a la derecha
% Grafico con lineas blancas los momentos en los que el animal freeza
for i = 1:length(inicio_freezing);
    freezing_event = [inicio_freezing(i) fin_freezing(i)];
    line(freezing_event,[1 1],'Color','w','LineWidth',5);
end
% Grafico con lineas rojas los momentos del CS+
cs1_color = [255 67 66]/255; % Seteo el color para el CS1
for i = 1:length(TTL_CS1_inicio);
    line([TTL_CS1_inicio(i) TTL_CS1_fin(i)],[1.05 1.05],'Color',cs1_color,'LineWidth',5);
end
% Grafico con lineas azules los momentos del CS-
cs2_color = [70 171 215]/255;
for i = 1:length(TTL_CS2_inicio);
    line([TTL_CS2_inicio(i) TTL_CS2_fin(i)],[1.05 1.05],'Color',cs2_color,'LineWidth',5);
end
ylim([0 1.1]); % Seteo el eje y derecho de 0 a 1.1

% Ploteo Espectrograma de frecuencias bajas de BLA
ax3 = subplot(2,2,3); % Tercer panel de la figura
yyaxis left; % Seteo la figura que va a quedar con el eje y a la izquierda
plot_matrix(S_lowband_BLA,t_lowband_BLA,f_lowband_BLA,'n'); 
xlabel(['Time (sec)']); ylabel(['Frequency (Hz)']); title(['Low Freq BLA Spectrogram ']);
colormap(jet); caxis([0 6000]); % Cambio el color del espectrograma y lo acoto entre 0 y 3000
ylim([0.7 20]); % Seteo el eje y izquiero de 0.7 a 20
hold on; % Sigo ploteando en la misma figura
yyaxis right % Seteo la figura que va a quedar con el eje y a la derecha
% Grafico con lineas blancas los momentos en los que el animal freeza
for i = 1:length(inicio_freezing);
    freezing_event = [inicio_freezing(i) fin_freezing(i)];
    line(freezing_event,[1 1],'Color','w','LineWidth',5);
end
% Grafico con lineas rojas los momentos del CS+
for i = 1:length(TTL_CS1_inicio);
    line([TTL_CS1_inicio(i) TTL_CS1_fin(i)],[1.05 1.05],'Color',cs1_color,'LineWidth',5);
end
% Grafico con lineas azules los momentos del CS-
cs2_color = [70 171 215]/255;
for i = 1:length(TTL_CS2_inicio);
    line([TTL_CS2_inicio(i) TTL_CS2_fin(i)],[1.05 1.05],'Color',cs2_color,'LineWidth',5);
end
ylim([0 1.1]); % Seteo el eje y derecho de 0 a 1.1

% Ploteo Espectrograma de frecuencias altas de PFC
ax2 = subplot(2,2,2); % Segundo panel de ploteo
yyaxis left; % Seteo la figura que va a quedar con el eje y a la izquierda
plot_matrix(S_highband_PFC,t_highband_PFC,f_highband_PFC,'n'); 
xlabel(['Time (sec)']); ylabel(['Frequency (Hz)']);  title(['High Freq PFC Spectrogram ']);
colormap(jet); 
% caxis([0 100000]); % Cambio el color del espectrograma y lo acoto entre 0 y 3000
caxis([0 3000]);
ylim([20 120]); % Seteo el eje y izquiero de 20 a 120
hold on; % Sigo ploteando en la misma figura
yyaxis right % Seteo la figura que va a quedar con el eje y a la derecha
% Grafico con lineas blancas los momentos en los que el animal freeza
for i = 1:length(inicio_freezing);
    freezing_event = [inicio_freezing(i) fin_freezing(i)];
    line(freezing_event,[1 1],'Color','w','LineWidth',5);
end
% Grafico con lineas rojas los momentos del CS+
for i = 1:length(TTL_CS1_inicio);
    line([TTL_CS1_inicio(i) TTL_CS1_fin(i)],[1.05 1.05],'Color',cs1_color,'LineWidth',5);
end
% Grafico con lineas azules los momentos del CS-
cs2_color = [70 171 215]/255;
for i = 1:length(TTL_CS2_inicio);
    line([TTL_CS2_inicio(i) TTL_CS2_fin(i)],[1.05 1.05],'Color',cs2_color,'LineWidth',5);
end
ylim([0 1.1]); % Seteo el eje y derecho de 0 a 1.1

% Ploteo Espectrograma de frecuencias bajas de PFC
ax4 = subplot(2,2,4); % Cuarto panel de ploteo
yyaxis left; % Seteo la figura que va a quedar con el eje y a la izquierda
plot_matrix(S_lowband_PFC,t_lowband_PFC,f_lowband_PFC,'n'); 
xlabel(['Time (sec)']); ylabel(['Frequency (Hz)']); title(['Low Freq PFC Spectrogram ']);
colormap(jet); caxis([0 6000]); % Cambio el color del espectrograma y lo acoto entre 0 y 3000
% caxis([0 6000]);
ylim([0.7 20]); % Seteo el eje y izquiero de 0.7 a 20
hold on; % Sigo ploteando en la misma figura
yyaxis right % Seteo la figura que va a quedar con el eje y a la derecha
% Grafico con lineas blancas los momentos en los que el animal freeza
for i = 1:length(inicio_freezing);
    freezing_event = [inicio_freezing(i) fin_freezing(i)];
    line(freezing_event,[1 1],'Color','w','LineWidth',5);
end
% Grafico con lineas rojas los momentos del CS+
for i = 1:length(TTL_CS1_inicio);
    line([TTL_CS1_inicio(i) TTL_CS1_fin(i)],[1.05 1.05],'Color',cs1_color,'LineWidth',5);
end
% Grafico con lineas azules los momentos del CS-
cs2_color = [70 171 215]/255;
for i = 1:length(TTL_CS2_inicio);
    line([TTL_CS2_inicio(i) TTL_CS2_fin(i)],[1.05 1.05],'Color',cs2_color,'LineWidth',5);
end
ylim([0 1.1]); % Seteo el eje y derecho de 0 a 1.1

% Linkeo los ejes X para que se correspondan en tiempo
linkaxes([ax1 ax2 ax3 ax4],'x'); % Linkeo el eje x de ambas figuras para que se comporten en conjunto