%% Script para plotear espectrograma de una sesión apetitiva o aversiva
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

    S_zscored = zscore(S,0,1);
    S_theta_power = mean(S_zscored(:,80:210),2); % Potencia zscoreada entre 6 y 16 Hz
    theta_pattern = zeros(size(S_theta_power));
    theta_pattern(S_theta_power > 0.5) = 1;

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
            if size(find(times_theta_pattern >= inicio_quietud(i) & times_theta_pattern <= fin_quietud(i)),2)/ventana < 0.3;
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

    save([strcat(name,'_epileptic+sleep.mat')]);
end

disp(['Ready!']);