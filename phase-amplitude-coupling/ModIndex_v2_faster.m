% [MI,MeanAmp]=ModIndex_v2_faster(Phase, Amp, position)
%
% Phase-amplitude cross-frequency coupling measure:
%
% Inputs:
% Phase = phase time series
% Amp = amplitude time series
% position = phase bins (left boundary)
%
% Outputs:
% MI = modulation index (see Tort et al PNAS 2008, 2009 and J Neurophysiol 2010)
% MeanAmp = amplitude distribution over phase bins (non-normalized)

function [MI, MeanAmp] = ModIndex_v2(Phase, Amp, position)
    nbin = length(position);  
    winsize = 2 * pi / nbin;
    
    % Compute the mean amplitude in each phase bin using logical indexing
    MeanAmp = zeros(1, nbin);
    for j = 1:nbin
        bin_indices = (Phase >= position(j)) & (Phase < position(j) + winsize);
        MeanAmp(j) = mean(Amp(bin_indices)); 
    end
    
    % Quantifying the amount of amplitude modulation by means of a
    % normalized entropy index (Tort et al PNAS 2008):
    P = MeanAmp / sum(MeanAmp); % Normalize MeanAmp
    H = -sum(P .* log(P + eps)); % Compute entropy (added eps to avoid log(0))
    MI = (log(nbin) - H) / log(nbin);
end
