%% Ploteamos Espectrograma en escala logaritmica.
clc
clear all

region = 'BLA';

path = pwd;
[~, name, ~] = fileparts(pwd);
name = name(1:6);

Fs = 1250; % Frecuencia de sampleo
ww = 0.5; % Window del espectrograma
load(strcat(name, '_sessioninfo.mat'));

% Cargamos el espectrograma
load([name '_specgram_' region 'LowFreq.mat']);
S = zscorem(S,1);
% S = 10*log10(S);
% S = bsxfun(@times, S, f); % Multiplica cada fila de S por el correspondiente valor de f
% S = bsxfun(@rdivide, S, median(median(S, 1))); % Dividir cada valor de S por la mediana de las medianas

% Cargamos los eventos de los CSs y los freezings
load([name '_epileptic.mat'], ...
    'TTL_CS1_inicio', 'TTL_CS1_fin', 'TTL_CS2_inicio', 'TTL_CS2_fin', 'inicio_freezing', 'fin_freezing');

cs = 15;

t_inicio = find(abs(t - TTL_CS1_inicio(cs)) == min(abs(t - TTL_CS1_inicio(cs)))) - 30 / ww;
t_fin = find(abs(t - TTL_CS2_fin(cs)) == min(abs(t - TTL_CS2_fin(cs)))) + 30 / ww;

% Definir frecuencias de interés para la escala no lineal
% Parámetros
start = 1; % Valor inicial (cercano a 0)
stop = 100;    % Valor final
num_values = 1967; % Número total de valores

% Generar el vector en escala logarítmica
f_log = logspace(log10(start), log10(stop), num_values);

f_linear = linspace(min(f), max(f), length(f)); % Eje de frecuencia original lineal

% Interpolar la matriz S a la escala no lineal
S_log = interp1(f, S(t_inicio:t_fin, :)', f_log, 'linear')'; % Interpolar a la nueva escala

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure;
plot_matrix_smooth(S_log, t(1, t_inicio:t_fin), f_log, 'n',10); % Graficar el espectrograma
clim([-10 10]); % Ajustar límites de color
ylim([min(f_log) max(f_log)]); % Ajustar límites del eje y
colorbar('off');
hold on;

% Configurar etiquetas del eje y con valores específicos
y_labels = [1, 2, 4, 8, 16, 32, 64, 100]; % Frecuencias específicas para el eje Y
set(gca, 'YScale', 'log', 'YTick', y_labels, 'YTickLabel', num2str(y_labels'));
set(gca, 'YMinorTick', 'off'); % Elimina ticks menores automáticos

% Ajustes de formato
title('');
ylabel('Frecuencia (Hz)');
xlabel('Tiempo (seg.)');
set(gca, 'FontSize', 7);