%% Trabajando con mis datos
% El ejemplo lo hice con R17D07 y las muestras 1:100000
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
t = (amplifier_timestamps_lfp - amplifier_timestamps(1))/30000; % Le restamos el primer timestamp y lo pasamos a segundos.

% Cargamos un canal LFP del amplificador
[amplifier_lfp] = LoadBinary(strcat(name,'_lfp.dat'), ch, ch_total);
lfp = amplifier_lfp * 0.195; % Convertir un canal de registro de bits a microvolts (uV).

% Creamos algunas variables necesarias
data_length = size(lfp,2);
srate = Fs;
dt = 1/srate;

data_t = t;
data = lfp;

t = data_t(1,1:100000);
lfp = data(1,1:100000);

% Creamos algunas variables necesarias
data_length = size(lfp,2);
srate = Fs;
dt = 1/srate;

%% Comodulogram Phase(Hz) vs. Frequency(Hz) in Modulation Index Units
% Or use the routine below to make a comodulogram using ModIndex_v1; this takes longer than
% the method outlined above using ModIndex_v2 because in this routine multiple filtering of the same
% frequency range is employed (the Amp frequencies are filtered multiple times, one
% for each phase frequency). This routine might be the only choice though
% for computers with low memory, because it does not create the matrices
% AmpFreqTransformed and PhaseFreqTransformed as the routine above

tic

% define phase bins
nbin = 18; % number of phase bins
position=zeros(1,nbin); % this variable will get the beginning (not the center) of each phase bin (in rads)
winsize = 2*pi/nbin;
for j=1:nbin 
    position(j) = -pi+(j-1)*winsize; 
end

% Default Values by Tort.
% PhaseFreqVector=2:2:50;
% AmpFreqVector=10:5:200;
% PhaseFreq_BandWidth=2;
% AmpFreq_BandWidth=20;

PhaseFreqVector = 1:1:30;
AmpFreqVector = 10:5:160;
PhaseFreq_BandWidth = 1;
AmpFreq_BandWidth = 10;


Comodulogram=zeros(length(PhaseFreqVector),length(AmpFreqVector));

counter1=0;
for Pf1=PhaseFreqVector;
    counter1=counter1+1;
    Pf1; % just to check the progress
    Pf2=Pf1+PhaseFreq_BandWidth;
    
    counter2=0;
    for Af1=AmpFreqVector;
        counter2=counter2+1;
        Af2=Af1+AmpFreq_BandWidth;
        
        [MI,MeanAmp]=ModIndex_v1(lfp,srate,Pf1,Pf2,Af1,Af2,position);
        Comodulogram(counter1,counter2)=MI;

    end
end

toc

% Plot comodulogram
figure();
contourf(PhaseFreqVector+PhaseFreq_BandWidth/2,AmpFreqVector+AmpFreq_BandWidth/2,Comodulogram',1000,'lines','none');
set(gca,'fontsize',14);
ylabel('Amplitude Frequency (Hz)');
xlabel('Phase Frequency (Hz)');
colormap('jet');
colorbar;
xlim([2 30]);
ylim([20 150]);
hcb1 = colorbar; hcb1.YLabel.String = strcat('Modulation Index'); hcb1.FontSize = 12;


% Set figure properties
set(gcf, 'Color', 'white');
set(gcf, 'Position', [100, 600, 500, 400]);

% Obtenemos las posiciones de las figuras
pos_ax1 = get(gca, 'Position');
pos_ax1c = get(hcb1, 'Position');

% Seteamos la posición de la barra de color
set(hcb1, 'Position', [pos_ax1c(1) 0.42 pos_ax1c(3) 0.2]);

% Seteamos la posición de la figura
set(gca, 'Position', [0.13 0.18 0.65 0.7]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Comodulogram Phase(Degree) vs. Frequency(Hz) in Normalized Power Units

% Define the frequency ranges
PhaseFreq_Band = [2, 5]; % Phase frequency band
AmpFreqVector = 20:5:160; % Amplitude frequencies
AmpFreq_BandWidth = 5; % Amplitude frequency bandwidth

% Define phase bins
nbin = 18; % Number of phase bins
position = zeros(1, nbin); % Phase bin positions
winsize = 2 * pi / nbin;
for j = 1:nbin
    position(j) = -pi + (j-1) * winsize; % -pi to pi
end

% Compute the phase of the phase frequency band
PhaseFreq = eegfilt(lfp, srate, PhaseFreq_Band(1), PhaseFreq_Band(2));
Phase = angle(hilbert(PhaseFreq));
% Phase values are naturally in -pi to pi

% Initialize the comodulogram matrix
Comodulogram = zeros(nbin, length(AmpFreqVector));

% Compute the phase-amplitude coupling
for j = 1:length(AmpFreqVector)
    AmpFreq = eegfilt(lfp, srate, AmpFreqVector(j), AmpFreqVector(j) + AmpFreq_BandWidth);
    Amp = abs(hilbert(AmpFreq));
    
    MeanAmp = zeros(1, nbin);
    for k = 1:nbin
        I = find(Phase < position(k) + winsize & Phase >= position(k));
        MeanAmp(k) = mean(Amp(I));
    end
    
    % Compute the modulation index
    MI = (log(nbin) - (-sum((MeanAmp/sum(MeanAmp)) .* log((MeanAmp/sum(MeanAmp)))))) / log(nbin);
    Comodulogram(:, j) = MeanAmp / sum(MeanAmp); % Normalize the amplitude distribution
end

% Extend the Comodulogram for seamless transition
ExtendedComodulogram = [Comodulogram(end,:); Comodulogram; Comodulogram(1,:)]; % Duplicate the first and last bins at the ends
ExtendedPosition = [-pi-winsize, position, pi+winsize]; % Extend the phase positions

% Normalize the comodulogram to be centered around 0
ExtendedComodulogram = (ExtendedComodulogram / mean(mean(ExtendedComodulogram)) - 1) * 20; % Normalize to center around 0

% Plot the comodulogram
figure();
contourf((ExtendedPosition + winsize/2) * 180 / pi, AmpFreqVector + AmpFreq_BandWidth / 2, ExtendedComodulogram', 1000, 'lines', 'none');
set(gca, 'fontsize', 14);
xlabel('Phase (Degrees)');
ylabel('Frequency (Hz)');
colormap('jet');
colorbar;
hcb1 = colorbar;
hcb1.YLabel.String = 'Normalized Power';
hcb1.FontSize = 12;

% Manually set x-axis ticks and labels
set(gca, 'XTick', -180:90:180);
set(gca, 'YTick', 30:10:150);
xlim([-180 180]);
ylim([30 150]);
clim([-1.5 1.5]);

title('Comodulogram Beta vs Gamma');

% Set figure properties
set(gcf, 'Color', 'white');
set(gcf, 'Position', [100, 600, 500, 400]);

% Obtenemos las posiciones de las figuras
pos_ax1 = get(gca, 'Position');
pos_ax1c = get(hcb1, 'Position');

% Seteamos la posición de la barra de color
set(hcb1, 'Position', [pos_ax1c(1) 0.42 pos_ax1c(3) 0.2]);

% Seteamos la posición de la figura
set(gca, 'Position', [0.13 0.18 0.65 0.7]);

%% Plotting the signal
clf 
subplot(2,1,1)
plot(t,lfp)
xlim([0 1])
set(gca,'fontsize',14)
xlabel('time (s)')
ylabel('mV')

%% Constructing an example

clear
clc

data_length = 2^15;
srate = 1024;
dt = 1/srate;
t = dt*(1:data_length);

nonmodulatedamplitude = 2; % increase this to get less modulation (lower MI value)

Phase_Modulating_Freq = 10;
Amp_Modulated_Freq = 80;

lfp = (0.2*(sin(2*pi*t*Phase_Modulating_Freq)+1)+nonmodulatedamplitude*0.1).*sin(2*pi*t*Amp_Modulated_Freq)+sin(2*pi*t*Phase_Modulating_Freq);
lfp = lfp+1*randn(1,length(lfp));

%% Working with actual LFP signals (example .mat file available at github)

clear all;
clc;
load('LFP_HG_HFO.mat')

lfp = lfpHG; % or lfp = lfpHFO;
data_length = length(lfp);
srate = 1000;
dt = 1/srate;
t = (1:data_length)*dt;

%% Define the amplitude- and phase-frequencies

PhaseFreqVector = 1:1:30;
AmpFreqVector = 10:5:160;

PhaseFreq_BandWidth = 1;
AmpFreq_BandWidth = 10;

% PhaseFreqVector = 2:1:20;
% AmpFreqVector = 5:5:140;
% 
% PhaseFreq_BandWidth = 1;
% AmpFreq_BandWidth = 20;


% Define phase bins

nbin = 36; % number of phase bins
position=zeros(1,nbin); % this variable will get the beginning (not the center) of each phase bin (in rads)
winsize = 2*pi/nbin;
for j=1:nbin 
    position(j) = -pi+(j-1)*winsize; 
end

% Filtering and Hilbert transform

'CPU filtering'
tic
Comodulogram=single(zeros(length(PhaseFreqVector),length(AmpFreqVector)));
AmpFreqTransformed = zeros(length(AmpFreqVector), data_length);
PhaseFreqTransformed = zeros(length(PhaseFreqVector), data_length);

for ii=1:length(AmpFreqVector)
    Af1 = AmpFreqVector(ii);
    Af2=Af1+AmpFreq_BandWidth;
    AmpFreq=eegfilt(lfp,srate,Af1,Af2); % filtering
    AmpFreqTransformed(ii, :) = abs(hilbert(AmpFreq)); % getting the amplitude envelope
end

for jj=1:length(PhaseFreqVector)
    Pf1 = PhaseFreqVector(jj);
    Pf2 = Pf1 + PhaseFreq_BandWidth;
    PhaseFreq=eegfilt(lfp,srate,Pf1,Pf2); % filtering 
    PhaseFreqTransformed(jj, :) = angle(hilbert(PhaseFreq)); % getting the phase time series
end
toc

% Compute MI and comodulogram

'Comodulation loop'

counter1=0;
for ii=1:length(PhaseFreqVector)
counter1=counter1+1;

    Pf1 = PhaseFreqVector(ii);
    Pf2 = Pf1+PhaseFreq_BandWidth;
    
    counter2=0;
    for jj=1:length(AmpFreqVector)
    counter2=counter2+1;
    
        Af1 = AmpFreqVector(jj);
        Af2 = Af1+AmpFreq_BandWidth;
        [MI,MeanAmp]=ModIndex_v2(PhaseFreqTransformed(ii, :), AmpFreqTransformed(jj, :), position);
        Comodulogram(counter1,counter2)=MI;
    end
end
toc

% Plot comodulogram
clf
% Comodulogram = Comodulogram ./ 1e-4;
contourf(PhaseFreqVector+PhaseFreq_BandWidth/2,AmpFreqVector+AmpFreq_BandWidth/2,Comodulogram',1000,'lines','none');
set(gca,'fontsize',14);
ylabel('Amplitude Frequency (Hz)');
xlabel('Phase Frequency (Hz)');
colormap('jet');
colorbar;
hcb1 = colorbar; hcb1.YLabel.String = 'Modulation Index'; hcb1.FontSize = 14;
clim([0 3e-4]);
xlim([2 30]);
ylim([20 150])

%%  Use the routine below to look at specific pairs of frequency ranges:
srate = 1250;
lfp1 = lfp(1:1250*5);
% Define phase bins

nbin = 18; % number of phase bins
position=zeros(1,nbin); % this variable will get the beginning (not the center) of each phase bin (in rads)
winsize = 2*pi/nbin;
for j=1:nbin 
    position(j) = -pi+(j-1)*winsize; 
end

Pf1 = 2;
Pf2 = 5;
Af1 = 40;
Af2 = 60;

[MI,MeanAmp] = ModIndex_v1(lfp1,srate,Pf1,Pf2,Af1,Af2,position);

bar(10:20:720,[MeanAmp,MeanAmp]/sum(MeanAmp),'k')
xlim([0 720])
set(gca,'xtick',0:360:720)
xlabel('Phase (Deg)')
ylabel('Amplitude')
title(['MI = ' num2str(MI)])
