%% Script para recorrer todas las carpetas y calcular momentos de aceleracion y desaceleracion
% Modificar parámetros ww_des ww_ac umbral_aceleracion
% umbral_desaceleracion para obtener resultados distintos
% OUTPUT: vectores 'aceleracion' y 'desaceleracion' con timestamps en
% segundos

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
        disp(['  Processing subfolder: ' current_D_folder]);
        
        % Change the current folder to the 'RxDy' subfolder
        cd(current_D_folder);
        [~,D,X] = fileparts(current_D_folder); name = D([1:6]);
        
        % Check if the session_info file exists and accelerometer data
        % exists

        sessioninfo_file = strcat(name, '_sessioninfo.mat');
        timestamps_file = strcat(name, '_timestamps.npy');
        if exist(sessioninfo_file, 'file') == 2 & exist(timestamps_file, 'file') == 2;
            disp(['    File '  sessioninfo_file ' exists. Computing acceleration... ']);
            load(strcat(name,'_sessioninfo.mat'),'ACC_channels');
            load(strcat(name,'_sessioninfo.mat'),'paradigm');
            if isempty(ACC_channels);
                disp(['    ACC_channels do not exist. Skipping action...']);
            else
                
                %%%%%% Pego mi script
                Fs = 1250; % Frecuencia de sampleo

                load(strcat(name,'_sessioninfo.mat'), 'ch_total'); % Número de canales totales
                load(strcat(name,'_sessioninfo.mat'), 'paradigm'); % Tipo de paradigma. Appetitive or aversive
                load(strcat(name,'_sessioninfo.mat'), 'ACC_channels'); % Cargamos los canales del acelerómetro

                % Cargamos los datos del amplificador
                amplifier_timestamps = readNPY(strcat(name,'_timestamps.npy')); % Cargamos el estado de cada input del IO Board.
                amplifier_timestamps = double(amplifier_timestamps(1):1:amplifier_timestamps(end)); % Hay que hacer esto porque amplifier.timestamps devuelve distinto número de tiempos que de registro.
                amplifier_timestamps_lfp = double(amplifier_timestamps(1):24:amplifier_timestamps(end)); % Hay que hacer esto porque amplifier.timestamps devuelve distinto número de tiempos que de registro.
                amplifier_timestamps_lfp = (amplifier_timestamps_lfp - amplifier_timestamps(1))/30000; % Le restamos el primer timestamp y lo pasamos a segundos. 

                % Importamos la señal del acelerómetro para detectar freezing para R10 a R14
                [amplifier_aux1]=LoadBinary(strcat(name(1:6),'_lfp.dat'), ACC_channels(1), ch_total); % Cargamos señal de AUX1
                amplifier_aux1 = amplifier_aux1 * 0.0000374; % Convertimos a volts
                [amplifier_aux2]=LoadBinary(strcat(name(1:6),'_lfp.dat'), ACC_channels(2), ch_total); % Cargamos señal de AUX2
                amplifier_aux2 = amplifier_aux2 * 0.0000374; % Convertimos a volts
                [amplifier_aux3]=LoadBinary(strcat(name(1:6),'_lfp.dat'), ACC_channels(3), ch_total); % Cargamos señal de AUX3
                amplifier_aux3 = amplifier_aux3 * 0.0000374; % Convertimos a volts

                timestamps = (0:1/Fs:((size(amplifier_aux1,2)/Fs)-(1/Fs))); % Timestamps en seg.

                % Combinamos las tres señales de aceleración en una sola realizando la suma de cuadrados
                amplifier_aux123 = sqrt(sum(amplifier_aux1(1,:).^2 + amplifier_aux1(1,:).^2 + amplifier_aux3(1,:).^2, 1)); % Magnitud de la aceleración
                magnitud_aceleracion = amplifier_aux123;

                % Filtramos las señales del acelerómetro con un pasa altos en 0.25 Hz y un pasabajos en 6 Hz.
                % Las señales quedan filtradas entre 0.25 Hz y 6 Hz. Quedan centradas en 0.
                samplePeriod = 1/Fs;
                % Filtro pasa altos
                filtCutOff = 0.25; % Frecuencia de corte del pasaaltos.
                filtHPF = (2*filtCutOff)/(1/samplePeriod);
                [b, a] = butter(4, filtHPF, 'high');
                amplifier_aux123_filt = filtfilt(b, a, amplifier_aux123); % Filtramos HPF a la señal aux123
                % Filtro pasa bajos
                filtCutOff = 6; % Frecuecia de corte del pasabajos.
                filtLPF = (2*filtCutOff)/(1/samplePeriod);
                [b, a] = butter(4, filtLPF, 'low');
                magnitud_aceleracion_suavizada = filtfilt(b, a, amplifier_aux123_filt); % Filtramos LPF a la señal aux123

                % Paso 3: Calcular la derivada de la magnitud de la aceleración
                derivada_aceleracion = diff(magnitud_aceleracion_suavizada);

                % Paso 4: Definir umbrales para detectar cambios significativos (ajustar según sea necesario)
                umbral_aceleracion = 0.001; % Umbral para detectar aceleración
                umbral_desaceleracion = -0.001; % Umbral para detectar desaceleración

                % Paso 5: Encontrar los momentos de aceleración y desaceleración
                momentos_aceleracion = zeros(1,size(derivada_aceleracion,2)+1);
                momentos_aceleracion(find(derivada_aceleracion > umbral_aceleracion) + 1) = 1;

                momentos_desaceleracion = zeros(1,size(derivada_aceleracion,2)+1);
                momentos_desaceleracion(find(derivada_aceleracion < umbral_desaceleracion) + 1) = 1;

                % Descartamos los eventos de desaceleración que duran menos de 500 ms.
                ww_des = 1/mean(diff(timestamps));
                cambio_duracion = diff(find(diff(momentos_aceleracion)));
                cambio_puntos = find(diff(momentos_aceleracion)) + 1; % Puntos de cambio
                cambio = diff(momentos_aceleracion); cambio(cambio == 0) = []; % Me quedo solo con los 1 y -1
                % Descarto los eventos de movilidad que no superan ww_desc de duración
                for i = 1:length(cambio_duracion);
                    if cambio(i) == -1 & cambio_duracion(i) <= ww_des;
                        momentos_aceleracion(cambio_puntos(i):(cambio_puntos(i+1))-1) = 1;
                    end
                end

                % Descartamos los eventos de desaceleración que duran menos de 500 ms.
                ww_ac = 1/mean(diff(timestamps));
                cambio_duracion = diff(find(diff(momentos_aceleracion)));
                cambio_puntos = find(diff(momentos_aceleracion)) + 1; % Puntos de cambio
                cambio = diff(momentos_aceleracion); cambio(cambio == 0) = []; % Me quedo solo con los 1 y -1
                % Descarto los eventos de movilidad que no superan ww_desc de duración
                for i = 1:length(cambio_duracion);
                    if cambio(i) == 1 & cambio_duracion(i) <= ww_ac;
                        momentos_aceleracion(cambio_puntos(i):(cambio_puntos(i+1))-1) = 0;
                    end
                end

                clear cambio_puntos cambio
                cambio_puntos = find(diff(momentos_aceleracion)) + 1;
                cambio = diff(momentos_aceleracion); cambio(cambio == 0) = []; % Me quedo solo con los 1 y -1

                aceleracion = timestamps(cambio_puntos(find(cambio == 1))); % Timestamps de inicio de la aceleracion
                desaceleracion =  timestamps(cambio_puntos(find(cambio == -1))); % Timestamps del inicio de la desaceleracion
                duracion_aceleracion = desaceleracion - aceleracion; % Duración de la aceleracion

                clearvars -except name aceleracion desaceleracion duracion_aceleracion...
                    cambio cambio_puntos parentFolder R_folders name D_folders d r current_R_folder
                disp(['    Saving acceleration file...']);
                save([strcat(name,'_acceleration.mat')]);
                %%%%%%
            end
        end
 
        % Go back to the 'Rxx' folder
        cd(current_R_folder);
    end
end
disp('Done!');
cd(parentFolder);