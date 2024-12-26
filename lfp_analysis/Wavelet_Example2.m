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

load(strcat(name,'_sessioninfo.mat'));

% Cargamos los datos del amplificador
amplifier_timestamps = readNPY(strcat(name,'_timestamps.npy')); % Cargamos el estado de cada input del IO Board.
amplifier_timestamps = double(amplifier_timestamps(1):1:amplifier_timestamps(end)); % Hay que hacer esto porque amplifier.timestamps devuelve distinto número de tiempos que de registro.
amplifier_timestamps_lfp = double(amplifier_timestamps(1):24:amplifier_timestamps(end)); % Hay que hacer esto porque amplifier.timestamps devuelve distinto número de tiempos que de registro.
amplifier_t = (amplifier_timestamps_lfp - amplifier_timestamps(1))/30000; % Le restamos el primer timestamp y lo pasamos a segundos.

% Cargamos los timestamps de los TTL y nos quedamos con los que quiero incluir
load(strcat(name,'_freezing.mat'),'TTL_CS1_inicio','TTL_CS1_fin','TTL_CS2_inicio','TTL_CS2_fin');

% Cargamos los eventos de freezing
load(strcat(name,'_epileptic.mat'),'inicio_freezing','fin_freezing','inicio_epileptic','fin_epileptic','inicio_sleep','fin_sleep');

% The file exists, do something
ch_BLA = BLA_mainchannel;
ch_PL = PL_mainchannel;
ch_IL = IL_mainchannel;

% BLA
if ~isempty(ch_BLA)
    % Cargamos la señal de BLA
    lfp_BLA = LoadBinary(strcat(name,'_lfp.dat'), ch_BLA, ch_total); % Cargamos la señal
    lfp_BLA = lfp_BLA * 0.195; % Convertir un canal de registro de bits a microvolts (uV)
    lfp_BLA = zpfilt(lfp_BLA,1250,0.1,300); % Filtramos la señal entre 0.1 y 300
    lfp_BLA = zscorem(lfp_BLA); % Lo normalizamos con zscore
    filt_BLA(1,:) = zpfilt(lfp_BLA,1250,2,5.3); % Filtramos la señal en 4-Hz
    filt_BLA(2,:) = zpfilt(lfp_BLA,1250,5.3,9.6); % Filtramos la señal en theta
    filt_BLA(3,:) = zpfilt(lfp_BLA,1250,13,30); % Filtramos la señal en beta
    filt_BLA(4,:) = zpfilt(lfp_BLA,1250,43,60); % Filtramos la señal en sgamma
    filt_BLA(5,:) = zpfilt(lfp_BLA,1250,60,98); % Filtramos la señal en fgamma
end

% PL
if ~isempty(ch_PL)
    % Cargamos la señal del PL
    lfp_PL = LoadBinary(strcat(name,'_lfp.dat'), ch_PL, ch_total);
    lfp_PL = lfp_PL * 0.195; % Convertir un canal de registro de bits a microvolts (uV).
    lfp_PL = zpfilt(lfp_PL,1250,0.1,300); % Filtramos la señal entre 0.1 y 300
    lfp_PL = zscorem(lfp_PL); % Lo Normalizamos con Zscore
    filt_PL(1,:) = zpfilt(lfp_PL,1250,2,5.3); % Filtramos la señal en 4-Hz
    filt_PL(2,:) = zpfilt(lfp_PL,1250,5.3,9.6); % Filtramos la señal en theta
    filt_PL(3,:) = zpfilt(lfp_PL,1250,13,30); % Filtramos la señal en beta
    filt_PL(4,:) = zpfilt(lfp_PL,1250,43,60); % Filtramos la señal en sgamma
    filt_PL(5,:) = zpfilt(lfp_PL,1250,60,98); % Filtramos la señal en fgamma
end

% IL
if ~isempty(ch_IL)
    % Cargamos la señal del PL
    lfp_IL = LoadBinary(strcat(name,'_lfp.dat'), ch_IL, ch_total);
    lfp_IL = lfp_IL * 0.195; % Convertir un canal de registro de bits a microvolts (uV).
    lfp_IL = zpfilt(lfp_IL,1250,0.1,300); % Filtramos la señal entre 0.1 y 300
    lfp_IL = zscorem(lfp_IL); % Lo Normalizamos con Zscore
    filt_IL(1,:) = zpfilt(lfp_IL,1250,2,5.3); % Filtramos la señal en 4-Hz
    filt_IL(2,:) = zpfilt(lfp_IL,1250,5.3,9.6); % Filtramos la señal en theta
    filt_IL(3,:) = zpfilt(lfp_IL,1250,13,30); % Filtramos la señal en beta
    filt_IL(4,:) = zpfilt(lfp_IL,1250,43,60); % Filtramos la señal en sgamma
    filt_IL(5,:) = zpfilt(lfp_IL,1250,60,98); % Filtramos la señal en fgamma
end

% ACC
if ~isempty(ACC_channels)
    % Cargamos la señal del PL
    ACC = LoadBinary(strcat(name,'_lfp.dat'), ACC_channels(1), ch_total);
    ACC = ACC * 0.195; % Convertir un canal de registro de bits a microvolts (uV).
    ACC = zpfilt(ACC,1250,0.1,30); % Filtramos la señal entre 0.1 y 300
    ACC = zscorem(ACC); % Lo Normalizamos con Zscore
end

load(strcat(name,'_behavior_timeseries.mat'),'behavior_timeseries','time_vector');

%% Cargamos los tiempos del CS
BLA_color = [66,133,244]/255; % BLA color
PL_color = [234,67,53]/255; % PL color
IL_color = [251,188,5]/255; % IL color
Bi_color = [0.9 0.9 0.9];
    
CS = 1;
time = TTL_CS1_inicio(CS);
time2 = TTL_CS1_fin(CS);
% time2 = TTL_CS2_inicio(CS);
pos = find(abs(amplifier_t - time) == min(abs(amplifier_t - time)));
lfp = lfp_BLA(1,pos-(Fs*10):pos+(Fs*280));
t = amplifier_t(1,pos-(Fs*10):pos+(Fs*280));
t1 = t;

%% Calculamos la Morse Wavelet
clear y f coi;
% [y2,f2,coi] = cwt(lfp,Fs,'wavetype','morlet','s0',10,'no',6); % Morlet Wavelet: me muestra mejor los ciclos de actividad de la oscilación
[y,f,coi] = cwt(lfp,Fs,'s0',6,'no',6); % Morse Wavelet: me muestra cuando tengo potencia de esa frecuencia y cuando dejo de tener
%
% Ploteamos la Morse Wavelet
figure(3); clf
ax1 = subplot(2,1,1:2);
    
%     % Activar estas líneas para smoothear el espectrograma
%     smooth = 4;
%     y = imresize(y,[size(y,1)*smooth size(y,2)*smooth]);
%     t1 = interp(t,smooth);
%     f = interp(f,smooth);
    
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
    title('');
    xlabel('Time (sec.)');
    ylabel('Frequency (Hz)');
    cb1 = colorbar;
    cb1.Label.String = 'Magnitude (a.u.)';
    hold(ax1,'on');
%     ylim([log2(2) log2(16)]);
    clim([0 1.5]);
    colorbar('off');
    
    % Agregamos lineas de referencia para el onset y offset del tono
    line([time time+60],[log2(14) log2(14)],'Color',[0.4627 0.0235 0.6039],'LineWidth',5);
    line([time2 time2+60],[log2(14) log2(14)],'Color',[0.3765 0.3765 0.3765],'LineWidth',5);
    for i = 1:size(inicio_freezing,2);
        line([inicio_freezing(i) fin_freezing(i)],[log2(12) log2(12)],'Color',[1 1 1],'LineWidth',5);
    end
    hold off
    
%%
ax2 = subplot(2,1,2);
    
%     % Activar estas líneas para smoothear el espectrograma
%     smooth = 4;
%     y = imresize(y,[size(y,1)*smooth size(y,2)*smooth]);
%     t1 = interp(t,smooth);
%     f = interp(f,smooth);
    
    imagesc(t1,log2(f2),abs(y2));
    cmap = jet(256);
    colormap(cmap);
    logyticks = round(log2(min(f2))):round(log2(max(f2)));
    ax1.YLim = log2([min(f2), max(f2)]);
    ax1.YTick = logyticks;
    ax1.YDir = 'normal';
    set(ax1,'YLim',log2([min(f2),max(f2)]), ...
        'layer','top', ...
        'YTick',logyticks(:), ...
        'YTickLabel',num2str(sprintf('%g\n',2.^logyticks)), ...
        'layer','top')
    title('');
    xlabel('Time (sec.)');
    ylabel('Frequency (Hz)');
    cb1 = colorbar;
    cb1.Label.String = 'Magnitude (a.u.)';
    hold(ax1,'on');
%     ylim([log2(2) log2(16)]);
    clim([0 1.5]);
       colorbar('off');
 
    % Agregamos lineas de referencia para el onset y offset del tono
    line([time time+60],[log2(14) log2(14)],'Color',[0.4627 0.0235 0.6039],'LineWidth',5);
    line([time2 time2+60],[log2(14) log2(14)],'Color',[0.3765 0.3765 0.3765],'LineWidth',5);
    for i = 1:size(inicio_freezing,2);
        line([inicio_freezing(i) fin_freezing(i)],[log2(12) log2(12)],'Color',[1 1 1],'LineWidth',5);
    end
    hold off
    
  
      linkaxes([ax1 ax2],'x');  
%% Calculamos y ploteamos el trazo crudo
ax2 = subplot(916)
    plot(amplifier_t,lfp_BLA(1,:),'Color',BLA_color,'LineWidth',0.5);
    xlim([t(1) t(end)]);
    pos_ax2 = get(ax2, 'Position');
    set(ax2, 'Position', [pos_ax2(1) pos_ax2(2)-0.026 0.6446 pos_ax2(4)+0.1]);
    set(ax2, 'XTick', [], 'YTick', []);
    box off; axis off;
%     annotation('textbox', [0.8, pos_ax2(2)-0.12, 0.1, 0.1], 'String', 'BLA', 'EdgeColor', 'none', 'HorizontalAlignment', 'left');

ax3 = subplot(917)
    plot(amplifier_t,lfp_PL(1,:),'Color',PL_color,'LineWidth',0.5);
    xlim([t(1) t(end)]);
    pos_ax3 = get(ax3, 'Position');
    set(ax3, 'Position', [pos_ax3(1) pos_ax3(2)-0.026 0.6446 pos_ax3(4)+0.1]);
    set(ax3, 'XTick', [], 'YTick', []);
    box off; axis off;
%     annotation('textbox', [0.8, pos_ax3(2)-0.12, 0.1, 0.1], 'String', 'PL', 'EdgeColor', 'none', 'HorizontalAlignment', 'left');

ax4 = subplot(918)
    plot(amplifier_t,lfp_IL(1,:),'Color',IL_color,'LineWidth',0.5);
    xlim([t(1) t(end)]);
    pos_ax4 = get(ax4, 'Position');
    set(ax4, 'Position', [pos_ax4(1) pos_ax4(2)-0.026 0.6446 pos_ax4(4)+0.1]);
    set(ax4, 'XTick', [], 'YTick', []);
    box off; axis off;
%     annotation('textbox', [pos_ax4(1)+0.5, pos_ax4(2), 0.1, 0.1], 'String', 'IL LFP', 'EdgeColor', 'none', 'HorizontalAlignment', 'left');
    
ax5 = subplot(919)
    plot(amplifier_t, ACC,'Color',[0 0 0],'LineWidth',0.5);
    pos_ax5 = get(ax5, 'Position');
    set(ax5, 'Position', [pos_ax5(1) pos_ax5(2)-0.026 0.6446 pos_ax5(4)+0.1]);
    box off; axis off;

% Set figure properties
set(gcf, 'Color', 'white');
set(gcf, 'Position', [600, 100, 600, 550]);
linkaxes([ax1 ax2 ax3 ax4 ax5],'x');

% xlim([146 166]);