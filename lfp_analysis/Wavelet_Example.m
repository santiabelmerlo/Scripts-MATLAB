%% Continue Wavelet Transform Example
% Ploteamos la wavelet de un pedacito de señal junto con la señal cruda y
% filtrada en distintas bandas frecuenciales.
% Usamos las funciones cwt() y eegfilt()

clc
clear all
path = pwd;
[~,name,~] = fileparts(pwd);
name = name(1:6);
Fs = 1250; % Frecuencia de sampleo
load(strcat(name,'_sessioninfo.mat'), 'BLA_mainchannel'); ch = BLA_mainchannel; clear BLA_mainchannel; % Canal a levantar
load(strcat(name,'_sessioninfo.mat'), 'ch_total'); % Número de canales totales
load(strcat(name,'_sessioninfo.mat'), 'paradigm'); % Tipo de paradigma. Appetitive or aversive

% Cargamos los datos del amplificador
amplifier_timestamps = readNPY(strcat(name,'_timestamps.npy')); % Cargamos el estado de cada input del IO Board.
amplifier_timestamps = double(amplifier_timestamps(1):1:amplifier_timestamps(end)); % Hay que hacer esto porque amplifier.timestamps devuelve distinto número de tiempos que de registro.
amplifier_timestamps_lfp = double(amplifier_timestamps(1):24:amplifier_timestamps(end)); % Hay que hacer esto porque amplifier.timestamps devuelve distinto número de tiempos que de registro.
amplifier_t = (amplifier_timestamps_lfp - amplifier_timestamps(1))/30000; % Le restamos el primer timestamp y lo pasamos a segundos.

% Cargamos un canal LFP del amplificador
[amplifier_lfp] = LoadBinary(strcat(name,'_lfp.dat'), ch, ch_total);
amplifier_lfp = amplifier_lfp * 0.195; % Convertir un canal de registro de bits a microvolts (uV).

%% Cargamos los tiempos del CS
load(strcat(name,'_freezing.mat'), 'TTL_CS1_inicio', 'inicio_freezing','fin_freezing')
CS = 1;
time = TTL_CS1_inicio(CS);
pos = find(abs(amplifier_t - time) == min(abs(amplifier_t - time)));
lfp = amplifier_lfp(1,pos-(Fs*30):pos+(Fs*300));
t = amplifier_t(1,pos-(Fs*30):pos+(Fs*300));

% Calculamos la Morse Wavelet
clear t1 y f coi;
% [y,f,coi] = cwt(lfp,Fs,'wavetype','morlet'); % Morlet Wavelet: me muestra mejor los ciclos de actividad de la oscilación
[y,f,coi] = cwt(lfp,Fs); % Morse Wavelet: me muestra cuando tengo potencia de esa frecuencia y cuando dejo de tener

% Ploteamos la Morse Wavelet
ax1 = subplot(9,1,1:3);
    
    % Activar estas líneas para smoothear el espectrograma
    smooth = 4;
    y = imresize(y,[size(y,1)*smooth size(y,2)*smooth]);
    t1 = interp(t,smooth);
    f = interp(f,smooth);
    
    imagesc(t1,log2(f),abs(y));
    cmap = jet(256);
    colormap(cmap);
    logyticks = round(log2(min(f))):round(log2(max(f)));
    ax1.YLim = log2([min(f), max(f)]);
    ax1.YTick = logyticks;
    ax1.YDir = 'normal';
    set(ax1,'YLim',log2([min(f),max(f)]), ...
        'layer','top', ...
        'YTick',logyticks(:), ...
        'YTickLabel',num2str(sprintf('%g\n',2.^logyticks)), ...
        'layer','top')
    title('Continuous Wavelet Transform');
    xlabel('Time (sec.)');
    ylabel('Frequency (Hz)');
    hcol = colorbar;
    hcol.Label.String = 'Magnitude (a.u.)';
    hold(ax1,'on');
    ylim([log2(0.5) log2(150)]);
    clim([0 150]);
    
    % Agregamos algunas lineas de referencia para los rangos de frecuencias
    line([t(1) t(end)],[log2(2) log2(2)],'Color',[1 1 1],'LineWidth',0.5,'LineStyle','--'); 
    line([t(1) t(end)],[log2(5.3) log2(5.3)],'Color',[1 1 1],'LineWidth',0.5,'LineStyle','--');
    line([t(1) t(end)],[log2(9.6) log2(9.6)],'Color',[1 1 1],'LineWidth',0.5,'LineStyle','--');
    line([t(1) t(end)],[log2(13) log2(13)],'Color',[1 1 1],'LineWidth',0.5,'LineStyle','--');
    line([t(1) t(end)],[log2(30) log2(30)],'Color',[1 1 1],'LineWidth',0.5,'LineStyle','--');
    line([t(1) t(end)],[log2(43) log2(43)],'Color',[1 1 1],'LineWidth',0.5,'LineStyle','--');
    line([t(1) t(end)],[log2(60) log2(60)],'Color',[1 1 1],'LineWidth',0.5,'LineStyle','--');
    line([t(1) t(end)],[log2(98) log2(98)],'Color',[1 1 1],'LineWidth',0.5,'LineStyle','--');
    
    % Agregamos lineas de referencia para el onset y offset del tono
    line([time time],[log2(0.5) log2(150)],'Color',[1 1 1],'LineWidth',0.5,'LineStyle','--');
    line([time+60 time+60],[log2(0.5) log2(150)],'Color',[1 1 1],'LineWidth',0.5,'LineStyle','--');
    
    for i = 1:size(inicio_freezing,2);
        line([inicio_freezing(i) fin_freezing(i)],[log2(120) log2(120)],'Color',[1 1 1],'LineWidth',5);
        line([inicio_freezing(i) fin_freezing(i)],[log2(5.3) log2(5.3)],'Color',[1 1 1],'LineWidth',5);
    end
    
    % Obtenemos las posiciones de las figuras
    pos_ax1 = get(ax1, 'Position');
    pos_ax1c = get(hcol, 'Position');
    % Seteamos la posición de la barra de color
    set(hcol, 'Position', [pos_ax1c(1)+0.03 0.77 pos_ax1c(3)-0.02 0.1]);
    % Seteamos la posición de la figura
    set(ax1, 'Position', [pos_ax1(1) 0.7 0.7 0.25]);
    
% Calculamos y ploteamos el trazo crudo
ax2 = subplot(914)
    plot(t,zscore(lfp),'Color',[38 70 83]/255,'LineWidth',0.5);
    xlim([t(1) t(end)]);
    pos_ax2 = get(ax2, 'Position');
    set(ax2, 'Position', [pos_ax2(1) pos_ax2(2) 0.7 pos_ax2(4)]);
    set(ax2, 'XTick', [], 'YTick', []);
    box off; axis off;
    annotation('textbox', [pos_ax2(1)+0.7, pos_ax2(2)-0.05, 0.1, 0.1], 'String', 'Raw', 'EdgeColor', 'none', 'HorizontalAlignment', 'left');
    
ax3 = subplot(915)
    lfp1 = eegfilt(lfp,Fs,60,98);
    plot(t,zscore(lfp1),'Color',[42 157 143]/255,'LineWidth',0.5);
    xlim([t(1) t(end)]);
    pos_ax3 = get(ax3, 'Position');
    set(ax3, 'Position', [pos_ax3(1) pos_ax3(2)+0.03 0.7 pos_ax3(4)]);
    set(ax3, 'XTick', [], 'YTick', []);
    box off; axis off;
    annotation('textbox', [pos_ax3(1)+0.7, pos_ax3(2)-0.02, 0.1, 0.1], 'String', 'Fast Gamma', 'EdgeColor', 'none', 'HorizontalAlignment', 'left');
    
ax4 = subplot(916)
    lfp2 = eegfilt(lfp,Fs,43,60);
    plot(t,zscore(lfp2),'Color',[138 177 125]/255,'LineWidth',0.5);
    xlim([t(1) t(end)]);
    pos_ax4 = get(ax4, 'Position');
    set(ax4, 'Position', [pos_ax4(1) pos_ax4(2)+0.06 0.7 pos_ax4(4)]);
    set(ax4, 'XTick', [], 'YTick', []);
    box off; axis off;
    annotation('textbox', [pos_ax4(1)+0.7, pos_ax4(2)+0.01, 0.1, 0.1], 'String', 'Slow Gamma', 'EdgeColor', 'none', 'HorizontalAlignment', 'left');
    
ax5 = subplot(917)
    lfp3 = eegfilt(lfp,Fs,13,30);
    plot(t,zscore(lfp3),'Color',[233 196 106]/255,'LineWidth',0.5);
    xlim([t(1) t(end)]);
    pos_ax5 = get(ax5, 'Position');
    set(ax5, 'Position', [pos_ax5(1) pos_ax5(2)+0.09 0.7 pos_ax5(4)]);
    set(ax5, 'XTick', [], 'YTick', []);
    box off; axis off;
    annotation('textbox', [pos_ax5(1)+0.7, pos_ax5(2)+0.04, 0.1, 0.1], 'String', 'Beta', 'EdgeColor', 'none', 'HorizontalAlignment', 'left');
    
ax6 = subplot(918)
    lfp4 = eegfilt(lfp,Fs,5.3,9.8);
    plot(t,zscore(lfp4),'Color',[244 162 97]/255,'LineWidth',0.5);
    xlim([t(1) t(end)]);
    pos_ax6 = get(ax6, 'Position');
    set(ax6, 'Position', [pos_ax6(1) pos_ax6(2)+0.12 0.7 pos_ax6(4)]);
    set(ax6, 'XTick', [], 'YTick', []);
    box off; axis off;
    annotation('textbox', [pos_ax6(1)+0.7, pos_ax6(2)+0.07, 0.1, 0.1], 'String', 'Theta', 'EdgeColor', 'none', 'HorizontalAlignment', 'left');
    
ax7 = subplot(919)
    lfp5 = eegfilt(lfp,Fs,2,5.3);
    plot(t,zscore(lfp5),'Color',[231 111 81]/255,'LineWidth',0.5);
    xlim([t(1) t(end)]);
    pos_ax7 = get(ax7, 'Position');
    set(ax7, 'Position', [pos_ax7(1) pos_ax7(2)+0.15 0.7 pos_ax7(4)]);
    set(ax7, 'XTick', [], 'YTick', []);
    box off; axis off;
    annotation('textbox', [pos_ax7(1)+0.7, pos_ax7(2)+0.10, 0.1, 0.1], 'String', '4-Hz', 'EdgeColor', 'none', 'HorizontalAlignment', 'left');

% Set figure properties
set(gcf, 'Color', 'white');
set(gcf, 'Position', [600, 100, 600, 800]);
linkaxes([ax1 ax2 ax3 ax4 ax5 ax6 ax7],'x');
