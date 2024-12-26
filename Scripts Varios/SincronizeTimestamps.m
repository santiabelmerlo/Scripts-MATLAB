clear all
clc 

% path_TTL = 'D:\Doctorado\Electrofisiología\Vol 9\Day5_2022-05-11_12-28-00_Rat1\Record Node 101\experiment1\recording1\events\Rhythm_FPGA-100.0/TTL_1/';
% path_amplifier = 'D:\Doctorado\Electrofisiología\Vol 9\Day5_2022-05-11_12-28-00_Rat1\Record Node 101\experiment1\recording1\continuous\Rhythm_FPGA-100.0';

path_TTL = 'D:\Doctorado\Electrofisiología\Vol 11\Day12_2022-08-30_11-43-46_Rat1\Record Node 101\experiment1\recording1\events\Rhythm_FPGA-100.0\TTL_1';
path_amplifier = 'D:\Doctorado\Electrofisiología\Vol 11\Day12_2022-08-30_11-43-46_Rat1\Record Node 101\experiment1\recording1\continuous\Rhythm_FPGA-100.0';

%%
% Cargamos los datos de los TTL y los timestamps.
cd(path_TTL); % Vamos a la carpeta donde se guardan los eventos.
TTL.states = readNPY('channel_states.npy'); % Cargamos el estado de cada input del IO Board. 
TTL.timestamps = readNPY('timestamps.npy'); % Los timestamps estan en unidad de muestreo: 30 kHz.
TTL.channels = readNPY('channels.npy'); % Cargamos los estados de los canales.

% Cargamos los timestamps del registro.
cd(path_amplifier); % Vamos a la carpeta donde se guarda el registro.
amplifier.timestamps = readNPY('timestamps.npy'); % Cargamos el estado de cada input del IO Board.
amplifier.timestamps = (amplifier.timestamps(1):1:amplifier.timestamps(end)); % Hay que hacer esto porque amplifier.timestamps devuelve distinto número de tiempos que de registro.

%%
% Sincronizamos los timestams y pasamos las unidades de tiempo a ms. 
amplifier.start = amplifier.timestamps(1); % Calculamos el tiempo de inicio del registro para determinar ese punto como 0.
amplifier.time = amplifier.timestamps - (amplifier.start - 1); % Restamos a los timestamps del registro el tiempo cero.
TTL.timestamps = TTL.timestamps - (amplifier.start - 1);  % Restamos a los timestamps de los eventos el tiempo cero. 
%TTL.timestamps = TTL.timestamps/30; % Pasamos las unidades a milisegundos. Esto se hace cuando el muestreo es a 30kb/s en el Open Ephys.
%amplifier.time = amplifier.time/30; % Pasamos las unidades a milisegundos. Esto se hace cuando el muestreo es a 30kb/s en el Open Ephys.

    % Buscamos los tiempos asociados a cada evento. 
    % Inicio y fin del CS+ asociado con la recompensa. Entrada #1 del IO board.
    CS1.start = TTL.timestamps(find(TTL.states == 1));
    CS1.end = TTL.timestamps(find(TTL.states == -1));
    % Inicio y fin del CS-. Entrada #1 del IO board. Entrada #2 del IO board.
    CS2.start = TTL.timestamps(find(TTL.states == 2));
    CS2.end = TTL.timestamps(find(TTL.states == -2));
    % Inicio y fin de los nosepokes en la puerta. Entrada #5 del IO board.
    IR2.start = TTL.timestamps(find(TTL.states == 5));
    IR2.end = TTL.timestamps(find(TTL.states == -5));
        % Borramos el dato si arranca en end o termina en start
        if IR2.start(1) > IR2.end(1);
            IR2.end(1) = [];
        elseif IR2.end(end) < IR2.start(end);
            IR2.start(end) = [];
        end
    for i = 1:length(IR2.start);
        IR2.duration(i,1) = IR2.end(i) - IR2.start(i);
    end
    % Inicio y fin de los nosepokes en el target. Entrada #6 del IO board.
    IR3.start = TTL.timestamps(find(TTL.states == 6));
    IR3.end = TTL.timestamps(find(TTL.states == -6));
        % Borramos el dato si arranca en end o termina en start
        if IR3.start(1) > IR3.end(1);
            IR3.end(1) = [];
        elseif IR3.end(end) < IR3.start(end);
            IR3.start(end) = [];
        end
    for i = 1:length(IR3.start);
        IR3.duration(i,1) = IR3.end(i) - IR3.start(i);
    end
    clear i;

%%    
cd(path_amplifier); 
amplifier.ch15 = LoadBinary('continuous.dat', 31, 35); % continuous.dat tiene 35 canales cuando tiene señal de AUX o acelerómetro.
%amplifier.ch15 = amplifier.ch15 * 0.0000374; % Convertir un canal auxiliar de bits a volts (V).
amplifier.ch15 = amplifier.ch15 * 0.195; % Convertir un canal de registro de bits a microvolts (mV).

%%
out = FilterLFP([1:length(amplifier.ch15');amplifier.ch15]','passband',[3 5]);

%%
plot(out(:,2));

%%

path = 'C:\Users\santi\Documents\Open Ephys\Day0_2022-05-31_14-32-32_Rat1\Record Node 113\experiment1\recording1';
cd(path);
a = fileread('structure.oebin');

%% Seteamos algunos parámetros para luego computar el espectrograma y espectro de potencias.
params.Fs = 30000; % Frecuencia de muestreo: 30000 muestras por segundo.
params.err = 0;
params.tapers = [3 5]; %[3 5]

% % Para analizar de 0 a 15 Hz descomentar las siguientes lineas:
% params.fpass=[0 15]; movingwin=[5 0.5];
%Para analizar de 15 a 100 Hz descomentar las siguientes lineas:
params.fpass=[30 100]; movingwin=[0.5 0.05];

% Computamos el espectrograma. % Quitamos Serr porque no queremos calcular el error.
[S,t,f] = mtspecgramc(amplifier.ch15,movingwin,params);

%% Multiplicamos por la frecuencia para quitar el pink noise.
for i = 1:size(S,2);
    S_nopink(:,i) = S(:,i)*f(i);
end

%% Ploteamos el espectrograma
figure('DefaultAxesFontSize',14); % Seteamos el tamaño de la fuente para la figura
plot_matrix(S_nopink,t,f); 
    title(['Spectrogram']); 
    xlabel(['Time (sec.)']); 
    ylabel(['Frequency (Hz)']);
    colormap(jet); 
    hcb = colorbar; hcb.YLabel.String = 'Power (a.u.)'; hcb.FontSize = 14;
 axis([1 6 15 100]); % Hacemos zoom en una determinada parte de la señal
%%
amplifier.ch15(abs(amplifier.ch15) > 1500) = 0; % Borramos los datos que superan un umbral.

%% Promedio de los espectrogramas para todos los picos de 30Hz centrados.
clear M % Si existe de antemano, borro a M porque sino tira error.
clear S
clear out
% params.fpass=[15 45]; % Frecuencias de interes para la figura.
positions = find(IR2.duration > 30000);
%positions = randi([1 length(amplifier.ch15)],55,1);

 for j = 1:length(positions);
     i = positions(j);
    time_window = 2;
    datos = amplifier.ch15((IR2.start(i))-(time_window*30000):(IR2.start(i))+(time_window*30000));
    [S,t,f] = mtspecgramc(datos,movingwin,params);
    for k = 1:size(S,2);
        S(:,k) = S(:,k)*f(k);
    end
    M(:,:,j) = S;
 end
out = mean(M,3);
%out = zscore(out(:,:));
t = t-mean(t);
subplot(2,1,1);
plot_matrix(out,t,f,'l'); 
    title(['Spectrogram']);
    xlabel(['Time (sec.)']); 
    ylabel(['Frequency (Hz)']); 
    colormap(jet); 
    hcb = colorbar; hcb.YLabel.String = 'Power (a.u.)'; hcb.FontSize = 10;
%clim([21 35]);
hold on
line([0 0],[0 100]);
hold off

% Promedio de los espectrogramas para todos los picos de 30Hz centrados.
clear M % Si existe de antemano, borro a M porque sino tira error.
clear S
clear out
% params.fpass=[15 45]; % Frecuencias de interes para la figura.
%positions = find(IR3.duration > 60000);
positions = randi([1 length(amplifier.ch15)],154,1);

 for j = 1:length(positions);
     i = positions(j);
    time_window = 2;
    datos = amplifier.ch15(i-(time_window*30000):i+(time_window*30000));
    [S,t,f] = mtspecgramc(datos,movingwin,params);
    for k = 1:size(S,2);
        S(:,k) = S(:,k)*f(k);
    end
    M(:,:,j) = S;
 end
out = mean(M,3);
%out = zscore(out(:,:));
t = t-mean(t);
subplot(2,1,2);
plot_matrix(out,t,f,'l'); 
    title(['Spectrogram']); 
    xlabel(['Time (sec.)']); 
    ylabel(['Frequency (Hz)']); 
    colormap(jet); 
    hcb = colorbar; hcb.YLabel.String = 'Power (a.u.)'; hcb.FontSize = 10;
% clim([21 35]);
hold on
line([0 0],[0 100]);
hold off

