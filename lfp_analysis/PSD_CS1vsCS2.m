%% Calculamos PSD de CS+ vs CS-
% Script para plotear el PSD promedio del CS+ vs el CS-
clc
clear all
clearvars -except PSD_CS1 PSD_CS2
path = pwd;
[~,name,~] = fileparts(pwd);
name = name(1:6);

% Seteamos qué canal queremos levantar de la señal
region = 'BLA';
% region = 'PL';
% region = 'IL';

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

% Cargo el espectrograma ya calculado
disp(['Uploading full band multi-taper spectrogram...']);
load(strcat(name,'_specgram_',region,'LowFreq.mat'));  

% Quitamos las partes del espectrograma que tienen ruido
disp(['Removing noise from analysis...']);
noise = csvread(strcat(name,'_noise.csv'));
% Busco las posiciones en S donde se ubica el ruido
for i = 1:size(noise,1);
    noise_enS(i) = find(abs(t-noise(i)) == min(abs(t-noise(i))));
    if noise_enS(i) < 5
        S(noise_enS(1):noise_enS(i)+5,:) = NaN;
    else
        S(noise_enS(i)-5:noise_enS(i)+5,:) = NaN;
    end
end

% Cargo los tiempos de los tonos
load(strcat(name,'_freezing.mat'),'TTL_CS1_inicio','TTL_CS1_fin','TTL_CS2_inicio','TTL_CS2_fin');

% Quitamos interpolamos la franja de 100 Hz que es ruidosa
fmin = find(abs(f-98) == min(abs(f-98)));
fmax = find(abs(f-102) == min(abs(f-102)));
for i = 1:fmax-fmin;
    S(:,fmin+i) = S(:,fmin) + i*((S(:,fmax+1)-S(:,fmin-1))/(fmax-fmin));
end

% Normalización del espectrograma
S = bsxfun(@times, S, f); 
S = bsxfun(@rdivide, S, nanmean(nanmean(S,1))); 

% Busco las posiciones en S donde inician y finalizan los tonos
j = 1;
for i = 1:size(TTL_CS1_inicio,1);
    CS1_inicioenS(j) = find(abs(t-TTL_CS1_inicio(i)) == min(abs(t-TTL_CS1_inicio(i))));
    CS1_finenS(j) = find(abs(t-TTL_CS1_fin(i)) == min(abs(t-TTL_CS1_fin(i))));
    CS2_inicioenS(j) = find(abs(t-TTL_CS2_inicio(i)) == min(abs(t-TTL_CS2_inicio(i))));
    CS2_finenS(j) = find(abs(t-TTL_CS2_fin(i)) == min(abs(t-TTL_CS2_fin(i))));
    j = j + 1;
end

% Metemos todos los pedazos de S durante el CS en una gran matriz y
% calculamos la media

S_CS1 = [];
S_CS2 = [];

window= round(mean(CS1_finenS - CS1_inicioenS));

for i = 1:size(CS1_inicioenS,2);
    S_CS1(:,:,i) = S(CS1_inicioenS(1,i):CS1_inicioenS(1,i)+window,:);
    S_CS2(:,:,i) = S(CS2_inicioenS(1,i):CS2_inicioenS(1,i)+window,:);
end
S_CS1 = nanmean(S_CS1,1); S_CS1 = squeeze(S_CS1); S_CS1 = S_CS1';
S_CS2 = nanmean(S_CS2,1); S_CS2 = squeeze(S_CS2); S_CS2 = S_CS2';

nanmean(S_CS1);
nanmean(S_CS2);

%%
figure();
% Espectro de potencias para el CS+
S_data = S_CS1;
y = nanmean(S_data); % your mean vector;
x = f;
stdem = nanstd(S_data,1)/sqrt(size(S_data,1));
curve1 = y + stdem;
curve2 = y - stdem;
x2 = [x, fliplr(x)];
inBetween = [curve1, fliplr(curve2)];
p1 = fill(x2, inBetween, cs1_color,'LineStyle','none');
set(p1,'facealpha',.4)
hold on;
plot(x, y, 'Color',cs1_color, 'LineWidth', 1);
hold on;
clear S_data;

% Espectro de potencias para el CS+
S_data = S_CS2;
y = nanmean(S_data); % your mean vector;
x = f;
stdem = nanstd(S_data,1)/sqrt(size(S_data,1));
curve1 = y + stdem;
curve2 = y - stdem;
x2 = [x, fliplr(x)];
inBetween = [curve1, fliplr(curve2)];
p2 = fill(x2, inBetween,cs2_color,'LineStyle','none');
set(p2,'facealpha',.3)
hold on;
plot(x, y, 'Color',cs2_color, 'LineWidth', 1);
hold on;
clear S_data;

xlim([1 100]);
lims = ylim;
ylim1 = lims(1);
ylim2 = lims(2);
xlabel('Frequency (Hz)');
ylabel('Normalized Power (a.u.)');
title('Power Spectrum Density (PSD)');
hold on;
set(gca, 'color', 'w');

%%
% Espectro de potencias para el CS+
S_data = PSD_CS1;
y = nanmean(S_data); % your mean vector;
x = f;
stdem = nanstd(S_data,1)/sqrt(size(S_data,1));
curve1 = y + stdem;
curve2 = y - stdem;
x2 = [x, fliplr(x)];
inBetween = [curve1, fliplr(curve2)];
p1 = fill(x2, inBetween, cs1_color,'LineStyle','none');
set(p1,'facealpha',.4)
hold on;
plot(x, y, 'Color',cs1_color, 'LineWidth', 1);
hold on;
clear S_data;

% Espectro de potencias para el CS-
S_data = PSD_CS2;
y = nanmean(S_data); % your mean vector;
x = f;
stdem = nanstd(S_data,1)/sqrt(size(S_data,1));
curve1 = y + stdem;
curve2 = y - stdem;
x2 = [x, fliplr(x)];
inBetween = [curve1, fliplr(curve2)];
p2 = fill(x2, inBetween,cs2_color,'LineStyle','none');
set(p2,'facealpha',.3)
hold on;
plot(x, y, 'Color',cs2_color, 'LineWidth', 1);
hold on;
clear S_data;

xlim([1 150]);
lims = ylim;
ylim1 = lims(1);
ylim2 = lims(2);
xlabel('Frequency (Hz)');
ylabel('Power (a.u.)');
% title('Power Spectrum Density (PSD)');
title('Reinstatement');
hold on;
set(gca, 'color', 'w');
set(gca, 'YTick', 0:1:ylim2);