function Comodulogram = comodulogram_faster(lfp)
    %% Define the amplitude- and phase-frequencies
    srate = 1250;
    dt = 1/srate;
    data_length = size(lfp, 2);

    PhaseFreqVector = 0:1:30;
    AmpFreqVector = 10:5:200;
    PhaseFreq_BandWidth = 1;
    AmpFreq_BandWidth = 20;

    % Define phase bins
    nbin = 36; % number of phase bins
    position = -pi + (0:nbin-1) * (2 * pi / nbin); % precompute positions

    % Preallocate matrices for results
    Comodulogram = single(zeros(length(PhaseFreqVector), length(AmpFreqVector)));
    AmpFreqTransformed = zeros(length(AmpFreqVector), data_length);
    PhaseFreqTransformed = zeros(length(PhaseFreqVector), data_length);

    % Filtering and Hilbert transform for amplitude
    parfor ii = 1:length(AmpFreqVector)
        Af1 = AmpFreqVector(ii);
        Af2 = Af1 + AmpFreq_BandWidth;
        AmpFreq = eegfilt_faster(lfp, srate, Af1, Af2); % filtering
        AmpFreqTransformed(ii, :) = abs(hilbert(AmpFreq)); % getting the amplitude envelope
    end

    % Filtering and Hilbert transform for phase
    parfor jj = 1:length(PhaseFreqVector)
        Pf1 = PhaseFreqVector(jj);
        Pf2 = Pf1 + PhaseFreq_BandWidth;
        PhaseFreq = eegfilt_faster(lfp, srate, Pf1, Pf2); % filtering 
        PhaseFreqTransformed(jj, :) = angle(hilbert(PhaseFreq)); % getting the phase time series
    end

    % Compute MI and comodulogram
    parfor ii = 1:length(PhaseFreqVector)
        tempComodulogram = zeros(1, length(AmpFreqVector));
        for jj = 1:length(AmpFreqVector)
            [MI, ~] = ModIndex_v2_faster(PhaseFreqTransformed(ii, :), AmpFreqTransformed(jj, :), position);
            tempComodulogram(jj) = MI;
        end
        Comodulogram(ii, :) = tempComodulogram;
    end
end
