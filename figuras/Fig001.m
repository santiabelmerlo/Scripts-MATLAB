%% Fig001: Ejemplo de espectrograma de un pedacito de la señal
% Ploteamos un pedacito de la señal en el periodo early o late de la sesión
% Tengo que entrar al folder de la sesión que quiero plotear

clc
clear all

region = 'BLA';
   
path = pwd;
[~,name,~] = fileparts(pwd);
name = name(1:6);

Fs = 1250; % Frecuencia de sampleo
ww = 0.5; % Window del espectrograma
load(strcat(name,'_sessioninfo.mat'));

% Cargamos el espectrograma
load([name '_specgram_' region 'LowFreq.mat']);

% Cargamos los eventos de los CSs y los freezings
load([name '_epileptic.mat'],...
    'TTL_CS1_inicio','TTL_CS1_fin','TTL_CS2_inicio','TTL_CS2_fin','inicio_freezing','fin_freezing');

t_inicio = find(abs(t-TTL_CS1_inicio(1)) == min(abs(t-TTL_CS1_inicio(1)))) - 30/ww;
t_fin = find(abs(t-TTL_CS2_fin(1)) == min(abs(t-TTL_CS2_fin(1)))) + 30/ww;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure;
ax2 = subplot(212);
plot_matrix(S(t_inicio:t_fin,:),t(1,t_inicio:t_fin),f,'l');
clim([15 40]);
ylim([1 12]);
colorbar('off');
hold on;

% line([TTL_CS1_inicio TTL_CS1_fin],[10 10],'Color',colores('CS1'),'LineWidth',5);
% line([TTL_CS2_inicio TTL_CS2_fin],[10 10],'Color',colores('CS2'),'LineWidth',5);
% line([inicio_freezing' fin_freezing'],[9 9],'Color',colores('Movement'),'LineWidth',5);

title('');
ylabel('Frecuencia (Hz)');
xlabel('Tiempo (seg.)');
set(gca, 'FontSize',7);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ax1 = subplot(211);
plot_matrix(S(t_inicio:t_fin,:),t(1,t_inicio:t_fin),f,'l');
clim([0 30]);
ylim([12 100]);
colorbar('off');
hold on;

line([TTL_CS1_inicio TTL_CS1_fin],[98 98],'Color',colores('Aversivo'),'LineWidth',3);
line([TTL_CS2_inicio TTL_CS2_fin],[98 98],'Color',colores('Control'),'LineWidth',3);
line([inicio_freezing' fin_freezing'],[90 90],'Color',colores('Blanco'),'LineWidth',3);

title('');
ylabel('Frecuencia (Hz)');
xlabel('');

% Set figure properties
set(gca, 'XTick', []);  % Eliminar los xticks
set(gca, 'FontSize',7);
set(gcf, 'Color', 'white');
set(gcf, 'Position', [600, 100, 350, 280]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Cargamos un canal LFP del amplificador
ch = eval([region '_mainchannel']);
lfp = LoadBinary(strcat(name,'_lfp.dat'), ch, ch_total);
lfp = lfp * 0.195; % Convertir un canal de registro de bits a microvolts (uV).
t_lfp = (1:size(lfp,2))/Fs_lfp;

t_inicio = find(abs(t_lfp-TTL_CS1_inicio(1)) == min(abs(t_lfp-TTL_CS1_inicio(1)))) - 30*Fs_lfp;
t_fin = find(abs(t_lfp-TTL_CS2_fin(1)) == min(abs(t_lfp-TTL_CS2_fin(1)))) + 30*Fs_lfp;

figure;
plot(t_lfp(1,t_inicio:t_fin),lfp(1,t_inicio:t_fin),'LineWidth',0.1,'Color',colores('BLA'));
xlim([t_lfp(1,t_inicio),t_lfp(1,t_fin)]);
axis off; % Remove axes

% Add scale bar
hold on;
scale_bar_length_time = 10; % 1 second
scale_bar_length_uV = 500; % 100 microvolts

% Calcular posiciones para la barra de escala
x_end = t_lfp(1, t_fin) - 0.1; % Offset desde el final del eje x
y_start = min(lfp(1, t_inicio:t_fin)) + 0.1 * range(lfp(1, t_inicio:t_fin)); % Offset desde la parte inferior

% Dibujar barra de escala horizontal (tiempo)
plot([x_end - scale_bar_length_time, x_end], [y_start, y_start], 'k', 'LineWidth', 1);
text(x_end - scale_bar_length_time / 2, y_start - 0.05 * range(lfp(1, t_inicio:t_fin)), ...
    sprintf('%d s', scale_bar_length_time), 'HorizontalAlignment', 'center', 'FontSize', 7);

% Dibujar barra de escala vertical (microvolts)
plot([x_end, x_end], [y_start, y_start + scale_bar_length_uV], 'k', 'LineWidth', 1);
text(x_end + 0.01 * range(t_lfp(1, t_inicio:t_fin)), y_start + scale_bar_length_uV / 2, ...
    sprintf('%d µV', scale_bar_length_uV), 'HorizontalAlignment', 'left', 'FontSize', 7);

% Configurar propiedades de la figura
set(gcf, 'Color', 'white');
set(gcf, 'Position', [600, 100, 415, 120]);