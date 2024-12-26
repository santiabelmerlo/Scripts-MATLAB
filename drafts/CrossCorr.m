%% Working with my data
clc
clear all
path = pwd;
[~,name,~] = fileparts(pwd);
name = name(1:6);

% Seteamos qué canal queremos levantar de la señal
Fs = 1250; % Frecuencia de sampleo

load(strcat(name,'_sessioninfo.mat'), 'BLA_mainchannel'); ch_BLA = BLA_mainchannel; clear BLA_mainchannel; % Canal a levantar
load(strcat(name,'_sessioninfo.mat'), 'PL_mainchannel'); ch_PL = PL_mainchannel; clear PL_mainchannel; % Canal a levantar
load(strcat(name,'_sessioninfo.mat'), 'IL_mainchannel'); ch_IL = IL_mainchannel; clear IL_mainchannel; % Canal a levantar

load(strcat(name,'_sessioninfo.mat'), 'ch_total'); % Número de canales totales
load(strcat(name,'_sessioninfo.mat'), 'paradigm'); % Tipo de paradigma. Appetitive or aversive

% Cargo los tiempos de los tonos
load(strcat(name,'_freezing.mat'),'TTL_CS1_inicio','TTL_CS1_fin','TTL_CS2_inicio','TTL_CS2_fin');

% Cargamos los datos del amplificador
amplifier_timestamps = readNPY(strcat(name,'_timestamps.npy')); % Cargamos el estado de cada input del IO Board.
amplifier_timestamps = double(amplifier_timestamps(1):1:amplifier_timestamps(end)); % Hay que hacer esto porque amplifier.timestamps devuelve distinto número de tiempos que de registro.
amplifier_timestamps_lfp = double(amplifier_timestamps(1):24:amplifier_timestamps(end)); % Hay que hacer esto porque amplifier.timestamps devuelve distinto número de tiempos que de registro.
t = (amplifier_timestamps_lfp - amplifier_timestamps(1))/30000; % Le restamos el primer timestamp y lo pasamos a segundos.

% Cargamos un canal LFP del amplificador
disp(['Loading BLA LFP signal...']);
[lfp_BLA] = LoadBinary(strcat(name,'_lfp.dat'), ch_BLA, ch_total);
lfp_BLA = lfp_BLA * 0.195; % Convertir un canal de registro de bits a microvolts (uV).
clear amplifier_timestamps amplifier_timestamps_lfp;

% Cargamos un canal LFP del amplificador
disp(['Loading PL LFP signal...']);
[lfp_PL] = LoadBinary(strcat(name,'_lfp.dat'), ch_PL, ch_total);
lfp_PL = lfp_PL * 0.195; % Convertir un canal de registro de bits a microvolts (uV).
clear amplifier_timestamps amplifier_timestamps_lfp;

% Cargamos un canal LFP del amplificador
disp(['Loading IL LFP signal...']);
[lfp_IL] = LoadBinary(strcat(name,'_lfp.dat'), ch_IL, ch_total);
lfp_IL = lfp_IL * 0.195; % Convertir un canal de registro de bits a microvolts (uV).
clear amplifier_timestamps amplifier_timestamps_lfp;

% Cargamos los eventos de freezing
load(strcat(name,'_epileptic.mat'));

%%
[acor,lag] = xcorr(lfp_BLA,lfp_PL);
[~,I] = max(abs(acor));
timeDiff = lag(I);
subplot(311); plot(lfp_BLA); title('BLA');
subplot(312); plot(lfp_PL); title('PL');
subplot(313); plot(lag,acor);
title('Cross-correlation between BLA and PL')

%%
params.Fs = 1250; 
params.err = [2 0.05]; 
params.tapers = [3 5]; 
params.pad = 2; 
params.fpass = [0 120];
movingwin = [3 0.5];
disp(['Analizing coherence between signals...']);
[C,phi,S12,S1,S2,t_C,f_C] = cohgramc(lfp_BLA',lfp_IL',movingwin,params);

disp(['Done']);

ax1 = subplot(3,1,1); plot_matrix(S1,t_C,f_C,'l'); clim([-20 40]); title('BLA Spectrogram');

hold on

disp(['Plotting events...']);
for i = 1:length(TTL_CS1_inicio);
    line([TTL_CS1_inicio(i) TTL_CS1_fin(i)],[110 110],'Color',[1 0 0],'LineWidth',4);
end
for i = 1:length(TTL_CS2_inicio);
    line([TTL_CS2_inicio(i) TTL_CS2_fin(i)],[110 110],'Color',[0 1 0],'LineWidth',4);
end

% for i = 1:size(IR2_start,1);
%     line([IR2_inicio(i,1) IR2_fin(i,:)],[105 105],'Color',[0 0 1],'LineWidth',2);
% end
% for i = 1:size(IR3_start,1);
%     line([IR3_inicio(i,1) IR3_fin(i,:)],[100 100],'Color',[0 0 1],'LineWidth',2);
% end

ax2 = subplot(3,1,2); plot_matrix(S2,t_C,f_C,'l'); clim([-20 40]); title('mPFC Spectrogram');
ax3 = subplot(3,1,3); plot_matrix(C,t_C,f_C,'n'); clim([0.5 1]); title('Coherence BLA-mPFC');

linkaxes([ax1 ax2 ax3],'xy');

figure;
plot(f_C,mean(C,1)); xlabel('Frecuency'); ylabel('Coherence'); ylim([0 1]); xlim([0 90]);
figure;
plot(f_C,mean(phi,1)); xlabel('Frecuency'); ylabel('Phase'); ylim([-1 1]); xlim([0 90]);

%%
filt_BLA = eegfilt(lfp_BLA, 1250, 6, 9);
filt_PL = eegfilt(lfp_PL, 1250, 6, 9); 
filt_IL = eegfilt(lfp_IL, 1250, 6, 9);

plot(t,filt_BLA,'color','b'); hold on;
plot(t,filt_PL,'color','g'); hold on;
plot(t,filt_IL,'color','r'); hold on;
%
% Phase_BLA = angle(hilbert(filt_BLA));
% Phase_PL = angle(hilbert(filt_PL));
% Phase_IL = angle(hilbert(filt_IL));
%
% dif_fase = Phase_PL - Phase_IL;
% dif_fase = mod(dif_fase + pi, 2*pi) - pi;
% plot(t,dif_fase);

for i = 1:length(inicio_freezing);
    line([inicio_freezing(i) fin_freezing(i)],[100 100],'Color',[0 0 0],'LineWidth',4);
end

disp(['Plotting events...']);
for i = 1:length(TTL_CS1_inicio);
    line([TTL_CS1_inicio(i) TTL_CS1_fin(i)],[110 110],'Color',[1 0 0],'LineWidth',4);
end
for i = 1:length(TTL_CS2_inicio);
    line([TTL_CS2_inicio(i) TTL_CS2_fin(i)],[110 110],'Color',[0 1 0],'LineWidth',4);
end

%%
dif_fase = Phase_BLA - Phase_IL;
dif_fase = mod(dif_fase + pi, 2*pi) - pi;

for i = 1:20;
    t1 = find(abs(t - TTL_CS1_inicio(i)) == min(abs(t - TTL_CS1_inicio(i))));
    t2 = find(abs(t - TTL_CS1_fin(i)) == min(abs(t - TTL_CS1_fin(i))));
    CS1 = median(dif_fase(1,t1:t2),2);

    t1 = find(abs(t - TTL_CS2_inicio(i)) == min(abs(t - TTL_CS2_inicio(i))));
    t2 = find(abs(t - TTL_CS2_fin(i)) == min(abs(t - TTL_CS2_fin(i))));
    CS2 = median(dif_fase(1,t1:t2),2);

    result(i) = CS2;
end

plot(result);