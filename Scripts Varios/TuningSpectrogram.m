%% Cargamos la señal
clear all
clc
path = pwd;
[~,D,X] = fileparts(path); name = strcat(D,X);

% Cargamos un canal LFP del amplificador
[data_lfp] = LoadBinary(strcat(name,'_lfp.dat'), 25, 70);
data_lfp = data_lfp * 0.195; % Convertir un canal de registro de bits a microvolts (uV).
data_lfp_timestamps = (1/1250:1/1250:size(data_lfp,2)/1250);

%% Documentación
% Para más info ver manual de Chronux y paper Prerau et al., 2016

% params.Fs - Es la frecuencia de sampleo. En el .dat downsampleado sería 1250 pero en el .dat original 
% es 30000. Usamos params.Fs = 1250

% params.err - Calculo del error teórico. [0 p] or 0 - no error bars); [1 p] Theoretical error bars; 
% [2 p] - Jackknife error bars; El valor p lo seteamos en 0,05. Usamos params.err = [2 0.05]                                                                 
                                   
% params.tapers - Parámetro en la forma [TW K] donde TW es el producto
% time-bandwidth y el K es el número de tapers.
% TW = N*?f/2 - donde N es la duración de la ventana y es el tiempo máximo
% en segundos donde uno asume que la señal es estacionaria. ?f es la
% resolución en frecuencias que quiero tener. Por ejemplo: 1 Hz.
% K = 2*TW - 1

% params.pad - Es el factor de relleno o padding. Cuanto mayor es este
% valor más resolución obtengo en frecuencias. Puede tomar valores
% -1,0,1,2,etc. -1 corresponde a no padding. El relleno es sobre la serie
% temporal. Usamos params.pad = 2

% params.fpass - Es el rango de frecuencias que queremos analizar en el
% espectrograma en la forma [fmin fmax]. Por ejemplo params.fpass = [1 20]

% movingwin - en la forma [window winstep] donde window es el tamaño de la
% ventana y tiene que ser consistente con el parámetro N de más arriba, y
% donde winstep es cuanto corro la ventana en el próximo step. Ambos
% parámetros en segundos. Winstep no modifica las asunciones de la
% estacionaridad de la señal, solo genera una interpolación temporal para
% resolver mejor en el eje tiempo. La ventana tiene que ser de 4 a 8 veces
% el tamaño de la frecuencia que quiero ver.

%% Parámetros óptimos para analizar frecuencias de 0 a 30 Hz.
% Igualmente calculo hasta 150 para tener el espectro completo
% Parámetros óptimos para calcular espectrograma en el momento
params.Fs = 1250; 
params.err = [2 0.05]; 
params.tapers = [1 1]; 
params.pad = 3; 
params.fpass = [0 150];
movingwin = [1 0.05];

% Parámetros para guardar el espectrograma y no generar un archivo muy
% pesado
params.Fs = 1250; 
params.err = [2 0.05]; 
params.tapers = [1 1]; 
params.pad = 1; 
params.fpass = [0 30];
movingwin = [1 0.1]; 

%% Parámetros óptimos para analizar frecuencias de 30 a 150 Hz.
% Parámetros óptimos para calcular espectrograma en el momento
params.Fs = 1250; 
params.err = [2 0.05]; 
params.tapers = [1 1]; 
params.pad = 3; 
params.fpass = [30 150];
movingwin = [0.1 0.01]; 

% Parámetros para guardar el espectrograma y no generar un archivo muy
% pesado
params.Fs = 1250; 
params.err = [2 0.05]; 
params.tapers = [1 1]; 
params.pad = 2; 
params.fpass = [30 150];
movingwin = [0.1 0.01]; 

%% Calculo el espectrograma y ploteo
[S,t,f,Serr] = mtspecgramc(data_lfp, movingwin, params);

%% Plot not zscored, logaritmic.
ax1 = subplot(3,1,1);
plot_matrix(S,t,f,'l');
        ylabel(['Frequency (Hz)']);
        xlabel('Time (sec.)');
        title('Spectrogram (10*log10(dB))');
        colormap(jet);    
        hcb = colorbar; hcb.YLabel.String = 'Power (dB)'; hcb.FontSize = 8;
        caxis([0 50]);
        ylim(params.fpass);
        xlim([600 605]);
        ax1.YLimMode = 'manual'; % Set y-axis limits manually
        ax1.YLim = [params.fpass]; % Replace y_min and y_max with your desired limits
        
% Plot zscore
ax2 = subplot(3,1,2);
plot_matrix(zscore(S,0,1),t,f,'n');
        ylabel(['Frequency (Hz)']);
        xlabel('Time (sec.)');
        title('Spectrogram (z-scored)');
        colormap(jet);    
        hcb = colorbar; hcb.YLabel.String = 'Power (z-score)'; hcb.FontSize = 8;
        caxis([-2 2]);
        ylim(params.fpass);
        xlim([600 605]);
        ax2.YLimMode = 'manual'; % Set y-axis limits manually
        ax2.YLim = [params.fpass]; % Replace y_min and y_max with your desired limits
        
% Plot zscored signal
data_lfp_timestamps = (1/params.Fs:1/params.Fs:size(data_lfp,2)/params.Fs);
ax3 = subplot(3,1,3);
plot(data_lfp_timestamps,zscore(data_lfp));
        ylabel(['Amplitude (z-score)']);
        xlabel('Time (sec.)');
        title('LFP Signal');
        hcb = colorbar; hcb.YLabel.String = '';
        ylim([-5 5]);
        xlim([600 605]);
        ax3.YLimMode = 'manual'; % Set y-axis limits manually
        ax3.YLim = [-5 5]; % Replace y_min and y_max with your desired limits        

linkaxes([ax1 ax2 ax3],'x'); 

%% Guardamos el OUTPUT del mtspectrumc en un archivo .m dentro del Current Folder
% Guardamos solo las variables f,S,Serr,t
filename = strcat(name,'_specgram.mat');
save(filename, 'f', 'S', 'Serr', 't');
