function Comodulogram = comodulogram_shift(lfp,lfp_shift)
    %% Define the amplitude- and phase-frequencies
    srate = 1250;
    dt = 1/srate;
    data_length = size(lfp, 2);

    % Define the amplitude- and phase-frequencies
%     PhaseFreqVector=2:2:50;
%     AmpFreqVector=10:5:200;
%     PhaseFreq_BandWidth=4;
%     AmpFreq_BandWidth=20;    
    
%     PhaseFreqVector = 1:1:32;
%     AmpFreqVector = 10:5:110;
%     PhaseFreq_BandWidth = 2;
%     AmpFreq_BandWidth = 20;

    PhaseFreqVector = 0:1:30;
    AmpFreqVector = 10:5:200;
    PhaseFreq_BandWidth = 1;
    AmpFreq_BandWidth = 20;

    % Define phase bins
    nbin = 36; % number of phase bins
    position=zeros(1,nbin); % this variable will get the beginning (not the center) of each phase bin (in rads)
    winsize = 2*pi/nbin;
    for j=1:nbin 
        position(j) = -pi+(j-1)*winsize; 
    end

    % Filtering and Hilbert transform
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
        PhaseFreq=eegfilt(lfp_shift,srate,Pf1,Pf2); % filtering 
        PhaseFreqTransformed(jj, :) = angle(hilbert(PhaseFreq)); % getting the phase time series
    end

    % Compute MI and comodulogram
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
end
