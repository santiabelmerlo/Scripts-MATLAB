%% Movement Detector
% Script para detectar los momentos de movimiento en el acelerómetro y
% guardar esos tiempos de inicio, fin y duración dentro del archivo
% epileptic.mat

clc;
clear all;

% Define the parent folder containing the 'Rxx' folders
parentFolder = 'D:\Doctorado\Backup Ordenado';

% List all 'Rxx' folders in the parent folder
R_folders = dir(fullfile(parentFolder, 'R*'));

% Iterate through each 'Rxx' folder
for r = 1:length(R_folders)
    current_R_folder = fullfile(parentFolder, R_folders(r).name);
    disp(['Processing folder: ' current_R_folder]);
    
    % List all subfolders inside the 'Rxx' folder
    D_folders = dir(fullfile(current_R_folder, 'R*D*'));
    D_folders = D_folders([D_folders.isdir]);
    
    % Iterate through each 'RxDy' folder
    for d = 1:length(D_folders)

        current_D_folder = fullfile(current_R_folder, D_folders(d).name);
        disp(['Processing subfolder: ' current_D_folder]);
        
        % Change the current folder to the 'RxDy' subfolder
        cd(current_D_folder);
        [~,D,X] = fileparts(current_D_folder); name = D([1:6]);
        
        % Check if the .dat file exists
        file_path = strcat(name, '_lfp.dat');
        % Check if the sessioninfo.mat file exists
        sessioninfo_path = strcat(name, '_sessioninfo.mat');
        % Check if the epileptic.mat file exists
        epileptic_path = strcat(name, '_epileptic.mat');
        % Check if the freezing.mat file exists
        freezing_path = strcat(name, '_freezing.mat');
        
        if exist(file_path, 'file') && exist(sessioninfo_path, 'file') && ...
                exist(epileptic_path, 'file') && exist(freezing_path, 'file') == 2
            
            load(strcat(name,'_sessioninfo.mat')); % Cargamos la información de la sesión

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

            % Detectamos movilidad seteando un umbral en el std.

            clear inicio_movement fin_movement duracion_movement immovility_aux123 cambio_duracion cambio_puntos cambio immovility_aux123_wwn

            % Detectamos inmovilidad seteando un umbral en el std.
            th_immovility = 0.05; % Umbral para detectar inmovilidad, en volts.
            for i = 1:length(amplifier_aux123_filt_std);
                immovility_aux123(i) = amplifier_aux123_filt_std(i) > th_immovility;
            end
            immovility_aux_timestamps = amplifier_aux_filt_std_timestamps;

            % Descartamos los eventos de inmovilidad que duran menos de 10 ventanas ww.
            ww_inc = 1; % Número de ventanas necesarias como mínimo para incluir un evento de inmovilidad. Cada ventana tiene una duración de ww_ms
            ww_inc2 = 10;
            ww_desc = 20; % Número máximo de ventanas para descartar un evento de movilidad dentro de uno de inmovilidad. Cada ventana tiene una duración de ww_ms
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
            inicio_movement = immovility_aux_timestamps(cambio_puntos(find(cambio == 1))); % Timestamps de inicio del freezing
            fin_movement =  immovility_aux_timestamps(cambio_puntos(find(cambio == -1))); % Timestamps del fin del freezing
            duracion_movement = fin_movement - inicio_movement; % Duración de los eventos de freezing

            inicio_movement = inicio_movement(duracion_movement >= 1);
            fin_movement = fin_movement(duracion_movement >= 1);
            duracion_movement = duracion_movement(duracion_movement >= 1);

            % Cargamos los datos de epileptic.mat
            load(strcat(name,'_epileptic.mat')); % Cargamos la información de la sesión

            % Inicializar listas para guardar los intervalos de movimiento filtrados
            inicio_movement_filtered = [];
            fin_movement_filtered = [];
            duracion_movement_filtered = [];

            % Iterar a través de cada evento de movimiento
            for i = 1:length(inicio_movement)
                movimiento_inicio = inicio_movement(i);
                movimiento_fin = fin_movement(i);

                % Verificar si el intervalo de movimiento se solapa con algún intervalo de freezing, epilepsia o de sueño
                solapa_con_freezing = false;
                solapa_con_epileptic = false;
                solapa_con_sleep = false;

                % Comprobar solapamiento con eventos de freezing
                for j = 1:length(inicio_freezing)
                    freezing_inicio = inicio_freezing(j);
                    freezing_fin = fin_freezing(j);

                    if (movimiento_inicio <= freezing_fin) && (movimiento_fin >= freezing_inicio)
                        solapa_con_freezing = true;
                        break; % Si se encuentra un solapamiento, no es necesario seguir comprobando
                    end
                end

                % Comprobar solapamiento con eventos de epilepsia
                for j = 1:length(inicio_epileptic)
                    epileptic_inicio = inicio_epileptic(j);
                    epileptic_fin = fin_epileptic(j);

                    if (movimiento_inicio <= epileptic_fin) && (movimiento_fin >= epileptic_inicio)
                        solapa_con_epileptic = true;
                        break; % Si se encuentra un solapamiento, no es necesario seguir comprobando
                    end
                end

                % Comprobar solapamiento con eventos de sueño
                for j = 1:length(inicio_sleep)
                    sleep_inicio = inicio_sleep(j);
                    sleep_fin = fin_sleep(j);

                    if (movimiento_inicio <= sleep_fin) && (movimiento_fin >= sleep_inicio)
                        solapa_con_sleep = true;
                        break; % Si se encuentra un solapamiento, no es necesario seguir comprobando
                    end
                end

                % Si no hay solapamiento con ningún evento de freezing, epilepsia o sueño, guardar el evento de movimiento
                if ~solapa_con_freezing && ~solapa_con_epileptic && ~solapa_con_sleep
                    inicio_movement_filtered(end+1) = movimiento_inicio;
                    fin_movement_filtered(end+1) = movimiento_fin;
                    duracion_movement_filtered(end+1) = duracion_movement(i);
                end
            end

            clear inicio_movement fin_movement duracion_movement

            % Convertir los resultados a vectores columna (opcional)
            inicio_movement = inicio_movement_filtered(1,:);
            fin_movement = fin_movement_filtered(1,:);
            duracion_movement = duracion_movement_filtered(1,:);
            
            save([strcat(name, '_epileptic.mat')], 'name', 'inicio_freezing', 'fin_freezing', 'duracion_freezing', ...
                'inicio_quietud', 'fin_quietud', 'duracion_quietud', 'inicio_epileptic', ...
                'inicio_sleep', 'fin_sleep', 'duracion_sleep', 'fin_epileptic', 'duracion_epileptic', ...
                'paradigm', 'inicio_movement', 'fin_movement', 'duracion_movement', ...
                'TTL_CS1_inicio', 'TTL_CS1_fin', 'TTL_CS2_inicio', 'TTL_CS2_fin');

            clearvars -except parentFolder R_folders r current_R_folder D_folders d current_D_folder
            
            disp(' Movement detection finished');
        else
            disp(' Some required file doesnt exist. Skipping session...');
        end
        
        % Go back to the 'Rxx' folder
        cd(current_R_folder);
    end
end
disp('Done!');
cd(parentFolder);
aleluya();