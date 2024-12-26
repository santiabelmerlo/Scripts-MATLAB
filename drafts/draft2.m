%% Comodulogram Phase(Degree) vs. Frequency(Hz) in Normalized Power Units

trials_toinclude = 1:4;
srate = 1250;
PhaseFreq_Band = [2,4];
colorlim = ([-0.35 0.35]);
vertlim = ([35 100]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
j = 1; % Inicializamos el valor k

for i = trials_toinclude
    
    if strcmp(paradigm,'aversive')
        trial_len = 1250*60;
    elseif strcmp(paradigm,'appetitive')
        trial_len = 1250*10;
    end
    
    % Calculamos la modulacion para los CSs
    lfp_CS1 = lfp(1,CS1_inicioenS(i):CS1_inicioenS(i) + trial_len-1);
    lfp_CS2 = lfp(1,CS2_inicioenS(i):CS2_inicioenS(i) + trial_len-1);
   
    % Calculamos la modulación para los shift predictors
    k = 1250 * randi(20,1); % Corrimiento de la fase de 1 a 30 seg.
    lfp_CS1_shift = lfp(1,CS1_inicioenS(i)+k:CS1_inicioenS(i)+k+trial_len-1);
    lfp_CS2_shift = lfp(1,CS2_inicioenS(i)+k:CS2_inicioenS(i)+k+trial_len-1);
    
    % Compute the comodulogram
    [C_CS1(:,:,j),P] = ComodulogramDegAmp(lfp_CS1, lfp_CS1, srate, PhaseFreq_Band);
    [C_CS2(:,:,j),P] = ComodulogramDegAmp(lfp_CS2, lfp_CS2, srate, PhaseFreq_Band);
    [C_CS1_shift(:,:,j),P] = ComodulogramDegAmp(lfp_CS1_shift, lfp_CS1, srate, PhaseFreq_Band);
    [C_CS2_shift(:,:,j),P] = ComodulogramDegAmp(lfp_CS2_shift, lfp_CS2, srate, PhaseFreq_Band);
    
    j = j + 1; % Le sumamos 1 a j.
end

% Promediamos todos los comodulogramas
C_CS1 = mean(C_CS1,3);
C_CS2 = mean(C_CS2,3);
C_CS1_shift = mean(C_CS1_shift,3);
C_CS2_shift = mean(C_CS2_shift,3);

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

subplot(221);
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
ylim(vertlim);
clim(colorlim);
title('CS+ Phase vs Gamma Amplitude');

subplot(222);
contourf((P + winsize/2) * 180 / pi, AmpFreqVector + AmpFreq_BandWidth / 2, C_CS2', 1000, 'lines', 'none');
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

subplot(223);
contourf((P + winsize/2) * 180 / pi, AmpFreqVector + AmpFreq_BandWidth / 2, C_CS1_shift', 1000, 'lines', 'none');
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

subplot(224);
contourf((P + winsize/2) * 180 / pi, AmpFreqVector + AmpFreq_BandWidth / 2, C_CS2_shift', 1000, 'lines', 'none');
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
set(gcf, 'Position', [200, 50, 1000, 600]);
