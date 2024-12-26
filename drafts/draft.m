%% Comodulogram Phase(Degree) vs. Frequency(Hz) in Normalized Power Units

trials_toinclude = 1:20;
freq_band = [2,3];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic

for i = trials_toinclude
    
    if strcmp(paradigm,'aversive')
        trial_len = 1250*60;
    else
        trial_len = 1250*10;
    end
    
    % Calculamos la modulacion para los CSs
    lfp_CS1 = lfp(1,CS1_inicioenS(i):CS1_inicioenS(i) +trial_len-1);
    data_length = length(lfp_CS1);
    lfp_CS2 = lfp(1,CS2_inicioenS(i):CS2_inicioenS(i) +trial_len-1);
   
    % Calculamos la modulación para los shift predictors
    k = 1250 * randi(30,1); % Corrimiento de la fase de 1 a 30 seg.
    lfp_CS1_shift = lfp(1,CS1_inicioenS(i)+k:CS1_inicioenS(i)+k+trial_len-1);
    lfp_CS2_shift = lfp(1,CS2_inicioenS(i)+k:CS2_inicioenS(i)+k+trial_len-1);
    
    % Define the frequency ranges
    PhaseFreq_Band = freq_band; % Phase frequency band
    AmpFreqVector = 20:5:200; % Amplitude frequencies
    AmpFreq_BandWidth = 10; % Amplitude frequency bandwidth

    % Definimos los bins de la fase
    nbin = 5; % Numeros de bin de fase
    position = zeros(1, nbin); % Phase bin positions
    winsize = 2 * pi / nbin;
    for j = 1:nbin
        position(j) = -pi + (j-1) * winsize; % -pi to pi
    end

    % Compute the phase of the phase frequency band
    PhaseFreq_CS1 = eegfilt(lfp_CS1, srate, PhaseFreq_Band(1), PhaseFreq_Band(2));
    PhaseFreq_CS2 = eegfilt(lfp_CS1, srate, PhaseFreq_Band(1), PhaseFreq_Band(2));
    PhaseFreq_CS1_shift = eegfilt(lfp_CS1_shift, srate, PhaseFreq_Band(1), PhaseFreq_Band(2));
    PhaseFreq_CS2_shift = eegfilt(lfp_CS1_shift, srate, PhaseFreq_Band(1), PhaseFreq_Band(2));
    Phase_CS1 = angle(hilbert(PhaseFreq_CS1));
    Phase_CS2 = angle(hilbert(PhaseFreq_CS2));
    Phase_CS1_shift = angle(hilbert(PhaseFreq_CS1_shift));
    Phase_CS2_shift = angle(hilbert(PhaseFreq_CS2_shift));

    % Initialize the comodulogram matrix
    Comodulogram_CS1 = zeros(nbin, length(AmpFreqVector));
    Comodulogram_CS2 = zeros(nbin, length(AmpFreqVector));
    Comodulogram_CS1_shift = zeros(nbin, length(AmpFreqVector));
    Comodulogram_CS2_shift = zeros(nbin, length(AmpFreqVector));

    % Compute the phase-amplitude coupling for CS1
    for j = 1:length(AmpFreqVector)
        AmpFreq_CS1 = eegfilt(lfp_CS1, srate, AmpFreqVector(j), AmpFreqVector(j) + AmpFreq_BandWidth);
        AmpFreq_CS2 = eegfilt(lfp_CS2, srate, AmpFreqVector(j), AmpFreqVector(j) + AmpFreq_BandWidth);
        Amp_CS1 = zscore(abs(hilbert(AmpFreq_CS1)),0,2); %Extraemos la amplitud de la transformada de Hilbert y la z-scoreamos
        Amp_CS2 = zscore(abs(hilbert(AmpFreq_CS2)),0,2); %Extraemos la amplitud de la transformada de Hilbert y la z-scoreamos

        % Para el CS1
        MeanAmp_CS1 = zeros(1, nbin);
        for k = 1:nbin
            I = find(Phase_CS1 < position(k) + winsize & Phase_CS1 >= position(k));
            MeanAmp_CS1(k) = mean(Amp_CS1(I));
        end
        Comodulogram_CS1(:, j) = MeanAmp_CS1;
        
        % Para el CS2
        MeanAmp_CS2 = zeros(1, nbin);
        for k = 1:nbin
            I = find(Phase_CS2 < position(k) + winsize & Phase_CS2 >= position(k));
            MeanAmp_CS2(k) = mean(Amp_CS2(I));
        end
        Comodulogram_CS2(:, j) = MeanAmp_CS2;   
        
        % Para el CS1 shift
        MeanAmp_CS1_shift = zeros(1, nbin);
        for k = 1:nbin
            I = find(Phase_CS1_shift < position(k) + winsize & Phase_CS1_shift >= position(k));
            MeanAmp_CS1_shift(k) = mean(Amp_CS1(I));
        end
        Comodulogram_CS1_shift(:, j) = MeanAmp_CS1_shift;
        
        % Para el CS2 shift
        MeanAmp_CS2_shift = zeros(1, nbin);
        for k = 1:nbin
            I = find(Phase_CS2_shift < position(k) + winsize & Phase_CS2_shift >= position(k));
            MeanAmp_CS2_shift(k) = mean(Amp_CS2(I));
        end
        Comodulogram_CS2_shift(:, j) = MeanAmp_CS2_shift;         
        
    end
    
    % Extend the Comodulogram position
    ExtendedPosition = [-pi-winsize, position, pi+winsize]; % Extend the phase position
    % Extend the Comodulogram for seamless transition for CS1
    ExtendedComodulogram_CS1 = [Comodulogram_CS1(end,:); Comodulogram_CS1; Comodulogram_CS1(1,:)]; % Duplicate the first and last bins at the ends
    ExtendedComodulogram_CS1(:,:,i) = ExtendedComodulogram_CS1;
    % Extend the Comodulogram for seamless transition for CS2
    ExtendedComodulogram_CS2 = [Comodulogram_CS2(end,:); Comodulogram_CS2; Comodulogram_CS2(1,:)]; % Duplicate the first and last bins at the ends
    ExtendedComodulogram_CS2(:,:,i) = ExtendedComodulogram_CS2;
    % Extend the Comodulogram for seamless transition for CS1_shift
    ExtendedComodulogram_CS1_shift = [Comodulogram_CS1_shift(end,:); Comodulogram_CS1_shift; Comodulogram_CS1_shift(1,:)]; % Duplicate the first and last bins at the ends
    ExtendedComodulogram_CS1_shift(:,:,i) = ExtendedComodulogram_CS1_shift;
    % Extend the Comodulogram for seamless transition for CS2_shift
    ExtendedComodulogram_CS2_shift = [Comodulogram_CS2_shift(end,:); Comodulogram_CS2_shift; Comodulogram_CS2_shift(1,:)]; % Duplicate the first and last bins at the ends
    ExtendedComodulogram_CS2_shift(:,:,i) = ExtendedComodulogram_CS2_shift;
 
end

% Promediamos todos los comodulogramas
ExtendedComodulogram_CS1 = mean(ExtendedComodulogram_CS1,3);
ExtendedComodulogram_CS2 = mean(ExtendedComodulogram_CS2,3);
ExtendedComodulogram_CS1_shift = mean(ExtendedComodulogram_CS1_shift,3);
ExtendedComodulogram_CS2_shift = mean(ExtendedComodulogram_CS2_shift,3);

% Plot the comodulogram
colorlim = ([-0.5 0.5]);
vertlim = ([35 100]);

figure();
contourf((ExtendedPosition + winsize/2) * 180 / pi, AmpFreqVector + AmpFreq_BandWidth / 2, ExtendedComodulogram_CS1', 1000, 'lines', 'none');
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
ylim(vertlim);
clim(colorlim);
title('CS+ Phase vs Gamma Amplitude');
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

figure();
contourf((ExtendedPosition + winsize/2) * 180 / pi, AmpFreqVector + AmpFreq_BandWidth / 2, ExtendedComodulogram_CS2', 1000, 'lines', 'none');
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
ylim(vertlim);
clim(colorlim);
title('CS- Phase vs Gamma Amplitude');
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

figure();
contourf((ExtendedPosition + winsize/2) * 180 / pi, AmpFreqVector + AmpFreq_BandWidth / 2, ExtendedComodulogram_CS1_shift', 1000, 'lines', 'none');
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
ylim(vertlim);
clim(colorlim);
title('CS+ (Shift Predictor)');
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

figure();
contourf((ExtendedPosition + winsize/2) * 180 / pi, AmpFreqVector + AmpFreq_BandWidth / 2, ExtendedComodulogram_CS2_shift', 1000, 'lines', 'none');
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
ylim(vertlim);
clim(colorlim);
title('CS- (Shift Predictor)');
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

