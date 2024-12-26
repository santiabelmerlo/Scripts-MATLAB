%%

%% Working with my data
clc
clear all
path = pwd;
[~,name,~] = fileparts(pwd);
name = name(1:6);

% Seteamos qué canal queremos levantar de la señal
Fs = 1250; % Frecuencia de sampleo

% load(strcat(name,'_sessioninfo.mat'), 'BLA_mainchannel'); ch = BLA_mainchannel; clear BLA_mainchannel; % Canal a levantar
load(strcat(name,'_sessioninfo.mat'), 'PL_mainchannel'); ch = PL_mainchannel; clear PL_mainchannel; % Canal a levantar
% load(strcat(name,'_sessioninfo.mat'), 'IL_mainchannel'); ch = IL_mainchannel; clear IL_mainchannel; % Canal a levantar
% load(strcat(name,'_sessioninfo.mat'), 'EO_channels'); ch = EO_channels; clear EO_channels; % Canal a levantar

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
disp(['Loading LFP signal...']);
[lfp] = LoadBinary(strcat(name,'_lfp.dat'), ch, ch_total);
lfp = lfp * 0.195; % Convertir un canal de registro de bits a microvolts (uV).
clear amplifier_timestamps amplifier_timestamps_lfp;

% Filtramos la señal
disp(['Filtering LFP signal...']);
highpass = 0.1; lowpass = 300; % Frecuencias de corte del filtro. Corte pasabajos en nyquist frequency.
data = lfp; % Señal que queremos filtrar
samplePeriod = 1/1250; % Frecuencia de muestreo de la señal subsampleada
% Aplicamos un filtro pasa altos con corte en 0.1 Hz
filtHPF = (2*highpass)/(1/samplePeriod);
[b, a] = butter(4, filtHPF, 'high');
data_hp = filtfilt(b, a, data);
% Aplicamos un filtro pasa bajos con corte en 300 Hz
filtLPF = (2*lowpass)/(1/samplePeriod);
[b, a] = butter(4, filtLPF, 'low');
data_hlp = filtfilt(b, a, data_hp); %señal de mag de acel filtrada
lfp = data_hlp; % Guardamos la señal filtrada como "amplifier_BLA_downsample_filt"
clear data_hlp a b data filtHPF data_hp filtLPF highpass lowpass samplePeriod;% Borramos las variables que no me sirven más

data_length = length(lfp);
srate = 1250;
dt = 1/srate;

% Borramos momentos de ruido
% lfp_noise = isoutlier(lfp,'median',10);
% lfp_noise = extendoutlier(lfp_noise,Fs*2.5);
% lfp(~lfp_noise == 0) = 0;
% figure()
% plot(lfp)

% % Busco las posiciones en S donde inician y finalizan los tonos
% j = 1;
% for i = 1:size(TTL_CS1_inicio,1);
%     CS1_inicioenS(j) = min(find(abs(t-TTL_CS1_inicio(i)) == min(abs(t-TTL_CS1_inicio(i)))));
%     CS1_finenS(j) = min(find(abs(t-TTL_CS1_fin(i)) == min(abs(t-TTL_CS1_fin(i)))));
%     CS2_inicioenS(j) = min(find(abs(t-TTL_CS2_inicio(i)) == min(abs(t-TTL_CS2_inicio(i)))));
%     CS2_finenS(j) = min(find(abs(t-TTL_CS2_fin(i)) == min(abs(t-TTL_CS2_fin(i)))));
%     j = j + 1;
% end 

%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PhaseF = '4hz'; % Colocar que rango de frecuencias quiero promediar como '4hz', 'theta' o 'beta'
AmpF = 'sgamma'; % Colocar que rango de frecuencias quiero promediar como 'sgamma' o 'fgamma'
SD = [1,3];
shift = 0; % Whether to calculate shift predictor or not.
npick = 10; % How many segments to pick per session
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Determinamos en que rango vamos a filtrar
if strcmp(PhaseF,'4hz')
    PhaseFreq_Band = [2,5.3];
elseif strcmp(PhaseF,'theta')
    PhaseFreq_Band = [5.3,9.6];
elseif strcmp(PhaseF,'beta')
    PhaseFreq_Band = [13,30];
end

theta = eegfilt(lfp,srate,PhaseFreq_Band(1),PhaseFreq_Band(2));
theta = abs(hilbert(theta));
theta = zscore(theta,1,2);

pos = 1:srate*10:size(theta,2);

for i = 1:size(pos,2)-1
    H(i) = median(theta(1,pos(1,i):pos(1,i+1)));
end

% H = zscorem(H,2); % Use zscore or zscorem si quiero normalizar la amplitud de la hilbert segun la media o la mediana. La primera opcion es más sensible a los ruidos.
H = zscore(H,1,2); % Use zscore or zscorem si quiero normalizar la amplitud de la hilbert segun la media o la mediana. La primera opcion es más sensible a los ruidos.

clear C_CS1 Comodulogram Comodulograms Modulation NormAmp2 NormAmp NormampP
posiciones = pos(H >= SD(1) & H <= SD(2));
NormAmp = (H(H >= SD(1) & H <= SD(2)))';

% Comodulogram Phase(Degree) vs. Frequency(Hz) in Normalized Power Units
colorlim = ([-0.35 0.35]);
vertlim = ([35 100]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
j = 1; % Inicializamos el valor k

pick = randperm(size(posiciones,2), npick);

for l = 1:size(pick,2)
    i = pick(1,l);
    disp(strcat('Posición = ',num2str(i),' de ',num2str(size(posiciones,2))))
    if posiciones(1,i)+srate*30 > size(lfp,2)
        % Do nothing
    else
        % Calculamos la modulacion para los CSs
        lfp_CS1 = lfp(1,posiciones(1,i):posiciones(1,i) + (srate*10));

        % Calculamos la modulación para los shift predictors
        k = 1250 * randi(20,1); % Corrimiento de la fase de 1 a 20 seg.
        lfp_CS1_shift = lfp(1,posiciones(1,i)+k:posiciones(1,i)+(srate*10)+k);

        % Compute the comodulogram
        [C_CS1(:,:,j),P] = ComodulogramDegAmp(lfp_CS1, lfp_CS1, srate, PhaseFreq_Band);
        if shift == 0;
            Comodulogram(:,:,j) = comodulogram(lfp_CS1);
            NormAmp2(j,1) = NormAmp(i,1);
        elseif shift == 1;
            Comodulogram(:,:,j) = comodulogram_shift(lfp_CS1,lfp_CS1_shift); 
        end
        j = j + 1; % Le sumamos 1 a j.
    end
end

PhaseFreqVector = 0:1:30;
AmpFreqVector = 10:5:200;
PhaseFreq_BandWidth = 1;
AmpFreq_BandWidth = 20;

Comodulogram_phase = PhaseFreqVector+PhaseFreq_BandWidth/2;
Comodulogram_amp = AmpFreqVector+AmpFreq_BandWidth/2;

% Determinamos en que rango promediar de acuerdo al valor que toma PhaseF
if strcmp(PhaseF,'4hz')
    range1 = [2:4]; % [2:5]
elseif strcmp(PhaseF,'theta')
    range1 = [6:10];
elseif strcmp(PhaseF,'beta')
    range1 = [14:30];
end

% Determinamos en que rango promediar de acuerdo al valor que toma PhaseF
if strcmp(AmpF,'sgamma')
    range2 = [6:9];
elseif strcmp(AmpF,'fgamma')
    range2 = [10:17];
end

Modulation = Comodulogram(range1,range2,:);
Modulation = median(Modulation,1); % Si quiero buscar el peak usar max
Modulation = median(Modulation,2); % Si quiero buscar el peak usar max
% Modulation = mean(Modulation,1); % Si quiero buscar el peak usar max
% Modulation = mean(Modulation,2); % Si quiero buscar el peak usar max
% Modulation = max(Modulation,[],1); % Si quiero buscar el peak usar max
% Modulation = max(Modulation,[],2); % Si quiero buscar el peak usar max
Modulation = squeeze(Modulation);

aleluya()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Promediamos todos los comodulogramas
C_CS1 = mean(C_CS1,3);

% Ploteamos el comodulograma
% Definimos algunas cosas antes de plotear
% Define the frequency ranges
AmpFreqVector = 20:5:200; % Amplitude frequencies
AmpFreq_BandWidth = 10; % Amplitude frequency bandwidth
% Define phase bins
nbin = 5; % Number of phase bins
position = zeros(1, nbin); % Phase bin positions
winsize = 2 * pi / nbin;
for j = 1:nbin
    position(j) = -pi + (j-1) * winsize; % -pi to pi
end

figure();
contourf((P + winsize/2) * 180 / pi, AmpFreqVector + AmpFreq_BandWidth / 2, C_CS1', 1000, 'lines', 'none');
set(gca, 'fontsize', 14);
xlabel('Phase (Degrees)');
ylabel('Frequency (Hz)');
colormap('jet');
colorbar;
hcb1 = colorbar;
hcb1.YLabel.String = 'Norm. Amplitude';
hcb1.FontSize = 12;
set(gca, 'XTick', -180:90:180);
set(gca, 'YTick', 30:10:200);
xlim([-180 180]);
% ylim(vertlim);
ylim([30 120]);
clim(colorlim);
title('CS+ Phase vs Gamma Amplitude');

% Set figure properties
set(gcf, 'Color', 'white');
set(gcf, 'Position', [200, 50, 1000, 600]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Define the amplitude- and phase-frequencies
PhaseFreqVector = 0:1:30;
AmpFreqVector = 10:5:200;
PhaseFreq_BandWidth = 1;
AmpFreq_BandWidth = 20;

Comodulograms = mean(Comodulogram,3);
figure();
contourf(PhaseFreqVector+PhaseFreq_BandWidth/2,AmpFreqVector+AmpFreq_BandWidth/2,Comodulograms',1000,'lines','none');  % Aumentar valor de 30 a 1000 Si quiero más 
set(gca,'fontsize',14);
ylabel('Amplitude Frequency (Hz)');
xlabel('Phase Frequency (Hz)');
colormap('jet');
colorbar;
hcb1 = colorbar; hcb1.YLabel.String = strcat('Modulation Index'); hcb1.FontSize = 12;
xlim([1.5 12]);
ylim([30 100]);
clim([0 0.005]);