%% Ejemplo de espectrograma de un pedacito de la señal
% Ploteamos un pedacito de la señal en el periodo early o late de la sesión

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

line([TTL_CS1_inicio TTL_CS1_fin],[95 95],'Color',colores('CS1'),'LineWidth',3);
line([TTL_CS2_inicio TTL_CS2_fin],[95 95],'Color',colores('CS2'),'LineWidth',3);
line([inicio_freezing' fin_freezing'],[90 90],'Color',colores('Movement'),'LineWidth',3);

title('');
ylabel('Frecuencia (Hz)');
xlabel('');

% Set figure properties
set(gca, 'XTick', []);  % Eliminar los xticks
set(gca, 'FontSize',7);
set(gcf, 'Color', 'white');
set(gcf, 'Position', [600, 100, 260, 280]);