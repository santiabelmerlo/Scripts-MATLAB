function [wave,phase,period,scale,coi,rawwave] = NP_Wavelet(EEGSR,EEGchunk,UpperLimitHz,LowerLimitHz,NumScales,toplot)
% [tempwave,period,scale,coi] = NP_Wavelet(EEGSR,EEGchunk,UpperLimitHz,LowerLimitHz,NumScales)
if (nargin < 6)
  toplot = 0;
end

dt = 1/EEGSR; %  time per sample of the eeg file

s0 = 1 / UpperLimitHz;

j1 = NumScales; % # of scales: frequency resolution

LowerLimitSeconds = 1 / LowerLimitHz;
dj = log2((LowerLimitSeconds/s0))/j1;

[rawwave,period,scale,coi] = wavelet(EEGchunk,dt,1,dj,s0,j1);

wave  = log(abs(rawwave).^2);
phase = angle(rawwave);
