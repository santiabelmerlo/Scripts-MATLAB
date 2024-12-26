function [C,P] = ComodulogramDegAmp(lfp1,lfp2, srate, PhaseFreq_Band)
    % ComodulogramDegAmp compute the phase amplitude comodulogram in
    % degrees in the x axis and normalized amplitude in the y axis.
    % Usage: [C,P] = ComodulogramDegAmp(lfp1, lfp2, srate, PhaseFreq_Band)
    % With: srate = 1250; PhaseFreq_Band = [2,3] (4-Hz modulation)

    % Compute the length of the data
    data_length = length(lfp1);

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

    % Compute the phase of the phase frequency band
    PhaseFreq = eegfilt(lfp1, srate, PhaseFreq_Band(1), PhaseFreq_Band(2));
    Phase = angle(hilbert(PhaseFreq));

    % Initialize the comodulogram matrix
    Comodulogram = zeros(nbin, length(AmpFreqVector));

    % Compute the phase-amplitude coupling
    for j = 1:length(AmpFreqVector)
        AmpFreq = eegfilt(lfp2, srate, AmpFreqVector(j), AmpFreqVector(j) + AmpFreq_BandWidth);
        Amp = zscore(abs(hilbert(AmpFreq)), 0, 2); % Extract the amplitude of the Hilbert transform and z-score it

        MeanAmp = zeros(1, nbin);
        for k = 1:nbin
            I = find(Phase < position(k) + winsize & Phase >= position(k));
            MeanAmp(k) = mean(Amp(I));
        end

        Comodulogram(:, j) = MeanAmp;
    end

    % Extend the Comodulogram for seamless transition
    C = [Comodulogram(end, :); Comodulogram; Comodulogram(1, :)]; % Duplicate the first and last bins at the ends
    P = [-pi-winsize, position, pi+winsize]; % Extend the phase position
end
