%% Script donde dejo ascentado cómo voy a normalizar mis espectrogramas y PSD

clc;
clear all;
path = pwd;
[~,name,~] = fileparts(pwd);
name = name(1:6);

% Importo un espectrograma cualquiera de una sesión
load(strcat(name,'_specgram_BLALowFreq.mat'));

% Los PSD los voy a visualizar en unidades arbitrarias

% Primero multiplico todos los valores del espectrograma por su banda frecuencial. 
%Esto me reduce el pink noise.
S3 = bsxfun(@times, S, f);

% Como la potencia me queda en una escala que va de 0 a 8000 por ejemplo, 
% divido cada valor del espectrograma por la media del espectrograma promedio 
% de toda la sesión y me queda entonces en una escala de 0 a 4 por ejemplo.
S3 = bsxfun(@rdivide, S3, mean(mean(S3,1)));        
 

figure();
S_data = S3;
y = mean(S_data); % your mean vector;
x = f;
stdem = std(S_data,1)/sqrt(size(S_data,1));
curve1 = y + stdem;
curve2 = y - stdem;
x2 = [x, fliplr(x)];
inBetween = [curve1, fliplr(curve2)];
p1 = fill(x2, inBetween, 'm','LineStyle','none');
set(p1,'facealpha',.4)
hold on;
plot(x, y,'m', 'LineWidth', 2);
hold on;
clear S_data;
ylabel(['Power ± SEM (a.u.)']);
xlabel('Frequency (Hz)');
title('Normalized PSD');

% Como la potencia debajo de 1 Hz se reduce drásticamente ya que estoy
% multiplicando por un valor menor a 1, lo que puedo hacer es cortar el
% plot en 1 Hz y en 99 Hz ya que en 100 tengo ruido y arriba de 100 no pasa
% nada.
xlim([1 99]);
hold on

%% Los espectrogramas los voy a visualizar en dB calculando 10*log10(uV2/Hz)
S2 = 10*log10(S);
figure();
plot_matrix(S2,t,f,'n');
        ylabel(['Frequency (Hz)']);
        xlabel('Time(sec.)');
        title('Multi-taper Spectrogram');
        colormap(jet);    
        hcb = colorbar; hcb.YLabel.String = 'Power (dB)'; hcb.FontSize = 12;
        caxis([10 40]);
        ylim([0 100]);

%% Si quiero solapar espectrogramas de varios trials y promediarlos
% Tengo que dividir al espectrograma por un PSD baseline que va a ser el PSD 
% promedio de toda la sesion
clear S4;
% Dividir por un PSD promedio es casi como un zscore pero me quedan todas
% las unidades positivas  mejora la visualización de los rangos ruidosos
% como el de 50 Hz.
S4 = bsxfun(@rdivide, S, mean(S,1)); 

% También puede funcionar haciendo zscore de la señal
% S4 = zscore(S,0,1);

% Lo que sucede con el zscore es que hay franjas de frecuencias que me dan
% valores muy cercanos a cero (color)

Fs = 1250; % Frecuencia de sampleo
load(strcat(name,'_sessioninfo.mat'), 'BLA_mainchannel'); ch = BLA_mainchannel; clear BLA_mainchannel; % Canal a levantar
% load(strcat(name,'_sessioninfo.mat'), 'PL_mainchannel'); ch = PL_mainchannel; clear PL_mainchannel; % Canal a levantar
% load(strcat(name,'_sessioninfo.mat'), 'IL_mainchannel'); ch = IL_mainchannel; clear IL_mainchannel; % Canal a levantar
% load(strcat(name,'_sessioninfo.mat'), 'EO_channels'); ch = EO_channels; clear EO_channels; % Canal a levantar
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

% Busco las posiciones en S donde inician y finalizan los tonos
for i = 1:size(TTL_CS1_inicio,1);
    CS1_inicioenS(i) = find(abs(t-TTL_CS1_inicio(i)) == min(abs(t-TTL_CS1_inicio(i))));
    CS1_finenS(i) = find(abs(t-TTL_CS1_fin(i)) == min(abs(t-TTL_CS1_fin(i))));
    CS2_inicioenS(i) = find(abs(t-TTL_CS2_inicio(i)) == min(abs(t-TTL_CS2_inicio(i))));
    CS2_finenS(i) = find(abs(t-TTL_CS2_fin(i)) == min(abs(t-TTL_CS2_fin(i))));
end

% Metemos todos los pedazos de S durante el CS en una gran matriz y
% calculamos la media

S_CS1 = [];
S_CS2 = [];

window= round(mean(CS1_finenS - CS1_inicioenS));

for i = 1:size(CS1_inicioenS,2);
    S_CS1(:,:,i) = S4(CS1_inicioenS(1,i):CS1_inicioenS(1,i)+window,:);
    S_CS2(:,:,i) = S4(CS2_inicioenS(1,i):CS2_inicioenS(1,i)+window,:);
end

S_CS1_b = S_CS1;
S_CS2_b = S_CS2;

S_CS1 = mean(S_CS1,3);
S_CS2 = mean(S_CS2,3);
t1 = 0:diff(t):diff(t)*(size(S_CS1,1)-1);

figure();
ax1 = subplot(121);
plot_matrix(S_CS1,t1,f,'n');
        ylabel(['Frequency (Hz)']);
        xlabel('Time(sec.)');
        title('CS+ Triggered Spectrogram');
        colormap(jet);    
        hcb = colorbar; hcb.YLabel.String = 'Power (dB)'; hcb.FontSize = 12;
        caxis([0 2.5]);
        ylim([0 100]);
        
ax2 = subplot(122);
plot_matrix(S_CS2,t1,f,'n');
        ylabel(['Frequency (Hz)']);
        xlabel('Time(sec.)');
        title('CS- Triggered Spectrogram');
        colormap(jet);    
        hcb = colorbar; hcb.YLabel.String = 'Power (dB)'; hcb.FontSize = 12;
        caxis([0 2.5]);
        ylim([0 100]);
        
linkaxes([ax1,ax2],'x');

%% Si quiero cuantificar la potencia en una banda frecuencial
% Tengo que promediar el espectrograma en una banda frecuencial 

% Defino los límites superior e inferior de la banda frecuencial
f_min = 2;
f_max = 6;

S_CS1_band = S_CS1_b;
S_CS2_band = S_CS2_b;

f_min_pos = find(abs(f-f_min) == min(abs(f - f_min)));
f_max_pos = find(abs(f-f_max) == min(abs(f - f_max)));

S_CS1_band = mean(S_CS1_band,1); S_CS1_band = squeeze(S_CS1_band); S_CS1_band = S_CS1_band';
S_CS2_band = mean(S_CS2_band,1); S_CS2_band = squeeze(S_CS2_band); S_CS2_band = S_CS2_band';

S_CS1_band = S_CS1_band(:,f_min:f_max); S_CS1_band = mean(S_CS1_band,2);
S_CS2_band = S_CS2_band(:,f_min:f_max); S_CS2_band = mean(S_CS2_band,2);

mean_CS1 = mean(S_CS1_band,1);
mean_CS2 = mean(S_CS2_band,1);
sem_CS1 = std(S_CS1_band,1) / sqrt(size(S_CS1_band,1));
sem_CS2 = std(S_CS2_band,1) / sqrt(size(S_CS2_band,1));

cs1_color = [0 128 0]/255; % Seteo el color para el CS+ apetitivo
cs2_color = [96 96 96]/255; % Seteo el color para el CS-
behaviour_color = [10 10 10]/255; % Seteo el color para comportamiento

bar(1,mean_CS1,0.7,'FaceColor',cs1_color,'FaceAlpha',0.3);
hold on
errorbar(1, mean_CS1, sem_CS1, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
bar(2,mean_CS2,0.7,'FaceColor',cs2_color,'FaceAlpha',0.3);
hold on
errorbar(2, mean_CS2, sem_CS2, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
xlim([0.5 2.5]);
ylabel('Power Ratio','FontSize', 12);

% Words = {'word_one'; 'word_two'; 'word_three'};
set(gca,'xtick',[1:2],'xticklabel',{'CS+'; 'CS-'})
set(gca,'FontSize',8);

hold on
[p] = ranksum(S_CS1_band,S_CS2_band);
p = p*25;
if p >= 0.05;
    p_value_res = 'ns';
elseif p < 0.05 && p >= 0.01;
    p_value_res = '*';
elseif p < 0.01 && p >= 0.001 ;
    p_value_res = '**';
elseif p < 0.001 && p >= 0.0001  ;
    p_value_res = '***';
elseif p < 0.0001 && p >= 0.00001 ;
    p_value_res = '****';
else
    p_value_res = '*****';
end

    ylim([0 2]);
    text(1.5,0.9,p_value_res,'HorizontalAlignment','center','VerticalAlignment','top','FontSize',10);

%% Si quiero detectar en qué bandas frecuenciales están las partes interesantes 
% de mi señal que me interesaría analizar, entonces tengo que ver cual es
% el sd de mi señal

sdm = std(S2,1);
plot(f,sdm, 'Color','m', 'LineWidth', 2);
ylabel(['SD from the mean']);
xlabel('Frequency (Hz)');
title('PSD Standard Deviation from the Mean');
ylim([2 5])

% Si quiero ver los puntos de cambio hago la primera derivada del PSD

% plot(f(1:end-1),diff(mean(S3,1)));

%%
hold on
