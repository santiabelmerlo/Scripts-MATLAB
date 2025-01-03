%% Accelerometer Freezing Detector
% Calculo el porcentaje de freezing durante cada tono
% Este script solo requiere tener los archivos: continuous.dat, channel_states.npy, timestamps.npy y channels.npy

clc
clear all
path = pwd;
[~,name,~] = fileparts(pwd);
name = name(1:6);

% Seteamos qu� canal queremos levantar de la se�al
Fs = 1250; % Frecuencia de sampleo
load(strcat(name,'_sessioninfo.mat'), 'BLA_mainchannel'); ch = BLA_mainchannel; clear BLA_mainchannel; % Canal a levantar
load(strcat(name,'_sessioninfo.mat'), 'ch_total'); % N�mero de canales totales
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

% Cargo los Eventos del CS
% Importamos los eventos con sus timestamps.
% Cargamos los datos de los TTL y los timestamps.
TTL_states = readNPY(strcat(name(1:6),'_TTL_channel_states.npy')); % Cargamos el estado de cada input del IO Board. 
TTL_timestamps = readNPY(strcat(name(1:6),'_TTL_timestamps.npy')); % Los timestamps estan en unidad de muestreo: 30 kHz.
TTL_channels = readNPY(strcat(name(1:6),'_TTL_channels.npy')); % Cargamos los estados de los canales.
TTL_start = TTL_timestamps(1); % Seteamos el primer timestamp 
TTL_end = TTL_timestamps(end); % Seteamos el �ltimo timestamp

% Buscamos los tiempos asociados a cada evento.
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

% Borramos todas las variables que no me sirven
clear TTL_timestamps TTL_states TTL_start TTL_end TTL_CS1_start TTL_CS1_end TTL_CS2_start TTL_CS2_end TTL_channels; 

% Importamos la se�al del aceler�metro para detectar freezing para R10 a R14
load(strcat(name,'_sessioninfo.mat'), 'ACC_channels'); % Cargamos los canales del aceler�metro
[amplifier_aux1]=LoadBinary(strcat(name(1:6),'_lfp.dat'), ACC_channels(1), ch_total); % Cargamos se�al de AUX1
amplifier_aux1 = amplifier_aux1 * 0.0000374; % Convertimos a volts
[amplifier_aux2]=LoadBinary(strcat(name(1:6),'_lfp.dat'), ACC_channels(2), ch_total); % Cargamos se�al de AUX2
amplifier_aux2 = amplifier_aux2 * 0.0000374; % Convertimos a volts
[amplifier_aux3]=LoadBinary(strcat(name(1:6),'_lfp.dat'), ACC_channels(3), ch_total); % Cargamos se�al de AUX3
amplifier_aux3 = amplifier_aux3 * 0.0000374; % Convertimos a volts

timestamps = (0:1/Fs:((size(amplifier_aux1,2)/Fs)-(1/Fs))); % Timestamps en seg.

% Combinamos las tres se�ales de aceleraci�n en una sola realizando la suma de cuadrados
amplifier_aux123 = sqrt(sum(amplifier_aux1(1,:).^2 + amplifier_aux1(1,:).^2 + amplifier_aux3(1,:).^2, 1)); % Magnitud de la aceleraci�n

% Filtramos las se�ales del aceler�metro con un pasa altos en 0.25 Hz y un pasabajos en 6 Hz.
% Las se�ales quedan filtradas entre 0.25 Hz y 6 Hz. Quedan centradas en 0.
samplePeriod = 1/Fs;
% Filtro pasa altos
filtCutOff = 0.25; % Frecuencia de corte del pasaaltos.
filtHPF = (2*filtCutOff)/(1/samplePeriod);
[b, a] = butter(1, filtHPF, 'high');
amplifier_aux123_filt = filtfilt(b, a, amplifier_aux123); % Filtramos HPF a la se�al aux123
% Filtro pasa bajos
filtCutOff = 6; % Frecuecia de corte del pasabajos.
filtLPF = (2*filtCutOff)/(1/samplePeriod);
[b, a] = butter(1, filtLPF, 'low');
amplifier_aux123_filt = filtfilt(b, a, amplifier_aux123_filt); % Filtramos LPF a la se�al aux123

% Calculamos el desv�o est�ndar de las se�ales filtradas en ventanas de tiempo fijas, no solapadas.
ww_ms = 100; % Ventana de an�lisis del aceler�metro en ms.
ww = (ww_ms/1000)*Fs; % Ventana de an�lisis del aceler�metro en muestras.
j = 1;

for i = ((round(ww/2))+1):ww:(size(amplifier_aux123_filt,2)-(round(ww/2))); % Desde el dato ww/2 hasta el final - ww/2 
    amplifier_aux123_filt_std(j) = std(amplifier_aux123_filt(i-(round(ww/2)):i+((round(ww/2))-1))); % Calculamos el desv�o est�ndar de la se�al aux123 filtrada
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
ww_inc = 10; % N�mero de ventanas necesarias como m�nimo para incluir un evento de inmovilidad. Cada ventana tiene una duraci�n de ww_ms
ww_desc = 5; % N�mero m�ximo de ventanas para descartar un evento de movilidad dentro de uno de inmovilidad. Cada ventana tiene una duraci�n de ww_ms
% Calculo la posici�n de los cambios de movilidad->inmovilidad o de inmovilidad->movilidad y la duraci�n de esos eventos
cambio_duracion = diff(find(diff(immovility_aux123))); % Duraci�n del evento
cambio_puntos = find(diff(immovility_aux123)) + 1; % Puntos de cambio de evento
cambio = diff(immovility_aux123); cambio(cambio == 0) = []; % Me quedo con los 1 y -1
% Me quedo solo con los eventos de inmovilidad que superan ww_inc de duraci�n
immovility_aux123_wwn(1:length(immovility_aux123)) = 0; % Arranco con un vector de todos ceros
for i = 1:length(cambio_duracion);
    if cambio(i) == 1 & cambio_duracion(i) >= ww_inc;
        immovility_aux123_wwn(cambio_puntos(i):(cambio_puntos(i+1))-1) = 1; % Reemplazo con 1 donde ocurren esos eventos de inmovilidad
    end
end
% Una vez que me qued� solo con los eventos de inmovilidad que superan ww_inc de duracion, voy a descartar los eventos de movilidad que no superan ww_desc
% Vuelvo a calcular la posicion de los cambios y la duraci�n de los eventos
cambio_duracion = diff(find(diff(immovility_aux123_wwn))); % Duraci�n del evento
cambio_puntos = find(diff(immovility_aux123_wwn)) + 1; % Puntos de cambio
cambio = diff(immovility_aux123_wwn); cambio(cambio == 0) = []; % Me quedo solo con los 1 y -1
% Descarto los eventos de movilidad que no superan ww_desc de duraci�n
for i = 1:length(cambio_duracion);
    if cambio(i) == -1 & cambio_duracion(i) <= ww_desc;
        immovility_aux123_wwn(cambio_puntos(i):(cambio_puntos(i+1))-1) = 1; % si la duraci�n de la movilidad no supera ww_desc de duraci�n, lo considero como inmovilidad
    end
end
% Vuelvo a calcular la posicion de los cambios y la duraci�n de los eventos
cambio_duracion = diff(find(diff(immovility_aux123_wwn))); % Duraci�n del evento
cambio_puntos = find(diff(immovility_aux123_wwn)) + 1; % Puntos de cambio
cambio = diff(immovility_aux123_wwn); cambio(cambio == 0) = []; % Me quedo solo con los 1 y -1

% Calculo los timestamps en segundos en los que inicia el freezing, los momentos en que termina, y la duraci�n de cada evento.
inicio_freezing = immovility_aux_timestamps(cambio_puntos(find(cambio == 1))); % Timestamps de inicio del freezing
fin_freezing =  immovility_aux_timestamps(cambio_puntos(find(cambio == -1))); % Timestamps del fin del freezing
duracion_freezing = fin_freezing - inicio_freezing; % Duraci�n de los eventos de freezing
  
freezing_timestamps = immovility_aux_timestamps;
freezing_detection = immovility_aux123_wwn;

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

disp('Ready quiescence detection!');

% Script para plotear espectrograma de una sesi�n apetitiva o aversiva
% Ploteamos bajas frecuencias, altas frecuencias y se�al raw con los
% eventos encima

% Cargamos los datos del amplificador
amplifier_timestamps = readNPY(strcat(name,'_timestamps.npy')); % Cargamos el estado de cada input del IO Board.
amplifier_timestamps = double(amplifier_timestamps(1):1:amplifier_timestamps(end)); % Hay que hacer esto porque amplifier.timestamps devuelve distinto n�mero de tiempos que de registro.
amplifier_timestamps_lfp = double(amplifier_timestamps(1):24:amplifier_timestamps(end)); % Hay que hacer esto porque amplifier.timestamps devuelve distinto n�mero de tiempos que de registro.
amplifier_timestamps_lfp = (amplifier_timestamps_lfp - amplifier_timestamps(1))/30000; % Le restamos el primer timestamp y lo pasamos a segundos. 

if exist(strcat(name,'_epileptic.mat')) == 2 & ismember('inicio_epileptic', who('-file', strcat(name,'_epileptic.mat')))
    disp(['Epileptic and sleep data already exist. Skipping action...']);
    load(strcat(name,'_epileptic.mat'));
    
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
        for i = 1:size(inicio_epileptic,2);
            line([inicio_epileptic(i) (inicio_epileptic(i)+duracion_epileptic(i))],[11 11],'Color',[1 0 0],'LineWidth',10);
        end
        for i = 1:size(inicio_sleep,2);
            line([inicio_sleep(i) (inicio_sleep(i)+duracion_sleep(i))],[10.5 10.5],'Color',[0 0 1],'LineWidth',10);
        end
    end
    hold off;
     
    clearvars -except name inicio_freezing fin_freezing duracion_freezing...
        inicio_quietud fin_quietud duracion_quietud inicio_epileptic...
        inicio_sleep fin_sleep duracion_sleep...
        fin_epileptic duracion_epileptic paradigm...
        TTL_CS1_inicio TTL_CS1_fin TTL_CS2_inicio TTL_CS2_fin

else
    disp(['Detecting epileptic and sleep events...']);

    disp(['Analizing low frequency multi-taper spectrogram...']);
    load(strcat(name,'_specgram_PLLowFreq.mat'));
    S = 10*log10(S);

    inicio_quietud = inicio_freezing; % Me lo backupeo en una nueva variable
    fin_quietud = inicio_freezing + duracion_freezing;
    duracion_quietud = duracion_freezing;
    clear inicio_freezing duracion_freezing

    % Patr�n epil�ptico
    S_zscored = zscore(S,0,1);
    S_theta_power = mean(S_zscored(:,80:210),2); % Potencia zscoreada entre 6 y 16 Hz
    theta_pattern = zeros(size(S_theta_power));
    theta_pattern(S_theta_power > 0.5) = 1;
    times_theta_pattern = t(find(theta_pattern == 1));

    % Patr�n de sue�o
    S_sleep_power = mean(S_zscored(:,1:20),2); % Potencia zscoreada entre 0 y 1.5 Hz
    sleep_pattern = zeros(size(S_sleep_power));
    sleep_pattern(S_sleep_power > 0.5) = 1;
    times_sleep_pattern = t(find(sleep_pattern == 1));

    % Buscamos para epileptic
    inicio_freezing = [];
    fin_freezing = [];
    inicio_epileptic = []; 
    fin_epileptic = [];

    for i = 1:size(inicio_quietud,2);
        ventana = duracion_quietud(i)/0.5;
        if isempty(find(times_theta_pattern >= inicio_quietud(i) & times_theta_pattern <= fin_quietud(i)));
            inicio_freezing = vertcat(inicio_freezing,inicio_quietud(i));
            fin_freezing = vertcat(fin_freezing,fin_quietud(i));
        else
            if size(find(times_theta_pattern >= inicio_quietud(i) & times_theta_pattern <= fin_quietud(i)),2)/ventana < 0.3;
                inicio_freezing = vertcat(inicio_freezing,inicio_quietud(i));
                fin_freezing = vertcat(fin_freezing,fin_quietud(i));
            else
                inicio_epileptic = vertcat(inicio_epileptic,inicio_quietud(i));
                fin_epileptic = vertcat(fin_epileptic,fin_quietud(i));
            end
        end
    end
    
    % Buscamos para sleep
    inicio_sleep = []; 
    fin_sleep = [];
    
    for i = 1:size(inicio_quietud,2);
        ventana = duracion_quietud(i)/0.5;
        if isempty(find(times_sleep_pattern >= inicio_quietud(i) & times_sleep_pattern <= fin_quietud(i)));
            % Skip
        else
            if size(find(times_sleep_pattern >= inicio_quietud(i) & times_sleep_pattern <= fin_quietud(i)),2)/ventana < 0.3;
                % Skip
            else
                inicio_sleep = vertcat(inicio_sleep,inicio_quietud(i));
                fin_sleep = vertcat(fin_sleep,fin_quietud(i));
            end
        end
    end

    duracion_freezing = fin_freezing - inicio_freezing;
    duracion_epileptic = fin_epileptic - inicio_epileptic;
    duracion_sleep = fin_sleep - inicio_sleep;

    % Transponemos todos los vectores porque otros scipts los usan as�
    inicio_freezing = inicio_freezing';
    fin_freezing = fin_freezing';
    duracion_freezing = duracion_freezing';
    inicio_epileptic = inicio_epileptic';
    fin_epileptic = fin_epileptic';
    duracion_epileptic = duracion_epileptic';
    inicio_sleep = inicio_sleep';
    fin_sleep = fin_sleep';
    duracion_sleep = duracion_sleep';

    clearvars -except name inicio_freezing fin_freezing duracion_freezing...
        inicio_quietud fin_quietud duracion_quietud inicio_epileptic...
        inicio_sleep fin_sleep duracion_sleep...
        fin_epileptic duracion_epileptic paradigm...
        TTL_CS1_inicio TTL_CS1_fin TTL_CS2_inicio TTL_CS2_fin

     save([strcat(name,'_epileptic.mat')]);
end

disp(['Ready!']);

