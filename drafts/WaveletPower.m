%% Loop para calcular la wavelet, cuantificar en 4Hz y Theta y guardar el vector en cada carpeta
% Usamos las funciones cwt()

clc
clear all
path = pwd;
[~,name,~] = fileparts(pwd);
name = name(1:6);
Fs = 1250; % Frecuencia de sampleo

load(strcat(name,'_sessioninfo.mat'));

% Iniciamos algunas variables vacías
wave_BLA_4Hz = [];
wave_BLA_Theta = [];
wave_PL_4Hz = [];
wave_PL_Theta = [];
wave_IL_4Hz = [];
wave_IL_Theta = [];
f = [];
t = [];

% BLA
if ~isempty(BLA_mainchannel)
    disp('    Loading BLA Channel...')
    % Cargamos la señal de BLA
    lfp_BLA = LoadBinary(strcat(name,'_lfp.dat'), BLA_mainchannel, ch_total); % Cargamos la señal
    lfp_BLA = lfp_BLA * 0.195; % Convertir un canal de registro de bits a microvolts (uV)
    lfp_BLA = zpfilt(lfp_BLA,1250,0.1,300); % Filtramos la señal entre 0.1 y 300
    lfp_BLA = zscorem(lfp_BLA); % Lo normalizamos con zscore
    t = 1/Fs:1/Fs:size(lfp_BLA,2)/Fs;
    % Calculamos el wavelet
    disp('      Computing Wavelet from BLA Channel...')
    clear y f coi;
    [y,f,coi] = cwt(lfp_BLA,Fs,'s0',24,'no',3,'nv',10); % Wavelet de 2 a 16 Hz
    wave  = abs(y);
    % Frecuencias de interés
    FourHz_idx = f >= 2 & f <= 5.3;
    Theta_idx = f >= 5.3 & f <= 9.6;
    wave_BLA_4Hz = nanmedian(wave(FourHz_idx,:),1);
    wave_BLA_Theta = nanmedian(wave(Theta_idx,:),1);
    % Borramos lo que no nos interesa
%     clear lfp_BLA y coi wave;
end

t_w = t;
f_w = f;

load(strcat(name,'_specgram_BLALowFreq.mat'));
load(strcat(name,'_epileptic.mat'));

% Para plotear
ax1 = subplot(3,1,1); 
    imagesc(t_w,log2(f_w),zscorem(wave,2));
    cmap = jet(256);
    colormap(cmap);
    logyticks = round(log2(min(f_w))):round(log2(max(f_w)));
    ax1.YLim = log2([min(f_w), max(f_w)]);
    ax1.YTick = logyticks;
    ax1.YDir = 'normal';
    set(ax1,'YLim',log2([min(f_w),max(f_w)]), ...
        'layer','top', ...
        'YTick',logyticks(:), ...
        'YTickLabel',num2str(sprintf('%g\n',2.^logyticks)), ...
        'layer','top')
    title('');
    xlabel('Time (sec.)');
    ylabel('Frequency (Hz)');
    colorbar('off');
    hold(ax1,'on');
    ylim([log2(2) log2(16)]);
    clim([-5 5]);
    
ax2 = subplot(312);
    plot_matrix(zscorem(S,1),t,f,'n');
    colorbar('off');
     clim([-5 5]);
    
ax3 = subplot(313)
    plot(t_w,zscorem(lfp_BLA));
    ylim([-10 10]);
    hold on;
    line([inicio_freezing' fin_freezing'],[8 8],'LineWidth',2,'Color',[0 0 0])
    
linkaxes([ax1, ax2, ax3], 'x');
%%
% PL
if ~isempty(PL_mainchannel)
    disp('    Loading PL Channel...')
    % Cargamos la señal de PL
    lfp_PL = LoadBinary(strcat(name,'_lfp.dat'), PL_mainchannel, ch_total); % Cargamos la señal
    lfp_PL  = lfp_PL  * 0.195; % Convertir un canal de registro de bits a microvolts (uV)
    lfp_PL  = zpfilt(lfp_PL ,1250,0.1,300); % Filtramos la señal entre 0.1 y 300
    lfp_PL  = zscorem(lfp_PL); % Lo normalizamos con zscore
    t = 1/Fs:1/Fs:size(lfp_PL ,2)/Fs;
    % Calculamos el wavelet
    disp('      Computing Wavelet from PL Channel...')
    clear y f coi;
    [y,f,coi] = cwt(lfp_PL ,Fs,'s0',24,'no',3,'nv',10); % Wavelet de 2 a 16 Hz
    wave  = abs(y);
    % Frecuencias de interés
    FourHz_idx = f >= 2 & f <= 5.3;
    Theta_idx = f >= 5.3 & f <= 9.6;
    wave_PL_4Hz = nanmedian(wave(FourHz_idx,:),1);
    wave_PL_Theta = nanmedian(wave(Theta_idx,:),1);
    % Borramos lo que no nos interesa
    clear lfp_PL y coi wave;
end
    
% IL
if ~isempty(IL_mainchannel)
    disp('    Loading IL Channel...')
    % Cargamos la señal de IL
    lfp_IL = LoadBinary(strcat(name,'_lfp.dat'), IL_mainchannel, ch_total); % Cargamos la señal
    lfp_IL  = lfp_IL  * 0.195; % Convertir un canal de registro de bits a microvolts (uV)
    lfp_IL  = zpfilt(lfp_IL ,1250,0.1,300); % Filtramos la señal entre 0.1 y 300
    lfp_IL  = zscorem(lfp_IL); % Lo normalizamos con zscore
    t = 1/Fs:1/Fs:size(lfp_IL ,2)/Fs;
    % Calculamos el wavelet
    disp('      Computing Wavelet from IL Channel...')
    clear y f coi;
    [y,f,coi] = cwt(lfp_IL ,Fs,'s0',24,'no',3,'nv',10); % Wavelet de 2 a 16 Hz
    wave  = abs(y);
    % Frecuencias de interés
    FourHz_idx = f >= 2 & f <= 5.3;
    Theta_idx = f >= 5.3 & f <= 9.6;
    wave_IL_4Hz = nanmedian(wave(FourHz_idx,:),1);
    wave_IL_Theta = nanmedian(wave(Theta_idx,:),1);
    % Borramos lo que no nos interesa
    clear lfp_IL y coi wave;
end


% save(strcat(name,'_wavelet.mat'),...
%     'wave_BLA_4Hz','wave_BLA_Theta','wave_PL_4Hz','wave_PL_Theta',...
%     'wave_IL_4Hz','wave_IL_Theta','f','t');

%%
tic

lfp = lfp_BLA(1,1:end);
t = amplifier_t;
t1 = t;
%%
clearvars -except lfp t Fs
tic
% Calculamos la Wavelet
clear y f coi;
[y,f,coi] = cwt(lfp,Fs,'s0',24,'no',3,'nv',10); % Wavelet de 2 a 16 Hz
wave  = abs(y);
toc
clear coi

%%
% Frecuencias de interés
FourHz_idx = f >= 2 & f <= 5.3;
Theta_idx = f >= 5.3 & f <= 9.6;
wave_4Hz = nanmedian(wave(FourHz_idx,:),1);
wave_Theta = nanmedian(wave(Theta_idx,:),1);

