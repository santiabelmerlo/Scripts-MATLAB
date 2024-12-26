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
delete(strcat(name,'_freezing.mat'));
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

save([strcat(name,'_freezing.mat')]);
disp('Ready freezing detection with accelerometer!');

% Script para plotear espectrograma de una sesión apetitiva o aversiva
% Ploteamos bajas frecuencias, altas frecuencias y señal raw con los
% eventos encima
clc
clear all
path = pwd;
[~,name,~] = fileparts(pwd);
name = name(1:6);

% Seteamos qué canal queremos levantar de la señal
Fs = 1250; % Frecuencia de sampleo
load(strcat(name,'_sessioninfo.mat'), 'BLA_mainchannel'); ch = BLA_mainchannel; clear BLA_mainchannel; % Canal a levantar
load(strcat(name,'_sessioninfo.mat'), 'ch_total'); % Número de canales totales
load(strcat(name,'_sessioninfo.mat'), 'paradigm'); % Tipo de paradigma. Appetitive or aversive

% Seteamos algunos colores para los ploteos
if strcmp(paradigm,'appetitive');
    cs1_color = [0 128 0]/255; % Seteo el color para el CS+ apetitivo
    cs2_color = [96 96 96]/255; % Seteo el color para el CS-
    behaviour_color = [10 10 10]/255; % Seteo el color para comportamiento
elseif strcmp(paradigm,'aversive');
    cs1_color = [118 6 154]/255; % Seteo el color para el CS+ aversivo
    cs2_color = [96 96 96]/255; % Seteo el color para el CS-
    behaviour_color = [10 10 10]/255; % Seteo el color para comportamiento
end

% Cargamos los datos del TTL1
TTL_states = readNPY(strcat(name,'_TTL_channel_states.npy')); % Cargamos el estado de cada input del IO Board. 
TTL_timestamps = readNPY(strcat(name,'_TTL_timestamps.npy')); % Los timestamps estan en unidad de muestreo: 30 kHz.
TTL_channels = readNPY(strcat(name,'_TTL_channels.npy')); % Cargamos los estados de los canales.

% Cargamos los datos del amplificador
amplifier_timestamps = readNPY(strcat(name,'_timestamps.npy')); % Cargamos el estado de cada input del IO Board.
amplifier_timestamps = double(amplifier_timestamps(1):1:amplifier_timestamps(end)); % Hay que hacer esto porque amplifier.timestamps devuelve distinto número de tiempos que de registro.
amplifier_timestamps_lfp = double(amplifier_timestamps(1):24:amplifier_timestamps(end)); % Hay que hacer esto porque amplifier.timestamps devuelve distinto número de tiempos que de registro.
amplifier_timestamps_lfp = (amplifier_timestamps_lfp - amplifier_timestamps(1))/30000; % Le restamos el primer timestamp y lo pasamos a segundos. 

if exist(strcat(name,'_freezing.mat')) == 2
    % The file exists, do something
    disp(['Uploading freezing data...']);
    % Cargo los datos de freezing
    load(strcat(name,'_freezing.mat'));
else
    % The file does not exist, do nothing
    disp(['Freezing data do not exists. Skipping action...']);
    clear all;
end

if exist(strcat(name,'_freezing.mat')) == 2 & ismember('inicio_immobility', who('-file', strcat(name,'_freezing.mat')))
    disp(['Freezing detection had been already cleaned. Skipping action...']);
    
    disp(['Analizing low frequency multi-taper spectrogram...']);
    load(strcat(name,'_specgram_PLLowFreq.mat'))
    S = 10*log10(S);
    
    disp(['Plotting low frequency multi-taper spectrogram...']);
    figure();
    plot_matrix(S,t,f,'n');
            ylabel(['Frequency (Hz)']);
            xlabel('Time (sec.)');
            title('Espectrograma de PL con momentos de freezing e inmovilidad');
            colormap(jet);    
            hcb = colorbar; hcb.YLabel.String = 'Power (dB)'; hcb.FontSize = 12;
            caxis([10 40]);
            colorbar('off');
            ylim([0 15]);
            hold on;

    disp(['Plotting events...']);
    for i = 1:length(TTL_CS1_inicio);
        line([TTL_CS1_inicio(i) TTL_CS1_fin(i)],[12 12],'Color',[191 64 191]/255,'LineWidth',10);
    end
    for i = 1:length(TTL_CS2_inicio);
        line([TTL_CS2_inicio(i) TTL_CS2_fin(i)],[12 12],'Color',[0.7 0.7 0.7],'LineWidth',10);
    end

    if strcmp(paradigm,'appetitive');
        for i = 1:size(IR2_start,1);
            line([IR2_inicio(i,1) IR2_fin(i,:)],[4 4],'Color',behaviour_color,'LineWidth',3);
        end
        for i = 1:size(IR3_start,1);
            line([IR3_inicio(i,1) IR3_fin(i,:)],[3.8 3.8],'Color',behaviour_color,'LineWidth',3);
        end
    elseif strcmp(paradigm,'aversive');
        for i = 1:size(inicio_freezing,2);
            line([inicio_freezing(i) (inicio_freezing(i)+duracion_freezing(i))],[10 10],'Color',[1 1 1],'LineWidth',10);
        end
        for i = 1:size(inicio_immobility,2);
            line([inicio_immobility(i) (inicio_immobility(i)+duracion_immobility(i))],[11 11],'Color',[1 0 0],'LineWidth',10);
        end
    end
    hold off;
    
    % Ploteamos ambas curvas
    figure();
    cs1_color = [118 6 154]/255; % Seteo el color para el CS+ aversivo
    cs2_color = [96 96 96]/255; % Seteo el color para el CS-
    plot(freezing_CS1_porc,'color',cs1_color,'LineWidth',2);
    hold on
    plot(freezing_CS2_porc,'color',cs2_color,'LineWidth',2);
    ylim([0 100])
    xlabel('Trial #');
    ylabel('Freezing (%)');
    title('Detección de freezing con acelerómetro');

    % Ploteamos ambas curvas binneado de a dos
    figure();
    cs1_color = [118 6 154]/255; % Seteo el color para el CS+ aversivo
    cs2_color = [96 96 96]/255; % Seteo el color para el CS-
    plot(freezing_CS1_binned_porc,'color',cs1_color,'LineWidth',2);
    hold on
    plot(freezing_CS2_binned_porc,'color',cs2_color,'LineWidth',2);
    ylim([0 100])
    xlabel('Trial #');
    ylabel('Freezing (%)');
    title('Detección de freezing con acelerómetro binneado');
     
    clearvars -except name inicio_freezing fin_freezing duracion_freezing...
    inicio_quietud fin_quietud duracion_quietud inicio_immobility...
    fin_immobility duracion_immobility freezing_detection freezing_timestamps...
    freezing_preCS freezing_preCS_porc freezing_CS1 freezing_CS2...
    freezing_CS1_porc freezing_CS2_porc freezing_CS1_binned freezing_CS2_binned...
    freezing_CS1_binned_porc freezing_CS2_binned_porc paradigm...
    TTL_CS1_inicio TTL_CS1_fin TTL_CS2_inicio TTL_CS2_fin freezing freezing_binned

else
    disp(['Cleaning freezing detection...']);
    % Calculamos los tiempos de los CSs.
    % Buscamos los tiempos asociados a cada evento.
    TTL_start = amplifier_timestamps(1); % Seteamos el primer timestamp 
    TTL_end = amplifier_timestamps(end); % Seteamos el último timestamp
    % Inicio y fin del CS+ asociado con la recompensa. Entrada #1 del IO board.
    TTL_CS1_start = TTL_timestamps(find(TTL_states == 1));
    TTL_CS1_end = TTL_timestamps(find(TTL_states == -1));
    % Inicio y fin del CS-. Entrada #1 del IO board. Entrada #2 del IO board.
    TTL_CS2_start = TTL_timestamps(find(TTL_states == 2));
    TTL_CS2_end = TTL_timestamps(find(TTL_states == -2));

    % Inicio y fin de los nosepokes en la puerta. Entrada #5 del IO board.
    IR2_start = TTL_timestamps(find(TTL_states == 5));
    IR2_end = TTL_timestamps(find(TTL_states == -5));
    % Borramos el dato si arranca en end o termina en start
    if size(IR2_start,1) ~= size(IR2_end,1);
        if IR2_start(1) >= IR2_end(1);
            if size(IR2_start,1) > size(IR2_end,1);  % Este if fue agregado despues y falta agregarlo para la condicion de IR3
                IR2_start(end) = [];
            elseif size(IR2_start,1) < size(IR2_end,1);
                IR2_end(1) = [];
            end
        elseif IR2_end(end) <= IR2_start(end);
            IR2_start(end) = [];
        end
    end

    % Inicio y fin de los nosepokes en el target. Entrada #6 del IO board.
    IR3_start = TTL_timestamps(find(TTL_states == 6));
    IR3_end = TTL_timestamps(find(TTL_states == -6));

    % Borramos el dato si arranca en end o termina en start
    if size(IR3_start,1) ~= size(IR3_end,1);
        if IR3_start(1) >= IR3_end(1);
            IR3_end(1) = [];
        elseif IR3_end(end) <= IR3_start(end);
            IR3_start(end) = [];
        end
    end   

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
    % Llevo los tiempos del Nosepoke a segundos y los sincronizo con los tiempos del registro
    IR2_inicio = IR2_start - TTL_start; IR2_inicio = double(IR2_inicio);
    IR2_fin = IR2_end - TTL_start; IR2_fin = double(IR2_fin);
    IR2_inicio = IR2_inicio/30000; % Llevo los tiempos a segundos
    IR2_fin = IR2_fin/30000; % Llevo los tiempos a segundos
    % Llevo los tiempos del licking a segundos y los sincronizo con los tiempos del registro
    IR3_inicio = IR3_start - TTL_start; IR3_inicio = double(IR3_inicio);
    IR3_fin = IR3_end - TTL_start; IR3_fin = double(IR3_fin);
    IR3_inicio = IR3_inicio/30000; % Llevo los tiempos a segundos
    IR3_fin = IR3_fin/30000; % Llevo los tiempos a segundos

    disp(['Analizing low frequency multi-taper spectrogram...']);
    load(strcat(name,'_specgram_PLLowFreq.mat'))
    S = 10*log10(S); 
    
    disp(['Plotting low frequency multi-taper spectrogram...']);
    figure();
    ax1 = subplot(1,2,1);
    plot_matrix(S,t,f,'n');
            ylabel(['Frequency (Hz)']);
            xlabel('Time (sec.)');
            title('Espectrograma PL con momentos de quiescencia');
            colormap(jet);    
            hcb = colorbar; hcb.YLabel.String = 'Power (dB)'; hcb.FontSize = 12;
            caxis([10 40]);
            colorbar('off');
            ylim([0 15]);
            hold on;

    disp(['Plotting events...']);
    for i = 1:length(TTL_CS1_inicio);
        line([TTL_CS1_inicio(i) TTL_CS1_fin(i)],[12 12],'Color',[191 64 191]/255,'LineWidth',10);
    end
    for i = 1:length(TTL_CS2_inicio);
        line([TTL_CS2_inicio(i) TTL_CS2_fin(i)],[12 12],'Color',[0.7 0.7 0.7],'LineWidth',10);
    end

    if strcmp(paradigm,'appetitive');
        for i = 1:size(IR2_start,1);
            line([IR2_inicio(i,1) IR2_fin(i,:)],[4 4],'Color',behaviour_color,'LineWidth',3);
        end
        for i = 1:size(IR3_start,1);
            line([IR3_inicio(i,1) IR3_fin(i,:)],[3.8 3.8],'Color',behaviour_color,'LineWidth',3);
        end
    elseif strcmp(paradigm,'aversive');
        for i = 1:size(inicio_freezing,2);
            line([inicio_freezing(i) (inicio_freezing(i)+duracion_freezing(i))],[10 10],'Color',[1 1 1],'LineWidth',10);
        end
    end
    hold off;

    inicio_quietud = inicio_freezing; % Me lo backupeo en una nueva variable
    fin_quietud = inicio_freezing + duracion_freezing;
    duracion_quietud = duracion_freezing;
    clear inicio_freezing duracion_freezing

    disp(['Analizing low frequency multi-taper spectrogram...']);
    load(strcat(name,'_specgram_PLLowFreq.mat'))
    S = bsxfun(@times, S, f); 
    S = bsxfun(@rdivide, S, mean(mean(S,1)));  
    
    S_zscored = S;
    S_theta_power = mean(S_zscored(:,80:210),2); % Potencia zscoreada entre 6 y 16 Hz
    S_8Hz_power = mean(S_zscored(:,80:133),2); % Potencia zscoreada entre 6 y 10 Hz
    S_4Hz_power = mean(S_zscored(:,21:54),2); % Potencia zscoreada entre 1.5 y 4 Hz
    S_1Hz_power = mean(S_zscored(:,1:20),2); % Potencia zscoreada entre 0 y 1.5 Hz
    S_4vs8_power =  (S_4Hz_power-((S_8Hz_power+S_1Hz_power)/1))./(S_8Hz_power+S_4Hz_power+S_1Hz_power);
    S_8vs4_power =  ((S_8Hz_power+S_1Hz_power)-S_4Hz_power)./(S_8Hz_power+S_4Hz_power+S_1Hz_power);
    theta_pattern = zeros(size(S_4vs8_power));
    theta_pattern(zscore(S_4vs8_power) < -0.3) = 1;

    times_theta_pattern = t(find(theta_pattern == 1));
    inicio_freezing = [];
    fin_freezing = [];
    inicio_immobility = []; 
    fin_immobility = [];

    for i = 1:size(inicio_quietud,2);
        ventana = duracion_quietud(i)/0.5;
        if isempty(find(times_theta_pattern >= inicio_quietud(i) & times_theta_pattern <= fin_quietud(i)));
            inicio_freezing = vertcat(inicio_freezing,inicio_quietud(i));
            fin_freezing = vertcat(fin_freezing,fin_quietud(i));
        else
            if size(find(times_theta_pattern >= inicio_quietud(i) & times_theta_pattern <= fin_quietud(i)),2)/ventana < 0.25;
                inicio_freezing = vertcat(inicio_freezing,inicio_quietud(i));
                fin_freezing = vertcat(fin_freezing,fin_quietud(i));
            else
                inicio_immobility = vertcat(inicio_immobility,inicio_quietud(i));
                fin_immobility = vertcat(fin_immobility,fin_quietud(i));
            end
        end
    end

    duracion_freezing = fin_freezing - inicio_freezing;
    duracion_immobility = fin_immobility - inicio_immobility;

    % Transponemos todos los vectores porque otros scipts los usan así
    inicio_freezing = inicio_freezing';
    fin_freezing = fin_freezing';
    duracion_freezing = duracion_freezing';
    inicio_immobility = inicio_immobility';
    fin_immobility = fin_immobility';
    duracion_immobility = duracion_immobility';

    disp(['Analizing low frequency multi-taper spectrogram...']);
    load(strcat(name,'_specgram_PLLowFreq.mat'))
    S = 10*log10(S); 
    
    disp(['Plotting low frequency multi-taper spectrogram...']);
    ax2 = subplot(1,2,2);
    plot_matrix(S,t,f,'n');
            ylabel(['Frequency (Hz)']);
            xlabel('Time (sec.)');
            title('Espectrograma PL con momentos de freezing e inmovilidad');
            colormap(jet);    
            hcb = colorbar; hcb.YLabel.String = 'Power (dB)'; hcb.FontSize = 12;
            caxis([10 40]);
            colorbar('off');
            ylim([0 15]);
            hold on;

    disp(['Plotting events...']);
    for i = 1:length(TTL_CS1_inicio);
        line([TTL_CS1_inicio(i) TTL_CS1_fin(i)],[12 12],'Color',[191 64 191]/255,'LineWidth',10);
    end
    for i = 1:length(TTL_CS2_inicio);
        line([TTL_CS2_inicio(i) TTL_CS2_fin(i)],[12 12],'Color',[0.7 0.7 0.7],'LineWidth',10);
    end

    if strcmp(paradigm,'appetitive');
        for i = 1:size(IR2_start,1);
            line([IR2_inicio(i,1) IR2_fin(i,:)],[4 4],'Color',behaviour_color,'LineWidth',3);
        end
        for i = 1:size(IR3_start,1);
            line([IR3_inicio(i,1) IR3_fin(i,:)],[3.8 3.8],'Color',behaviour_color,'LineWidth',3);
        end
    elseif strcmp(paradigm,'aversive');
        for i = 1:size(inicio_freezing,2);
            line([inicio_freezing(i) (inicio_freezing(i)+duracion_freezing(i))],[10 10],'Color',[1 1 1],'LineWidth',10);
        end
        for i = 1:size(inicio_immobility,2);
            line([inicio_immobility(i) (inicio_immobility(i)+duracion_immobility(i))],[11 11],'Color',[1 0 0],'LineWidth',10);
        end
    end
    hold off;

    linkaxes([ax1 ax2],'x');

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

    clear i j freezing;

    freezing_CS1_porc = (freezing_CS1/60)*100;
    freezing_CS2_porc = (freezing_CS2/60)*100;

    % Promediamos bloques de 2 trials
    if mod(size(freezing_CS1,1), 2) == 1;
        freezing_CS1(end+1) = freezing_CS1(end);
        freezing_CS2(end+1) = freezing_CS2(end);
        freezing_CS1_porc(end+1) = freezing_CS1_porc(end);
        freezing_CS2_porc(end+1) = freezing_CS2_porc(end);
    end
    freezing_CS1_binned = mean(reshape(freezing_CS1, 2, []), 1)';
    freezing_CS2_binned = mean(reshape(freezing_CS2, 2, []), 1)';
    freezing_CS1_binned_porc = (freezing_CS1_binned/60)*100;
    freezing_CS2_binned_porc = (freezing_CS2_binned/60)*100;

    freezing = table(freezing_CS1,freezing_CS2,freezing_CS1_porc,freezing_CS2_porc); % Creamos una tabla con los datos de freezing de CS1 y CS2
    freezing_binned = table(freezing_CS1_binned,freezing_CS2_binned,freezing_CS1_binned_porc,freezing_CS2_binned_porc);
    
    % Ploteamos ambas curvas
    figure();
    cs1_color = [118 6 154]/255; % Seteo el color para el CS+ aversivo
    cs2_color = [96 96 96]/255; % Seteo el color para el CS-
    plot(freezing_CS1_porc,'color',cs1_color,'LineWidth',2);
    hold on
    plot(freezing_CS2_porc,'color',cs2_color,'LineWidth',2);
    ylim([0 100])
    xlabel('Trial #');
    ylabel('Freezing (%)');
    title('Detección de freezing con acelerómetro');

    % Ploteamos ambas curvas binneado de a dos
    figure();
    cs1_color = [118 6 154]/255; % Seteo el color para el CS+ aversivo
    cs2_color = [96 96 96]/255; % Seteo el color para el CS-
    plot(freezing_CS1_binned_porc,'color',cs1_color,'LineWidth',2);
    hold on
    plot(freezing_CS2_binned_porc,'color',cs2_color,'LineWidth',2);
    ylim([0 100])
    xlabel('Trial #');
    ylabel('Freezing (%)');
    title('Detección de freezing con acelerómetro');

    clearvars -except name inicio_freezing fin_freezing duracion_freezing...
        inicio_quietud fin_quietud duracion_quietud inicio_immobility...
        fin_immobility duracion_immobility freezing_detection freezing_timestamps...
        freezing_preCS freezing_preCS_porc freezing_CS1 freezing_CS2...
        freezing_CS1_porc freezing_CS2_porc freezing_CS1_binned freezing_CS2_binned...
        freezing_CS1_binned_porc freezing_CS2_binned_porc paradigm...
        TTL_CS1_inicio TTL_CS1_fin TTL_CS2_inicio TTL_CS2_fin freezing freezing_binned

    save([strcat(name,'_freezing.mat')]);
end

disp(['Ready cleaning freezing and saving file!']);